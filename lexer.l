%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "parser.tab.h"

%}

%option noyywrap
%option yylineno
%option case-insensitive

LETTER              [a-zA-Z_]
DIGIT               [0-9]
IDENTIFIER          {LETTER}({LETTER}|{DIGIT})*
INTEGER             {DIGIT}+
DECIMAL             {DIGIT}+\.{DIGIT}+
WHITESPACE          [ \t\r]+

%%

{WHITESPACE}        ;

"--".*              ;
"SELECT"            { return SELECT; }
"INSERT"            { return INSERT; }
"WHERE"             { return WHERE; }
"UPDATE"            { return UPDATE; }
"DELETE"            { return DELETE; }
"FROM"              { return FROM; }
"AND"               { return AND; }
"OR"                { return OR; }
"NOT"               { return NOT; }

{DECIMAL}           {
    yylval.sval = strdup(yytext); return DECIMAL;
}

{INTEGER}           {
    yylval.ival = atoi(yytext); return INTEGER;
}

\"([^"\n])*\"       {
    yylval.sval = strdup(yytext);
    return STRING;
}

'([^'\n])*'         {
    yylval.sval = strdup(yytext);
    return STRING;
}

{IDENTIFIER}        {
    yylval.sval = strdup(yytext);
    return IDENTIFIER;
}

"<="                { return LE; }
">="                { return GE; }
"="                 { return EQ; }
">"                 { return GT; }
"<"                 { return LT; }
";"                 { return SEMICOLON; }
","                 { return COMMA; }
"("                 { return LPAREN; }
")"                 { return RPAREN; }
.                   {
    printf("Caracter inesperado: '%s' en línea %d\n", yytext, yylineno);
    return ERROR;
}

%%