#!/usr/bin/perl

################################################################################
# MATA (Masakazu Tiny Mips Assembler)
# ver. 1.2
# by Masakazu Taniguchi
# date 05.20.11
################################################################################

use strict;

################################################################################
# config part
################################################################################
my %fms; # formats
my %regexp; # formats for error check
my $isa_width = 32; # bit width of isa
my $data_width = 8; # bit width of data
# each row : 'name' => 'format1, format2, ...'
# format   : number         -> number
#            $string_number -> call "string" function(sub). number is bit width.
%fms=(
#          opcode|$2(5bits)|$3(5bits)|$1(5bits)|function_code
'add'   => '000000, $r2.5, $r3.5, $r1.5, 00000, 100000',
'sub'   => '000000, $r2.5, $r3.5, $r1.5, 00000, 100010',
'and'   => '000000, $r2.5, $r3.5, $r1.5, 00000, 100100',
'or'    => '000000, $r2.5, $r3.5, $r1.5, 00000, 100101',
'slt'   => '000000, $r2.5, $r3.5, $r1.5, 00000, 101010',
#          opcode|$2(5bits)|$1(5bits)|immediate_value(16bits)
'addi'  => '001000, $r2.5, $r1.5, $imm.16',
#          opcode|$1(5bits)|$2(5bits)|relative_label(16bits)
'beq'   => '000100, $r1.5, $r2.5, $relLbl.16',
#          opcode|absolute_value(26bits)
'j'     => '000010, $absLbl.26',
#          opcode|base(5bits)|$1(5bits)|offset(16bits)
'lb'    => '100000, $base.5, $r1.5, $offset.16',
'sb'    => '101000, $base.5, $r1.5, $offset.16',
'lw'    => '100011, $base.5, $r1.5, $offset.16',
'sw'    => '101011, $base.5, $r1.5, $offset.16',
#          data($data_width(default 8bits))
'.dw'   => '$data.'.$data_width.', $zero.'.($isa_width - $data_width)
);

# each instruction format
# you should write only formats of operands
%regexp= (
'add'   => '\$[0-9]+[\t\s]*,[\t\s]*\$[0-9]+[\t\s]*,[\t\s]*\$[0-9]+',
'sub'   => '\$[0-9]+[\t\s]*,[\t\s]*\$[0-9]+[\t\s]*,[\t\s]*\$[0-9]+',
'and'   => '\$[0-9]+[\t\s]*,[\t\s]*\$[0-9]+[\t\s]*,[\t\s]*\$[0-9]+',
'or'    => '\$[0-9]+[\t\s]*,[\t\s]*\$[0-9]+[\t\s]*,[\t\s]*\$[0-9]+',
'slt'   => '\$[0-9]+[\t\s]*,[\t\s]*\$[0-9]+[\t\s]*,[\t\s]*\$[0-9]+',
'addi'  => '\$[0-9]+[\t\s]*,[\t\s]*\$[0-9]+[\t\s]*,[\t\s]*\-?[0-9]+',
'beq'   => '\$[0-9]+[\t\s]*,[\t\s]*\$[0-9]+[\t\s]*,[\t\s]*[a-zA-Z_]\w*',
'j'     => '[a-zA-Z_]\w*',
'lb'    => '\$[0-9]+[\t\s]*,[\t\s]*[0-9]+[\t\s]*\([\t\s]*\$[0-9]+\)',
'sb'    => '\$[0-9]+[\t\s]*,[\t\s]*[0-9]+[\t\s]*\([\t\s]*\$[0-9]+\)',
'lw'    => '\$[0-9]+[\t\s]*,[\t\s]*[0-9]+[\t\s]*\([\t\s]*\$[0-9]+\)',
'sw'    => '\$[0-9]+[\t\s]*,[\t\s]*[0-9]+[\t\s]*\([\t\s]*\$[0-9]+\)',
'.dw'   => '[0-9]+'
);

################################################################################
# body part
################################################################################
my $tmp;     # temporary value
my @tmp;     # temporary array
my $i;       # temporary value
my $j;       # temporary value
my $key;     # key for foreach loop for hash
my $val;     # value for foreach loop for hash

