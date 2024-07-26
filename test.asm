# mipstest.asm
# 9/16/03 David Harris David_Harris@hmc.edu
#
# Test MIPS instructions. Assumes memory was
# initialized as:
# word 16: 3 - be careful of endianness
# word 17: 5
# word 18: 12
main:   #Assembly Code     egffect                 Machine Code
        lb $2, 68($0)      # initialize $2 = 5     80020044 00 IF ID EX MA WB
        lb $7, 64($0)      # initialize $7 = 3     80070040 04    IF ID EX MA WB
        lb $3, 69($7)      # initialize $3 = 12    80e30045 08       IF ID ID EX MA WB [st:EX->ID][fw:WB->EX]
        or $4, $7, $2      # $4 <= 3 or 5 = 7      00e22025 0c          IF IF ID EX MA WB [st:EX->IF]
        and $5, $3, $4     # $5 <= 12 and 7 = 4    00642824 10                IF ID EX MA WB [fw:MA->EX]
        add $5, $5, $4     # $5 <= 4 + 7 = 11      00a42820 14                   IF ID EX MA WB [fw:MA->EX]
        beq $5, $7, end    # shouldn't be taken    10a70008 18                      IF ID EX MA WB [fw:MA->EX]
        slt $6, $3, $4     # $6 <= 12 < 7 = 0      0064302a 1c                         IF ID EX MA WB
        beq $6, $0, around # should be taken       10c00001 20                            IF ID EX MA WB [fw:MA->EX]
        lb $5, 0($0)       # shouldn't happen      80050000 24                               IF ID [nop:MA->EX]
around: slt $6, $7, $2     # $6 <= 3 < 5 = 1       00e2302a 28                                  IF    IF ID EX MA WB [nop:MA->ID][fw:MA->pc]
        add $7, $6, $5     # $7 <= 1 + 11 = 12     00c53820 2c                                           IF ID EX MA WB [nop:MA->IF][fw:MA->EX]
        sub $7, $7, $2     # $7 <= 12 - 5 = 7      00e23822 30                                              IF ID EX MA WB [fw:MA->EX]
        j end              # should be taken       0800000f 34                                                 IF ID EX MA WB
        lb $7, 0($0)       # shouldn't happen      80070000 38                                                    IF ID [nop:MA->EX]
end:    sb $7, 0($2)       # write adr 5 <=  7     a0470000 3c                                                       IF    IF ID EX MA WB [nop:MA->ID][fw:MA->pc]
        .dw 3              #                       03000000 40
        .dw 5              #                       05000000 44
        .dw 12             #                       0c000000 48
