%{
    #include <stdlib.h>
    #include <string.h>
    #include <stdio.h>
    #include <stdbool.h>

    void yyerror (const char* s);
    int yywrap();
    int yylex();

    extern FILE *yyin;
    extern FILE *yyout;
    extern char * yytext;
    extern int lineno;


    // type functions
    // struct nodeType* intNode(); 
    // struct nodeType* floatNode();
    // struct nodeType* boolNode();
    // struct nodeType* stringNode();

    typedef enum { KEYWORD, FUNCTION, VARIABLE, CONSTANT } SymbolType;
    char* types [4] = {"KEYWORD", "FUNCTION", "VARIABLE", "CONSTANT"};

    typedef struct  {
        char *name;                         /* symbol name */
        char *datatype;                     /* symbol data type [int, float, enum <name>, ...etc] */
        SymbolType type;               /* symbol type [function, variable, ...etc] */
        int lineno;                         /* line number where this symbol's declared */
        bool initialized, is_const;   /* flags to indicate the state of the symbol */
        // int scope;
        // int scopes[10];
    } SymbolTableEntryType;

    typedef struct {
        SymbolTableEntryType *array;
        size_t used;
        size_t size;
    } SymbolTable;

    SymbolTable symbolTable;

    void handleEnumDeclaration(char* identifier, char* enumValues);
    void insertSymbol(SymbolTableEntryType symbol);


    void initSymbolTable(SymbolTable *symbolTable, size_t initialSize);
    void insertSymbol( bool initialized, bool is_const, SymbolType type);
    void printSymbolTable(SymbolTable *symbolTable);

    void updateLastSeenDatatype();
    char *datatype;                            /* to hold the last seen data type */
    // struct nodeType {
    //     char *type;              /* type of node */
    //     char *expr_type;
    // };
    
%}
%union {
    int INTEGER;
    char *STRING;
    char *ID;
    float FLOAT;
    char CHAR;
    int BOOL;
    // struct nodeType* node_type;
}
%token<ID> IDENTIFIER
%token<INTEGER> INT_DECLARATION
%token<FLOAT> FLOAT_DECLARATION
%token<CHAR> CHAR_DECLARATION 
%token<STRING> STRING_DECLARATION
%token<BOOL> BOOL_DECLARATION
%token ENUM_DECLARATION
%token CONST_DECLARATION
%token AND OR NOT EQ NE LT GT LE GE
%token IF ELSE WHILE FOR DO SWITCH CASE DEFAULT BREAK CONTINUE
%token RETURN VOID PRINT
%token INTEGER_CONSTANT FLOAT_CONSTANT CHAR_CONSTANT STRING_CONSTANT
%token TRUE_KEYWORD FALSE_KEYWORD
%token SINGLE_LINE_COMMENT 
/* %nonassoc IFX */
%nonassoc ELSE
%nonassoc UMINUS

/* %type <node_type>  */

%right '='
%left  OR
%left  AND
%left  EQ NE
%left  LT GT LE GE
%left  '+' '-'
%left  '*' '/' '%'
%right NOT

%%
program:                                statement_list                    {printf("program\n");}
;

// declaration_list:                       declaration_list declaration            {printf("declaration_list\n");}
// |                                       declaration                             {printf("declaration_list\n");}
// ;

declaration:                            variable_declaration ';'            {printf("variable declaration\n");}
|                                       function_declaration                {printf("function declaration\n");}
;

variable_declaration:                   variable_type IDENTIFIER {printf("variable22\n"); insertSymbol( false, false, VARIABLE); }
|                                       variable_type IDENTIFIER {printf("variable33\n"); insertSymbol( true, false, VARIABLE); } '=' expression 
/*|                                       variable_type IDENTIFIER '=' function_call      {printf("variable declared using function call\n");}*/
/*|                                       variable_type IDENTIFIER '=' expression '+' function_call*/
|                                       enum_definition
|                                       CONST_DECLARATION variable_type IDENTIFIER {printf("variable\n"); insertSymbol( true, true, VARIABLE); } '=' expression
;

