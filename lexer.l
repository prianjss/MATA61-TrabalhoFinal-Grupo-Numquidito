%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"

#define MAX_INDENT 100

int indent_stack[MAX_INDENT];
int indent_top = 0;
int pending_dedents = 0;
int at_line_start = 1;
int eof_handled = 0;

void init_lexer() {
    indent_stack[0] = 0;
    indent_top = 0;
    pending_dedents = 0;
    at_line_start = 1;
    eof_handled = 0;
}

void lexical_error(const char *msg, const char *lexeme) {
    if (lexeme)
        fprintf(stderr, "Erro lexico na linha %d: %s ('%s')\n", yylineno, msg, lexeme);
    else
        fprintf(stderr, "Erro lexico na linha %d: %s\n", yylineno, msg);
    exit(1);
}
%}

%option noyywrap
%option yylineno

%x NORMAL

DIGITO      [0-9]
LETRA       [a-zA-Z_]
ID          {LETRA}({LETRA}|{DIGITO})*
NUM_INT     {DIGITO}+
NUM_FLOAT   {DIGITO}+"."{DIGITO}+

%%

%{
    if (pending_dedents > 0) {
        pending_dedents--;
        return DEDENT;
    }
%}

<INITIAL>[ ]*#[^\n]*\n { /* Comentario */ }
<INITIAL>[ ]*#[^\n]* { /* Comentario no EOF */ }
<INITIAL>[ ]*\n { /* Linha em branco */ }

<INITIAL>[ \t]+ {
    for (int i = 0; yytext[i] != '\0'; i++) {
        if (yytext[i] == '\t') {
            lexical_error("tabulacao nao permitida na indentacao", NULL);
        }
    }
    int current_indent = yyleng;
    at_line_start = 0;
    BEGIN(NORMAL);

    int top_indent = indent_stack[indent_top];
    if (current_indent > top_indent) {
        if (indent_top + 1 >= MAX_INDENT) {
            lexical_error("limite maximo de indentacao excedido", NULL);
        }
        indent_stack[++indent_top] = current_indent;
        return INDENT;
    } else if (current_indent < top_indent) {
        while (indent_top > 0 && indent_stack[indent_top] > current_indent) {
            indent_top--;
            pending_dedents++;
        }
        if (indent_stack[indent_top] != current_indent) {
            lexical_error("recuo nao corresponde a nenhum nivel anterior", NULL);
        }
        if (pending_dedents > 0) {
            pending_dedents--;
            return DEDENT;
        }
    }
}

<INITIAL><<EOF>> {
    if (indent_top > 0) {
        indent_top--;
        return DEDENT;
    }
    return 0;
}

<INITIAL>. {
    at_line_start = 0;
    BEGIN(NORMAL);
    if (indent_stack[indent_top] > 0) {
        while (indent_top > 0 && indent_stack[indent_top] > 0) {
            indent_top--;
            pending_dedents++;
        }
        yyless(0);
        if (pending_dedents > 0) {
            pending_dedents--;
            return DEDENT;
        }
    }
    yyless(0);
}

<NORMAL>"lacrou"    { return KW_IF; }
<NORMAL>"gag"       { return KW_ELSE; }
<NORMAL>"babado"    { return KW_FOR; }
<NORMAL>"na"        { return KW_IN; }
<NORMAL>"turne"     { return KW_RANGE; }
<NORMAL>"flash"     { return KW_PRINT; }

<NORMAL>{DIGITO}+"."/[^0-9] {
    lexical_error("numero decimal malformado (faltam digitos apos o ponto)", yytext);
}
<NORMAL>"."{DIGITO}+ {
    lexical_error("numero decimal malformado (faltam digitos antes do ponto)", yytext);
}

<NORMAL>{NUM_FLOAT} { return NUM_FLOAT; }
<NORMAL>{NUM_INT}   { return NUM_INT; }

<NORMAL>\"[^\"\n]*\" { return STRING; }
<NORMAL>\'[^\'\n]*\' { return STRING; }
<NORMAL>\"[^\"\n]*   { lexical_error("string sem aspas de fechamento", yytext); }
<NORMAL>\'[^\'\n]*   { lexical_error("string sem aspas de fechamento", yytext); }

<NORMAL>"=="        { return OP_IGUAL; }
<NORMAL>"!="        { return OP_DIF; }
<NORMAL>">="        { return OP_MAIOR_IGUAL; }
<NORMAL>"<="        { return OP_MENOR_IGUAL; }

<NORMAL>"="         { return OP_ATRIB; }
<NORMAL>"+"         { return OP_SOMA; }
<NORMAL>"-"         { return OP_SUB; }
<NORMAL>"*"         { return OP_MULT; }
<NORMAL>"/"         { return OP_DIV; }
<NORMAL>">"         { return OP_MAIOR; }
<NORMAL>"<"         { return OP_MENOR; }

<NORMAL>"("         { return DELIM_ABRE_PAR; }
<NORMAL>")"         { return DELIM_FECHA_PAR; }
<NORMAL>":"         { return DELIM_DOIS_PONTOS; }
<NORMAL>","         { return DELIM_VIRGULA; }

<NORMAL>{ID}        { return ID; }

<NORMAL>[ ]+        { /* descarta espacos */ }
<NORMAL>#[^\n]*     { /* descarta comentario */ }

<NORMAL>\n {
    BEGIN(INITIAL);
    at_line_start = 1;
    return NEWLINE;
}

<NORMAL><<EOF>> {
    BEGIN(INITIAL);
    at_line_start = 1;
    return NEWLINE;
}

<NORMAL>\t          { lexical_error("caractere de tabulacao invalido", NULL); }
<NORMAL>.           { lexical_error("caractere invalido", yytext); }

%%
