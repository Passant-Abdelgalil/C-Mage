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

    void printSymbolTable();
    void printWarnings();
    void printErrors();

    typedef enum { KEYWORD, FUNCTION, VARIABLE, CONSTANT, ENUM } SymbolType;
    char* types [5] = {"KEYWORD", "FUNCTION", "VARIABLE", "CONSTANT", "ENUM"};

    typedef enum {Int, Float, String, Bool, Char} valueDatatype;
    char* datatypes [5] = {"int", "float", "string", "bool", "char"};
    int typeToEnum(char* value) {
        printf("TYPE TO ENUM type is %s\n", value);
        for (int i = 0; i < 5; i++) {
            if (strcmp(datatypes[i], value) == 0) {
                return i;
            }
        }
        printSymbolTable();
        return -1; // Value not found
    }

    typedef struct  {
        char** parameterNames;
        char** parameterTypes;
        char* returnType;
    }FunctionData;

    typedef struct  {
        char *name;                         /* symbol name */
        char *datatype;                     /* symbol data type [int, float, enum <name>, ...etc] */
        SymbolType type;               /* symbol type [function, variable, ...etc] */
        int lineno;                         /* line number where this symbol's declared */
        bool initialized, is_const, is_used;   /* flags to indicate the state of the symbol */
        
        FunctionData functionData;
    } SymbolTableEntryType;

    typedef struct {
        SymbolTableEntryType *array;
        size_t used;
        size_t size;
    } SymbolTable;

    int errorCount = 0;
    char **errors;
    int warningCount = 0;
    char **warnings;

    bool errorCode = false;

    SymbolTable symbolTable;
    

    struct nodeType {
        valueDatatype type;
        char *value;
        bool is_const;
        bool initialized;
    };


    
    void initSymbolTable(size_t initialSize);


    // Variables Functions
    bool handleVariableDeclaration(char* type, char* indentifier, struct nodeType *value, bool is_const);
    bool handleFunctionDeclaration(char* type, char* identifier, char* parameters);
    // Enums Functions
    void handleEnumDeclaration(char* identifier, char* enumValues);
    void handleEnumVariableDeclaration(char* enumName, char* identifier, struct nodeType *value);


    char* checkTypes(char* op1, char* op2, char* op);
    char* getType(char* variable);
    void insertSymbol(SymbolTableEntryType symbol);
    int  getSymbolIdx(char* symbolName);
    void setUsed(char* identifier);
    int checkInitialization(char* identifier);
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


    // type functions
    struct nodeType* intNode(int value); 
    struct nodeType* floatNode(float value);
    struct nodeType* boolNode(char* value);
    struct nodeType* stringNode(char* value);
    struct nodeType* charNode(char value);

    struct nodeType* combineNode(struct nodeType* node1, struct nodeType* node2);
    struct nodeType* dupNode(struct nodeType* node);
    struct nodeType* getNode(char* identifier);
    void initializationError(char * identifier);

    char *stak[10000];
    int stakNext = 0;

    int regNext = 0;
    char *tempReg() {
        char *temp = (char *) malloc(10);
        sprintf(temp, "R%d", regNext++);
        return temp;
    }

    int labelNext = 100;
    char *label() {
        char *temp = (char *) malloc(10);
        sprintf(temp, "L%d", labelNext++);
        return temp;
    }

    void chk_undeflow(int x) {
      if (stakNext < x) {
        printf("ERROR: stack underflow\n");
        exit(1);
      }
    }

    void chk_overflow(int x) {
      if (stakNext + x >= 10000) {
        printf("ERROR: stack overflow\n");
        exit(1);
      }
    }

    void push(char *);
    void sto();
    void expr();

%}

%union {
    int INTEGER;
    float FLOAT;
    char *STRING;
    char CHAR;
    char* BOOL;

    struct nodeType* node_type;
}


