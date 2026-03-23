lw t0, a           
lw t1, b           
addi t2, x0, 0
     
bge t1, t2, else
add t2, t0, t1  
   
jal x0, fim 

else:
sub t2, t0, t1

fim:
sw t2, m           
halt               


a: .word 6
b: .word 15
m: .word 0
