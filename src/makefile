lexer:
	flex lexer.l

parser:
	bison -d parser.y -Weverything

build: parser lexer

phase1: build
		gcc parser.tab.c lex.yy.c
		.\a.exe ../test/testscope.cpp

testfile: build
		gcc parser.tab.c lex.yy.c
		.\a.exe $(FILE)

phase2:
	bison -d parser.y
	flex lexer.l
	gcc parser.tab.c lex.yy.c
	./a.exe ../test/test.cpp

phase2_ubnutu:
	bison -d parser.y
	flex lexer.l
	gcc parser.tab.c lex.yy.c
	./a.out ../test/test.cpp

clean:
	rm -rf *.tab.* lex.yy.c ./a.exe* ./a.out 

k: build
	gcc parser.tab.c lex.yy.c
	./a.out ../test/gen.cpp
	rm a.out parser.tab.c parser.tab.h lex.yy.c

ki: build
	gcc parser.tab.c lex.yy.c
	./a.out
	rm a.out parser.tab.c parser.tab.h lex.yy.c