%token<STRING> VOID IDENTIFIER STRING_DECLARATION ENUM_DECLARATION CONST_DECLARATION BOOL_DECLARATION CHAR_DECLARATION FLOAT_DECLARATION INT_DECLARATION PRINT
%token<INTEGER> INTEGER_CONSTANT
%token<FLOAT> FLOAT_CONSTANT
%token<CHAR>  CHAR_CONSTANT
%token<BOOL> TRUE_KEYWORD FALSE_KEYWORD
%token<STRING> STRING_CONSTANT

%token AND OR NOT EQ NE LT GT LE GE
%token IF ELSE WHILE FOR DO SWITCH CASE DEFAULT BREAK CONTINUE
%token RETURN  
%token SINGLE_LINE_COMMENT 
%nonassoc IFX
%nonassoc ELSE
%nonassoc UMINUS

%type <STRING> enum_list
%type <STRING> enum_state
%type <STRING> enum_definition
%type <STRING> variable_type
%type <STRING> function_call
%type <node_type> expression
%type <node_type> const_expression
%type <STRING> general_declaration
%type <STRING> parameter_list
%type <STRING> parameter
/* %type <STRING> expression_error */



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
|                                       statement error ';' {yyerrok;}
;

braced_statements:                      '{' statement_list '}'  //{printf("braced statements\n");}
;

statement:                              expression
|                                       variable_declaration
|                                       assignment  
|                                       RETURN                              { /*rtn(); */}                              
|                                       RETURN expression                   { /* rtn();*/ }                         
|                                       BREAK                               {/*brk();*/}                 
|                                       CONTINUE                            {/*cnt();*/}                 
|                                       
;

general_declaration:                    variable_type IDENTIFIER                                                { handleVariableDeclaration($1, $2, NULL, false); sprintf($$, "%s:%s", $1, $2);}
|                                       variable_type IDENTIFIER '=' {push($2);} expression                     { if(handleVariableDeclaration($1, $2, $5, false)) sto();  sprintf($$, "%s:%s", $1, $2);}
|                                       CONST_DECLARATION variable_type IDENTIFIER {push($3);} '=' expression   { if(handleVariableDeclaration($2, $3, $6, true)) sto();  sprintf($$, "%s:%s", $1, $2);}
;

variable_declaration:                   general_declaration
|                                       enum_definition
|                                       ENUM_DECLARATION IDENTIFIER IDENTIFIER                                  { handleEnumVariableDeclaration($2, $3, NULL); }
|                                       ENUM_DECLARATION IDENTIFIER IDENTIFIER {push($3);}'=' expression        { sto(); handleEnumVariableDeclaration($2, $3, $6);}
|                                       variable_declaration_error
{
    yyerror("missing identifier");
    yyerrok;
}
|                                       const_declaration_error
{
    errors = realloc(errors, sizeof(char*) * (errorCount+1));
    int errorMsgLen = strlen("Line %d: Can not declare constant without intialization") +
                        snprintf(NULL, 0, "%d", yylineno) - 1;
    errors[errorCount] = malloc(sizeof(char) * errorMsgLen);
    sprintf(errors[errorCount], "Line %d: Can not declare constant without intialization", yylineno);
    errorCount++;
}
;

variable_type:                          INT_DECLARATION                     { $$ = $1; }   
|                                       FLOAT_DECLARATION                   { $$ = $1; }
|                                       CHAR_DECLARATION                    { $$ = $1; }
/*|                                       CONST_DECLARATION */
|                                       BOOL_DECLARATION                    { $$ = $1; }
|                                       STRING_DECLARATION                  { $$ = $1; }
;

enum_definition:                        ENUM_DECLARATION IDENTIFIER '{' enum_list '}' { handleEnumDeclaration($2, $4); }
;

enum_state:                             IDENTIFIER '=' INTEGER_CONSTANT     { sprintf($$, "%s=%d", $1, $3); }
|                                       IDENTIFIER                          { sprintf($$, "%s", $1); }
;

enum_list:                              enum_list ',' enum_state            {sprintf($$, "%s,%s", $1, $3); }  
|                                       enum_state                          {$$ = $1;}
;

