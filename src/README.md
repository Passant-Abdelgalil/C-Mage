## You will need to install the following dependencies on your system:
  - `Bison 3.8.2`
  - `Flex 2.6.4`
  - `gcc`

To test our compiler, we have been reading input from a file, which we have included with our delivery. The compiler will read the file `test.cpp` and will output the result in the terminal. It will print the test cases, some of the rules they match and the result of the parsing. Not printing what rule matches the input does not mean the test case is incorrect, Not all rules are printed when they match an input.</br>
If an error is found, the program will print "Syntax error" and stop the parsing.

## To run the program:
  - `bison -d parser.y`
  - `flex lexer.l`
  - `gcc parser.tab.c lex.yy.c`
  - `.\a.exe test.cpp`


<!-- how to get the version of bison and flex -->
<!-- bison --version -->
<!-- flex --version -->