variable_type:                          INT_DECLARATION                     { printf("var type\n"); updateLastSeenDatatype(); }       
|                                       FLOAT_DECLARATION                   { printf("var type\n"); updateLastSeenDatatype(); }
|                                       CHAR_DECLARATION                    { printf("var type\n"); updateLastSeenDatatype(); }
/*|                                       CONST_DECLARATION */
|                                       BOOL_DECLARATION                    { printf("var type\n");updateLastSeenDatatype(); }
|                                       STRING_DECLARATION                  { printf("var type\n");updateLastSeenDatatype(); }
;

/* a function can have the additional type void as well as the other types */
/* problem here */
/* proposed solution 1: add void to the function definition and remove this rule*/
// function_type:                          variable_type
// |                                       VOID
// ;


enum_definition:                        ENUM_DECLARATION  IDENTIFIER '{' enum_list '}' {handleEnumDeclaration($2, $3)}
;

enum_list:                              IDENTIFIER enum_opt_value ',' enum_list 
|                                       IDENTIFIER enum_opt_value
;

enum_opt_value:                         '=' INTEGER_CONSTANT
|                                       /* empty */
;

expression:                             IDENTIFIER                              {printf("identifier expression\n");}
|                                       INTEGER_CONSTANT                        {printf("integer const\n"); insertSymbol( false, true, CONSTANT); }
|                                       FLOAT_CONSTANT                          {printf("float const\n"); insertSymbol( false, true, CONSTANT); }
|                                       CHAR_CONSTANT                           {printf("char const\n"); insertSymbol( false, true, CONSTANT); }
|                                       STRING_CONSTANT                         {printf("string const\n"); insertSymbol( false, true, CONSTANT); }
|                                       TRUE_KEYWORD                            {printf("true keyword\n"); insertSymbol( false, true, KEYWORD); }
|                                       FALSE_KEYWORD                           {printf("false keyword\n"); insertSymbol( false, true, KEYWORD); }
|                                       '(' expression ')'
|                                       expression '+' expression
|                                       expression '-' expression
|                                       expression '*' expression
|                                       expression '/' expression
|                                       expression '%' expression
|                                       expression EQ expression
|                                       expression NE expression
|                                       expression LT expression
|                                       expression GT expression
|                                       expression LE expression
|                                       expression GE expression
|                                       expression AND expression
|                                       expression OR expression
|                                       NOT expression
|                                       '-' expression %prec UMINUS
|                                       function_call
;
    /* may not use arrays */
// |                                       IDENTIFIER '[' expression ']'

function_declaration:                   variable_type IDENTIFIER {printf("function1\n"); insertSymbol( false, false, FUNCTION); } '(' parameter_list ')' block
|                                       VOID IDENTIFIER {printf("function\n"); insertSymbol( false, false, FUNCTION); } '(' parameter_list ')' block
;

function_call:                          IDENTIFIER '(' arguemnt_list ')'                {printf("function call\n");}
|                                       reserved_functions '(' arguemnt_list ')'        {printf("print call\n");}
;

/*reserved functions rule */
reserved_functions:                     PRINT                                           {printf("print\n"); insertSymbol( false, false, KEYWORD); }
/* | cout and whatnot*/
; 

arguemnt_list:                          arguemnt_list ',' expression        
|                                       expression
|                                    /* empty */
;

parameter_list:                         parameter_list ',' parameter
|                                       parameter
|                                       /* empty */
;

parameter:                              variable_declaration
;

block:                                  '{' statement_list '}'                 {printf("block\n");}
;

statement_list:                         statement statement_list
|                                      /* empty */
;

statement:                              expression ';'
|                                       declaration
/*|                                       function_call ';'*/
|                                       for_loop
|                                       assignment
|                                       if_statement
|                                       while_loop
|                                       do_while_loop
|                                       block
|                                       RETURN {printf("return\n"); insertSymbol( false, false, KEYWORD); } ';'                                          {printf("empty return\n");}
|                                       RETURN {printf("return2\n"); insertSymbol( false, false, KEYWORD); } expression ';'                               {printf("return\n");}
|                                       BREAK {printf("break\n"); insertSymbol(false, false, KEYWORD); } ';'                                           {printf("break\n");}
|                                       CONTINUE {printf("continue\n"); insertSymbol( false, false, KEYWORD); } ';'                                        {printf("continue\n");}
|                                       switch_statement
|                                       comments
/*|                                       if while for ... */
;