const_expression:                       INTEGER_CONSTANT                    { $$ = intNode($1); char str[30]; sprintf(str, "%d", $1); push(str);}
|                                       FLOAT_CONSTANT                      { $$ = floatNode($1); char str[30]; sprintf(str, "%f", $1); push(str);}
|                                       CHAR_CONSTANT                       { $$ = charNode($1); char str[3]; sprintf(str, "%c", $1); push(str);}
|                                       STRING_CONSTANT                     { $$ = stringNode($1); push($1); }
|                                       TRUE_KEYWORD                        { $$ = boolNode($1); push("true");}
|                                       FALSE_KEYWORD                       { $$ = boolNode($1); push("false");}
;


expression:                             IDENTIFIER                              { $$ = getNode($1); push($1); setUsed($1);}
|                                       const_expression                        { $$ = dupNode($1); }
|                                       '(' expression ')'                      { $$ = dupNode($2); }
|                                       expression '+' expression               { $$ = combineNode($1, $3); expr("+"); }
|                                       expression '-' expression               { $$ = combineNode($1, $3); expr("-"); }
|                                       expression '*' expression               { $$ = combineNode($1, $3); expr("*"); }
|                                       expression '/' expression               { $$ = combineNode($1, $3); expr("/"); }
|                                       expression '%' expression               { $$ = combineNode($1, $3); expr("%"); }
|                                       expression EQ expression                { $$ = combineNode($1, $3); expr("=="); }
|                                       expression NE expression                { $$ = combineNode($1, $3); expr("!="); }
|                                       expression LT expression                { $$ = combineNode($1, $3); expr("<"); }
|                                       expression GT expression                { $$ = combineNode($1, $3); expr(">");}
|                                       expression LE expression                { $$ = combineNode($1, $3); expr("<=");}
|                                       expression GE expression                { $$ = combineNode($1, $3); expr(">=");}
|                                       expression AND expression               { $$ = combineNode($1, $3); expr("&&");}
|                                       expression OR expression                { $$ = combineNode($1, $3); expr("||");}
|                                       NOT expression                          { $$ = dupNode($2); expr("!");}
|                                       '-' expression %prec UMINUS             { $$ = dupNode($2); expr("-");}
|                                       function_call                           { $$ = getNode($1); }
/* |                                       expression_error                    { $$ = $1; }
{
    yyerror("missing operand");
    yyerrok;
} */
;

function_declaration:                   variable_type   IDENTIFIER {/*decl_func_s($2);*/}  '(' parameter_list ')' braced_statements {/*decl_func_e($2);*/ handleFunctionDeclaration($1, $2, $5); }
|                                       VOID            IDENTIFIER {/*decl_func_s($2);*/}  '(' parameter_list ')' braced_statements {/*decl_func_e($2);*/ handleFunctionDeclaration($1, $2, $5); }
;

function_call:                          IDENTIFIER '(' arguemnt_list ')'                { $$ = $1; /*call_func($1);*/}
|                                       PRINT { /*call_rf_print();*/} '(' arguemnt_list ')'        { $$ = $1; }
;

arguemnt_list:                          arguemnt_list ',' expression        
|                                       expression
|                                    /* empty */
;

parameter_list:                         parameter_list ',' parameter                            { sprintf($$, "%s,%s", $1, $3); }
|                                       parameter                                               { sprintf($$, "%s", $1); }
|                                       /* empty */                                             { $$ = "";}
;

parameter:                              general_declaration                                     { $$ = $1; }
;

control_statement:                      if_statement            {/*pop the labels */ /*pop(2);*/}
|                                       while_loop              {/*pop the labels */ /*pop(2);*/}
|                                       do_while_loop
|                                       switch_statement
|                                       for_loop
|                                       comments
|                                       function_declaration
;

assignment:                             IDENTIFIER {push($1);} '=' expression {sto();}                       // {printf("assignment\n");}
;

for_loop:                               FOR '(' variable_declaration ';' statement ';' assignment ')' braced_statements // {printf("for loop\n");}
;

if_statement:                           IF '(' expression ')' braced_statements %prec IFX               // {printf("if statement\n");}
|                                       IF '(' expression ')' braced_statements ELSE braced_statements              // {printf("if statement with else\n");}
|                                       IF '(' expression ')' braced_statements ELSE if_statement       // {printf("if statement with else if\n");}
;

