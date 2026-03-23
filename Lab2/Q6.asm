addi x5, x0, 2               # porta atual = 2

loop:
        lb x10, 1026(x0)     # lê botão
        andi x10, x10, 0x1   # isola bit
        beq x10, x0, off     # se o botão é solto -> apaga

on:
        lb x10, 36(x0)       # HIGH
        sb x5, 1029(x0)      # seleciona porta atual
        sb x10, 1029(x0)     # acende
        jal x0, loop

off:
        lb x10, 37(x0)       # LOW
        sb x5, 1029(x0)      # seleciona porta atual
        sb x10, 1029(x0)     # apaga
        addi x5, x5, 1       # avança porta
        addi x6, x0, 8
        beq x5, x6, fim      # verifica se chegou na 8 e para
        jal x0, loop

fim:
        jal x0, fim

HIGH: .byte 1
LOW:  .byte 0
