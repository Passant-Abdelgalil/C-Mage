k: build
		gcc parser.tab.c lex.yy.c
		./a.out gen.cpp
		rm a.out parser.tab.c parser.tab.h lex.yy.c

lexer:
	flex lexer.l

parser:
	bison -d parser.y -Wall -Weverything

build: parser lexer

phase1: build
		gcc parser.tab.c lex.yy.c
		.\a.exe test.cpp

testfile: build 
		gcc parser.tab.c lex.yy.c 
		.\a.exe $(FILE)

clean: 
		rm a.out parser.tab.c parser.tab.h lex.yy.c
