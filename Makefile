CC = gcc
FLEX = flex
BISON = bison
CFLAGS = -Wall -g

TARGET = divalang
EXEMPLO = testes/exemplo_enxuto.diva
EXEMPLO_CRLF = testes/exemplo_enxuto.crlf.tmp

.PHONY: all test test-lf test-crlf clean

all: $(TARGET)

$(TARGET): parser.tab.c lex.yy.c main.c
	$(CC) $(CFLAGS) -o $(TARGET) parser.tab.c lex.yy.c main.c

parser.tab.c parser.tab.h: parser.y
	$(BISON) -d parser.y

lex.yy.c: lexer.l parser.tab.h
	$(FLEX) lexer.l

test: test-lf test-crlf

# Teste de referencia com finais de linha LF (Linux)
test-lf: $(TARGET)
	./$(TARGET) $(EXEMPLO)

# Regressao: o mesmo programa com finais de linha CRLF (Windows) deve ser aceito
test-crlf: $(TARGET)
	sed 's/$$/\r/' $(EXEMPLO) > $(EXEMPLO_CRLF)
	./$(TARGET) $(EXEMPLO_CRLF); status=$$?; rm -f $(EXEMPLO_CRLF); exit $$status

clean:
	rm -f $(TARGET) parser.tab.c parser.tab.h lex.yy.c $(EXEMPLO_CRLF)
