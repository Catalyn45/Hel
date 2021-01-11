yacc -d main.y
lex main.l
gcc lex.yy.c y.tab.c -o out
