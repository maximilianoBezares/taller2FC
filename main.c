#include <stdio.h>
#include <string.h>

// Declaraciones externas necesarias para Bison/Flex
extern int yyparse();
extern FILE *yyin;
extern int yylineno; 
extern int yylex_destroy();

int main(int argc, char *argv[]) {
    
    // Modo interactivo (sin argumentos)
    if (argc == 1) {
        printf("Iniciando modo interactivo. Escriba consultas SQL seguidas de punto y coma (;)\n");
        printf("Escriba Ctrl+D (EOF) para salir.\n");
        yyin = stdin; 

        // Bucle principal para el modo interactivo
        while (1) {
            printf(">> "); 
            yylineno = 1; 
            
            // Llama al parser. La salida del AST y los errores semánticos se manejan 
            // directamente en las acciones de Bison (parser.y).
            if (yyparse() != 0) {
                // Si se encuentra EOF (Ctrl+D) durante el parseo, salimos.
                if (feof(yyin)) {
                    printf("\nSaliendo...\n");
                    break; 
                }
            }
        }
        
    } else {
        // Modo de archivo (con argumento)
        FILE *file = fopen(argv[1], "r");
        if (!file) {
            perror("Error al abrir el archivo de entrada");
            return 1;
        }
        yyin = file;
        
        printf("Analizando archivo: %s\n", argv[1]);
        yylineno = 1; 
        yyparse(); 
        
        fclose(file);
    }

    // Limpieza de recursos de Flex
    yylex_destroy();
    
    return 0;
}