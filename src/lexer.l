%{
    #include <stdio.h>
    #include <stdlib.h>
    #include "parser.tab.h"
    void yyerror(char *);
%}

%%

    /* variables and constants declaration */
"int"                       { return INT_DECLARATION; }
"float"                     { return FLOAT_DECLARATION; }
"char"                      { return CHAR_DECLARATION; }
"const"                     { return CONST_DECLARATION; }
"enum"                      { return ENUM_DECLARATION; }

    /* mathematical and logical expressions */
[-+*/%(){};:=,]             { return *yytext; }
"&&"                        { return AND; }
"||"                        { return OR; }
"!"                         { return NOT; }
"=="                        { return EQ; }
"!="                        { return NE; }
"<"                         { return LT; }
">"                         { return GT; }
"<="                        { return LE; }
">="                        { return GE; }

    /* control statements */
"if"                        { return IF; }
"else"                      { return ELSE; }
"while"                     { return WHILE; }
"for"                       { return FOR; }
"repeat"                    { return REPEAT; }
"until"                     { return UNTIL; }
"switch"                    { return SWITCH; }
"case"                      { return CASE; }
"default"                   { return DEFAULT; }
"break"                     { return BREAK; }
"continue"                  { return CONTINUE; }

    /* functions */
"return"                    { return RETURN; }
"void"                      { return VOID; }

[a-zA-Z_][a-zA-Z0-9_]*      { return IDENTIFIER; }
[0-9]+                      { return INTEGER_CONSTANT; }
[0-9]+"."[0-9]+             { return FLOAT_CONSTANT; }
"'"[a-zA-Z0-9]"'"           { return CHAR_CONSTANT; }

\/\/.*\n                    {} /* ignore comments */
[ \t\n]                     {} /* ignore whitespace */

.                           { yyerror("Unknown character"); }

%%

int yywrap(void) {
    return 1;
}