assignment:                             IDENTIFIER '=' expression ';'                       {printf("assignment\n");}
/*|                                       IDENTIFIER '=' function_call ';'                     {printf("function assignment\n");}*/
;


for_loop:                               FOR {insertSymbol( false, false, KEYWORD);} '(' for_init ';' for_condition ';' for_update ')' block {printf("for loop\n");}
;

for_init:                               variable_declaration
|                                       assignment
|                                       /* empty */
;

for_condition:                          expression
|                                       /* empty */
;

for_update:                             assignment
|                                       /* empty */
;


if_statement:                           IF { printf("if\n");insertSymbol(false, false, KEYWORD); } '(' expression ')' block else_statement
/* |                                       IF '(' expression ')' block ELSE block              {printf("if statement with else\n");} */
/* |                                       IF '(' expression ')' block ELSE if_statement       {printf("if statement with else if\n");} */
;

else_statement:                         ELSE statement
|                                       /* empty */
;

/* body:                                   statement
|                                       block
; */

while_loop:                             WHILE { printf("while\n");insertSymbol(false, false, KEYWORD); } '(' expression ')' block
;

do_while_loop:                          DO { printf("do while\n");insertSymbol( false, false, KEYWORD); } block WHILE { insertSymbol( false, false, KEYWORD); } '(' expression ')' ';'              {printf("do while loop\n");}
;

switch_statement:                       SWITCH {printf("switch\n"); insertSymbol( false, false, KEYWORD); } '(' expression ')' '{' case_list '}' 
;

case_list:                              case_list case
|                                       case
;

case:                                   CASE {printf("case\n"); insertSymbol( false, false, KEYWORD); } expression ':' statement_list 
|                                       DEFAULT  { printf("case default\n"); insertSymbol(false, false, KEYWORD); }':' statement_list
;

comments:                               SINGLE_LINE_COMMENT                            {printf("single line comment\n");}
/*|                                       MULTI_LINE_COMMENT                           {printf("multi line comment\n");}*/
;

%%

void yyerror(const char *s) {
    fprintf(stdout, "%s\n", s);
}

int main(int argc, char *argv[])
{
    yyin = fopen(argv[1], "r");
    initSymbolTable(&symbolTable, 1000);

    yyparse();
    printf("parsed\n");
    
    printSymbolTable(&symbolTable);

    if (yywrap()) printf("Parsing successful ya regala!\n");
    
    fclose(yyin); 
    return 0;
}

void handleEnumDeclaration(char* identifier, char* enumValues){
    char *token;
    char **tokens = NULL; // Declare the tokens array as a pointer to pointers
    int num_tokens = 0;

    // Get the first token
    token = strtok(enumValues, ",");

    // Iterate over the rest of the tokens
    while (token != NULL) {
        num_tokens++;
        tokens = realloc(tokens, num_tokens * sizeof(char*)); // Resize the tokens array
        tokens[num_tokens - 1] = malloc(strlen(token) + 1); // Allocate memory for the token
        strcpy(tokens[num_tokens - 1], token); // Copy the token into the array
        token = strtok(NULL, ",");
    }
    /* This variable will hold the value that should be set to the enum variables */
    int varValue = -1;
    char* varName;
    // Print the tokens for verification
    for (int i = 0; i < num_tokens; i++) {
        // Find the position of the '=' character in the token
        char *eq = strchr(tokens[i], '=');
        char* value;
        /* no set value for this variable */
        if (eq == NULL) {
            varValue = varValue + 1;
            varName = tokens[i];
        }
        else{
            // Allocate memory for the key and value substrings
            varName = malloc(eq - tokens[i] + 1);
            value = malloc(strlen(eq + 1) + 1);
            // Extract the key and value substrings
            strncpy(varName, tokens[i], eq - tokens[i]);
            varName[eq - tokens[i]] = '\0';
            strcpy(value, eq + 1);

            /* convert the value to an integer */
            char* endptr;
            int num = strtol(value, &endptr, 10);

            // Check for errors
            if (errno == ERANGE || endptr == str || *endptr != '\0') {
                printf("Error: Invalid integer\n");
                return;
                /* TODO: handle this error because enums can only hold integer values in our language */
            } else {
                varValue = num;
            }
        }
        SymbolTableEntryType entry;
        entry.name = varName;
        entry.type = CONSTANT;
        entry.value = varValue;
        entry.lineno = lineno;
        entry.initialized = true;
        entry.is_const = true;

        char type[] = "enum %s";
        int datatype_length = strlen(type) + strlen(varName) - 1;
        entry.datatype = malloc(datatype_length * sizeof(char));
        sprintf(entry.datatype, type, varName);
        
        insertSymbol(entry);

        // Free the memory allocated for the substrings
        free(varName);
        free(value);
    }

    // Free the memory allocated for the tokens
    for (int i = 0; i < num_tokens; i++) {
        free(tokens[i]);
    }
    free(tokens);
}