while_loop:                             WHILE '(' expression ')' braced_statements                      // {printf("while loop\n");}
;

do_while_loop:                          DO braced_statements WHILE '(' expression ')' ';'
;

switch_statement:                       SWITCH '(' expression ')' '{' case_list '}'          
;

case_list:                              case_list case
|                                       case
;

case:                                   CASE expression ':' statement_list 
|                                       DEFAULT ':' statement_list
;

comments:                               SINGLE_LINE_COMMENT                       


/* expression_error:                       expression '+'                  { $$ = $1; }
; */

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
    initSymbolTable(1000);
    printf("will parse\n");
    yyparse();
    printSymbolTable();
    printErrors();
    printWarnings();

    if (yywrap())
    {
        printf("\nParsing successful ya regala!\n");
    }
    fclose(yyin); 
    return 0;
}

void initializationError(char* identifier) {
    warnings = realloc(warnings, sizeof(char*) * (warningCount+1));
    int warningMsgLen = strlen("Line %d: Variable %s used before initialization") +
                        strlen(identifier) +
                        snprintf(NULL, 0, "%d", yylineno) - 1;
    warnings[warningCount] = malloc(sizeof(char) * warningMsgLen);
    sprintf(warnings[warningCount], "Line %d: Variable %s used before, initialization", yylineno, identifier);
    warningCount++;
}

bool handleFunctionDeclaration(char* type, char* identifier, char* parameters) {
    printf("inside function declaration: %s %s (%s)\n", type, identifier, parameters);
    
    int symbolIdx = getSymbolIdx(identifier);
    if(symbolIdx != -1 ){
        errors = realloc(errors, sizeof(char*) * (errorCount+1));
        int errorMsgLen = strlen("Line %d: Variable redeclaration, %s initially declared at %d") +
                            snprintf(NULL, 0, "%d", symbolTable.array[symbolIdx].lineno) +
                            strlen(identifier) +
                            snprintf(NULL, 0, "%d", yylineno) - 1;
        errors[errorCount] = malloc(sizeof(char) * errorMsgLen);
        sprintf(errors[errorCount], "Line %d: Variable redeclaration, %s initially declared at %d", 
                                    yylineno, identifier, symbolTable.array[symbolIdx].lineno);
        errorCount++;
        return false;
    }

    FunctionData functionData;
    functionData.returnType = strdup(type);
    functionData.parameterNames = malloc(sizeof(char**));
    functionData.parameterTypes = malloc(sizeof(char**));
    
    char *parameter;
    int num_tokens = 0;
    // Get the first parameter
    parameter = strtok(parameters, ",");
    // Iterate over the rest of the tokens
    while (parameter != NULL) {
        num_tokens++;
        printf("inside while loop\n");

        functionData.parameterNames = realloc(functionData.parameterNames, num_tokens * sizeof(char*)); // Resize the tokens array
        functionData.parameterTypes = realloc(functionData.parameterTypes, num_tokens * sizeof(char*)); // Resize the tokens array
        
        char* token = strtok(parameter, ":");
        char* parameterName;
        char* parameterType;
        if (token != NULL)
            parameterType = strdup(token);
        else{
            printf("Something is wrong in function parameters %s\n", parameters);
            break;
        }
        
        token = strtok(parameter, ":");
        if (token != NULL) 
            parameterName = strdup(token);
        else {
            printf("Something is wrong in function parameters %s\n", parameters);
            break;
        }
        
        functionData.parameterTypes[num_tokens - 1] = malloc(strlen(parameterType) + 1); // Allocate memory for the token
        functionData.parameterNames[num_tokens - 1] = malloc(strlen(parameterName) + 1); // Allocate memory for the token

        parameter= strtok(NULL, ",");
    }

    /* insert the new variable in the symbol table */
    SymbolTableEntryType entry;
    entry.name = trim(strdup(identifier));
    entry.type = FUNCTION;
    entry.lineno = yylineno;

    entry.is_const = true;
    entry.is_used = false;
    entry.initialized = true;

    entry.datatype = strdup(type);
    entry.functionData = functionData;

    insertSymbol(entry);
    return true;
}

