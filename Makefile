
all:
	$(CC) -Wall -g -O3 -ObjC \
		-framework Foundation -framework AppKit \
		-o pngpaste \
		pngpaste.m

	$(CC) -Wall -g -O3 -ObjC \
		-framework Foundation -framework AppKit \
		-o pngcopy \
		pngcopy.m

install: all
	cp pngpaste /usr/local/bin/
	cp pngcopy /usr/local/bin/

clean:
	rm -rfv *~ #*# *.o
	rm -rfv *.dSYM/ pngpaste pngcopy
