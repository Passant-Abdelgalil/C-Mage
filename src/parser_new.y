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

    typedef enum {Int, Float, String, Bool, Char} valueDatatype;
    char* datatypes [5] = {"int", "float", "string", "bool", "char"};
    int typeToEnum(char* value) {
        for (int i = 0; i < 5; i++) {
            if (strcmp(datatypes[i], value) == 0) {
                return i;
            }
        }
        return -1; // Value not found
    }
    union NodeValue {
        int i;
        float f;
        char* str;
        bool b;
    };

    typedef struct  {
        char *name;                         /* symbol name */
        char *datatype;                     /* symbol data type [int, float, enum <name>, ...etc] */
        SymbolType type;               /* symbol type [function, variable, ...etc] */
        int lineno;                         /* line number where this symbol's declared */
        bool initialized, is_const, is_used;   /* flags to indicate the state of the symbol */
        // int scope;
        // int scopes[10];
    } SymbolTableEntryType;

    typedef struct {
        SymbolTableEntryType *array;
        size_t used;
        size_t size;
    } SymbolTable;

    int errorCount = 0;
    char **errors;

    SymbolTable symbolTable;
    struct nodeType {
        valueDatatype type;
        char *value;
        bool is_const;
    };
    void initSymbolTable(size_t initialSize);
    void printSymbolTable();

    // Variables Functions
    bool handleVariableDeclaration(char* type, char* indentifier, struct nodeType *value, bool is_const);

    // Enums Functions
    void handleEnumDeclaration(char* identifier, char* enumValues);
    void handleEnumVariableDeclaration(char* enumName, char* identifier, struct nodeType *value);


    char* checkTypes(char* op1, char* op2, char* op);
    char* getType(char* variable);
    void insertSymbol(SymbolTableEntryType symbol);
    int  getSymbolIdx(char* symbolName);
    void setUsed(char* identifier);
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


    char *stak[100];
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
      if (stakNext + x >= 100) {
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


%token<STRING> IDENTIFIER STRING_DECLARATION ENUM_DECLARATION CONST_DECLARATION BOOL_DECLARATION CHAR_DECLARATION FLOAT_DECLARATION INT_DECLARATION PRINT
%token<INTEGER> INTEGER_CONSTANT
%token<FLOAT> FLOAT_CONSTANT
%token<CHAR>  CHAR_CONSTANT
%token<BOOL> TRUE_KEYWORD FALSE_KEYWORD
%token<STRING> STRING_CONSTANT

%token AND OR NOT EQ NE LT GT LE GE
%token IF ELSE WHILE FOR DO SWITCH CASE DEFAULT BREAK CONTINUE
%token RETURN VOID 
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
|                                       RETURN                       { /*rtn(); */}                                // {printf("empty return\n");}
|                                       RETURN expression             { /* rtn();*/ }                          // {printf("return\n");}
|                                       BREAK                        {/*brk();*/}                 // {printf("break\n");}
|                                       CONTINUE                       {/*cnt();*/}                  // {printf("continue\n");}
|                                       
;

variable_declaration:                   variable_type IDENTIFIER                                        { handleVariableDeclaration($1, $2, NULL, false); }
|                                       variable_type IDENTIFIER '=' {push($2);} expression             { if(handleVariableDeclaration($1, $2, $5, false)) sto(); }
|                                       enum_definition
|                                       CONST_DECLARATION variable_type IDENTIFIER {push($3);} '=' expression { if(handleVariableDeclaration($2, $3, $6, true)) sto();}
|                                       ENUM_DECLARATION IDENTIFIER IDENTIFIER                { handleEnumVariableDeclaration($2, $3, NULL); }
|                                       ENUM_DECLARATION IDENTIFIER IDENTIFIER {push($3);}'=' expression  { sto(); handleEnumVariableDeclaration($2, $3, $6);}
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

const_expression:                       INTEGER_CONSTANT                    { $$ = intNode($1); char str[30];sprintf(str, "%d", $1); push(str);}
|                                       FLOAT_CONSTANT                      { $$ = floatNode($1); char str[30];sprintf(str, "%f", $1); push(str);}
|                                       CHAR_CONSTANT                       { $$ = charNode($1); char str[3];sprintf(str, "%c", $1); push(str);}
|                                       STRING_CONSTANT                     { $$ = stringNode($1); push($1); }
|                                       TRUE_KEYWORD                        { $$ = boolNode($1); push("true");}
|                                       FALSE_KEYWORD                       { $$ = boolNode($1); push("false");}
;


expression:                             IDENTIFIER                              { $$ = getNode($1); push($1);}
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

function_declaration:                   variable_type   IDENTIFIER {/*decl_func_s($2);*/}  '(' parameter_list ')' braced_statements {/*decl_func_e($2);*/}
|                                       VOID            IDENTIFIER {/*decl_func_s($2);*/} '(' parameter_list ')' braced_statements {/*decl_func_e($2);*/}
;

function_call:                          IDENTIFIER '(' arguemnt_list ')'                { $$ = $1; /*call_func($1);*/}
|                                       PRINT { /*call_rf_print();*/} '(' arguemnt_list ')'        { $$ = $1; }
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

control_statement:                      if_statement            {/*pop the labels */ /*pop(2);*/}
|                                       while_loop              {/*pop the labels */ /*pop(2);*/}
|                                       do_while_loop
|                                       switch_statement
|                                       for_loop
|                                       comments
|                                       function_declaration


/*missing_semicolon:                      expression error
;
*/

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

    if (yywrap())
    {
        printf("\nParsing successful ya regala!\n");
    }
    fclose(yyin); 
    return 0;
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
    }

    return p;
}

