%{
    #include <stdlib.h>
    #include <stdio.h>
    void yyerror (char* ); int yywrap();
    int yylex();
    extern FILE *yyin;
    extern FILE *yyout;
%}

%token INT_DECLARATION FLOAT_DECLARATION CHAR_DECLARATION CONST_DECLARATION BOOL_DECLARATION ENUM_DECLARATION
%token AND OR NOT EQ NE LT GT LE GE
%token IF ELSE WHILE FOR REPEAT UNTIL SWITCH CASE DEFAULT BREAK CONTINUE
%token RETURN VOID PRINT
%token IDENTIFIER INTEGER_CONSTANT FLOAT_CONSTANT CHAR_CONSTANT
%nonassoc IFX
%nonassoc ELSE
%nonassoc UMINUS

%right '='
%left  OR
%left  AND
%left  EQ NE
%left  LT GT LE GE
%left  '+' '-'
%left  '*' '/' '%'
%right NOT

%%

program:                                statement_list                        {printf("program\n");}
;

// declaration_list:                       declaration_list declaration            {printf("declaration_list\n");}
// |                                       declaration                             {printf("declaration_list\n");}
// ;

declaration:                            variable_declaration ';'           {printf("variable declaration\n");}
|                                       function_declaration           {printf("function declaration\n");}
;

variable_type:                          INT_DECLARATION                    
|                                       FLOAT_DECLARATION
|                                       CHAR_DECLARATION
|                                       CONST_DECLARATION
|                                       BOOL_DECLARATION
;

/* a function can have the additional type void as well as the other types */
/* problem here */
/* proposed solution 1: add void to the function definition and remove this rule*/
// function_type:                          variable_type
// |                                       VOID
// ;

variable_declaration:                   variable_type IDENTIFIER 
|                                       variable_type IDENTIFIER '=' expression 
/* may remove arrays */
|                                       variable_type IDENTIFIER '[' INTEGER_CONSTANT ']' 
|                                       variable_type IDENTIFIER '[' INTEGER_CONSTANT ']' '=' '{' expression_list '}'
|                                       enum_definition
;

enum_definition:                        ENUM_DECLARATION IDENTIFIER'{' enum_list '}'
;

enum_list:                              IDENTIFIER enum_opt_value ',' enum_list 
|                                       IDENTIFIER enum_opt_value
;

enum_opt_value:                         '=' INTEGER_CONSTANT
|                                       /* empty */
;

expression_list:                        expression_list ',' expression
|                                       expression
;

expression:                             IDENTIFIER
|                                       INTEGER_CONSTANT
|                                       FLOAT_CONSTANT
|                                       CHAR_CONSTANT
|                                       '(' expression ')'
|                                       expression '+' expression
|                                       expression '-' expression
|                                       expression '*' expression
|                                       expression '/' expression
|                                       expression '%' expression
|                                       expression EQ expression
|                                       expression NE expression
|                                       expression LT expression
|                                       expression GT expression
|                                       expression LE expression
|                                       expression GE expression
|                                       expression AND expression
|                                       expression OR expression
|                                       NOT expression
|                                       '-' expression %prec UMINUS
    /* may not use arrays */
// |                                       IDENTIFIER '[' expression ']'

function_declaration:                   variable_type IDENTIFIER '(' parameter_list ')' block
|                                       VOID IDENTIFIER '(' parameter_list ')' block
;

function_call:                          IDENTIFIER '(' arguemnt_list ')' ';'    {printf("function call\n");}
|                                       reserved_functions '(' arguemnt_list ')' ';'  {printf("print call\n");}
;

/*reserved functions rule */
reserved_functions:                     PRINT
/* | cout or whatnot*/
; 

arguemnt_list:                          arguemnt_list ',' expression        
|                                       expression
|                                    /* empty */
;

parameter_list:                         parameter_list ',' parameter
|                                       parameter
|                                       /* empty */
;

parameter:                              variable_declaration
;

block:                                  '{' statement_list '}'
;

statement_list:                         statement statement_list
|                                      /* empty */
;

statement:                              expression ';'
|                                       declaration
|                                       function_call
|                                       for_loop
|                                       assignment
/*|                                       if while for ... */
;

for_loop:                               FOR '(' statement statement statement ')' block     {printf("for loop\n");}
|                                       FOR '(' statement statement ')' block               {printf("for loop\n");}
|                                       FOR '(' statement ')' block                         {printf("for loop\n");}
;

assignment:                             IDENTIFIER '=' expression ';'
;

%%

void yyerror(char *s) {
    fprintf(stdout, "%s\n", s);
}

int main(int argc, char *argv[])
{
    yyin = fopen(argv[1], "r");
    yyparse();
    if (yywrap())
    {
        printf("Parsing successful ya regala!\n");
    }
    fclose(yyin); 
    return 0;
}
