#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "envar.h"

extern char **environ;

void print_env();
void change_dir();
void set_env(char* env_var, char* val);
void unset_env(char* env_var);
void show_aliases();
void set_alias();
void unset_alias();
int is_alias();
char* get_alias_cmd();