my $ARGC;    # the number of arguments
my $arg;     # temporary argument

my $result;  # result of function

my $next_output_flag;  # flag for -o

my $input_path;   # input path
my $output_path;  # output path
my $in_flag;      # input path specified?
my $out_flag;     # output path specified?

my @lines;        # temporary lines
my @olines;       # lines for output
my $line;         # file line
my $oline;        # output file line
my @tokens;       # instruction tokens
my $token;        # token
my @out2in;       # line number for debug ( out2in[out] = in )


my $tmplabel;     # temporary label
my %label_table;  # label table ( key label, value line number);

my $inst;         # instruction
my $found_flag;   # whether the line's instruction is found or not on @is

my $msg;          # message string

my $regs;         # temporary regular expression

my @fms_keys;     # keys of formats %fms
my $fm;           # format line
my @fm_tokens;    # tokens of format line
my $fm_token;          # format token

# get keys of format %fms
foreach $key ( keys ( %fms ) ) {
	push(@fms_keys, $key);
}

# get argument and error detection
$ARGC = @ARGV;
error(__LINE__,'please specify input file/path','help') if ( $ARGC == 0 );
error(__LINE__,'too many arguments','help') if ( $ARGC > 3 );

$in_flag = 0;
$out_flag = 0;
$next_output_flag = 0;
foreach $arg ( @ARGV ) {
	if ( $arg eq '-h' ||
		 $arg =~ /help/ ) {
		print_help();
	}
	if ( $arg eq '-o' ){
		$next_output_flag = 1;
		next;
	}
	if ( $next_output_flag == 1 ) {
		$output_path = $arg;
		$out_flag = 1;
		$next_output_flag = 0;
	} else {
		error(__LINE__,'too many input files/paths','help') if ( $in_flag == 1 );
		$input_path = $arg;
		$in_flag = 1;
	}
}
error(__LINE__,'please specify input file/path','help') if ( ! $in_flag );
if ( ! $out_flag ) {
	$output_path = $input_path;
	$output_path =~ s/\.[\w]+//g; # remove extention
	$output_path .= '.dat';       # add extention ".dat"
} elsif ( -d $output_path ) {
	@tmp = split('/', $input_path);
	$tmp = pop(@tmp);
	$tmp =~ s/\.[\w]+//g;         # remove extention
	$output_path .= '/'.$tmp;         # add file name without extention
	$output_path .= '.dat';       # add extention ".dat"
}

if ( ! -f $input_path ) {
	error(__LINE__, "input file is not a regular file");
}
if ( $input_path !~ /\.asm$/ ) {
	error(__LINE__, "extention of the input file must be 'asm'.");
}

print "input  : $input_path\n";
print "output : $output_path\n";

if ( $input_path eq $output_path ) {
	error(__LINE__,"input path and out path must be different");
}
open ( IN, $input_path ) or 
	error(__LINE__,"could not open input file.\n path : $input_path");
open ( OUT, '> '.$output_path ) or
	error(__LINE__,"could not open output file.\n path : $output_path");