struct nodeType* intNode(int value) {
    struct nodeType* p = malloc(sizeof(struct nodeType));
    
	p->type = Int;
    p->is_const = true;

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

    int num_digits = snprintf(NULL, 0, "%f", value);
    // Allocate memory for the string based on the number of digits
    p->value = (char *) malloc(num_digits + 1);
    // Call sprintf to convert the number to a string
    sprintf(p->value, "%f", value);

    return p;
}

struct nodeType* boolNode(char* value) {
    struct nodeType* p = malloc(sizeof(struct nodeType));;
    
    p->type = Bool;
    p->is_const = true;

    p-> value = strcmp(value, "true") == 0? "1": "0";
    return p;
}
 struct nodeType* charNode(char value) {
    struct nodeType* p = malloc(sizeof(struct nodeType));;
    p->type = Char;
    p->is_const = true;
    p->value = malloc(sizeof(char*)*1);
    sprintf(p->value, "%c", value);
    return p;
 }
struct nodeType* stringNode(char* value) {
    struct nodeType* p = malloc(sizeof(struct nodeType));;
    
    p->type = String;
    p->is_const = true;
    p->value = strdup(value);
    return p;
}


struct nodeType* dupNode(struct nodeType* node){
    struct nodeType* p = malloc(sizeof(struct nodeType));

    p->is_const = node->is_const;
    p->value = node->value;
    p->type = node->type;

    return p;
}


struct nodeType* combineNode(struct nodeType* node1, struct nodeType* node2){
    struct nodeType* p = malloc(sizeof(struct nodeType));

    p->is_const = node1->is_const && node2->is_const;
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
        int errorMsgLen = strlen("Line %d: Variable redeclaration, initially declared at %d") +
                            snprintf(NULL, 0, "%d", symbolTable.array[symbolIdx].lineno) +
                            snprintf(NULL, 0, "%d", yylineno) - 1;
        errors[errorCount] = malloc(sizeof(char) * errorMsgLen);
        sprintf(errors[errorCount], "Line %d: Variable redeclaration, initially declared at %d", yylineno, symbolTable.array[symbolIdx].lineno);
        errorCount++;
        return false;
    }

    if(is_const && (value != NULL && !(value->is_const))){
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
    entry.initialized = (value != NULL);
    entry.is_const = is_const;
    entry.datatype = strdup(type);

    insertSymbol(entry);
    return true;
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

char* checkTypes(char* op1, char* op2, char* op) {
    printf("inside checkTypes: %s %s %s\n", op1, op2, op);

    char* oper1, oper2;
    char* type1 = getType(op1);
    char* type2 = getType(op2);
    bool stringOperation =  strcmp(type1, "string") == 0 ||
                            strcmp(type2, "string") == 0 || 
                            strcmp(type1, "char")   == 0 || 
                            strcmp(type2, "char")   == 0;

    /* + , - , * , / , % */
    if(strcmp(op, "+") == 0 || strcmp(op, "-") == 0 ||
        strcmp(op, "*") == 0 || strcmp(op, "/") == 0 || strcmp(op, "%") == 0) {
        if(stringOperation) {
            errors = realloc(errors, sizeof(char*) * (errorCount+1));
            int errorMsgLen = strlen("Line %d: Mathematical operations can only be applied on numeric values") + snprintf(NULL, 0, "%d", yylineno) - 1; 
            errors[errorCount] = malloc(sizeof(char) * errorMsgLen);
            sprintf(errors[errorCount], "Line %d: Mathematical operations can only be applied on numeric values", yylineno);
            errorCount++;
            return "ERROR";
        }
        if(strcmp(type1, "float") == 0 || strcmp(type2, "float") == 0)
            return "float";
        else
            return "int";
    }

    /* &&, ||, !,  */
    if(strcmp(op, "&&") == 0 || strcmp(op, "||") == 0 || strcmp(op, "!") == 0){
        if(stringOperation){
            errors = realloc(errors, sizeof(char*) * (errorCount+1));
            int errorMsgLen = strlen("Line %d: Logical operations can only be applied on numeric values") + snprintf(NULL, 0, "%d", yylineno) - 1; 
            errors[errorCount] = malloc(sizeof(char) * errorMsgLen);
            sprintf(errors[errorCount], "Line %d: Logical operations can only be applied on numeric values", yylineno);
            errorCount++;
            return "ERROR";
        }
        return "bool";

    }
    /* < , >, == , <= , >= , !=  */
    if(strcmp(type1, type2) != 0){
        errors = realloc(errors, sizeof(char*) * (errorCount+1));
        int errorMsgLen = strlen("Line %d: Type mismatch, operation %s can not be from %s to %s") +
                        strlen(type1) + strlen(type2) + snprintf(NULL, 0, "%d", yylineno) - 1;
        errors[errorCount] = malloc(sizeof(char) * errorMsgLen);
        sprintf(errors[errorCount], "Line %d: Type mismatch, operation %s can not be from %s to %s",
                yylineno, op, type1, type2);
        errorCount++;
        return "ERROR";
    }

    return "bool";
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

void printSymbolTable() {
    printf("\nName\tData Type\tType\tLine\tConst\tInitialized\n");
    
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