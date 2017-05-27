CC = gcc
CFLAGS = -g -Wall -Wextra
args = -f text.txt -t 1 -u s

manager : manager.o
	$(CC) $(CFLAGS) -o manager manager.o 

manager.o : manager.c
	$(CC) $(CFLAGS) -c manager.c 
run :
	./manager $(args)

	
clean : 
	rm *.o

# DO NOT DELETE

manager.o: /usr/include/stdlib.h /usr/include/features.h
manager.o: /usr/include/stdc-predef.h /usr/include/alloca.h
manager.o: /usr/include/stdio.h /usr/include/libio.h /usr/include/_G_config.h
manager.o: /usr/include/wchar.h /usr/include/unistd.h /usr/include/getopt.h
manager.o: /usr/include/errno.h /usr/include/time.h
