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

(repeated variables for step by step)

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/5b7875dc-bd0f-400c-bdfc-ed5287c6533a/Untitled.png)

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

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/a25c11e3-7f6c-48fa-ba2d-8941d7d0df64/Untitled.png)

## Code Playground
![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/8e0b98ca-ad84-4647-af1f-b3b53b555a91/Untitled.png)
