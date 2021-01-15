%{
#include <stdio.h>
#include <string.h>
#include "y.tab.h"
%}
%option noyywrap
%%

\n {yylineno++;}

[ \t];

";" {return *yytext;}
"{" {return *yytext;}
"}" {return *yytext;}
"=" {return *yytext;}
"(" {return *yytext;}
")" {return *yytext;}
"," {return *yytext;}
"." {return *yytext;}
"[" {return *yytext;}
"]" {return *yytext;}

"int"|"char"|"string"|"float"|"bool" {yylval.type = strdup(yytext);return TYPE;}

"struct" {return CUSTOM_TYPE;}

"const" {return CONST;}

"main" {return START_P;}

"return" {return RET;}

"if" {return IF;}
"else" {return ELSE;}
"for" {return FOR;}
"while" {return WHILE;}

"<="|">="|"=="|"<"|">"  {return COMPARE;}
"++" {return CONCAT;}

"+"|"-"|"*"|"/"|"%" {return ARIT;}

"&&"|"||" {return BI_LOGIC;}
"!" {return U_LOGIC;}

"True"|"False" {
	yylval.const_value_bool = strdup(yytext);
	return BVAL;
}
\"[^\'\"\n]+\" {
	yylval.const_value_string = strdup(yytext);
	return SVAL;
}

\'.{1}\' {
	yylval.const_value_char = yytext[1];
	return CHAR;
}

[0-9]+\.[0-9]+ {
	yylval.const_value_float = atof(yytext);
	return FLOAT_NR;
}

[1-9][0-9]*|0 {
	yylval.const_value_int = atoi(yytext);
	return UINT_NR;
}

[+-]?[1-9][0-9]*|0 {
	yylval.const_value_int = atoi(yytext);
	return INT_NR;
}

[_a-zA-Z][_a-zA-Z0-9]* {yylval.var_name = strdup(yytext);return ID;}

%%
