%{
#include <stdio.h>
#include "functions.cpp"
extern FILE* yyin;
extern char* yytext;
extern int yylineno;
int yylex();
void yyerror(const char * s);
%}
%union
{
	char* type;
	char* var_name;
	float const_value_float;
	char* const_value_string;
	char* const_value_bool;
	char* const_value_int;
}

%token <var_name> ID
%token <type> TYPE 
%token CONST COMPARE CONCAT
%token <const_value_bool> BVAL
%token SVAL START_P RET 
%token <const_value_int> INT_NR 
%token <const_value_float> FLOAT_NR 
%token CUSTOM_TYPE IF ELSE FOR BI_LOGIC U_LOGIC ARIT
%left ARIT
%left BI_LOGIC
%left COMPARE
%right U_LOGIC
%right '='
%start s
%%

s : antets START_P begin_scope code end_scope {}
  {

  }

  | START_P begin_scope code end_scope{
  	printf("incep main\n");
  }
  ;
 
antets : antet
	   | antets antet
	   ;

antet : declaration
	  | CONST declaration
	  | struct_definition ';'
	  ;

declaration : fun_declaration {
				if(!add_func())
				{
					yyerror("function name already exists\n");
					return 0;
				}
			}
			| var_declaration ';' { add_var();}
			| struct_declaration ';'
			;

fun_declaration : declared_fun ';'
				| declared_fun begin_scope code end_scope{
				}
				;

declared_fun : TYPE ID '('')'{
				current_function_type = $1;
				current_function_name = $2;
			 }
			 | TYPE ID '(' parameters ')'{
				current_function_type = $1;
				current_function_name = $2;
			 }
			 ;

var_declaration : TYPE ID {
					current_type = $1;
					current_var_name = $2;
				}
				| TYPE ID '=' value {
					current_type = $1;
					current_var_name = $2;
				}
				;

begin_scope : '{' {
	increase_scope();
}

end_scope : '}' {
	decrease_scope();
}

parameters : parameter
		   | parameters ',' parameter
		   ;

parameter : TYPE ID{
			 if(!add_parameter($1, $2))
			 {
			 	yyerror("Invalid parameters for function\n");
			 	return 0;
			 }
		  }
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
			| CONST struct_declaration
		    | var_declaration { 
		    	if(!add_var())
		    	{
		    		yyerror("Variable already declared\n");
		    		return 0;
		    	}
		    }
		    | CONST var_declaration { 
		    	if(!add_var(true))
		    	{
		    		yyerror("Variable already declared\n");
		    		return 0;
		    	}
		    }
		    | ID '=' value
		    | function_call
		    | ID '.' ID
		    ;

if : IF '('exp')' begin_scope code end_scope {
	}
 	| IF '('exp')' begin_scope code end_scope ELSE begin_scope code end_scope{
 	}
 	;

for : FOR '(' custom_stmt ';' exp ';' custom_stmt ')' begin_scope code end_scope {
	}
	;

exp : aexp {printf("am luat aexp: %s\n", yytext);}
    | bexp	{printf("am luat bexp%s\n", yytext);}
    | ID {printf("am luat id%s\n", yytext);}
    | U_LOGIC exp {printf("fac not%s\n", yytext);}
    | exp BI_LOGIC exp {printf("fac bilogic%s\n", yytext);}
    | exp COMPARE exp {printf("compar exp%s\n", yytext);}
    | exp ARIT exp {printf("fac aritm%s\n", yytext);}
    ;


bexp : BVAL{
		current_value.value_bool = parse_bool($1);
	}
     ;

aexp : INT_NR {

	 }
	 | FLOAT_NR{
	 	current_value.value_float = $1;
	 }
     ;

function_call : ID '(' ')'
			  | ID '(' arguments ')'
			  ;

arguments : value
		  | arguments ',' value
		  ;

return : RET value
	   ;

struct_definition : CUSTOM_TYPE ID  '{' members '}' {
				  }
				  | CUSTOM_TYPE ID '{' members '}' ID{
				  }
				  ;

members : member
		| members member
		;

member : var_declaration ';'
	   | struct_declaration ';'
	   | struct_definition ';'
	   ;

%%

void yyerror(const char * s){
	printf("eroare: %s la linia:%d\n",s,yylineno);
}

int main(int argc, char* argv[]){
	 yyin = fopen(argv[1], "r");
	 yyparse();
	 fclose(yyin);
}
