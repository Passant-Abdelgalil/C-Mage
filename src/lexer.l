%{
    #include <stdio.h>
    #include <stdlib.h>
    #include "parser.tab.h"
    void yyerror(char *);
    int yylineno;
%}


/* %option yylineno */


%%

#[\s\t]*.*                       {/* printf("%s",yytext); */} /* ignore comments */

    /* variables and constants declaration */
"int"                           { yylval.STRING = strdup(yytext);   return INT_DECLARATION; }
"float"                         { yylval.STRING = strdup(yytext);   return FLOAT_DECLARATION; }
"char"                          { yylval.STRING = strdup(yytext);   return CHAR_DECLARATION; }
"bool"                          { yylval.STRING = strdup(yytext);   return BOOL_DECLARATION; }
"const"                         { yylval.STRING = strdup(yytext);   return CONST_DECLARATION; }
"string"                        { yylval.STRING = strdup(yytext);   return STRING_DECLARATION; }
"enum"                          { yylval.STRING = strdup(yytext);   return ENUM_DECLARATION; }

    /* mathematical and logical expressions */
[-+*/%(){};:=,\[\]]             { return *yytext; }
"&&"                            { return AND; }
"||"                            { return OR; }
"!"                             { return NOT; }
"=="                            { return EQ; }
"!="                            { return NE; }
"<"                             { return LT; }
">"                             { return GT; }
"<="                            { return LE; }
">="                            { return GE; }

    /* control statements */
"if"                            { yylval.STRING = strdup(yytext);  return IF; }
"else"                          { yylval.STRING = strdup(yytext);  return ELSE; }
"while"                         { yylval.STRING = strdup(yytext);  return WHILE; }
"for"                           { yylval.STRING = strdup(yytext);  return FOR; }
"do"                            { yylval.STRING = strdup(yytext);  return DO; }
"switch"                        { yylval.STRING = strdup(yytext);  return SWITCH; }
"case"                          { yylval.STRING = strdup(yytext);  return CASE; }
"default"                       { yylval.STRING = strdup(yytext);  return DEFAULT; }
"break"                         { yylval.STRING = strdup(yytext);  return BREAK; }
"continue"                      { yylval.STRING = strdup(yytext);  return CONTINUE; }

    /* functions */
"return"                        { yylval.STRING = strdup(yytext);  return RETURN; }
"void"                          { yylval.STRING = strdup(yytext);  return VOID; }
"print"                         { yylval.STRING = strdup(yytext);  return PRINT; }

"true"                          { yylval.BOOL = strdup(yytext);  return TRUE_KEYWORD; }
"false"                         { yylval.BOOL = strdup(yytext);  return FALSE_KEYWORD; }

[a-zA-Z_][a-zA-Z0-9_]*          { yylval.STRING = strdup(yytext);  return IDENTIFIER; }
[0-9]+                          { yylval.INTEGER = atoi(yytext);  return INTEGER_CONSTANT; }
[0-9]+"."[0-9]+                 { yylval.INTEGER = atof(yytext); return FLOAT_CONSTANT; }
"'"[a-zA-Z0-9]"'"               { yylval.CHAR = yytext[1]; return CHAR_CONSTANT; }
\"[a-zA-Z0-9]+\"                { yylval.STRING = strdup(yytext);  return STRING_CONSTANT; }


[ \t]+                        { /* printf("%s",yytext); */ } /* ignore whitespace */

\n                            { ++yylineno; } /* ignore newlines */

\r                            { } /* ignore newlines */

.                               { /* printf("%s",yytext); */yyerror("Unknown character"); }

%%

int yywrap(void) {
    return 1;
}
