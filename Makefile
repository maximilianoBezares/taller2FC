# Define el nombre del programa ejecutable
PROGRAM = sql_parser

# Herramientas (especifica la ruta completa si no están en PATH)
# Ejemplo Windows: BISON = C:/path/to/win_bison.exe
BISON = "C:/Users/Gabriel Briones/.winflexbison/win_bison.exe"
FLEX = "C:/Users/Gabriel Briones/.winflexbison/win_flex.exe"

# Archivos fuente de Bison, Flex y C
BISON_FILE = parser.y
FLEX_FILE = lexer.l
C_MAIN = main.c

# Archivos intermedios generados por Flex y Bison
BISON_OUTPUT_C = $(patsubst %.y, %.tab.c, $(BISON_FILE))
BISON_OUTPUT_H = $(patsubst %.y, %.tab.h, $(BISON_FILE))
FLEX_OUTPUT = $(patsubst %.l, lex.yy.c, $(FLEX_FILE))

# Compilador y banderas
CC = gcc
CFLAGS = -Wall -g 
# -lfl es crucial para enlazar con las funciones generadas por Flex
LDFLAGS = -lfl

# Regla principal: compila todo
all: $(PROGRAM)

# 1. Enlaza los archivos C/generados para crear el ejecutable
$(PROGRAM): $(BISON_OUTPUT_C) $(FLEX_OUTPUT) $(C_MAIN)
	$(CC) $(CFLAGS) $(BISON_OUTPUT_C) $(FLEX_OUTPUT) $(C_MAIN) -o $(PROGRAM) $(LDFLAGS)

# 2. Genera los archivos .c y .h de Bison
# La opción -d crea el archivo de cabecera (.tab.h) que usa Flex
$(BISON_OUTPUT_C) $(BISON_OUTPUT_H): $(BISON_FILE)
	$(BISON) -d $(BISON_FILE)

# 3. Genera el archivo .c de Flex (depende de la cabecera de Bison para los tokens)
$(FLEX_OUTPUT): $(FLEX_FILE) $(BISON_OUTPUT_H)
	$(FLEX) $(FLEX_FILE)

# Limpieza: elimina todos los archivos generados
clean:
	rm -f $(PROGRAM) $(BISON_OUTPUT_C) $(BISON_OUTPUT_H) $(FLEX_OUTPUT) *.o

.PHONY: all clean