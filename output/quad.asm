<<<<<<< HEAD
STO 0, i
L383:
LT i, 5, R0
JZ L777
JMP L886
L915:
ADD i, 1, R1
STO R1, i
JMP L383
L886:
STO 11, x
L335:
GT x, 10, R2
TEST R2
JZ L793
STO 11, x
JMP L335
JMP L335
L793:
GT x, 10, R3
TEST R3
JZ L492
STO 11, x
JMP L386
L492:
STO 10, x
L386:
JMP L915
JMP L915
L777:
L649:
STO 1, x
JMP L362
JMP L421
L362:
ADD x, 1, R4
TEST R4
JNZ L649
L421:
=======
PUSH 	2 
POP 	a 
PUSH 	3 
POP 	b 
mov	edx,len    
mov	ecx,msg    
mov	ebx,1      
mov	eax,4      
int	0x80       
mov	eax,1      
int	0x80       
PUSH 	a 
PUSH 	b 
ADD 	a, b, RO 
POP 	c
PUSH 	4.5 
PUSH 	6.5 
MUL 	4.5, 6.5, RI 
POP 	d 
PUSH 	true 
POP 	bo 
PUSH 	"A3E" 
POP 	
PUSH 	a 
PUSH 	b 
GT 	a, b, R2 
JZ 	LI 
PUSH 	c 
PUSH 	2 	
MOD 	c, 2, R3 
POP 	c 
B2: 
JMP 	L2 
LI: 
PUSH 	c 

>>>>>>> 21b993623076707f7d2336f1d3ce5e824487707e
