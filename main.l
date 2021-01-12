%{
#include <stdio.h>
#include "y.tab.h"
%}
%option noyywrap
%%

\n {yylineno++;}

";" {return *yytext;}
"{" {return *yytext;}
"}" {return *yytext;}
"=" {return *yytext;}
"(" {return *yytext;}
")" {return *yytext;}
"," {return *yytext;}
"." {return *yytext;}

"string"|"float"|"bool" {return TYPE;}

"struct" {return CUSTOM_TYPE;}

"const" {return CONST;}

"main" {return START_P;}

"return" {return RET;}

"if" {return IF;}
"else" {return ELSE;}
"for" {return FOR;}

"<="|">="|"=="|"<"|">"  {return COMPARE;}
"+"|"-"|"*"|"/"|"%" {return ARIT;}

"&&"|"||" {return BI_LOGIC;}
"!" {return U_LOGIC;}

"++" {return CONCAT;}

"True"|"False" {return BVAL;}
\"[^\'\"\n]+\" {return SVAL;}


[0-9]+\.[0-9]+ { return FLOAT_NR;}

[+-]?[1-9][0-9]*|0 {return INT_NR;}

[_a-zA-Z][_a-zA-Z0-9]* {return ID;}

%%