void setUsed(char* identifier)
{
    int symbolIdx =  getSymbolIdx(identifier);
    if(symbolIdx == -1) return;
    symbolTable.array[symbolIdx].is_used = true;
}
void push(char * name) {
  // printf("begin, push\n");
  chk_overflow(1);
  // push the value of yylval onto the stack
  // printf("PUSH %s\n", name);
  // push to stack
  stak[stakNext++] = strdup(name);

  // printf("PUHS\n");
}

void sto() {
  // printf("STOOO\n");
  chk_undeflow(2);
  printf("STO %s, %s\n", stak[stakNext-1], stak[stakNext-2]);
}

void expr(char *op) {
  // printf("begin expr\n");
  chk_undeflow(2);

  char *reg = tempReg();

  // +
    if (strcmp(op, "+") == 0) {
        printf("ADD %s, %s, %s\n", stak[stakNext-2], stak[stakNext-1], reg);
        stakNext--;
        strcpy(stak[stakNext-1], reg);
    }
    // -
    else if (strcmp(op, "-") == 0) {
        printf("SUB %s, %s, %s\n", stak[stakNext-2], stak[stakNext-1], reg);
        stakNext--;
        strcpy(stak[stakNext-1], reg);
    }
    else if (strcmp(op, "*") == 0) {
    printf("MUL %s, %s, %s\n", stak[stakNext-2], stak[stakNext-1], reg);
    stakNext--;
    strcpy(stak[stakNext-1], reg);
    }
  // /
    else if (strcmp(op, "/") == 0) {
        printf("DIV %s, %s, %s\n", stak[stakNext-2], stak[stakNext-1], reg);
        stakNext--;
        strcpy(stak[stakNext-1], reg);
    }
  // error
  else {
    printf("ERROR: unknown operator %s\n", op);
    /* exit(1); */
  }
}

struct nodeType* getNode(char* identifier) {
    struct nodeType* p = malloc(sizeof(struct nodeType));

    int symbolIdx = getSymbolIdx(identifier);
    if(symbolIdx == -1){
        /* doesn't exist, handle later */
    }
    else {
        p->type = typeToEnum(symbolTable.array[symbolIdx].datatype);
        p->value = strdup(identifier);
        p->is_const = symbolTable.array[symbolIdx].is_const;
        p->initialized = symbolTable.array[symbolIdx].initialized;
    }

    return p;
}

struct nodeType* intNode(int value) {
    struct nodeType* p = malloc(sizeof(struct nodeType));
    
	p->type = Int;
    p->is_const = true;
    p->initialized = true;

    int num_digits = snprintf(NULL, 0, "%d", value);
    // Allocate memory for the string based on the number of digits
    p->value = (char *) malloc(num_digits + 1);
    // Call sprintf to convert the number to a string
    sprintf(p->value, "%d", value);
    return p;
}

struct nodeType* floatNode(float value) {
    struct nodeType* p = malloc(sizeof(struct nodeType));

    p->type = Float;
    p->is_const = true;
    p->initialized = true;

    int num_digits = snprintf(NULL, 0, "%f", value);
    // Allocate memory for the string based on the number of digits
    p->value = (char *) malloc(num_digits + 1);
    // Call sprintf to convert the number to a string
    sprintf(p->value, "%f", value);

    return p;
}

struct nodeType* boolNode(char* value) {
    struct nodeType* p = malloc(sizeof(struct nodeType));
    
    p->type = Bool;
    p->is_const = true;
    p->initialized = true;

    p-> value = strcmp(value, "true") == 0? "1": "0";
    return p;
}
 struct nodeType* charNode(char value) {
    struct nodeType* p = malloc(sizeof(struct nodeType));
    p->type = Char;
    p->is_const = true;
    p->initialized = true;

    p->value = malloc(sizeof(char*)*1);
    sprintf(p->value, "%c", value);
    return p;
 }
struct nodeType* stringNode(char* value) {
    struct nodeType* p = malloc(sizeof(struct nodeType));    
    p->type = String;
    p->is_const = true;
    p->initialized = true;

