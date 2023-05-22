%{
    #include <stdlib.h>
    #include <stdio.h>
    #include <string.h>
    #include <stdbool.h>
    #include <errno.h>
    #include <ctype.h>

    void yyerror (char* ); int yywrap();
    int yylex();
    extern FILE *yyin;
    extern FILE *yyout;
    extern int yylineno;

    typedef enum { KEYWORD, FUNCTION, VARIABLE, CONSTANT, ENUM } SymbolType;
    char* types [5] = {"KEYWORD", "FUNCTION", "VARIABLE", "CONSTANT", "ENUM"};

    typedef struct  {
        char *name;                         /* symbol name */
        char *datatype;                     /* symbol data type [int, float, enum <name>, ...etc] */
        SymbolType type;               /* symbol type [function, variable, ...etc] */
        int lineno;                         /* line number where this symbol's declared */
        bool initialized, is_const;   /* flags to indicate the state of the symbol */
        char* value;
        // int scope;
        // int scopes[10];
    } SymbolTableEntryType;

    typedef struct {
        SymbolTableEntryType *array;
        size_t used;
        size_t size;
    } SymbolTable;

    SymbolTable symbolTable;

    void initSymbolTable(size_t initialSize);
    void printSymbolTable();

    void handleEnumDeclaration(char* identifier, char* enumValues);
    void insertSymbol(SymbolTableEntryType symbol);

    // Helper functions

    char *ltrim(char *s)
    {
        while(isspace(*s)) s++;
        return s;
    }

    char *rtrim(char *s)
    {
        char* back = s + strlen(s);
        while(isspace(*--back));
        *(back+1) = '\0';
        return s;
    }

    char *trim(char *s)
    {
        return rtrim(ltrim(s)); 
    }

%}

%union {
    int INTEGER;
    char *STRING;
    float FLOAT;
    char CHAR;
    char *BOOL;
}
%token<STRING> IDENTIFIER STRING_DECLARATION ENUM_DECLARATION CONST_DECLARATION BOOL_DECLARATION CHAR_DECLARATION FLOAT_DECLARATION INT_DECLARATION
%token<INTEGER> INTEGER_CONSTANT
%token<FLOAT> FLOAT_CONSTANT
%token<CHAR>  CHAR_CONSTANT
%token<BOOL> TRUE_KEYWORD FALSE_KEYWORD
%token<STRING> STRING_CONSTANT

%token AND OR NOT EQ NE LT GT LE GE
%token IF ELSE WHILE FOR DO SWITCH CASE DEFAULT BREAK CONTINUE
%token RETURN VOID PRINT
%token SINGLE_LINE_COMMENT 
%nonassoc IFX
%nonassoc ELSE
%nonassoc UMINUS

%type <STRING> enum_list
%type <STRING> enum_state
%type <STRING> enum_definition
/* %type <STRING> enum_opt_value */


%right '='
%left  OR
%left  AND
%left  EQ NE
%left  LT GT LE GE
%left  '+' '-'
%left  '*' '/' '%'
%right NOT

%%
statement_list:                         statement ';'
|                                       statement_list statement ';'
|                                       control_statement
|                                       statement_list control_statement
|                                       braced_statements
|                                       statement_list braced_statements
|                                       statement error {yyerrok;}
;

braced_statements:                      '{' statement_list '}'  //{printf("braced statements\n");}
;

statement:                              expression
|                                       variable_declaration
|                                       assignment  
|                                       RETURN                                           // {printf("empty return\n");}
|                                       RETURN expression                               // {printf("return\n");}
|                                       BREAK                                           // {printf("break\n");}
|                                       CONTINUE                                        // {printf("continue\n");}
|                                       
;

variable_declaration:                   variable_type IDENTIFIER 
|                                       variable_type IDENTIFIER '=' expression
|                                       enum_definition
|                                       CONST_DECLARATION variable_type IDENTIFIER '=' expression
|                                       ENUM_DECLARATION IDENTIFIER IDENTIFIER 
|                                       ENUM_DECLARATION IDENTIFIER assignment
|                                       variable_declaration_error
{
    yyerror("missing identifier");
    yyerrok;
}
|                                       const_declaration_error
{
    yyerror("cannot declare constant without value");
    yyerrok;
}
;

variable_type:                          INT_DECLARATION                    
|                                       FLOAT_DECLARATION
|                                       CHAR_DECLARATION
/*|                                       CONST_DECLARATION */
|                                       BOOL_DECLARATION
|                                       STRING_DECLARATION
;

enum_definition:                        ENUM_DECLARATION IDENTIFIER '{' enum_list '}' { handleEnumDeclaration($2, $4); }
;

enum_state:                             IDENTIFIER '=' INTEGER_CONSTANT     { sprintf($$, "%s=%d", $1, $3); }
|                                       IDENTIFIER                          { sprintf($$, "%s", $1); }
;

enum_list:                              enum_list ',' enum_state  {sprintf($$, "%s,%s", $1, $3); }  
|                                       enum_state          {$$ = $1;}
;


expression:                             IDENTIFIER                            // {printf("identifier expression\n");}
|                                       INTEGER_CONSTANT
|                                       FLOAT_CONSTANT
|                                       CHAR_CONSTANT                        // {printf("char constant expression\n");}
|                                       STRING_CONSTANT                      // {printf("string constant expression\n");}
|                                       TRUE_KEYWORD                         
|                                       FALSE_KEYWORD
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
|                                       expression_error
{
    yyerror("missing operand");
    yyerrok;
}
;

function_declaration:                   variable_type IDENTIFIER '(' parameter_list ')' braced_statements
|                                       VOID IDENTIFIER '(' parameter_list ')' braced_statements
;

