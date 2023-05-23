lexer:
	flex lexer.l

parser:
	bison -d parser_new.y

build: parser lexer

phase1: build
		gcc parser_new.tab.c lex.yy.c
		.\a.exe test.cpp

testfile: build
		gcc parser_new.tab.c lex.yy.c
		.\a.exe $(FILE)
