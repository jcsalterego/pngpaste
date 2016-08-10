pngpaste
========

Paste PNG into files, much like `pbpaste` does for text.

However instead of `pngpaste > thefile.png`, it's `pngpaste thefile.png`,
so one does not accidentally barf binary into the console.

### Motivation

[http://apple.stackexchange.com/q/11100/4795](http://apple.stackexchange.com/q/11100/4795)

### Installation

You can install via `brew`:

    $ brew install pngpaste

or from source code:

    $ git clone https://github.com/jcsalterego/pngpaste
    $ cd pngpaste
    $ make all
    $ sudo make install

### Usage

    $ pngpaste hooray.png

### Error Handling

Minimal :'(
