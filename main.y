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
	char const_value_char;
	int const_value_int;
	int exp_type;
}

%token <var_name> ID
%token <type> TYPE 
%token CONST COMPARE CONCAT
%token <const_value_bool> BVAL
%token <const_value_string> SVAL
%token START_P RET 
%token <const_value_int> INT_NR 
%token <const_value_float> FLOAT_NR 
%token <const_value_int> UINT_NR;
%token <const_value_char> CHAR;
%token CUSTOM_TYPE IF ELSE WHILE FOR BI_LOGIC U_LOGIC ARIT

%type <exp_type> variable
%type <exp_type> aexp
%type <exp_type> bexp
%type <exp_type> strexp
%type <exp_type> exp
%type <exp_type> value
%type <exp_type> function_call
%type <exp_type> member_access
%type <exp_type> struct_definition
%type <type> fun_name;

%left ARIT
%left BI_LOGIC
%left COMPARE
%left CONCAT
%right U_LOGIC
%right '='
%left '.'
%start s
%%

s : antets start {
		std::cout << "Syntax and semantic is correct!\n";
	}
  | start {
  		std::cout << "Syntax and semantic is correct!\n";
 	}
  ;

start: main begin_scope code end_scope {}
  	 ;

main : START_P {
		symbol_table.push_back(symbol_var{
			.type = symbol_types::MAIN
		});
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
			| var_declaration ';' { 
				if(!add_var())
				{
					yyerror("Error at adding var\n");
					return -1;
				}
			}
			| vect_declaration ';' {
				if(!add_var(false, false, true))
				{
					yyerror("Error at adding var\n");
					return -1;
				}
			}
			| struct_declaration ';'{ 
				if(!add_var(false, true))
				{
					yyerror("Error at adding var\n");
					return -1;
				}
			}
			;

fun_declaration : declared_fun ';'
				{
				}
				| declared_fun_defined begin_scope code end_scope {
				}
				;

declared_fun : TYPE ID '('')'{
				if(!add_func($1, $2))
				{
					yyerror("Error at adding the function");
					return -1;
				}
			 }
			 | TYPE ID '(' parameters ')'{
				if(!add_func($1, $2))
				{
					yyerror("Error at adding the function");
					return -1;
				}
			 }
			 ;
declared_fun_defined :  TYPE ID '('')'{

						if(!add_func($1, $2, true))
						{
							yyerror("Error at adding the function");
							return -1;
						}
					 }
					 | TYPE ID '(' parameters ')'{
						if(!add_func($1, $2, true))
						{
							yyerror("Error at adding the function");
							return -1;
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
						return -1;
					}
					current_type = $1;
					current_var_name = $2;
					current_declared_initiated = true;
				}
vect_declaration : TYPE ID '[' UINT_NR ']' {
					current_type = $1;
					current_var_name = $2;
					current_vect_size = $4;
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
			 current_type = $1;
			 current_var_name = $2;

			 if(!add_parameter())
			 {
			 	yyerror("Invalid parameters for function\n");
			 	return -1;
			 }
		  }
		  | struct_declaration {
		  		if(!add_parameter(true))
		  		{
				 	yyerror("Invalid parameters for function\n");
			 		return -1;
		  		}
		  	}
		  ;

value : exp {
			$$ = $1;
	  }

	  | function_call {
	  	$$ = $1;
	  }
	  ;

struct_declaration : CUSTOM_TYPE ID ID {
						current_custom_type = $2;
						current_var_name = $3;
					}
				   ;

code : stmt
	 | code stmt
	 ;

stmt : custom_stmt ';'
	 | if
	 | for
	 | while
     | return ';'
     | struct_definition ';'
 	 ;

custom_stmt : struct_declaration{
				if(!add_var(false, true))
				{
					yyerror("Variable already declared\n");
					return -1;
				}
			}
			| CONST struct_declaration {
				if(!add_var(true, true))
				{
					yyerror("Variable already declared\n");
					return -1;
				}
			}
		    | var_declaration { 
		    	if(!add_var())
		    	{
		    		yyerror("Variable already declared\n");
		    		return -1;
		    	}
		    }
		    |vect_declaration {
		    	if(!add_var(false, false, true))
		    	{
		    		yyerror("Variable already declared\n");
		    		return -1;
		    	}
		    }
		    | CONST var_declaration { 
		    	if(!add_var(true))
		    	{
		    		yyerror("Variable already declared\n");
		    		return -1;
		    	}
		    }
		    | variable '=' value {
		    	if ($1 != $3)
		    	{
		    		yyerror("Can't assign different types\n");
		    		return -1;
		    	}
		    }
		    | member_access '=' value {
		    	if ($1 != $3)
		    	{
		    		yyerror("Can't assign different types\n");
		    		return -1;
		    	}
		    }
		    | function_call
		    ;

variable : ID {
	    	$$ = get_var_type($1);

	    	if($$ == -1)
			{
				yyerror("Undeclarated variable");
				return -1;
			}
		}
		;
member_access :  ID '.' ID {
			    	$$ = get_member_type($1, $3);
					if($$ == -1)
			    	{
			    		yyerror("can't acces that member\n");
			    		return -1;
			    	}
				}
			  | ID '[' UINT_NR ']' {
			  	$$ = get_vect_type($1, $3);
 		    	if($$ == -1)
				{
					yyerror("Undeclarated variable");
					return -1;
				}
			  }
			  ;

if : IF '('exp')' begin_scope code end_scope {
	}
 	| IF '('exp')' begin_scope code end_scope ELSE begin_scope code end_scope{
 	}
 	;

while : WHILE '(' exp ')' begin_scope code end_scope{

}

for : FOR '(' custom_stmt ';' exp ';' custom_stmt ')' begin_scope code end_scope {
	}
	;

exp : aexp {
		$$ = $1;
	}
    | bexp	{
    	$$ = 1;
    }
    | strexp {
    	$$ = 4;
    }
    | variable {
    	$$ = $1;
    }
    | member_access {
    	$$ = $1;
    }
    | U_LOGIC exp {
    	if($2 != 1)
    	{
    		yyerror("Invalid expression\n");
    		return -1;
    	}

    	$$ = 1;
    }

    | exp BI_LOGIC exp {
    	if($1 != 1 || $3 != 1)
    	{
    		yyerror("Invalid expression\n");
    		return -1;
    	}

    	$$ = 1;
    }
    | exp COMPARE exp {

    	if($1 == 1 || $3 == 1 || $1 == 4 || $3 == 4)
    	{
    		yyerror("Invalid expression\n");
    		return -1;
    	}

    	$$ = 1;
    }
    | exp ARIT exp {

    	if($1 == 1 || $3 == 1 || $1 == 4 || $3 == 4)
    	{
    		yyerror("Invalid expression\n");
    		return -1;
    	}

    	$$ = $1;
    }
    | exp CONCAT exp {

    	if($1 != 4 || $3 != 4)
    	{
    		yyerror("Invalid expression\n");
    		return -1;
    	}

    	$$ = 4;
    }
    ;


bexp : BVAL{
		current_value.value_bool = parse_bool($1);
	}
     ;

aexp : INT_NR {
		current_value.value_int = $1;
		$$ = 2;
	 }
	 | UINT_NR {
	 	current_value.value_int = $1;
	 	$$ = 2;
	 }
	 | FLOAT_NR {
	 	current_value.value_float = $1;
	 	$$ = 0;
	 }
	 | CHAR {
	 	current_value.value_char = $1;
	 	$$ = 3;
	 }
     ;

strexp : SVAL {
	current_value.value_str = $1;
}

function_call : fun_name '(' ')' {
			      $$ = get_fun_type($1, true);
			      current_fun_call.pop();
			      if($$ == -1)
			      {
			      		yyerror("Function not defined or arguments doesn't match\n");
			      		return -1;
			      }
			  }
			  | fun_name '(' arguments ')' {
			      $$ = get_fun_type($1, true);
			      current_fun_call.pop();
			      if($$ == -1)
			      {
			      		yyerror("Function not defined or arguments doesn't match\n");
			      		return -1;
			      }
			  }
			  ;
fun_name : ID {
			current_fun_call.push($1);
			$$ = $1;
		 }
	   	 ;

arguments : value
			{
				add_arg({$1, last_custom_type});
			}
		  | arguments ',' value
		    {
		    	add_arg({$3, last_custom_type});
		    }
		  ;

return : RET value
	   ;

struct_definition : CUSTOM_TYPE ID  '{' members '}' {
						if(!define_structure($2))
						{
							yyerror("Structure already defined!\n");
							return -1;
						}
						$$ = 5;
				  }
				  | CUSTOM_TYPE ID '{' members '}' ID{
						if(!define_structure($2))
						{
							yyerror("Structure already defined!\n");
							return -1;
						}

						current_var_name = $6;
						current_custom_type = $2;

						if(!add_var(false, true))
						{
							yyerror("Variable already defined!\n");
							return -1;
						}

						$$ = 5;

				  }
				  ;

members : member
		| members member
		;

member : var_declaration ';'{
			if(!add_member())
			{
				yyerror("member already exists!\n");
				return -1;
			}
	   }
	   | vect_declaration ';' {
			if(!add_member(false, false, true))
			{
				yyerror("member already exists!\n");
				return -1;
			}
	   }
	   | struct_declaration ';' {
			if(!add_member(false, true))
			{
				yyerror("member already exists!\n");
				return -1;
			}
	   }
	   ;

%%

void yyerror(const char * s){
	printf("eroare: %s la linia:%d\n",s,yylineno);
}

int main(int argc, char* argv[]){
	 yyin = fopen(argv[1], "r");
	 if(yyparse() != -1)
	 	write_symbol_table();
	 fclose(yyin);
}
