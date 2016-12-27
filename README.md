pngpaste
========

Paste PNG into files, much like `pbpaste` does for text.

However instead of `pngpaste > thefile.png`, it's `pngpaste thefile.png`,
so one does not accidentally barf binary into the console.

### Motivation

[http://apple.stackexchange.com/q/11100/4795](http://apple.stackexchange.com/q/11100/4795)

### Build

    $ make all

### Installation

From source:

    $ make all
    $ sudo make install

Or with Homebrew:

    $ brew install pngpaste

### Usage

    $ pngpaste hooray.png

### Bonus and Disclaimers

Supported input formats are PNG, PDF, GIF, TIF, JPEG.

Supported output formats are PNG, GIF, JPEG, TIFF.

Output formats are determined by the provided filename extension,
falling back to PNG.

It's unclear if EXIF data in JPEG sources are preserved. There's an
issue with pasting into JPEG format from a GIF source.

### Error Handling

Minimal :'(
