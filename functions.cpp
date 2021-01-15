#include <iostream>
#include <string>
#include <vector>
#include <stack>
#include <algorithm>
#include <string.h>
#include <fstream>
enum class types
{
	FLOAT,
	BOOL,
	INT,
	CHAR,
	STRING,
	CUSTOM,
	NOT_FOUND
};

union val
{
	float value_float;
	bool value_bool;
	char* value_str;
	char value_char;
	int value_int;
	bool is_const;
};

struct var_info
{
	int scope;
	std::string name;
	types type;
	const char* cs_type;
   	val value;
	bool is_const;
	bool is_vector;
	bool declared_initiated;
	int vect_sz;
};

struct custom_data
{
	int scope;
	std::string name;
	std::vector<var_info> members;
};

struct parameter
{

	types type;
	const char* cs_type;

	std::string name;
	bool is_const;
};

struct call_types
{
	int type;
	std::string cs_type;
};

struct function_info
{
	std::string name;
	std::vector<parameter> params;
	types type;
	bool is_defined;
	std::vector<call_types> current_call_types;
};

enum class symbol_types
{
	FUNCTION,
	STRUCT,
	GLOBAL_VAR,
	VAR,
	MAIN
};

struct symbol_var
{
	symbol_types type;
	function_info function;
	custom_data structure;
	var_info variable;
};

int current_scope;

std::string current_type;
std::string current_var_name;

std::vector<parameter> current_parameters;

union val current_value;
std::vector<var_info> variables;
std::vector<function_info> functions;
std::vector<custom_data> custom_types;

std::string current_custom_type;

std::vector<var_info> members_to_add;
std::string last_custom_type;

std::vector<symbol_var> symbol_table;

std::stack<std::string> current_fun_call;

int current_vect_size;

bool current_declared_initiated = false;
bool begin_main;

void increase_scope()
{
	current_scope++;
}

void decrease_scope()
{
	auto it = std::remove_if(variables.begin(), variables.end(), [](var_info v){
		return (v.scope == current_scope);
	});

	variables.erase(it, variables.end());

	auto it2 = std::remove_if(custom_types.begin(), custom_types.end(), [](custom_data v){
		if (v.scope == current_scope)
		{
			return true;
		}

		return false;
	});

	custom_types.erase(it2, custom_types.end());
	
	current_scope--;
}

types get_type(std::string type)
{
	if (type == "bool")
		return types::BOOL;

	if(type == "float")
		return types::FLOAT;

	if(type == "char")
		return types::CHAR;

	if(type == "int")
		return types::INT;

	if(type == "string")
		return types::STRING;

	return types::NOT_FOUND;
}

bool parse_bool(const char* text)
{
	const std::string buffer = text;

	if(buffer == "True")
		return true;

	return false;
}

bool add_var(bool is_const = false, bool is_custom = false, bool is_vector = false)
{
	types var_type = types::NOT_FOUND;

	if(is_custom)
		var_type = types::CUSTOM;
	else
		var_type = get_type(current_type);

	if(var_type == types::NOT_FOUND)
		return false;

	for(const auto &it : variables)
	{
		if(it.scope == current_scope && current_var_name == it.name)
			return false;
	}

	var_info v;

	if(var_type == types::CUSTOM)
	{
		bool custom_exists = false;

		for(const auto& it : custom_types)
		{
			if(it.name == current_custom_type)
			{
				custom_exists = true;
				break;
			}
		}

		if(!custom_exists)
		{
			std::cout << "this struct does not exists\n";
			return false;
		}
		v = var_info {
			.scope = current_scope,
			.name = current_var_name,
			.type = var_type,
			.cs_type = strdup(current_custom_type.c_str()),
			.value = current_value,
			.is_const = is_const,
			.is_vector = is_vector,
			.declared_initiated = current_declared_initiated,
			.vect_sz = current_vect_size
		};
	}
	else
	{
		v = var_info{
			.scope = current_scope,
			.name = current_var_name,
			.type = var_type,
			.value = current_value,
			.is_const = is_const,
			.is_vector = is_vector,
			.declared_initiated = current_declared_initiated,
			.vect_sz = current_vect_size
		};
	}

	variables.push_back(v);

	if(current_scope == 0)
	{
		symbol_table.push_back(symbol_var{
			.type = symbol_types::GLOBAL_VAR,
			.variable = v
		});
	}
	else 
	{
		symbol_table.push_back(symbol_var{
			.type = symbol_types::VAR,
			.variable = v
		});
	}


	current_declared_initiated = false;

	return true;
}


