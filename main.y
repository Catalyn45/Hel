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
	int const_value_int;
	int exp_type;
}

%token <var_name> ID
%token <type> TYPE 
%token CONST COMPARE CONCAT
%token <const_value_bool> BVAL
%token SVAL START_P RET 
%token <const_value_int> INT_NR 
%token <const_value_float> FLOAT_NR 
%token CUSTOM_TYPE IF ELSE FOR BI_LOGIC U_LOGIC ARIT

%type <exp_type> variable
%type <exp_type> aexp
%type <exp_type> bexp
%type <exp_type> strexp
%type <exp_type> exp
%type <exp_type> value
%type <exp_type> function_call
%type <exp_type> member_access

%left ARIT
%left BI_LOGIC
%left COMPARE
%right U_LOGIC
%right '='
%left '.'
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

declaration : fun_declaration
			| var_declaration ';' { add_var();}
			| struct_declaration ';' { add_var(false, true);}
			;

fun_declaration : declared_fun ';'
				| declared_fun_defined begin_scope code end_scope {}
				;

declared_fun : TYPE ID '('')'{
				if(!add_func($1, $2))
				{
					yyerror("Error at adding the function");
					return 0;
				}
			 }
			 | TYPE ID '(' parameters ')'{
			 	printf("Acum pun numele functiei si tipul\n");

				if(!add_func($1, $2))
				{
					yyerror("Error at adding the function");
					return 0;
				}
			 }
			 ;
declared_fun_defined :  TYPE ID '('')'{

						if(!add_func($1, $2, true))
						{
							yyerror("Error at adding the function");
							return 0;
						}
					 }
					 | TYPE ID '(' parameters ')'{
					 	printf("Acum pun numele functiei si tipul\n");

						if(!add_func($1, $2, true))
						{
							yyerror("Error at adding the function");
							return 0;
						}
					 }

var_declaration : TYPE ID {
					current_type = $1;
					current_var_name = $2;
				}
				| TYPE ID '=' value {
					if(to_exp_type($1) != $4)
					{
						yyerror("can't assign different types\n");
						return 0;
					}
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
		 	 printf("Adaug parametri acm\n");
			 current_type = $1;
			 current_var_name = $2;

			 if(!add_parameter())
			 {
			 	yyerror("Invalid parameters for function\n");
			 	return 0;
			 }
		  }
		  | struct_declaration {
		  		if(!add_parameter(true))
		  		{
		  			std::cout << "aici e cu structura la parametru\n";
				 	yyerror("Invalid parameters for function\n");
			 		return 0;
		  		}
		  	}
		  ;

value : exp {printf("am gasi exp\n"); $$ = $1;}
	  | function_call {
	  	printf("am gasi function call\n");
	  	$$ = $1;
	  }
	  ;

struct_declaration : CUSTOM_TYPE ID ID {
						current_custom_type = $2;
						current_var_name = $3;
					}
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

custom_stmt : struct_declaration{
				if(!add_var(false, true))
				{
					yyerror("Variable already declared\n");
					return 0;
				}
			}
			| CONST struct_declaration {
				if(!add_var(true, true))
				{
					yyerror("Variable already declared\n");
					return 0;
				}
			}
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
		    | variable '=' value {
		    	if ($1 != $3)
		    	{
		    		yyerror("Can't assign different types\n");
		    		return 0;
		    	}
		    }
		    | member_access '=' value {
		    	if ($1 != $3)
		    	{
		    		yyerror("Can't assign different types\n");
		    		return 0;
		    	}
		    }
		    | function_call
		    ;

variable : ID {
	    	$$ = get_var_type($1);

	    	if($$ == -1)
			{
				yyerror("Undeclarated variable");
				return 0;
			}
		}
		;
member_access :  ID '.' ID {
			    	$$ = get_member_type($1, $3);
					std::cout << "tipul membrului: "<< $$ << "\n";
					if($$ == -1)
			    	{
			    		yyerror("can't acces that member\n");
			    		return 0;
			    	}
				}
			  ;

if : IF '('exp')' begin_scope code end_scope {
	}
 	| IF '('exp')' begin_scope code end_scope ELSE begin_scope code end_scope{
 	}
 	;

for : FOR '(' custom_stmt ';' exp ';' custom_stmt ')' begin_scope code end_scope {
	}
	;

exp : aexp {
		printf("am luat aexp: %s\n", yytext);
		$$ = 0;
	}
    | bexp	{
    	printf("am luat bexp%s\n", yytext);
    	$$ = 1;
    }
    | strexp {
    	printf("am luat strexp%s\n", yytext);
    	$$ = 2;
    }
    | variable {
    	printf("am luat variabila %s\n", yytext);
    	$$ = $1;
    }
    | member_access {
    	printf("am luat member_access %s\n", yytext);
    	$$ = $1;
    }
    | U_LOGIC exp {
    	printf("fac not%s\n", yytext);

    	if($2 != 1)
    	{
    		yyerror("Invalid expression\n");
    		return 0;
    	}

    	$$ = 1;
    }

    | exp BI_LOGIC exp {
    	printf("fac bilogic%s\n", yytext);
    	if($1 != 1 || $3 != 1)
    	{
    		yyerror("Invalid expression\n");
    		return 0;
    	}

    	$$ = 1;
    }
    | exp COMPARE exp {
    	printf("compar exp%s\n", yytext);

    	if($1 != 0 || $3 != 0)
    	{
    		yyerror("Invalid expression\n");
    		return 0;
    	}

    	$$ = 1;
    }
    | exp ARIT exp {
    	printf("fac aritm%s\n", yytext);

    	if($1 != 0 || $3 != 0)
    	{
    		yyerror("Invalid expression\n");
    		return 0;
    	}

    	$$ = 0;
    }
    ;


bexp : BVAL{
		current_value.value_bool = parse_bool($1);
	}
     ;

aexp : INT_NR {
		current_value.value_int = $1;
	 }
	 | FLOAT_NR{
	 	current_value.value_float = $1;
	 }
     ;

strexp : SVAL {printf("am gasi string\n");}

function_call : ID '(' ')' {
			      $$ = get_fun_type($1);

			      if($$ == -1)
			      {
			      		yyerror("Function not defined\n");
			      		return 0;
			      }
			  }
			  | ID '(' arguments ')' {
			      $$ = get_fun_type($1);

			      if($$ == -1)
			      {
			      		yyerror("Function not defined\n");
			      		return 0;
			      }
			  }
			  ;

arguments : value
		  | arguments ',' value
		  ;

return : RET value
	   ;

struct_definition : CUSTOM_TYPE ID  '{' members '}' {
						if(!define_structure($2))
						{
							yyerror("Structure already defined!\n");
							return 0;
						}
				  }
				  | CUSTOM_TYPE ID '{' members '}' ID{
						if(!define_structure($2))
						{
							yyerror("Structure already defined!\n");
							return 0;
						}

						current_var_name = $6;
						current_custom_type = $2;

						if(!add_var(false, true))
						{
							yyerror("Variable already defined!\n");
							return 0;
						}
				  }
				  ;

members : member
		| members member
		;

member : var_declaration ';'{
			if(!add_member())
			{
				yyerror("member already exists!\n");
				return 0;
			}
	   }
	   | struct_declaration ';'
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
