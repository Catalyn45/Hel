%{
#include <stdio.h>
extern FILE* yyin;
extern char* yytext;
extern int yylineno;
int yylex();
void yyerror(char * s);
%}
%token ID TYPE CONST COMPARE CONCAT BVAL SVAL START_P RET INT_NR FLOAT_NR CUSTOM_TYPE IF ELSE FOR BI_LOGIC U_LOGIC ARIT ASIGN
%start s
%%

s : antets START_P '{' code '}' {printf("The sintax is correct!\n");}
  | START_P '{' code '}' {printf("The sintax is correct!\n");}
  ;
 
antets : antet
	   | antets antet
	   ;

antet : declaration
	  | CONST declaration
	  | struct_definition
	  ;

declaration : fun_declaration
			| var_declaration
			| struct_declaration ';'
			;

fun_declaration : declared_fun ';'
				| declared_fun '{' code '}'
				;

declared_fun : TYPE ID '('')'
			 | TYPE ID '(' parameters ')'
			 ;

var_declaration : TYPE ID ';' {printf("Declar fara sa initializez\n");}
				| TYPE ID '=' value ';' {printf("Declar si initializez\n");}
				;

parameters : parameter
		   | parameters ',' parameter
		   ;

parameter : TYPE ID
		  | struct_declaration
		  ;

value : aexp {printf("am gasi bool\n");}
	  | SVAL {printf("am gasi string\n");}
  	  | bexp {printf("am gasi int: %s\n", yytext);}
	  | ID {printf("am gasi id\n");}
	  | function_call {printf("am gasi function call\n");}
	  ;

struct_declaration : CUSTOM_TYPE ID ID
				   ;

code : stmt {printf("ma duc in stmt\n");}
	 | code stmt
	 ;

stmt : var_declaration {printf("ma duc in var decl\n");}
	 | struct_definition
	 | struct_declaration ';'
	 | if
	 | for
	 | ID '=' value ';'
 	 | function_call ';'
 	 | return ';'
 	 ;

if : IF '('bexp')' '{' code '}'
 	| IF '('bexp')' '{'code'}' ELSE '{'code '}'
 	;

for : FOR '(' stmt bexp ';' stmt ')' '{'code'}'
	;

bexp : BVAL
     | U_LOGIC '('bexp')'
     | '('bexp')' BI_LOGIC '('bexp')'
     |  '('aexp')' COMPARE '('aexp')'
     ;

aexp : INT_NR
	 | FLOAT_NR
	 | '('aexp')' ARIT '('aexp')'
	 ;

function_call : ID '(' ')'
			  | ID '(' arguments ')'
			  ;

arguments : value
		  | arguments ',' value
		  ;

return : RET value
	   ;

struct_definition : CUSTOM_TYPE ID  '{' members '}' ';'
				  | CUSTOM_TYPE ID '{' members '}' ID ';'
				  ;

members : member
		| members member
		;

member : var_declaration
	   | struct_declaration ';'
	   | struct_definition
	   ;

%%

void yyerror(char * s){
	printf("eroare: %s la linia:%d\n",s,yylineno);
}

int main(int argc, char* argv[]){
	 yyin = fopen(argv[1], "r");
	 yyparse();
	 fclose(yyin);
}
