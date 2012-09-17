
all:
	$(CC) -Wall -g -O3 -ObjC \
		-framework Foundation -framework AppKit \
		-o pngpaste \
		pngpaste.m
install: all
	cp pngpaste /usr/local/bin/
clean:
	find . \( -name '*~' -or -name '#*#' -or -name '*.o' \
		  -or -name 'pngpaste' -or -name 'pngpaste.dSYM' \) \
		-exec rm -rfv {} \;
	rm -rfv *.dSYM/ pngpaste;
