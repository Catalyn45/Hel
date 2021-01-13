yacc -d main.y
lex main.l
g++ lex.yy.c y.tab.c -o out
