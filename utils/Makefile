CC = gcc
TARGETS = asc2kim5 kim52asc

all: $(TARGETS)

asc2kim5: asc2kim5.c
	$(CC) -o $@ $^

kim52asc: kim52asc.c
	$(CC) -o $@ $^

clean:
	rm -f $(TARGETS)
