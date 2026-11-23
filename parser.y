%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int token_line;
extern char *yytext;
void yyerror(const char *s);
%}

/* parse.error custom (Bison 3.6+): as mensagens de erro sintatico sao
   montadas em yyreport_syntax_error, em portugues, listando os tokens que
   eram esperados. parse.lac full (lookahead correction) deixa essa lista
   exata, sem ser afetada pelas reducoes padrao das tabelas LALR. */
%require "3.6"
%define parse.error custom
%define parse.lac full

/* Os apelidos entre aspas sao os nomes exibidos nas mensagens de erro. */
%token ID        "identificador"
%token NUM_INT   "numero inteiro"
%token NUM_FLOAT "numero real"
%token STRING    "texto"
%token KW_IF     "'lacrou'"
%token KW_ELSE   "'gag'"
%token KW_FOR    "'babado'"
%token KW_IN     "'na'"
%token KW_RANGE  "'turne'"
%token KW_PRINT  "'flash'"
%token OP_ATRIB  "'='"
%token OP_SOMA   "'+'"
%token OP_SUB    "'-'"
%token OP_MULT   "'*'"
%token OP_DIV    "'/'"
%token OP_IGUAL       "'=='"
%token OP_DIF         "'!='"
%token OP_MAIOR       "'>'"
%token OP_MENOR       "'<'"
%token OP_MAIOR_IGUAL "'>='"
%token OP_MENOR_IGUAL "'<='"
%token DELIM_ABRE_PAR    "'('"
%token DELIM_FECHA_PAR   "')'"
%token DELIM_DOIS_PONTOS "':'"
%token DELIM_VIRGULA     "','"
%token NEWLINE "fim da linha"
%token INDENT  "aumento de recuo"
%token DEDENT  "fim de bloco"

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

/* Imprime "Erro sintatico na linha N (proximo a ...)", sem quebra de linha.
   Tokens sem lexema visivel sao descritos pelo nome; os demais mostram
   o texto lido. yychar e o token de lookahead em que o erro ocorreu. */
static void imprime_inicio_erro(void) {
    const char *descr = NULL;
    switch (yychar) {
        case NEWLINE: descr = "fim da linha"; break;
        case INDENT:  descr = "aumento de recuo"; break;
        case DEDENT:  descr = "fim de bloco (reducao de recuo)"; break;
        case YYEOF:   descr = "fim do arquivo"; break;
        case YYEMPTY: break;
        default:
            fprintf(stderr, "Erro sintatico na linha %d (proximo a '%s')",
                    token_line, yytext);
            return;
    }
    if (descr)
        fprintf(stderr, "Erro sintatico na linha %d (proximo ao %s)",
                token_line, descr);
    else
        fprintf(stderr, "Erro sintatico na linha %d", token_line);
}

/* Imprime o nome de um token usando o apelido declarado em %token, sem as
   aspas duplas que o Bison guarda na tabela de nomes. */
static void imprime_simbolo(yysymbol_kind_t simbolo) {
    if (simbolo == YYSYMBOL_YYEOF) {
        fputs("fim do arquivo", stderr);
        return;
    }
    const char *nome = yysymbol_name(simbolo);
    size_t tam = strlen(nome);
    if (tam >= 2 && nome[0] == '"' && nome[tam - 1] == '"')
        fprintf(stderr, "%.*s", (int) (tam - 2), nome + 1);
    else
        fputs(nome, stderr);
}

/* Chamada pelo Bison em cada erro sintatico (parse.error custom).
   Ex.: Erro sintatico na linha 3 (proximo a ')'): esperado identificador,
        numero inteiro, numero real, texto, '-' ou '('
   Se houver mais opcoes do que MAX_ESPERADOS, a lista e omitida para nao
   poluir a mensagem. */
int yyreport_syntax_error(const yypcontext_t *ctx) {
    enum { MAX_ESPERADOS = 6 };
    yysymbol_kind_t esperados[MAX_ESPERADOS];
    int n = yypcontext_expected_tokens(ctx, esperados, MAX_ESPERADOS);
    if (n < 0)
        return n; /* falta de memoria: o yyparse trata o erro */

    imprime_inicio_erro();
    if (n == 0) {
        fputs(": simbolo inesperado", stderr);
    } else {
        fputs(": esperado ", stderr);
        for (int i = 0; i < n; i++) {
            if (i > 0)
                fputs(i == n - 1 ? " ou " : ", ", stderr);
            imprime_simbolo(esperados[i]);
        }
    }
    fputc('\n', stderr);
    return 0;
}

/* Com parse.error custom, o Bison so chama yyerror para erros internos
   (ex.: "memory exhausted"). */
void yyerror(const char *s) {
    imprime_inicio_erro();
    fprintf(stderr, ": %s\n", s);
}