# first path ( read and mark labels)
$tmplabel = '/';
$i = 0; # output line number
$j = 0; # input line number
while ($line = <IN>) {
	$j++;
	chomp($line);
	$line =~ s/#.*//;
	next if ($line =~ /^[ \t]*$/);
	if ($line =~ /\:[ \t]*$/ ) {
		$tmplabel = $`;
		next;
	}
	if ( $tmplabel ne '/' ) {
		$line = $tmplabel.':'.$line;
		$tmplabel = '/';
	}
	
	if ( $line =~ /(\w+)\:/ ) {
		if ( defined($label_table{$&}) ) {
			error(__LINE__,"label \"".$1."\" is found more than once.\nnear line $j\n  ".$line);
		}
		$label_table{$1} = $i;
	}
	$line =~ s/\w+\://g;
	$line =~ s/^[ \t]+//g;
	push(@lines,$line);
	$out2in[$i] = $j;
	$i++;
}
close ( IN );



#debug for 1st path

# for ( $i = 0; $i < @lines; $i++) {
# 	print $lines[$i];
# }
# while ( ($key,$val) = each(%label_table) ) {
# 	$val = $label_table{$key};
# 	print $key." => ".$val."\n";

# }
# foreach $key (@fms_keys) {
# 	print $key."\n";
# }






# 2nd path ( convert )


# each line
@olines = ();
for ( $i = 0; $i < @lines; $i++) {
 	$line = $lines[$i];
	@tokens = split(/[\t ,]+/,$line);
	$inst = $tokens[0];

	# exists check ( instruction is defined? )
	if ( ! exists( $fms{$inst} ) ) {
		$msg = << "EOL";
instruction not found in instruction format table.
line num    : $out2in[$i]
line        : $line
instruction : $inst
EOL
		error(__LINE__,$msg);
	}

	# regexp check ( format check )
	if ( exists( $regexp{$inst} ) ) {
		$regs = '^[\s\t]*'.$inst.'[\s\t]+'.$regexp{$inst}.'[\s\t]*$';
		if ( $line !~ /$regs/ ) {
			$msg = <<"EOL";
instruction format wrong
line num    : $out2in[$i]
line        : $line
EOL
				error(__LINE__,$msg);
		}
	}
	$fm = $fms{$inst};
	$fm =~ s/[ \t]//g;
	@fm_tokens = split(',',$fm);
	$oline = '';
	foreach $fm_token(@fm_tokens){
		if ( !$fm_token ) { error(__LINE__,"format table wrong(0).\n row : $fm"); }
		if ( $fm_token =~ /^[0-9]+$/ ) {
			$oline .= $fm_token;
		} elsif ( $fm_token =~ /^\$([\w]+)\.([0-9]+)$/ ) {
			$result = eval("$1".'($line, \@tokens, '."$2, $i)");
			if ( !defined($result) ) {
				error(__LINE__,"format table wrong(1).\n row : $fm\n");
			}
			
			$oline .= $result;
		} else {
			error(__LINE__,"format table wrong(2).\n row : $fm\n");
		}
	}

	if ( length($oline) != $isa_width ) {
		$msg = <<"EOL";
format table or instruction wrong
format row  : $fm
line num    : $out2in[$i]
instruction : $line
EOL
			error(__LINE__,$msg);
	}
	$oline = unpack("H*", pack("B$isa_width",  $oline));
    $olines[$i] = $oline;
}


foreach $oline ( @olines ) {
	print OUT $oline."\n";
}
close ( OUT );




################################################################################
# functions for each format token
################################################################################
sub reg{
	my $line  = shift;
	my $token_ref = shift;
	my $width = shift;
	my $num   = shift; # order of register
	my $cnt = 0;
	my $val;
	my @tokens = @$token_ref;
	foreach $token ( @tokens ) {
		if ( $token =~ /^\$([0-9]+)/ ) {
			$val = $1;
			$cnt++;
			if ( $cnt == $num ) {
				if ( $val >= (1 << $width) ) {
					error(__LINE__,"variable should be less than ".(1 << $width)."\n val : $val");
				}
				$val = dec2bin( $val, $width );
				return $val;
			}
		}
	}
	error(__LINE__,"line is wrong(reg).\n line : $line");
}
sub r1{
	my $line  = shift;
	my $token_ref = shift;
	my $width = shift;
	my $pc = shift;
	return reg($line, $token_ref, $width, 1);
}
sub r2{
	my $line  = shift;
	my $token_ref = shift;
	my $width = shift;
	my $pc = shift;
	return reg($line, $token_ref, $width, 2);
}
sub r3{
	my $line  = shift;
	my $token_ref = shift;
	my $width = shift;
	my $pc = shift;
	return reg($line, $token_ref, $width, 3);
}
sub r4{
	my $line  = shift;
	my $token_ref = shift;
	my $width = shift;
	my $pc = shift;
	return reg($line, $token_ref, $width, 4);
}
sub r5{
	my $line  = shift;
	my $token_ref = shift;
	my $width = shift;
	my $pc = shift;
	return reg($line, $token_ref, $width, 5);
}
sub imm{
	my $line  = shift;
	my $token_ref = shift;
	my $width = shift;
	my $pc = shift;
	my @tokens = @$token_ref;
	my $token;
	foreach $token ( @tokens ) {
		if ( $token =~ /^(\-?[0-9]+)$/ ) {
			return dec2bin( $1, $width );
		}
	}
	error(__LINE__,"line is wrong(imm).\n line : $line");
}
sub relLbl{
	my $line  = shift;
	my $token_ref = shift;
	my $width = shift;
	my $pc = shift;
	my $label;
	my @tokens = @$token_ref;
	my $token;
	shift(@tokens);
	foreach $token ( @tokens ) {
		if ( $token =~ /^([a-zA-Z_]\w+)$/ ) {
			$label = $1;
			if ( $label_table{$label} !~ /^[0-9]+$/ ) {
				$msg = << "EOL";
label not found
line num    : $out2in[$pc]
line        : $line
label       : $label
EOL
                error(__LINE__, $msg);
			}
			return dec2bin( $label_table{$label} - $pc - 1, $width);
		}
	}
	error(__LINE__,"line is wrong(retLbl).\n line : $line");	
}
sub absLbl{
	my $line  = shift;
	my $token_ref = shift;
	my $width = shift;
	my $pc = shift;
	my $label;
	my @tokens = @$token_ref;
	my $token;
	shift(@tokens);
	foreach $token ( @tokens ) {
		if ( $token =~ /^([a-zA-Z_]\w*)$/ ) {
			$label = $1;
			if ( $label_table{$label} !~ /^[0-9]+$/ ) {
				$msg = << "EOL";
label not found
line num    : $out2in[$pc]
line        : $line
label       : $label
EOL
                error(__LINE__, $msg);
			}
			return dec2bin( $label_table{$label}, $width);
		}
	}
	error(__LINE__,"line is wrong(absLbl).\n line : $line");	
}
sub base{
	my $line  = shift;
	my $token_ref = shift;
	my $width = shift;
	my $pc = shift;
	my @tokens = @$token_ref;
	my $token;
	shift(@tokens);
	foreach $token ( @tokens ) {
		if ( $token =~ /^[0-9]+\(\$([0-9])+\)$/ ) {
			return dec2bin( $1, $width);
		}
	}
	error(__LINE__,"line is wrong(base).\n line : $line");	
}
sub offset{
	my $line  = shift;
	my $token_ref = shift;
	my $width = shift;
	my $pc = shift;
	my @tokens = @$token_ref;
	my $token;
	foreach $token ( @tokens ) {
		if ( $token =~ /^([0-9]+)\(\$[0-9]+\)$/ ) {
			return dec2bin( $1, $width);
		}
	}
	error(__LINE__,"line is wrong(offset).\n line : $line");	
}
sub data{
	my $line  = shift;
	my $token_ref = shift;
	my $width = shift;
	my $pc = shift;
	foreach $token ( @tokens ) {
		if ( $token =~ /^([0-9]+)$/ ) {
			return dec2bin( $1, $width);
		}
	}
	error(__LINE__,"line is wrong(data).\n line : $line");	

}
sub zero{
	my $line  = shift;
	my $token_ref = shift;
	my $width = shift;
	my $pc = shift;
	my $ret;
	my $i;
	$ret = '';
	for ( $i = 0 ; $i < $width; $i++ ) {
		$ret .= '0';
	}
	return $ret;
}

################################################################################
# other functions 
################################################################################
# decimal to binary
sub dec2bin{
	my $val = shift;
	my $width = shift;
	my $i;
	my $msb;
	if ( $val > ( 1 << $width - 1) ) {
		error(__LINE__,"value($val) must be equal or less then max value(".( 1 << $width - 1  ).")");
	}
	$val = sprintf('%0'.$width.'b', $val);
	$val = substr( $val, -1 * $width);
	return $val;
}

# help
sub print_help{
	print "This is an assembler for tiny mips.\n";
	print "  usage : $0 input_file(path) [-o output_file(path)]\n";
	print "  default output_file(path) is \"input_file_name.dat\"\n";
	exit -1;
}

# error
sub error{
	my $line = shift;
	my $msg  = shift;
	my $help = shift;
	print "ERROR($line) $msg\n";
	if ( $help =~ /help/ ) {
		print_help();
	}
	exit -1;
}








