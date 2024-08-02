fib:                   # Assembly Code	Effect
      addi $3, $0, 8   # initialize n = 8
      addi $4, $0, 1   # initialize f1 = 1
      addi $5, $0, -1  # initialize f2 = -1
loop:	beq $3, $0, dma  # Done with loop if n = 0
      add $4, $4, $5   # f1 = f1 + f2
      sub $5, $4, $5   # f2 = f1 - f2
      addi $3, $3, -1  # n = n - 1
      sb $4, 128($3)   # store f1 in address 128+n
      j loop           # repeat until done
dma:  addi $1, $0, 128 # src_addr = 128
      sb $1, 252($0)
      addi $1, $0, 192 # dst_addr = 192
      sb $1, 253($0)
      addi $1, $0, 8   # size = 8
      sb $1, 254($0)
      addi $1, $0, 1   # start DMA transfer
      sb $1, 255($0)
wait: lb $1, 255($0)
      beq $1, $0, wait # repeat until eop != 0
      addi $2, $2, 0   # workaround for eratta: "j done" is evaluated before "beq $1, $0, wait"
      addi $2, $2, 0
      addi $2, $2, 0
done: j done
