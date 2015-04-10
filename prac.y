%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdarg.h>
#include "command.h"
#include "envar.h"
#include "cmdcode.h"
#include "alias.h"
#include "io_redir.h"


//int yydebug=1;

int cmdtab_curr = 0;
int cmdtab_start = 0;
int appendOutputRequested = 0;

char* first_cmd;
char* PIPE = "PIPE";

void yyerror(const char *str)
{
        flush_buffer();
        fprintf(stderr,"\terror: %s\n",str);
}
 
int yywrap()
{
        return 1;
}

void addCommand(char* name, int cmd_id, int argnum, ...)
{
        int cmd_ind = cmdtab_curr % MAX_COMMANDS;
        struct command *cmd = &commands[cmd_ind];
        cmd->name = name;
        cmd->cmd_id = cmd_id;
        cmd->argnum = argnum;

        va_list args;
        va_start(args, argnum);
        int i;
        for(i = 0; i < argnum; i++){
                cmd->args[i] = va_arg(args, char*);
        }
        va_end(args);
}

void addInputRedirection(int cmd_index, char* in_fn)
{
        struct command *cmd = &commands[cmd_index];
        cmd->infile = in_fn;
}       

void addOutputRedirection(int cmd_index, char* out_fn, int appendOut)
{
        struct command *cmd = &commands[cmd_index];
        cmd->outfile = strdup(out_fn);
        cmd->appendOut = appendOut;
}       

%}


%token <string> TOKCD
%token <string> TOKSETENV TOKCLEARENV TOKPRINTENV
%token <string> TOKALIAS TOKUNALIAS
%token <string> TOKQUOTE
%token <string> TOKBYE 
%token TOKENDEXP TOKPIPE TOK_IO_REDIR_IN TOK_IO_REDIR_OUT TOK_IO_REDIR_OUT_APPEND


%union 
{
        int number;
        char *string;
}

%token <number> NUMBER
%token <string> WORD

%type<string> io_redir_in
%type<string> io_redir_out
%type<string> io_redir_out_append
%type<string> io_redir

%start line

%%
line: /* empty */ 
        |
        TOKENDEXP 
        {
                YYACCEPT;
        }
        |
        commands TOKENDEXP 
        {      
                YYACCEPT;
        }
        |
        commands io_redir TOKENDEXP 
        {
                if(appendOutputRequested)
                        addOutputRedirection(cmdtab_curr, $2, 1);
                else
                        addOutputRedirection(cmdtab_curr, $2, 0);

                YYACCEPT;
        }
        |
        default TOKENDEXP{
                if(is_alias(first_cmd) == 1){

                    scan_string(get_alias_cmd(first_cmd));
                }
                else
                {
                    printf("\tCommand %s not recognized\n", first_cmd);
                    YYERROR;
                }

                first_cmd = NULL;
                YYACCEPT;
                }
        ;

commands: 
        command 
        | 
        commands TOKPIPE 
        {
                addOutputRedirection(cmdtab_curr, "PIPE", 0);
                ++cmdtab_curr; 
                addInputRedirection(cmdtab_curr, "PIPE");
        } command 
        ;

command:
        change_dir 
        |
        change_dir_home
        |
        set_env_var
        |
        unset_env_var
        |
        print_env_var
        |
        show_aliases
        |
        set_alias
        |
        unset_alias
        |
        bye
        |
        quote
        ;

change_dir:
        TOKCD WORD
        {
                addCommand("CD", CD, 1, $2);
        }

change_dir_home:
        TOKCD
        {
                addCommand("CD", CD, 1, HOME);
        }
        ;
        
set_env_var:
        TOKSETENV WORD WORD
        {
                addCommand("SETENV", SETENV, 2, $2, $3);
        }
        ;

unset_env_var:
        TOKCLEARENV WORD
        {
                addCommand("UNSETENV", UNSETENV, 1, $2);
                
        }
        ;

print_env_var:
        TOKPRINTENV
        {
                addCommand("PRINTENV", PRINTENV, 0);
                
        }
        ;

show_aliases:
        TOKALIAS
        {
                addCommand("SHOW_ALIAS", SHOW_ALIAS, 0);
                  
        }
        ;

set_alias:
        TOKALIAS WORD WORD
        {
               addCommand("SET_ALIAS", SET_ALIAS, 2, $2, $3);
                
        }
        |
        TOKALIAS WORD TOKCD
        {
                addCommand("SET_ALIAS", SET_ALIAS, 2, $2, $3);
                
        }
        |
        TOKALIAS WORD TOKSETENV
        {
                addCommand("SET_ALIAS", SET_ALIAS, 2, $2, $3);
                
        }
        |
        TOKALIAS WORD TOKCLEARENV
        {
                addCommand("SET_ALIAS", SET_ALIAS, 2, $2, $3);
                
        }
        |
        TOKALIAS WORD TOKPRINTENV
        {
                addCommand("SET_ALIAS", SET_ALIAS, 2, $2, $3);
                
        }
        |
        TOKALIAS WORD TOKALIAS
        {
                addCommand("SET_ALIAS", SET_ALIAS, 2, $2, $3);
                
        }
        |
        TOKALIAS WORD TOKUNALIAS
        {
                addCommand("SET_ALIAS", SET_ALIAS, 2, $2, $3);
                
        }
        |
        TOKALIAS WORD TOKBYE
        {
                addCommand("SET_ALIAS", SET_ALIAS, 2, $2, $3);
                
        }
        ;

unset_alias:
        TOKUNALIAS WORD
        {
                addCommand("UNALIAS", UNSET_ALIAS, 1, $2);
                
        }
        ;

bye:
        TOKBYE
        {
                addCommand("BYE", BYE, 0);    
        }

quote:
        TOKQUOTE
        {
        }
        ;

io_redir:
        io_redir_in io_redir_out 
        {
                addInputRedirection(cmdtab_start, $1); //Add input redir to start command
                $$ = $2; //We don't know the final ending command index so we don't do output redir yet.
        }
        |
        io_redir_in io_redir_out_append
        {
                addInputRedirection(cmdtab_start, $1);
                $$ = $2; 
        }
        |
        io_redir_out io_redir_in
        {
                addInputRedirection(cmdtab_start, $2);
                $$ = $1; 
        }
        |
        io_redir_out_append io_redir_in
        {
                addInputRedirection(cmdtab_start, $2);
                $$ = $1; 
        }
        |
        io_redir_in
        {
                addInputRedirection(cmdtab_start, $1);
        }
        | 
        io_redir_out
        {
                $$ = $1; 
        }
        |
        io_redir_out_append
        {
                $$ = $1; 
        }
        ;

io_redir_in:
        TOK_IO_REDIR_IN WORD
        {
               $$ = $2;
        }
        ;

io_redir_out:
        TOK_IO_REDIR_OUT WORD
        {
               $$ = $2;
        }

io_redir_out_append:
        TOK_IO_REDIR_OUT_APPEND WORD
        {
                appendOutputRequested = 1;
                $$ = $2;
        }
        ;

default:
        default WORD
        |
        WORD
        {
                if(first_cmd == NULL)
                        first_cmd = $1;
        }
        ;
        
%%