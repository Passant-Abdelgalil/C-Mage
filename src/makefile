lexer:
	flex lexer.l

parser:
	bison -d parser.y

build: parser lexer

phase1: build
		gcc parser.tab.c lex.yy.c
		.\a.exe test.cpp

testfile: build 
		gcc parser.tab.c lex.yy.c 
		.\a.exe $(FILE)