    p->value = strdup(value);
    return p;
}

struct nodeType* dupNode(struct nodeType* node){
    struct nodeType* p = malloc(sizeof(struct nodeType));

    p->is_const = node->is_const;
    p->value = node->value;
    p->initialized = node->initialized;

    p->type = node->type;
    return p;
}


struct nodeType* combineNode(struct nodeType* node1, struct nodeType* node2){
    struct nodeType* p = malloc(sizeof(struct nodeType));
    if(node1 == NULL) printf("node1 is null\n");
    else              printf("node1 value is: %s and type is: %d\n", node1->value, node1->type);
    if(node2 == NULL) printf("node2 is null\n");
    else              printf("node2 value is: %s and type is: %d\n", node2->value, node2->type);
    
    // check if both nodes have the same type
    // if not, output an error message
    if(node1->type != node2->type) {
        errors = realloc(errors, sizeof(char*) * (errorCount+1));
        int errorMsgLen = strlen("Line %d: Can not combine different types") +
                            snprintf(NULL, 0, "%d", yylineno) - 1;
        errors[errorCount] = malloc(sizeof(char) * errorMsgLen);
        sprintf(errors[errorCount], "Line %d: Can not combine different types", yylineno);
        errorCount++;
        printf("first condition\n");
        return NULL;
    }

    // check if both nodes have values ( both are initialized )
    // if not, output an warning using Passant's initializationError(char* identifier) function
    // check which of them is not initialized and output the warning
    if (!node1->initialized && !node2->initialized) {
        initializationError("");
        printf("second condition\n");

        return NULL;
    }
    else if (!node1->initialized) {
        initializationError("");
        printf("third condition\n");
        return NULL;
    }
    else if (!node2->initialized) {
        initializationError("");
        printf("fourth condition\n");
        return NULL;
    }

    p->is_const = node1->is_const && node2->is_const;
    p->initialized = node1->initialized && node2->initialized;
    p->type = node1->type;

    return p;
}

/* Initialize the dynamic symbol table */
void initSymbolTable(size_t initialSize) {
    symbolTable.used = 0;
    symbolTable.size = initialSize;
    symbolTable.array = malloc(initialSize * sizeof(SymbolTableEntryType));
}

bool handleVariableDeclaration(char* type, char* identifier, struct nodeType* value, bool is_const) {
    if(value != NULL)
        printf("inside handle variable with: %s %s = %s\n", type,  identifier, value->value);
    else
        printf("inside handle variable with: %s %s\n", type,  identifier);

    /* check if the enumName exists in symbol table */
    int symbolIdx = getSymbolIdx(trim(strdup(identifier)));
    if(symbolIdx != -1) {
        errors = realloc(errors, sizeof(char*) * (errorCount+1));
        int errorMsgLen = strlen("Line %d: Variable redeclaration, %s initially declared at %d") +
                            snprintf(NULL, 0, "%d", symbolTable.array[symbolIdx].lineno) +
                            strlen(identifier) +
                            snprintf(NULL, 0, "%d", yylineno) - 1;
        errors[errorCount] = malloc(sizeof(char) * errorMsgLen);
        sprintf(errors[errorCount], "Line %d: Variable redeclaration, %s initially declared at %d", 
                                    yylineno, identifier, symbolTable.array[symbolIdx].lineno);
        errorCount++;
        return false;
    }
    if(value == NULL) printf("value is null\n");

    if(is_const && (value != NULL && !(value->is_const))){
        errors = realloc(errors, sizeof(char*) * (errorCount+1));
        int errorMsgLen = strlen("Line %d: Can not assign variable value to const") +
                            snprintf(NULL, 0, "%d", yylineno) - 1;
        errors[errorCount] = malloc(sizeof(char) * errorMsgLen);
        printf("lineno with variable to const is: %d\n", yylineno);
        sprintf(errors[errorCount], "Line %d: Can not assign variable value to const", yylineno);
        errorCount++;
        return false;
    }

    // check if we are assigning an uninitialized variable to another variable
    // if uninitialized, print an warning
    if(value != NULL && !value->initialized) {
        initializationError("");
        return false;
    }

    // check if we are assigning an incompatible type to a variable
    // if incompatible, print an error
    if(value != NULL && typeToEnum(type) != value->type) {
        errors = realloc(errors, sizeof(char*) * (errorCount+1));
        int errorMsgLen = strlen("Line %d: Can not assign variable value to const") +
                            snprintf(NULL, 0, "%d", yylineno) - 1;
        errors[errorCount] = malloc(sizeof(char) * errorMsgLen);
        sprintf(errors[errorCount], "Line %d: Can not assign variable value to const", yylineno);
        errorCount++;
        return false;
    }


    /* insert the new variable in the symbol table */
    SymbolTableEntryType entry;
    entry.name = trim(strdup(identifier));
    entry.type = is_const? CONSTANT : VARIABLE;
    entry.lineno = yylineno;
    entry.is_const = is_const;
    entry.is_used = false;
    entry.datatype = strdup(type);
    if (value != NULL){
        if(value->value != NULL){
            int initialized = checkInitialization(value->value);
            if (initialized != -1)
                entry.initialized = initialized;
            else
                entry.initialized = (value->value != NULL);
        }
        else 
            entry.initialized = true;
    }
    else 
        entry.initialized = false;
    
    insertSymbol(entry);
    return true;
}

