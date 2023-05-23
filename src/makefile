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

phase2:
	bison -d parser_new.y
	flex lexer.l
	gcc parser_new.tab.c lex.yy.c
	./a.exe test.cpp

phase2_ubnutu:
	bison -d parser_new.y
	flex lexer.l
	gcc parser_new.tab.c lex.yy.c
	./a.out test.cpp
