%{
    #include <stdio.h>
    #include <stdlib.h>
    #include "parser.tab.h"
    void yyerror(char *);
    
    int lineno = 1;
%}


%option yylineno


%%

#[\s\t]*.*                       {printf("found %s\n",yytext);} /* ignore comments */

    /* variables and constants declaration */
"int"                           { printf("found %s\n",yytext); return INT_DECLARATION; }
"float"                         { printf("found %s\n",yytext); return FLOAT_DECLARATION; }
"char"                          { printf("found %s\n",yytext); return CHAR_DECLARATION; }
"bool"                          { printf("found %s\n",yytext); return BOOL_DECLARATION; }
"const"                         { printf("found %s\n",yytext); return CONST_DECLARATION; }
"string"                        { printf("found %s\n",yytext); return STRING_DECLARATION; }
"enum"                          { printf("found %s\n",yytext); return ENUM_DECLARATION; }

    /* mathematical and logical expressions */
[-+*/%(){};:=,\[\]]             { printf("found %s\n",yytext); return *yytext; }
"&&"                            { printf("found %s\n",yytext); return AND; }
"||"                            { printf("found %s\n",yytext); return OR; }
"!"                             { printf("found %s\n",yytext); return NOT; }
"=="                            { printf("found %s\n",yytext); return EQ; }
"!="                            { printf("found %s\n",yytext); return NE; }
"<"                             { printf("found %s\n",yytext); return LT; }
">"                             { printf("found %s\n",yytext); return GT; }
"<="                            { printf("found %s\n",yytext); return LE; }
">="                            { printf("found %s\n",yytext); return GE; }

    /* control statements */
"if"                            { printf("found %s\n",yytext); return IF; }
"else"                          { printf("found %s\n",yytext); return ELSE; }
"while"                         { printf("found %s\n",yytext); return WHILE; }
"for"                           { printf("found %s\n",yytext); return FOR; }
"do"                            { printf("found %s\n",yytext); return DO; }
"switch"                        { printf("found %s\n",yytext); return SWITCH; }
"case"                          { printf("found %s\n",yytext); return CASE; }
"default"                       { printf("found %s\n",yytext); return DEFAULT; }
"break"                         { printf("found %s\n",yytext); return BREAK; }
"continue"                      { printf("found %s\n",yytext); return CONTINUE; }

    /* functions */
"return"                        { printf("found %s\n",yytext); return RETURN; }
"void"                          { printf("found %s\n",yytext); return VOID; }
"print"                         { printf("found %s\n",yytext); return PRINT; }

"true"                          { printf("found %s\n",yytext); yylval.BOOL = 1; return TRUE_KEYWORD; }
"false"                         { printf("found %s\n",yytext); yylval.BOOL = 0; return FALSE_KEYWORD; }

[a-zA-Z_][a-zA-Z0-9_]*          { printf("found %s\n",yytext); yylval.ID = strdup(yytext); return IDENTIFIER; }
[0-9]+                          { printf("found %s\n",yytext); yylval.INTEGER = atoi(yytext); return INTEGER_CONSTANT; }
[0-9]+"."[0-9]+                 { printf("found %s\n",yytext); yylval.FLOAT = atof(strdup(yytext)); return FLOAT_CONSTANT; }
"'"[a-zA-Z0-9]"'"               { printf("found %s\n",yytext); yylval.CHAR = strdup(yytext); return CHAR_CONSTANT; }
\"[a-zA-Z0-9]+\"                { printf("found %s\n",yytext); yylval.STRING = strdup(yytext); return STRING_CONSTANT; }


[ \t]+                          { printf("found %s\n",yytext); } /* ignore whitespace */
\n                              { lineno++ }
.                               { printf("found %s\n",yytext);yyerror("Unknown character"); }

%%

int yywrap(void) {
    return 1;
}