int checkInitialization(char* identifier) {
    int symbolIdx = getSymbolIdx(identifier);
    if(symbolIdx != -1) return symbolTable.array[symbolIdx].initialized;
    return -1;
}

void handleEnumVariableDeclaration(char* enumName, char* identifier, struct nodeType* node) {
    /* enum test t */
    /* check if the enumName exists in symbol table */
    int enumIdx = getSymbolIdx(enumName);
    if(enumIdx == -1) {
        errors = realloc(errors, sizeof(char*) * (errorCount+1));
        int errorMsgLen = strlen("Line %d: enum of type %s is not declared") + strlen(enumName) + snprintf(NULL, 0, "%d", yylineno) - 1; 
        errors[errorCount] = malloc(sizeof(char) * errorMsgLen);
        sprintf(errors[errorCount], "Line %d: enum of type %s is not declared", yylineno, enumName);
        errorCount++;
        return;
    }
    /* check if its type is Enum */

    /* insert the new variable in the symbol table */
    SymbolTableEntryType entry;
    entry.name = trim(strdup(identifier));
    entry.type = VARIABLE;
    entry.lineno = yylineno;
    entry.initialized = true;
    entry.is_const = false;
    /* Set the variable datatype to be 'enum <variable name>' */
    char type[] = "enum %s";
    int datatype_length = strlen(type) + strlen(enumName) - 1;
    entry.datatype = malloc(datatype_length * sizeof(char));
    sprintf(entry.datatype, type, enumName);
    if(node != NULL && (!node->is_const  || !node->type != Int)) {
        errors = realloc(errors, sizeof(char*) * (errorCount+1));
        int errorMsgLen = strlen("Line %d: Enum variables can be set to only const integers") + snprintf(NULL, 0, "%d", yylineno) - 1; 
        errors[errorCount] = malloc(sizeof(char) * errorMsgLen);
        sprintf(errors[errorCount], "Line %d: Enum variables can be set to only const integers", yylineno);
        errorCount++;
        return;
    }
 
    insertSymbol(entry);
}

