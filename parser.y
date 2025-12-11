%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>

#ifdef _WIN32
#define strcasecmp _stricmp
#endif

typedef struct Node {
    char *label;
    struct Node *left;
    struct Node *right;
} Node;

Node* createNode(char *label, Node *left, Node *right) {
    Node *node = (Node*) malloc(sizeof(Node));
    node->label = strdup(label);
    node->left = left;
    node->right = right;
    return node;
}

Node* createLeaf(const char *val) {
    char *s = strdup(val);
    return createNode(s, NULL, NULL);
}

Node* createLeafInt(int v) {
    char buf[64];
    snprintf(buf, sizeof(buf), "%d", v);
    return createLeaf(buf);
}

void printAST(Node *node, int level, char *side) {
    if (node == NULL) return;
    for (int i = 0; i < level; i++) printf("    ");
    if (level == 0) printf("RAIZ -> ");
    else printf("|--(%s)-- ", side);
    printf("[%s]\n", node->label);
    printAST(node->left, level + 1, "IZQ");
    printAST(node->right, level + 1, "DER");
}

void freeAST(Node *n) {
    if (!n) return;
    freeAST(n->left);
    freeAST(n->right);
    if (n->label) free(n->label);
    free(n);
}

int yylex();
void yyerror(const char *s);
extern int yylineno;

typedef struct {
    const char *table;
    const char *cols[16];
    int count;
} TableDef;

TableDef tables[] = {
    { "alumnus", { "nombre", "edad", "promedio" }, 3 },
    { "cursos",  { "codigo", "nombre", "creditos" }, 3 }
};
int tableCount = sizeof(tables)/sizeof(tables[0]);

char *current_table = NULL;

int table_exists(const char *t) {
    if (!t) return 0;
    for (int i = 0; i < tableCount; ++i) {
        if (strcasecmp(t, tables[i].table) == 0) return 1;
    }
    return 0;
}

int validate_column(const char *table, const char *col) {
    if (!table || !col) return 0;
    for (int i = 0; i < tableCount; ++i) {
        if (strcasecmp(table, tables[i].table) == 0) {
            for (int j = 0; j < tables[i].count; ++j) {
                if (strcasecmp(col, tables[i].cols[j]) == 0) return 1;
            }
            return 0;
        }
    }
    return 0;
}

void validate_leaves(Node *n) {
    if (!n) return;
    if (!n->left && !n->right) {
        if (!validate_column(current_table, n->label)) {
            printf("Error Semantico (Linea %d): Columna '%s' no existe en tabla '%s'.\n", 
                   yylineno, n->label, current_table);
        }
    } else {
        validate_leaves(n->left);
        validate_leaves(n->right);
    }
}

void validate_leaves_insert(Node *n) {
    if (!n) return;
    if (!n->left && !n->right) {
        if (!validate_column(current_table, n->label)) {
            printf("Error Semantico (Linea %d): Columna '%s' no existe en tabla '%s'.\n", 
                   yylineno, n->label, current_table);
        }
    } else {
        validate_leaves_insert(n->left);
        validate_leaves_insert(n->right);
    }
}

void validate_pairs(Node *n) {
    if (!n) return;
    if (strcmp(n->label, "=") == 0 && n->left) {
        if (!validate_column(current_table, n->left->label)) {
            printf("Error Semantico (Linea %d): Columna '%s' no existe en tabla '%s'.\n", 
                   yylineno, n->left->label, current_table);
        }
    }
    validate_pairs(n->left);
    validate_pairs(n->right);
}
%}

%union {
    char *sval;
    int ival;
    struct Node *node;
}

%token SELECT INSERT WHERE UPDATE DELETE FROM
%token AND OR NOT
%token EQ LT GT LE GE
%token COMMA SEMICOLON LPAREN RPAREN
%token <sval> IDENTIFIER STRING DECIMAL
%token <ival> INTEGER
%token ERROR

%type <node> query statement select_stmt insert_stmt update_stmt delete_stmt
%type <node> column_list where_clause expr comp value_list pair_list

%left OR
%left AND
%right NOT

%%

query:
    | query statement
    ;

statement:
      select_stmt SEMICOLON {
        printf("AST (SELECT)");
        printAST($1, 0, "RAIZ");
        freeAST($1);
        if (current_table) { free(current_table); current_table = NULL; }
        printf(">> ");
    }
    | insert_stmt SEMICOLON {
        printf("AST (INSERT)");
        printAST($1, 0, "RAIZ");
        freeAST($1);
        if (current_table) { free(current_table); current_table = NULL; }
        printf(">> ");
    }
    | update_stmt SEMICOLON {
        printf("AST (UPDATE)");
        printAST($1, 0, "RAIZ");
        freeAST($1);
        if (current_table) { free(current_table); current_table = NULL; }
        printf(">> ");
    }
    | delete_stmt SEMICOLON {
        printf("AST (DELETE)");
        printAST($1, 0, "RAIZ");
        freeAST($1);
        if (current_table) { free(current_table); current_table = NULL; }
        printf(">> ");
    }
    | error SEMICOLON {
        yyerrok;
        printf(">> ");
    }
    ;

