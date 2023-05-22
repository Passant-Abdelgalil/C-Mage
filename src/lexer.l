%{
    #include <stdio.h>
    #include <stdlib.h>
    #include "parser.tab.h"
    void yyerror(char *);
    extern int yylineno;
%}

%%

#[\s\t]*.*                       {/* printf("%s",yytext); */} /* ignore comments */

    /* variables and constants declaration */
"int"                           { /* printf("%s",yytext); */ return INT_DECLARATION; }
"float"                         { /* printf("%s",yytext); */ return FLOAT_DECLARATION; }
"char"                          { /* printf("%s",yytext); */ return CHAR_DECLARATION; }
"bool"                          { /* printf("%s",yytext); */ return BOOL_DECLARATION; }
"const"                         { /* printf("%s",yytext); */ return CONST_DECLARATION; }
"string"                        { /* printf("%s",yytext); */ return STRING_DECLARATION; }
"enum"                          { /* printf("%s",yytext); */ return ENUM_DECLARATION; }

    /* mathematical and logical expressions */
[-+*/%(){};:=,\[\]]             { /* printf("%s",yytext); */ return *yytext; }
"&&"                            { /* printf("%s",yytext); */ return AND; }
"||"                            { /* printf("%s",yytext); */ return OR; }
"!"                             { /* printf("%s",yytext); */ return NOT; }
"=="                            { /* printf("%s",yytext); */ return EQ; }
"!="                            { /* printf("%s",yytext); */ return NE; }
"<"                             { /* printf("%s",yytext); */ return LT; }
">"                             { /* printf("%s",yytext); */ return GT; }
"<="                            { /* printf("%s",yytext); */ return LE; }
">="                            { /* printf("%s",yytext); */ return GE; }

    /* control statements */
"if"                            { /* printf("%s",yytext); */ return IF; }
"else"                          { /* printf("%s",yytext); */ return ELSE; }
"while"                         { /* printf("%s",yytext); */ return WHILE; }
"for"                           { /* printf("%s",yytext); */ return FOR; }
"do"                            { /* printf("%s",yytext); */ return DO; }
"switch"                        { /* printf("%s",yytext); */ return SWITCH; }
"case"                          { /* printf("%s",yytext); */ return CASE; }
"default"                       { /* printf("%s",yytext); */ return DEFAULT; }
"break"                         { /* printf("%s",yytext); */ return BREAK; }
"continue"                      { /* printf("%s",yytext); */ return CONTINUE; }

    /* functions */
"return"                        { /* printf("%s",yytext); */ return RETURN; }
"void"                          { /* printf("%s",yytext); */ return VOID; }
"print"                         { /* printf("%s",yytext); */ return PRINT; }

"true"                          { /* printf("%s",yytext); */ return TRUE_KEYWORD; }
"false"                         { /* printf("%s",yytext); */ return FALSE_KEYWORD; }

[a-zA-Z_][a-zA-Z0-9_]*          { /* printf("%s",yytext); */ return IDENTIFIER; }
[0-9]+                          { /* printf("%s",yytext); */ return INTEGER_CONSTANT; }
[0-9]+"."[0-9]+                 { /* printf("%s",yytext); */ return FLOAT_CONSTANT; }
"'"[a-zA-Z0-9]"'"               { /* printf("%s",yytext); */ return CHAR_CONSTANT; }
\"[a-zA-Z0-9]+\"                { /* printf("%s",yytext); */ return STRING_CONSTANT; }
 

[ \t]+                        { /* printf("%s",yytext); */ } /* ignore whitespace */

\n                            { ++yylineno; } /* ignore newlines */

.                               { /* printf("%s",yytext); */yyerror("Unknown character"); }

%%

int yywrap(void) {
    return 1;
}