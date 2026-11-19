#include <stdio.h>
#include <stdlib.h>

extern FILE *yyin;
extern int yyparse();
extern void init_lexer();

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Uso: %s <arquivo.diva>\n", argv[0]);
        return 1;
    }

    FILE *arquivo = fopen(argv[1], "r");
    if (!arquivo) {
        perror("Erro ao abrir o arquivo");
        return 1;
    }

    yyin = arquivo;
    init_lexer();

    printf("Iniciando analise lexica e sintatica de '%s'...\n", argv[1]);

    if (yyparse() == 0) {
        printf("Sucesso! O programa DivaLang esta sintaticamente correto.\n");
        fclose(arquivo);
        return 0;
    } else {
        fprintf(stderr, "Falha na compilacao devido a erros sintaticos.\n");
        fclose(arquivo);
        return 1;
    }
}
