%{
#include <stdio.h>
extern FILE* yyin;
extern char* yytext;
extern int yylineno;
int yylex();
void yyerror(char * s);
%}
%token ID TYPE CONST COMPARE CONCAT BVAL SVAL START_P RET INT_NR FLOAT_NR CUSTOM_TYPE IF ELSE FOR BI_LOGIC U_LOGIC ARIT
%left ARIT
%left BI_LOGIC
%left COMPARE
%right U_LOGIC
%right '='
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
	  | struct_definition ';'
	  ;

declaration : fun_declaration
			| var_declaration ';'
			| struct_declaration ';'
			;

fun_declaration : declared_fun ';'
				| declared_fun '{' code '}'
				;

declared_fun : TYPE ID '('')'
			 | TYPE ID '(' parameters ')'
			 ;

var_declaration : TYPE ID {printf("Declar fara sa initializez\n");}
				| TYPE ID '=' value {printf("Declar si initializez\n");}
				;

parameters : parameter
		   | parameters ',' parameter
		   ;

parameter : TYPE ID
		  | struct_declaration
		  ;

value : exp {printf("am gasi exp\n");}
	  | SVAL {printf("am gasi string\n");}
	  | function_call {printf("am gasi function call\n");}
	  ;

struct_declaration : CUSTOM_TYPE ID ID
				   ;

code : stmt {printf("ma duc in stmt\n");}
	 | code stmt
	 ;

stmt : custom_stmt ';'
	 | if
	 | for
     | return ';'
     | struct_definition ';'
 	 ;

custom_stmt : struct_declaration
		    | var_declaration
		    | ID '=' value
		    | function_call
		    ;

if : IF '('exp')' '{' code '}'
 	| IF '('exp')' '{'code'}' ELSE '{' code '}'
 	;

for : FOR '(' custom_stmt ';' exp ';' custom_stmt ')' '{' code '}'
	;

exp : aexp {printf("am luat aexp: %s\n", yytext);}
    | bexp	{printf("am luat bexp%s\n", yytext);}
    | ID {printf("am luat id%s\n", yytext);}
    | U_LOGIC exp {printf("fac not%s\n", yytext);}
    | exp BI_LOGIC exp {printf("fac bilogic%s\n", yytext);}
    | exp COMPARE exp {printf("compar exp%s\n", yytext);}
    | exp ARIT exp {printf("fac aritm%s\n", yytext);}
    ;


bexp : BVAL
     ;

aexp : INT_NR {printf("am luat int\n");}
	 | FLOAT_NR
     ;

function_call : ID '(' ')'
			  | ID '(' arguments ')'
			  ;

arguments : value
		  | arguments ',' value
		  ;

return : RET value
	   ;

struct_definition : CUSTOM_TYPE ID  '{' members '}'
				  | CUSTOM_TYPE ID '{' members '}' ID
				  ;

members : member
		| members member
		;

member : var_declaration ';'
	   | struct_declaration ';'
	   | struct_definition ';'
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
