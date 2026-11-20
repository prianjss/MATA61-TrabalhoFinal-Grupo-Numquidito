CC = gcc
FLEX = flex
BISON = bison
CFLAGS = -Wall -g

TARGET = divalang
EXEMPLO = testes/validos/exemplo_enxuto.diva

.PHONY: all test exemplo clean

all: $(TARGET)

$(TARGET): parser.tab.c lex.yy.c main.c
	$(CC) $(CFLAGS) -o $(TARGET) parser.tab.c lex.yy.c main.c

parser.tab.c parser.tab.h: parser.y
	$(BISON) -d parser.y

lex.yy.c: lexer.l parser.tab.h
	$(FLEX) lexer.l

# Suite completa: casos validos e invalidos, cada um em LF e em CRLF
test: $(TARGET)
	sh testes/rodar_testes.sh ./$(TARGET)

# Roda apenas o programa de exemplo, mostrando a saida do analisador
exemplo: $(TARGET)
	./$(TARGET) $(EXEMPLO)

clean:
	rm -f $(TARGET) parser.tab.c parser.tab.h lex.yy.c
