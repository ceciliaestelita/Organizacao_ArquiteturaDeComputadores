addi t0, x0, 42

loop:
    lb x10, 1025(x0)
    beq x10, x0, loop
    beq x10, t0, fim
    sb x10, 1024(x0)
    jal x0, loop

fim:
    halt
