CC = gcc
FLEX = flex
BISON = bison
CFLAGS = -Wall -g

TARGET = divalang

all: $(TARGET)

$(TARGET): parser.tab.c lex.yy.c main.c
	$(CC) $(CFLAGS) -o $(TARGET) parser.tab.c lex.yy.c main.c

parser.tab.c parser.tab.h: parser.y
	$(BISON) -d parser.y

lex.yy.c: lexer.l parser.tab.h
	$(FLEX) lexer.l

test: $(TARGET)
	./$(TARGET) testes/exemplo_enxuto.diva

clean:
	rm -f $(TARGET) parser.tab.c parser.tab.h lex.yy.c
