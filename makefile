
# makefile for RND

CC = fbc
CFLAGS = -gen gcc -O max -w all
NAME = rnd
INPUTLIST = rnd.bas


rnd:
	$(CC) $(CFLAGS) $(INPUTLIST) -x $(NAME)

install:
	sudo cp $(NAME) /usr/local/bin/$(NAME)
	@echo "Attempted to copy $(NAME) to /usr/local/bin"
