lw t0, a           
lw t1, b           
addi t2,x0, 0     
bge t1, t2, condicao 
add t2, t0, t1     

condicao:
sw t2, m           
halt               


a: .word 6
b: .word 5
m: .word 0

