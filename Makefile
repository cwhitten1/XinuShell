all:
	flex prac.l;
	yacc -d prac.y ;
	cc lex.yy.c y.tab.c command.c path_handle.c io_redir.c envar.c cmdcode.c main.c -o run
clean:
	rm -rf *o run