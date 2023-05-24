yems: 
	python GUI/app.py

lexer:
	flex -o build/lex.yy.c src/lexer.l

parser:
	bison -o build/parser.tab.c -d src/parser.y -Weverything

build: parser lexer

phase1: build
		gcc build/parser.tab.c build/lex.yy.c -o ./bin/a.exe
		bin/a.exe tests/testscope.cln

testfile: build
		gcc build/parser.tab.c build/lex.yy.c -o ./bin/a.exe
		bin/a.exe $(FILE)

phase2:	build
	gcc build/parser.tab.c build/lex.yy.c -o ./bin/a.exe
	bin/a.exe tests/test.cln

phase2_ubnutu: build
	gcc build/parser.tab.c build/lex.yy.c -o ./bin/a.out
	bin/a.out tests/test.cln

k: build
	gcc build/parser.tab.c build/lex.yy.c -o ./bin/a.out
	bin/a.out tests/loop_test.cln

d: build
	gcc -g build/parser.tab.c build/lex.yy.c -o ./bin/a.out
	gdb -tui ./bin/a.out tests/loop_test.cln

ki: build
	gcc build/parser.tab.c build/lex.yy.c -o ./bin/a.out
	bin/a.out

gui: build
	gcc build/parser.tab.c build/lex.yy.c -o ./bin/a.exe
	./bin/a.exe ./GUI/to_compile.cln

