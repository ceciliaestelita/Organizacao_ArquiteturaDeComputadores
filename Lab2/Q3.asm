lw x20, g          
lw x21, h           
lw x22, i          
lw x23, j
        
bne x22, x23, Else
add x19, x20, x21
jal x0, Exit        

Else:
sub x19, x20, x21

Exit:
sw x19, f          
halt                


f: .word 0          
g: .word 10       
h: .word 5         
i: .word 2          
j: .word 2      
