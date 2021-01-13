#include <iostream>
#include <string>
#include <vector>
#include <algorithm>
#include <string.h>

enum class types
{
	BOOL,
	FLOAT,
	STRING,
	CUSTOM,
	NOT_FOUND
};

union val
{
	float value_float;
	bool value_bool;
	char* value_str;
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

struct function_info
{
	std::string name;
	std::vector<parameter> params;
	types type;
	bool is_defined;
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

void increase_scope()
{
	std::cout << "increase scope\n";
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
			std::cout << "Sterg definire\n";
			return true;
		}

		return false;
	});

	custom_types.erase(it2, custom_types.end());
	


	for(auto it : variables)
	{
		std::cout << it.name << " ";
	}

	std::cout << "\n";
	current_scope--;
}

types get_type(std::string type)
{
	if (type == "bool")
		return types::BOOL;

	if(type == "float")
		return types::FLOAT;

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

bool add_var(bool is_const = false, bool is_custom = false)
{
	std::cout << "Se adauga variabila\n";

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

	if(var_type == types::CUSTOM)
	{

		std::cout << "Verific daca exista definit\n";
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

		variables.push_back(var_info{
			.scope = current_scope,
			.name = current_var_name,
			.type = var_type,
			.cs_type = strdup(current_custom_type.c_str()),
			.value = current_value,
			.is_const = is_const
		});;
	}
	else
	{
		variables.push_back(var_info{
			.scope = current_scope,
			.name = current_var_name,
			.type = var_type,
			.value = current_value,
			.is_const = is_const
		});;
	}

	return true;
}


bool add_member(bool is_const = false, bool is_custom = false, const char* custom_name = nullptr)
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
			std::cout << "Curent: " << it.name << "\n";
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
			.cs_type = custom_name,
			.value = current_value,
			.is_const = is_const
		});;
	}
	else
	{
		std::cout << "Nu e custom\n";
		members_to_add.push_back(var_info{
			.scope = 0,
			.name = current_var_name,
			.type = var_type,
			.value = current_value,
			.is_const = is_const
		});;
	}

	std::cout << "Member added: " << current_var_name << "\n";

	return true;
}

bool define_structure(std::string name)
{
	for(const auto &it : custom_types)
	{
		if(it.scope == current_scope && it.name == name)
			return false;
	}

	for(const auto &it : members_to_add)
	{
		std::cout <<"Adding member: " << it.name << " ";
	}
	std::cout << "\n";

	custom_types.push_back(custom_data {
		current_scope,
		name,
		members_to_add
	});

	members_to_add.clear();

	std::cout << "\n";

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
		std::cout << current_var_name << " Added as parameter custom: " << current_custom_type.c_str() << "\n";
		current_parameters.push_back(parameter{
			.type = var_type,
			.cs_type = strdup(current_custom_type.c_str()),
			.name = current_var_name,
			.is_const = false
		});
	}
	else
	{
		std::cout << current_var_name << " Added as parameter\n";
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
	variables.push_back(var_info{
		scope,
		par.name,
		par.type,
		par.cs_type,
		current_value,
		par.is_const
	});
}

bool add_func(std::string type, std::string name, bool is_defined = false)
{
	types var_type = get_type(type);

	if(var_type == types::NOT_FOUND)
	{
		std::cout << "Tipul functiei e necunoscut\n";
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

			std::cout << "Functia exista deja\n";
			return false;
		}
	}

	if(need_add)
	{
		functions.push_back(function_info{
				name,
				current_parameters,
				var_type,
				is_defined
			}
		);
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
				case types::STRING:
					return 2;
				default:
					return -1;
			}
		}
	}

	return -1;
}

int get_fun_type(std::string fun_name)
{
	for(const auto& it : functions)
	{
		if(it.name == fun_name)
		{
			if(it.is_defined == false)
				return -1;

			switch(it.type)
			{
				case types::FLOAT:
					return 0;
				case types::BOOL:
					return 1;
				case types::STRING:
					return 2;
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
					case types::STRING:
						return 2;
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

	if(type == "string")
		return 2;

	return -1;
}