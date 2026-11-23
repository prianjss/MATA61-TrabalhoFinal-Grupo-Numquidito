%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"

#define MAX_INDENT 100

int indent_stack[MAX_INDENT];
int indent_top = 0;
int pending_dedents = 0;
int token_line = 1;

#define YY_USER_ACTION                             \
    {                                              \
        int nl = 0;                                \
        for (int i = 0; i < yyleng; i++)           \
            if (yytext[i] == '\n') nl++;           \
        token_line = yylineno - nl;                \
    }

void init_lexer() {
    token_line = 1;
    indent_stack[0] = 0;
    indent_top = 0;
    pending_dedents = 0;
}

static void print_escaped(FILE *out, const char *s) {
    for (const unsigned char *p = (const unsigned char *) s; *p; p++) {
        switch (*p) {
            case '\r': fputs("\\r", out); break;
            case '\n': fputs("\\n", out); break;
            case '\t': fputs("\\t", out); break;
            default:
                if (*p < 0x20 || *p == 0x7F)
                    fprintf(out, "\\x%02X", *p);
                else
                    fputc(*p, out);
        }
    }
}

void lexical_error(const char *msg, const char *lexeme) {
    fprintf(stderr, "Erro lexico na linha %d: %s", yylineno, msg);
    if (lexeme) {
        fputs(" ('", stderr);
        print_escaped(stderr, lexeme);
        fputs("')", stderr);
    }
    fputc('\n', stderr);
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
NL          \r?\n

%%

%{
    if (pending_dedents > 0) {
        pending_dedents--;
        return DEDENT;
    }
%}

<INITIAL>[ ]*#[^\r\n]*{NL} { ; }
<INITIAL>[ ]*#[^\r\n]*     { ; }
<INITIAL>[ ]*{NL}          { ; }

<INITIAL>[ \t]+ {
    for (int i = 0; yytext[i] != '\0'; i++) {
        if (yytext[i] == '\t') {
            lexical_error("tabulacao nao permitida na indentacao", NULL);
        }
    }

    int current_indent = yyleng;
    int prox = input();
    if (prox == EOF || prox == 0) {
        break;
    }
    unput(prox);

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
    BEGIN(NORMAL);
    yyless(0);
    if (indent_stack[indent_top] > 0) {
        while (indent_top > 0 && indent_stack[indent_top] > 0) {
            indent_top--;
            pending_dedents++;
        }
        if (pending_dedents > 0) {
            pending_dedents--;
            return DEDENT;
        }
    }
}

<NORMAL>"lacrou"    { return KW_IF; }
<NORMAL>"gag"       { return KW_ELSE; }
<NORMAL>"babado"    { return KW_FOR; }
<NORMAL>"na"        { return KW_IN; }
<NORMAL>"turne"     { return KW_RANGE; }
<NORMAL>"flash"     { return KW_PRINT; }

<NORMAL>{NUM_FLOAT} { return NUM_FLOAT; }
<NORMAL>{DIGITO}+"." {
    lexical_error("numero decimal malformado (faltam digitos apos o ponto)", yytext);
}
<NORMAL>"."{DIGITO}+ {
    lexical_error("numero decimal malformado (faltam digitos antes do ponto)", yytext);
}
<NORMAL>{NUM_INT}   { return NUM_INT; }

<NORMAL>\"[^\"\r\n]*\" { return STRING; }
<NORMAL>\'[^\'\r\n]*\' { return STRING; }
<NORMAL>\"[^\"\r\n]*   { lexical_error("string sem aspas de fechamento", yytext); }
<NORMAL>\'[^\'\r\n]*   { lexical_error("string sem aspas de fechamento", yytext); }

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

<NORMAL>[ ]+        { ; }
<NORMAL>#[^\r\n]*   { ; }

<NORMAL>{NL} {
    BEGIN(INITIAL);
    return NEWLINE;
}

<NORMAL><<EOF>> {
    BEGIN(INITIAL);
    return NEWLINE;
}

<NORMAL>\t          { lexical_error("caractere de tabulacao invalido", NULL); }
<NORMAL>.           { lexical_error("caractere invalido", yytext); }

%%
