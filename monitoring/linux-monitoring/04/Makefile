CC=gcc
FLAGS=-std=c11
NAME=getlog


all: install run read

install:
	@$(CC) $(FLAGS) generate_log.c -o $(NAME)

run:
	@./getlog

read: 
	@less access0.log

clean:
	@rm -rf *.log getlog