select_stmt:
    SELECT column_list FROM IDENTIFIER where_clause {
        if (current_table) free(current_table);
        current_table = strdup($4);

        if (!table_exists(current_table)) {
            printf("Error Semantico: La tabla '%s' no existe.\n", current_table);
        } else {
            validate_leaves($2);
        }

        Node *fromNode = createNode("FROM", createLeaf($4), $5);
        $$ = createNode("SELECT", $2, fromNode);
    }
    ;

column_list:
      IDENTIFIER { $$ = createLeaf($1); }
    | column_list COMMA IDENTIFIER { $$ = createNode("COLS", $1, createLeaf($3)); }
    ;

insert_stmt:
    INSERT IDENTIFIER LPAREN column_list RPAREN LPAREN value_list RPAREN {
        if (current_table) free(current_table);
        current_table = strdup($2);

        if (!table_exists(current_table)) {
            printf("Error Semantico: La tabla '%s' no existe.\n", current_table);
        } else {
            validate_leaves_insert($4);
        }

        Node *cols = $4;
        Node *vals = $7;
        Node *t = createLeaf($2);
        Node *from = createNode("TARGET", t, NULL);
        Node *cv = createNode("DATA", cols, vals);
        $$ = createNode("INSERT", from, cv);
    }
    ;

value_list:
      STRING { $$ = createLeaf($1); free($1); }
    | INTEGER { $$ = createLeafInt($1); }
    | DECIMAL { $$ = createLeaf($1); free($1); }
    | value_list COMMA STRING { $$ = createNode("VLIST", $1, createLeaf($3)); free($3); }
    | value_list COMMA INTEGER { $$ = createNode("VLIST", $1, createLeafInt($3)); }
    | value_list COMMA DECIMAL { $$ = createNode("VLIST", $1, createLeaf($3)); free($3); }
    ;

update_stmt:
    UPDATE IDENTIFIER pair_list where_clause {
        if (current_table) free(current_table);
        current_table = strdup($2);

        if (!table_exists(current_table)) {
            printf("Error Semantico: La tabla '%s' no existe.\n", current_table);
        } else {
            validate_pairs($3);
        }

        Node *t = createLeaf($2);
        Node *setNode = createNode("ASSIGN", $3, NULL);
        if ($4) setNode->right = $4;
        $$ = createNode("UPDATE", t, setNode);
    }
    ;

pair_list:
      IDENTIFIER EQ STRING {
          $$ = createNode("=", createLeaf($1), createLeaf($3)); free($3);
      }
    | IDENTIFIER EQ INTEGER {
          $$ = createNode("=", createLeaf($1), createLeafInt($3));
      }
    | IDENTIFIER EQ DECIMAL {
          $$ = createNode("=", createLeaf($1), createLeaf($3)); free($3);
      }
    | pair_list COMMA IDENTIFIER EQ STRING {
          $$ = createNode(",", $1, createNode("=", createLeaf($3), createLeaf($5))); free($5);
      }
    | pair_list COMMA IDENTIFIER EQ INTEGER {
          $$ = createNode(",", $1, createNode("=", createLeaf($3), createLeafInt($5)));
      }
    | pair_list COMMA IDENTIFIER EQ DECIMAL {
          $$ = createNode(",", $1, createNode("=", createLeaf($3), createLeaf($5))); free($5);
      }
    ;

delete_stmt:
    DELETE FROM IDENTIFIER where_clause {
        if (current_table) free(current_table);
        current_table = strdup($3);

        if (!table_exists(current_table)) {
            printf("Error Semantico: La tabla '%s' no existe.\n", current_table);
        }
        Node *t = createLeaf($3);
        Node *fromN = createNode("FROM", t, $4);
        $$ = createNode("DELETE", fromN, NULL);
    }
    ;

where_clause:
      /* empty */ { $$ = NULL; }
    | WHERE expr { $$ = createNode("WHERE", $2, NULL); }
    ;

expr:
      comp
    | expr AND expr { $$ = createNode("AND", $1, $3); }
    | expr OR expr  { $$ = createNode("OR", $1, $3); }
    | NOT expr      { $$ = createNode("NOT", $2, NULL); }
    | LPAREN expr RPAREN { $$ = $2; }
    ;

comp:
      IDENTIFIER EQ INTEGER { $$ = createNode("=", createLeaf($1), createLeafInt($3)); }
    | IDENTIFIER EQ STRING  { $$ = createNode("=", createLeaf($1), createLeaf($3)); free($3); }
    | IDENTIFIER EQ DECIMAL { $$ = createNode("=", createLeaf($1), createLeaf($3)); free($3); }
    | IDENTIFIER GE INTEGER { $$ = createNode(">=", createLeaf($1), createLeafInt($3)); }
    | IDENTIFIER LE INTEGER { $$ = createNode("<=", createLeaf($1), createLeafInt($3)); }
    | IDENTIFIER GT INTEGER { $$ = createNode(">", createLeaf($1), createLeafInt($3)); }
    | IDENTIFIER LT INTEGER { $$ = createNode("<", createLeaf($1), createLeafInt($3)); }
    ;

%%

void yyerror(const char *s) {
    printf("Error Sintactico en linea %d: %s\n", yylineno, s);
}