addi t0, x0, 0

loop:
    lb t1, 28(t0)
    beq t1, x0, fim
    sb t1, 1024(x0)
    addi t0, t0, 1
    jal x0, loop

fim:
    halt

str1: .string "Hello World"
