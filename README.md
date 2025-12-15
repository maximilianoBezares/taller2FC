# Analizador Léxico y Sintáctico de SQL (Taller 2)

Este repositorio contiene la implementación de un compilador para un subconjunto del lenguaje SQL, desarrollado en C utilizando las herramientas Flex y Bison. El programa realiza análisis léxico, sintáctico y semántico sobre consultas SQL.

---

## Funcionalidades

El analizador procesa y valida las siguientes sentencias SQL:

- SELECT: Consultas de selección de columnas.
- INSERT: Inserción de nuevos registros.
- UPDATE: Actualización de valores en registros existentes.
- DELETE: Eliminación de registros.
- WHERE: Soporte para condiciones lógicas (AND, OR, NOT) y comparadores (=, <, >, <=, >=).

### Características Técnicas

1. Generación de AST  
   El parser construye un Árbol de Sintaxis Abstracta (AST) que representa la estructura de la consulta y lo imprime en consola.

2. Validación Semántica  
   - Verifica que las tablas consultadas existan.
   - Verifica que las columnas utilizadas pertenezcan a la tabla correspondiente.
   - Tablas definidas en el sistema:
     - alumnus: nombre, edad, promedio
     - cursos: codigo, nombre, creditos

---

## Tecnologías Utilizadas

- Lenguaje: C
- Lexer: Flex
- Parser: Bison
- Compilador: GCC

---

## Estructura del Proyecto

- lexer.l: Define los tokens y reglas léxicas.
- parser.y: Define la gramática, la estructura del AST (struct Node) y la validación semántica.
- main.c: Punto de entrada del programa.
- Makefile: Automatiza la compilación del proyecto.

---

## Compilación

Para compilar el proyecto, asegúrate de tener instalados GCC, Flex y Bison, luego ejecuta:

```bash
make
```

Esto generará el ejecutable taller2.

---

## Ejecución

El analizador se ejecuta leyendo consultas SQL desde la entrada estándar:

```bash
./taller2 < archivo.txt
```

Ejemplo:

```bash
./taller2 < valido1.txt
```

---

## Casos de Prueba

### Consultas Válidas

#### valido1.txt — SELECT básico
```sql
SELECT nombre, edad FROM alumnus WHERE edad >= 18;
```

---

#### valido2.txt — INSERT y UPDATE (sintaxis del taller)
```sql
INSERT alumnus (nombre, promedio) ("Juan", 5.5);
UPDATE cursos creditos=4 WHERE codigo=101;
```

Nota: La gramática no utiliza INTO, VALUES ni SET.

---

#### valido3.txt — DELETE y operadores lógicos
```sql
delete FROM alumnus WHERE edad < 20 AND NOT promedio = 7.0;
```

Se verifica la insensibilidad a mayúsculas y el uso de operadores lógicos.

---

### Casos con Error

#### error_semantico.txt — Error semántico
```sql
SELECT nombre, direccion FROM alumnus;
```

La columna direccion no existe en la tabla alumnus. Debe activarse el control de error semántico implementado en C.

---

#### error_sintactico.txt — Error sintáctico
```sql
INSERT INTO alumnus VALUES ("Pedro");
```

La gramática no define los tokens INTO ni VALUES, por lo que debe producirse un error sintáctico.

---

## Manejo de Errores

- Errores sintácticos: Detectados automáticamente por Bison cuando la consulta no cumple la gramática.
- Errores semánticos: Detectados manualmente en C cuando las tablas o columnas no son válidas.

En ambos casos, el programa muestra el error por consola y detiene el análisis.

---

## Notas Finales

Este proyecto corresponde al Taller 2 y tiene como objetivo reforzar el uso de Flex y Bison, el diseño de gramáticas, la construcción de un AST y la validación semántica básica en