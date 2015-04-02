#include <stdio.h>
#include <stdlib.h>
#include "y.tab.h"
#include "command.h"
#include "envar.h"

struct command commands[MAX_COMMANDS];

void printShellSymbol()
{
        printf(":p > ");
} 

void shell_init(){ 
	//Initialize global vars
	exitRequested = 0;
	PATH = getenv("PATH");
	HOME = getenv("HOME");
	PWD = getenv("PWD");
	printf("PATH: %s\n", PATH);
	printf("HOME: %s\n", HOME);
	printf("PWD: %s\n", PWD);

}

int main()
{
	shell_init();
	while(!exitRequested)
	{
	    printShellSymbol();
	    yyparse();
	}

}



