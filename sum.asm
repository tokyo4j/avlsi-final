# sum.asm
# 05/19/11 Masakazu Taniguchi

main:
	addi $3, $0, 0    # s = 0
	addi $4, $0, 20   # i = 20
loop:
	beq $4, $0, end   # done with loop i = 0
	add $3, $3, $4	  # s += i
	addi $4, $4, -1   # i--
	j loop            # repeat until done
end:
	sb $3, 255($0)    # store