bool add_member(bool is_const = false, bool is_custom = false, bool is_vector = false)
{
	types var_type = types::NOT_FOUND;

	if(is_custom)
		var_type = types::CUSTOM;
	else
		var_type = get_type(current_type);

	if(var_type == types::NOT_FOUND)
	{
		printf("member type not found\n");
		return false;
	}

	for(const auto &it : members_to_add)
	{
		if(current_var_name == it.name)
		{
			return false;
		}
	}

	if(var_type == types::CUSTOM)
	{
		bool custom_exists = false;

		for(const auto& it : custom_types)
		{
			if(it.name == current_custom_type)
			{
				custom_exists = true;
				break;
			}
		}

		if(!custom_exists)
		{
			std::cout << "this struct does not exists\n";
			return false;
		}

		members_to_add.push_back(var_info{
			.scope = 0,
			.name = current_var_name,
			.type = var_type,
			.cs_type = strdup(current_custom_type.c_str()),
			.value = current_value,
			.is_const = is_const,
			.is_vector = is_vector,
			.vect_sz = current_vect_size
		});;
	}
	else
	{
		members_to_add.push_back(var_info{
			.scope = 0,
			.name = current_var_name,
			.type = var_type,
			.value = current_value,
			.is_const = is_const,
			.is_vector = is_vector,
			.vect_sz = current_vect_size
		});;
	}

	return true;
}

bool define_structure(std::string name)
{
	for(const auto &it : custom_types)
	{
		if(it.scope == current_scope && it.name == name)
			return false;
	}


	custom_data v = {
		current_scope,
		name,
		members_to_add
	};
	custom_types.push_back(v);

	members_to_add.clear();

	symbol_table.push_back(symbol_var{
		.type = symbol_types::STRUCT,
		.structure = v
	});

	return true;
}

bool add_parameter(bool is_custom = false)
{
	types var_type = types::NOT_FOUND;

	if(is_custom)
		var_type = types::CUSTOM;
	else
		var_type = get_type(current_type);

	if(var_type == types::NOT_FOUND)
		return false;

	for(const auto& it : current_parameters)
	{
		if(it.name == current_var_name)
			return false;
	}

	if(is_custom)
	{
		bool custom_exists = false;

		for(const auto& it : custom_types)
		{
			if(it.name == current_custom_type)
			{
				custom_exists = true;
				break;
			}
		}

		if(!custom_exists)
		{
			std::cout << "this struct does not exists\n";
			return false;
		}
		current_parameters.push_back(parameter{
			.type = var_type,
			.cs_type = strdup(current_custom_type.c_str()),
			.name = current_var_name,
			.is_const = false
		});
	}
	else
	{
		current_parameters.push_back(parameter{
			.type = var_type,
			.name = current_var_name,
			.is_const = false
		});
	}

	return true;
}

void declare_parameter(int scope, parameter par)
{
	var_info v = {
		scope,
		par.name,
		par.type,
		par.cs_type,
		current_value,
		par.is_const
	};

	variables.push_back(v);

	symbol_table.push_back(symbol_var{
		.type = symbol_types::VAR,
		.variable = v
	});
}

bool add_func(std::string type, std::string name, bool is_defined = false)
{
	types var_type = get_type(type);

	if(var_type == types::NOT_FOUND)
	{
		std::cout << "Unknown function type\n";
		return false;
	}

	bool need_add = true;

	for(auto &it : functions)
	{
		if(name == it.name)
		{
			if (is_defined == true && it.is_defined == false)
			{
				it.is_defined = true;
				need_add = false;
				break;
			}

			std::cout << "Function already exists\n";
			return false;
		}
	}

	if(need_add)
	{
		function_info v = {
				name,
				current_parameters,
				var_type,
				is_defined
			};

		functions.push_back(v);

		symbol_table.push_back(symbol_var{
			.type = symbol_types::FUNCTION,
			.function = v
		});
	}

	if(is_defined)
	{
		for(auto & it : current_parameters)
		{
			declare_parameter(current_scope + 1, it);
		}
	}

	current_parameters.clear();

	return true;
}

int get_var_type(std::string var_name)
{
	for(const auto& it : variables)
	{
		if(it.name == var_name)
		{
			switch(it.type)
			{
				case types::FLOAT:
					return 0;
				case types::BOOL:
					return 1;
				case types::INT:
					return 2;
				case types::CHAR:
					return 3;
				case types::STRING:
					return 4;
				case types::CUSTOM:
				{
					last_custom_type = it.cs_type;
					return 5;
				}
				default:
					return -1;
			}
		}
	}

	return -1;
}

int get_vect_type(std::string var_name, int size)
{
	for(const auto& it : variables)
	{
		if(it.name == var_name && it.is_vector)
		{
			if(it.vect_sz <= size)
				return -1;

			switch(it.type)
			{
				case types::FLOAT:
					return 0;
				case types::BOOL:
					return 1;
				case types::INT:
					return 2;
				case types::CHAR:
					return 3;
				case types::STRING:
					return 4;
				case types::CUSTOM:
					return 5;
				default:
					return -1;
			}
		}
	}

	return -1;
}

