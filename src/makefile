lexer: 
	flex lexer.l

parser: 
	bison -d parser.y

build: lexer parser

compile: build
	gcc parser.tab.c lex.yy.c
