# Colon
A simple programming language compiler similar to `c`. 

## Tools used

Flex and Bison

## Tokens

```c
%token<STRING> IDENTIFIER STRING_DECLARATION ENUM_DECLARATION CONST_DECLARATION BOOL_DECLARATION CHAR_DECLARATION FLOAT_DECLARATION INT_DECLARATION PRINT
%token<INTEGER> INTEGER_CONSTANT
%token<FLOAT> FLOAT_CONSTANT
%token<CHAR>  CHAR_CONSTANT
%token<BOOL> TRUE_KEYWORD FALSE_KEYWORD
%token<STRING> STRING_CONSTANT

%token AND OR NOT EQ NE LT GT LE GE
%token IF ELSE WHILE FOR DO SWITCH CASE DEFAULT BREAK CONTINUE
%token RETURN VOID 
%token SINGLE_LINE_COMMENT 
%nonassoc IFX
%nonassoc ELSE
%nonassoc UMINUS

%type <STRING> enum_list
%type <STRING> enum_state
%type <STRING> enum_definition
%type <STRING> variable_type
%type <STRING> function_call
%type <node_type> expression
%type <node_type> const_expression
/* %type <STRING> expression_error */

%right '='
%left  OR
%left  AND
%left  EQ NE
%left  LT GT LE GE
%left  '+' '-'
%left  '*' '/' '%'
%right NOT
```

## Allowed rules

- Variable declaration
- Const declaration
- Enum declaration
- Braced Statement
- Statements
- Control Statements ( If, while, do while, for )
- Return, Break, Continue
- Function delcaration ( with default values )

## Symbol Table

![image](https://github.com/AhmadJamal01/Colon/assets/65499354/4f1672d7-6f0b-4b75-95f6-8d7ba44354fa)

## Intermediate Code Syntax

| Test op | evaluates jump conditions based on operand op, ex: Test x ; JZ L1 ; |
| --- | --- |
| L<num>: | Label with number = <num> |
| JZ L<num> | Jmp if equal zero to Label |
| JNZ L<num> | Jmp if not equal zero to Label |
| JMP L<num> | Unconditional Jump to label |
| STO src, dest | Store ‘src’ to ‘dest’ |
| ADD s1, s2, r | r = s1 + s2 |
| MUL s1, s2, r | r = s1 * s2 |
| DIV s1, s2, r | r = s1 / s2 |
| SUB s1, s2, r | r = s1 - s2 |
| MOD s1, s2, r | r = s1 % s2 |
| LT s1, s2, r | r = s1 < s2 |
| GT s1, s2, r | r = s1 > s2 |
| LE s1, s2, r | r = s1 ≤ s2 |
| GE s1, s2, r | r = s1 ≥ s2 |
| EQ s1, s2, r | r = s1 == s2 |
| NE s1, s2, r | r = s1 ≠ s2 |
| AND s1, s2, r | r = s1 && s2 |
| OR s1, s2, r | r = s1 || s2 |
| INC s, r | r = s +1 |
| DEC s, r | r = s - 1 |
| NOT s, r | r = ! s |
| NEG s, r | r = - s |
|  |  |


## Code Playground
![image](https://github.com/AhmadJamal01/Colon/assets/65499354/02f9b9f5-6608-4633-aaca-399b455b14cc)