void handleEnumDeclaration(char* identifier, char* enumValues){
    if (identifier == NULL || enumValues == NULL) {
        printf("null values\n");
        return;
    }
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
                errors = realloc(errors, sizeof(char*) * (errorCount+1));
                int errorMsgLen = strlen("Line %d: Enum should hold integer values only") + snprintf(NULL, 0, "%d", yylineno) - 1; 
                errors[errorCount] = malloc(sizeof(char) * errorMsgLen);
                sprintf(errors[errorCount], "Line %d: Enum should hold integer values only", yylineno);
                errorCount++;
                return;
            } else {
                varValue = num;
            }
        }
        int symbolIdx = getSymbolIdx(varName);
        if(symbolIdx != -1) {
            errors = realloc(errors, sizeof(char*) * (errorCount+1));
            int errorMsgLen = strlen("Line %d: Variable redeclaration, initially declared at %d") +
                            snprintf(NULL, 0, "%d", symbolTable.array[symbolIdx].lineno) +
                            snprintf(NULL, 0, "%d", yylineno) - 1;
            errors[errorCount] = malloc(sizeof(char) * errorMsgLen);
            sprintf(errors[errorCount], "Line %d: Variable redeclaration, initially declared at %d", yylineno,  symbolTable.array[symbolIdx].lineno);
            errorCount++;
            if(eq != NULL)
                free(varName);
            continue;
        }
        SymbolTableEntryType entry;
        entry.name = trim(strdup(varName));
        entry.type = CONSTANT;
        entry.lineno = yylineno;
        entry.initialized = true;
        entry.is_const = true;
        /* Set the variable datatype to be 'enum <variable name>' */
        char type[] = "enum %s";
        int datatype_length = strlen(type) + strlen(identifier) - 1;
        entry.datatype = malloc(datatype_length * sizeof(char));
        sprintf(entry.datatype, type, identifier);

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

char* getType(char* variable) {
    printf("inside getType: %s\n", variable);
    char* endptr;
    strtol(variable, &endptr, 10);
    // Check for errors while parsing the string as integer
    if (errno == ERANGE || endptr == variable || *endptr != '\0') {
        /* check if it's a vairbla */
        int symbolIdx =  getSymbolIdx(variable);
        if(symbolIdx != -1)
            return strstr(symbolTable.array[symbolIdx].datatype, "enum") != NULL ? "int" : symbolTable.array[symbolIdx].datatype;
        else
            return variable[0] == '"'? "string" : "ERROR";
    }
    return strchr(variable, '.') == NULL ? "int" : "float";
}


int getSymbolIdx(char* symbolName) {
    for (int i=0; i < symbolTable.used; i++){
        if (strcmp(symbolName, symbolTable.array[i].name) == 0)
            return i;
    }
    return -1;
}

void insertSymbol(SymbolTableEntryType symbol) {
    /* check if the symbol table is full */
    if(symbolTable.used == symbolTable.size) {
        /* printf("doubling symbol table size\n"); */
        /* double the symbol table array size */
        symbolTable.size *= 2;
        /* reallocate the array with the new size keeping the old data */
        symbolTable.array = realloc(symbolTable.array, symbolTable.size * sizeof(SymbolTableEntryType));
    }
    /* printf("will insert symbol %s\n", symbol.name); */
    symbolTable.array[symbolTable.used++] = symbol;
    /* printf("inserted\n"); */
}

void printErrors(){
    FILE *fp = fopen("output/errors.txt", "w");
    if(fp == NULL) {
        printf("Error opening errors.txt file!\n");
        exit(1);
    }

    for (int i = 0; i < errorCount; i++)
        fprintf(fp, "%s\n", errors[i]);
}

void printWarnings(){
    FILE *fp = fopen("output/warnings.txt", "w");
    if(fp == NULL) {
        printf("Error opening warnings.text file!\n");
        exit(1);
    }

    for (int i = 0; i < warningCount; i++)
        fprintf(fp, "%s\n", warnings[i]);
}

void printSymbolTable() {
     // write symbol table to file
    FILE *fp = fopen("output/symbol_table.txt", "w");
    if(fp == NULL) {
        printf("Error opening symbol_table.txt file!\n");
        exit(1);
    }

    fprintf(fp, "\nName\tData Type\tType\tLine\tConst\tInitialized\tUsed\n");

    for(int i=0; i < symbolTable.used; i++) {
        SymbolTableEntryType entry = symbolTable.array[i];

        fprintf(fp, "%s\t%s\t%s\t%d\t%s\t%s\t%s\n", 
            entry.name,
            entry.datatype,
            types[entry.type], 
            entry.lineno,
            entry.is_const? "YES" : "NO", 
            entry.initialized? "YES" : "NO",
            entry.is_used? "YES" : "NO"
        ); 
    }
}