function_call:                          IDENTIFIER '(' arguemnt_list ')'                // {printf("function call\n");}
|                                       reserved_functions '(' arguemnt_list ')'        // {printf("print call\n");}
;

/*reserved functions rule */
reserved_functions:                     PRINT
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

control_statement:                      if_statement
|                                       while_loop
|                                       do_while_loop
|                                       switch_statement
|                                       for_loop
|                                       comments
|                                       function_declaration


/*missing_semicolon:                      expression error
;
*/

assignment:                             IDENTIFIER '=' expression                       // {printf("assignment\n");}
;

for_loop:                               FOR '(' variable_declaration ';' statement ';' assignment ')' braced_statements // {printf("for loop\n");}
;

if_statement:                           IF '(' expression ')' braced_statements %prec IFX               // {printf("if statement\n");}
|                                       IF '(' expression ')' braced_statements ELSE braced_statements              // {printf("if statement with else\n");}
|                                       IF '(' expression ')' braced_statements ELSE if_statement       // {printf("if statement with else if\n");}
;

while_loop:                             WHILE '(' expression ')' braced_statements                      // {printf("while loop\n");}
;

do_while_loop:                          DO braced_statements WHILE '(' expression ')' ';'              // {printf("do while loop\n");}
;

switch_statement:                       SWITCH '(' expression ')' '{' case_list '}'          //{printf("switch statement\n");}
;

case_list:                              case_list case
|                                       case
;

case:                                   CASE expression ':' statement_list 
|                                       DEFAULT ':' statement_list
;

comments:                               SINGLE_LINE_COMMENT                            // {printf("single line comment\n");}


expression_error:                       expression '+'
;

variable_declaration_error:             variable_type
|                                       variable_type IDENTIFIER '='
;

const_declaration_error:                CONST_DECLARATION variable_type IDENTIFIER 
;

%%

void yyerror(char *s) {
    fprintf(stderr, "\n%s at line %d\n", s, yylineno);
}

int main(int argc, char *argv[])
{
    yyin = fopen(argv[1], "r");
    printf("in main\n");
    initSymbolTable(1000);
    printf("symbol table created\n");
    yyparse();
    printf("parsed\n");
    printSymbolTable();

    if (yywrap())
    {
        printf("\nParsing successful ya regala!\n");
    }
    fclose(yyin); 
    return 0;
}

/* Initialize the dynamic symbol table */
void initSymbolTable(size_t initialSize) {
    symbolTable.used = 0;
    symbolTable.size = initialSize;
    symbolTable.array = malloc(initialSize * sizeof(SymbolTableEntryType));
}


void handleEnumDeclaration(char* identifier, char* enumValues){
    if (identifier == NULL || enumValues == NULL){
        printf("null values\n");
        return;
    }
    printf("in handle enum\n");
    printf("%s %s\n", identifier, enumValues);
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
        token= strtok(NULL, ",");
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
        else {
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
            if (errno == ERANGE || endptr == value || *endptr != '\0') {
                printf("Error: Invalid integer\n");
                return;
                /* TODO: handle this error because enums can only hold integer values in our language */
            } else {
                varValue = num;
            }
        }
        
        SymbolTableEntryType entry;
        entry.name = trim(strdup(varName));
        entry.type = CONSTANT;
        entry.lineno = yylineno;
        entry.initialized = true;
        entry.is_const = true;
        /* Set the variable datatype to be 'enum <vairable name>' */
        char type[] = "enum %s";
        int datatype_length = strlen(type) + strlen(identifier) - 1;
        entry.datatype = malloc(datatype_length * sizeof(char));
        sprintf(entry.datatype, type, identifier);
        /* Set the variable value to its string representation */        
        // Calculate the number of digits in the number
        int num_digits = snprintf(NULL, 0, "%d", varValue);
        // Allocate memory for the string based on the number of digits
        entry.value = (char *) malloc(num_digits + 1);
        // Call sprintf to convert the number to a string
        sprintf(entry.value, "%d", varValue);

        /* insert the symbol in the table */
        insertSymbol(entry);

        // Free the memory allocated for the substrings
        if(eq != NULL)
            free(varName);
    }

    SymbolTableEntryType entry;
    entry.name = trim(strdup(identifier));
    entry.type = ENUM;
    entry.lineno = yylineno;
    entry.initialized = true;
    entry.is_const = true;
    entry.datatype = "enum";

    insertSymbol(entry);
    // Free the memory allocated for the tokens
    for (int i = 0; i < num_tokens; i++) {
        free(tokens[i]);
    }
    free(tokens);
}

void insertSymbol(SymbolTableEntryType symbol) {
    /*  check if this symbol already exists */
    for (int i=0; i < symbolTable.used; i++){
        if (strcmp(symbol.name, symbolTable.array[i].name) == 0) {
            /* ERROR: symbol already exists */
            printf("symbol %s already exists\n", symbol.name);
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
    printf("will insert symbol %s\n", symbol.name);
    symbolTable.array[symbolTable.used++] = symbol;
    printf("inserted\n");
}

void printSymbolTable() {
    printf("\nName\tData Type\tType\tLine\tConst\tInitialized \n");
    
    for (int i=0; i < symbolTable.used; i++){
        SymbolTableEntryType *symbolData = &(symbolTable.array[i]);

        printf("%s\t%s\t%s\t%d\t%s\t%s\n",
            symbolData->name,
            symbolData->datatype, 
            types[symbolData->type],
            symbolData->lineno,
            symbolData->is_const ? "YES" : "NO", 
            symbolData->initialized ? "YES": "NO");
    }
}