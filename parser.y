%{
#include <stdio.h>
#include <stdlib.h>

extern int yylex();
extern int token_line;
extern char *yytext;
void yyerror(const char *s);
%}

%token ID NUM_INT NUM_FLOAT STRING
%token KW_IF KW_ELSE KW_FOR KW_IN KW_RANGE KW_PRINT
%token OP_ATRIB
%token OP_SOMA OP_SUB OP_MULT OP_DIV
%token OP_IGUAL OP_DIF OP_MAIOR OP_MENOR OP_MAIOR_IGUAL OP_MENOR_IGUAL
%token DELIM_ABRE_PAR DELIM_FECHA_PAR DELIM_DOIS_PONTOS DELIM_VIRGULA
%token NEWLINE INDENT DEDENT

/* Relacionais sem associatividade (especificacao 4.2): comparacoes
   encadeadas como 1 < x < 5 sao erro sintatico. */
%nonassoc OP_IGUAL OP_DIF OP_MAIOR OP_MENOR OP_MAIOR_IGUAL OP_MENOR_IGUAL
%left OP_SOMA OP_SUB
%left OP_MULT OP_DIV
%right UMINUS

%start programa

%%

programa
    : /* vazio */
    | comandos
    ;

comandos
    : comando
    | comandos comando
    ;

comando
    : comando_simples NEWLINE
    | comando_composto
    ;

comando_simples
    : atribuicao
    | impressao
    ;

atribuicao
    : ID OP_ATRIB expr
    ;

impressao
    : KW_PRINT DELIM_ABRE_PAR args_opcionais DELIM_FECHA_PAR
    ;

args_opcionais
    : /* vazio */
    | lista_args
    ;

lista_args
    : expr
    | lista_args DELIM_VIRGULA expr
    ;

comando_composto
    : condicional
    | laco_for
    ;

condicional
    : KW_IF expr DELIM_DOIS_PONTOS bloco
    | KW_IF expr DELIM_DOIS_PONTOS bloco KW_ELSE DELIM_DOIS_PONTOS bloco
    ;

laco_for
    : KW_FOR ID KW_IN KW_RANGE DELIM_ABRE_PAR args_turne DELIM_FECHA_PAR DELIM_DOIS_PONTOS bloco
    ;

args_turne
    : expr
    | expr DELIM_VIRGULA expr
    | expr DELIM_VIRGULA expr DELIM_VIRGULA expr
    ;

bloco
    : NEWLINE INDENT comandos DEDENT
    ;

expr
    : expr OP_IGUAL expr
    | expr OP_DIF expr
    | expr OP_MAIOR expr
    | expr OP_MENOR expr
    | expr OP_MAIOR_IGUAL expr
    | expr OP_MENOR_IGUAL expr
    | expr OP_SOMA expr
    | expr OP_SUB expr
    | expr OP_MULT expr
    | expr OP_DIV expr
    | OP_SUB expr %prec UMINUS
    | DELIM_ABRE_PAR expr DELIM_FECHA_PAR
    | atomo
    ;

atomo
    : ID
    | NUM_INT
    | NUM_FLOAT
    | STRING
    ;

%%

void yyerror(const char *s) {
    /* Tokens sem lexema visivel sao descritos pelo nome; os demais mostram
       o texto lido. yychar e o token de lookahead em que o erro ocorreu. */
    const char *descr = NULL;
    switch (yychar) {
        case NEWLINE: descr = "fim da linha"; break;
        case INDENT:  descr = "aumento de recuo"; break;
        case DEDENT:  descr = "fim de bloco (reducao de recuo)"; break;
        case YYEOF:   descr = "fim do arquivo"; break;
        case YYEMPTY: break;
        default:
            fprintf(stderr, "Erro sintatico na linha %d (proximo a '%s'): %s\n",
                    token_line, yytext, s);
            return;
    }
    if (descr)
        fprintf(stderr, "Erro sintatico na linha %d (proximo ao %s): %s\n",
                token_line, descr, s);
    else
        fprintf(stderr, "Erro sintatico na linha %d: %s\n", token_line, s);
}