void insertSymbol(SymbolTableEntryType symbol) {

    for (int i=0; i < symbolTable->used; i++){
        SymbolTableEntryType *symbolData = &(symbolTable->array[i]);

        if (strcmp(symbol.name, symbolData->name) == 0) {
            /* ERROR: symbol already exists */
            return;
        }
    }

    /* check if the symbol table is full */
    if(symbolTable.used == symbolTable.size) {
        printf("doubling symbol table size\n");
        /* double the symbol table array size */
        symbolTable.size *= 2;
        /* reallocate the array with the new size keeping the old data */
        symbolTable.array = realloc(symbolTable.array, symbolTable.size * sizeof(SymbolTableEntryType));
    }

    symbolTable.array[symbolTable.used++] = symbolData;
    printf("inserted\n");
}

/* Initialize the dynamic symbol table */
void initSymbolTable(SymbolTable *symbolTable, size_t initialSize) {
    symbolTable->array = malloc(initialSize * sizeof(SymbolTableEntryType));
    symbolTable->used = 0;
    symbolTable->size = initialSize;
}

void insertSymbol(bool initialized, bool is_const, SymbolType type) {
    printf("calling insertSymbol\n");
    /* check if the symbol table is full */
    if(symbolTable.used == symbolTable.size) {
        printf("doubling symbol table size\n");
        /* double the symbol table array size */
        symbolTable.size *= 2;
        /* reallocate the array with the new size keeping the old data */
        symbolTable.array = realloc(symbolTable.array, symbolTable.size * sizeof(SymbolTableEntryType));
    }

    /* TODO: check if this symbol already exists and throw error */
    
    /* insert the symbol entry in the table */
    SymbolTableEntryType symbolData;

    symbolData.initialized = initialized;
    symbolData.is_const = is_const;
    symbolData.type = type;
    symbolData.lineno = lineno;
    printf("yytext is: %s\n", yytext);
    if (symbolData.type != VARIABLE && symbolData.type != FUNCTION) {
        printf("not variable \n");
        /* yytext points at the first char in the token
            we pass it to strdup to create a copy of this
            string and store it as the symbol name
        */
        symbolData.name = strdup(yytext);
        symbolData.datatype = strdup("N/A");
    }
    else {
        symbolData.name = strdup(yylval.ID);
        symbolData.datatype = datatype;
    }
    printf("symbol name: %s\n",symbolData.name);

    symbolTable.array[symbolTable.used++] = symbolData;
    printf("inserted\n");
}

void printSymbolTable(SymbolTable *symbolTable) {
    printf("\nName\tData Type\tScope\tType\tLine\tConst\tInitialized \n");
    
    for (int i=0; i < symbolTable->used; i++){
        SymbolTableEntryType *symbolData = &(symbolTable->array[i]);

        printf("%s\t%s\t%d\t%s\t%d\t%s\t%s\n",
            symbolData->name,
            symbolData->datatype, 
            symbolData->scope, 
            types[symbolData->type],
            symbolData->lineno,
            symbolData->is_const ? "YES" : "NO", 
            symbolData->initialized ? "YES": "NO");
    }
}

void updateLastSeenDatatype() {
    datatype = strdup(yytext);
    printf("last seen datatype : %s\n", datatype);
}

//------------------------------------------------------------------------------- 
// Type checking functions 
//-------------------------------------------------------------------------------  