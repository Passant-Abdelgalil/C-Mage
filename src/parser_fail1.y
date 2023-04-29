%{
    #include <stdio.h>
    void yyerror(char *);
    int yylex(void);
%}

%token INT_DECLARATION FLOAT_DECLARATION CHAR_DECLARATION CONST_DECLARATION ENUM_DECLARATION
%token AND OR NOT EQ NE LT GT LE GE
%token IF ELSE WHILE FOR REPEAT UNTIL SWITCH CASE DEFAULT BREAK CONTINUE
%token RETURN VOID
%token IDENTIFIER INTEGER_CONSTANT FLOAT_CONSTANT CHAR_CONSTANT

%left  ','
%right '='
%left  OR
%left  AND
%left  EQ NE
%left  LT GT LE GE
%left  '+' '-'
%left  '*' '/' '%'
%right NOT

%%
    /* program is a list of zero or more definitions */
program:                program definition
|                        
;
    /* definition is a function or variable definition */
definition:             variable_definition
|                       function_definition
;

    /* function definition is a type followed by a list of zero or more variables */
function_definition:    VOID IDENTIFIER '(' parameter_list_opt ')' '{' statement '}'
|                       variable_type IDENTIFIER '(' parameter_list_opt ')' '{' statement '}'
;

    /* to allow for zero or more parameters which are separated by commas */
parameter_list:         parameter_list ',' parameter
|                       parameter
;
parameter_list_opt:     parameter_list
|                        
;

parameter:              variable_type IDENTIFIER
;

variable_type:          INT_DECLARATION
|                       FLOAT_DECLARATION
|                       CHAR_DECLARATION
;

// function_type:          VOID
// |                       variable_type
// ;

variable_declaration:   variable_type IDENTIFIER

variable_initialization:    '=' expression ';'
|                           '=' '{' expression_list '}' ';'
|                           ';'
|
;

variable_definition:    variable_declaration variable_initialization
|                       CONST_DECLARATION variable_declaration variable_initialization
|                       enum_definition
;

// variable_definition:    variable_type IDENTIFIER ';'
// |                       CONST_DECLARATION variable_type IDENTIFIER '=' expression ';'
// |                       variable_type IDENTIFIER '=' expression ';'
// |                       INT_DECLARATION IDENTIFIER '[' INTEGER_CONSTANT ']' '=' '{' expression_list '}' ';'
// |                       FLOAT_DECLARATION IDENTIFIER '[' INTEGER_CONSTANT ']' '=' '{' expression_list '}' ';'
//     /* may change this to take a string expression where the expression is not delimited by a comma */
// |                       CHAR_DECLARATION IDENTIFIER '[' INTEGER_CONSTANT ']' '=' '{' expression_list '}' ';'
// |                       enum_definition
// ;

expression_list:        expression_list ',' expression
|                       expression
;

expression:             expression '+' expression
|                       expression '-' expression
|                       expression '*' expression
|                       expression '/' expression
|                       expression '%' expression
|                       expression EQ expression
|                       expression NE expression
|                       expression LT expression
|                       expression GT expression
|                       expression LE expression
|                       expression GE expression
|                       expression AND expression
|                       expression OR expression
|                       '(' expression ')'
|                       '-' expression  %prec NOT
|                       NOT expression
|                       INTEGER_CONSTANT
|                       FLOAT_CONSTANT
|                       CHAR_CONSTANT
|                       IDENTIFIER
;


statement:              '{' statement '}'
|                       variable_definition
|                       expression ';'
|                       RETURN expression ';'
|                       RETURN ';'
|                       if_statement else_statement
|                       WHILE '(' expression ')' statement
|                       FOR '(' expression ';' expression ';' expression ')' statement
|                       REPEAT statement UNTIL '(' expression ')' ';'
|                       SWITCH '(' expression ')' '{' case_list '}'
|                       ';'
|                       BREAK ';'
|                       CONTINUE ';'
;

compound_statement:     '{' statement '}'

if_statement:           IF '(' expression ')' compound_statement
;

else_statement:         ELSE compound_statement
|   
;

case_list:              case_list case
|                       case
;

// case:                   CASE INTEGER_CONSTANT ':' statement
// |                       CASE FLOAT_CONSTANT ':' statement
// |                       CASE CHAR_CONSTANT ':' statement
//     /* may need to add boolean cases */
// |                       CASE expression ':' statement /*?*/
// |                       DEFAULT ':' statement
case:                   CASE expression ':' statement /*?*/
|                       DEFAULT ':' statement
;

enum_definition:        ENUM_DECLARATION IDENTIFIER '{' enum_list '}'
;

enum_list:              enum_list ',' IDENTIFIER
|                       enum_list ',' IDENTIFIER '=' INTEGER_CONSTANT
|                       IDENTIFIER '=' INTEGER_CONSTANT
|                       IDENTIFIER
;

    /* variables and constants declaration */

    /* mathematical and logical expressions */

    /* control statements */

    /* functions */
%%

void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
}

int main(void) {
    yyparse();
}