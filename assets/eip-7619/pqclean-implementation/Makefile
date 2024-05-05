# Based on PQClean https://github.com/PQClean/PQClean/tree/master/crypto_sign/falcon-512/clean
# This Makefile can be used with GNU Make or BSD Make

LIB=libfalcon-512_clean.a

SOURCES = codec.c common.c fft.c normalizer.c keygen.c pqclean.c rng.c sign.c verify-signature.c
OBJECTS = codec.o common.o fft.o normalizer.o keygen.o pqclean.o rng.o sign.o verify-signature.o
HEADERS = api.h normalizer.h inner.h

CFLAGS=-std=c99 -O2 -W -Wall -Wconversion -Wextra -Wpedantic -Wvla -Werror -Wmissing-prototypes -Wredundant-decls -I../../../common $(EXTRAFLAGS)

all: $(LIB)

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -c -o $@ $<

$(LIB): $(OBJECTS)
	$(AR) -r $@ $(OBJECTS)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(LIB)