int get_fun_type(std::string fun_name, bool match_args = false)
{
	for(auto& it : functions)
	{
		if(it.name == fun_name)
		{
			if(it.is_defined == false)
				return -1;
			if(match_args)
			{
				if(it.current_call_types.size() != it.params.size())
				{
					return -1;
				}

				for(unsigned i = 0 ; i < it.current_call_types.size(); i++)
				{
					if(it.current_call_types[i].type != (int)it.params[i].type)
						return -1;

					if(it.current_call_types[i].type == 5)
					{
						if(it.current_call_types[i].cs_type != std::string(it.params[i].cs_type))
							return -1;
					}
				}

				it.current_call_types.clear();
			}


			switch(it.type)
			{
				case types::FLOAT:
					return 0;
				case types::BOOL:
					return 1;
				case types::INT:
					return 2;
				case types::CHAR:
					return 3;
				case types::STRING:
					return 4;
				case types::CUSTOM:
					return 5;
				default:
					return -1;
			}
		}
	}

	return -1;
}


int get_member_type(std::string var_name, std::string member)
{
	var_info* info = nullptr;

	for(auto& it : variables)
	{
		if(it.name == var_name)
		{
			info = &it;
			break;
		}
	}

	if(info == nullptr)
		return false;

	if(info -> type != types::CUSTOM)
		return false;

	for(auto &it : custom_types)
	{
		if(it.name == info->cs_type)
		{
			for(auto& it2 : it.members)
			{
				if(it2.name == member)
				{
					switch(it2.type)
					{
					case types::FLOAT:
						return 0;
					case types::BOOL:
						return 1;
					case types::INT:
						return 2;
					case types::CHAR:
						return 3;
					case types::STRING:
						return 4;
					case types::CUSTOM:
						return 5;
					default:
						return -1;
					}
				}
			}
		}
	}

	return -1;
}

int to_exp_type(std::string type)
{
	if(type == "float")
		return 0;

	if(type == "bool")
		return 1;

	if(type == "int")
		return 2;

	if(type == "char")
		return 3;

	if(type == "string")
		return 4;

	return -1;
}

std::string type_to_str(types v, const char* custom = nullptr)
{
	switch(v)
	{
	case types::FLOAT:
		return "float";
	case types::BOOL:
		return "bool";
	case types::INT:
		return "int";
	case types::CHAR:
		return "char";
	case types::STRING:
		return "string";
	case types::CUSTOM:
		return "struct " + std::string(custom);
	default:
		break;
	}

	return "";
}

std::string get_value(var_info v)
{
	switch(v.type)
	{
	case types::FLOAT:
		return std::to_string(v.value.value_float);
	case types::BOOL:
		if(v.value.value_bool)
			return "True";
		else
			return "False";
	case types::INT:
		return std::to_string(v.value.value_int);
	case types::CHAR:
		return "\'" + std::string(1, v.value.value_char) + "\'";
	case types::STRING:
		return v.value.value_str;
	case types::CUSTOM:
	default:
		break;
	}

	return "";
}

void write_symbol_table()
{

	std::ofstream g("symbol_table.txt");

	g << "GLOBAL VARS:\n";
	for(auto it : symbol_table)
		if(it.type == symbol_types::GLOBAL_VAR)
		{
			g << "\t" << type_to_str(it.variable.type, it.variable.cs_type) <<" " << it.variable.name;

			if(it.variable.is_vector)
				g << "[" << std::to_string(it.variable.vect_sz) << "]";

			if(it.variable.declared_initiated)
			{
				g <<" = " << get_value(it.variable);
			}

			g << "\n";
		}

	g <<"FUNCTONS:\n";
	for(auto it : symbol_table)
	{
		if(it.type == symbol_types::FUNCTION)
		{
			g <<"\t"<< type_to_str(it.function.type) << " " << it.function.name;
			g << "(";
			for(auto it2 : it.function.params)
			{
				g <<" "<< type_to_str(it2.type, it2.cs_type);
			}
			g << " )\n";
		}
		else if(it.type == symbol_types::VAR)
		{
			g << "\t\t" << type_to_str(it.variable.type, it.variable.cs_type) <<" " << it.variable.name;
			if(it.variable.is_vector)
				g << "[" << std::to_string(it.variable.vect_sz) << "]";

			if(it.variable.declared_initiated)
			{
				g <<" = " << get_value(it.variable);
			}

			g << "\n";
		}
		else if(it.type == symbol_types::MAIN)
		{
			g <<"\tmain\n";
		}
	}

	g <<"STRUCTURES:\n";
	for(auto it : symbol_table)
	{
		if(it.type == symbol_types::STRUCT)
		{
			g << "\t" << it.structure.name << "\n";

			for(auto it2 : it.structure.members)
			{
				g << "\t\t" << type_to_str(it2.type, it2.cs_type) <<" " << it2.name ;

				if(it2.is_vector)
					g << "[" << std::to_string(it2.vect_sz) << "]";

				if(it2.declared_initiated)
				{
					g <<" = " << get_value(it2);
				}

				g << "\n";
			}
		}
	}
	g.close();
}


void add_arg(call_types call)
{
	for(auto &it : functions)
	{
		if(it.name == current_fun_call.top())
		{
			it.current_call_types.push_back(call);
			return;
		}
	}
}