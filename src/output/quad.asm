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

