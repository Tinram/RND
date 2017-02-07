
# RND

### Random data generator.


##### RND v.1.2

##### Linux and Windows


## Purpose

Flexibly generate random data:

1. Specific file size (e.g. 607 bytes, 10MB) for integrity, processing, hashing, network, and benchmarking tests (creating non-sparse files).
2. Random restricted range ASCII character stream.
3. ASCII control characters.
4. Random or pre-defined text as content filler.
5. File overwrites to the exact byte count.
6. Long password strings.

Additionally, create specific data:

1. Specific character sequence.
2. Character range sequence.
3. Unicode character range sequence.


## OS Support

+ Linux
+ Linux ARM6
+ Windows


## Usage

    rnd.exe or rnd       (Windows)        display command-line options
    ./rnd                (Linux)


### Options

    rnd -c [number of bytes (or: 1K, 1M, 1G)] [low_character high_character] [file]
    rnd -s [number] ["text to output"] [file]
    rnd -b <num,num,num,num, ...> [file]
    rnd -b <low_character>-<high_character> [file]
    rnd -u <low_character>-<high_character>
    rnd -p
    rnd -a

           - square brackets denote optional commands
           - all numbers must be in decimal


### Usage Examples


#### ASCII List

    rnd -a               list the 8-bit ASCII character table, 0 to 255
                         (0 to 31 are displayed as control code acronyms)
                         (127 to 255 are not printable on a Linux terminal; however, 'rnd -u 128-255' will display some)


#### Characters

    rnd -c                                  output 255 random characters in the range ! to ~ (33 to 126) on the command-line
    rnd -c 100                              100 characters in the range ! to ~
    rnd -c 100 49 57                        100 characters in the range 1 to 9
    rnd -c 672 97 122 > test.txt            output a 672 byte file containing random characters in the range a to z
    rnd -c 1k 97 122 > test.txt             a 1kB (1024 bytes) file containing a to z (suffix is case insensitive)
    rnd -c 10M 65 90 dump.txt               output a 10MB file called dump.txt containing characters A to Z, using a fast file dump
                                                (much faster than redirecting output, BUT the generated data is NOT cryptographically secure [fast non-crypto random number generator used])

    rnd -c 1k 0 255 | ent                   pipe 1kB of random characters to 'ent', an entropy checking program
    rnd -c 1k 0 255 | nc 192.168.1.20 80    pipe 1kB of characters to 'netcat' to send to 192.168.1.20 on port 80 (test web server response)
    rnd -c 1k 65 90 | nc 192.168.1.20 80    same as above, but with A to Z, triggering an HTTP 501 in Apache/2.4.16

    rnd -p                                  quick option to generate a 32-character password (! to ~)


#### Strings

    rnd -s                                  255 instances of the text string 'lorem ipsum '
    rnd -s 100                              100 instances of 'lorem ipsum '
    rnd -s 100 "test text "                 100 instances of any chosen text (if text contains spaces, the string must be quoted)
    rnd -s 10000 test dump.txt              output a file called dump.txt containing 10,000 instances of 'test' using a fast file dump
                                                (some string patterns may corrupt when viewing in some editors)


#### Bytes

    rnd -b 82,78,68,13,10                   output 'RND<CR><LF>'
    rnd -b 82|78|68|13|10                   'RND<CR><LF>' ('|' as an alternative delimiter, ';' also supported)
    rnd -b 82,78,68,13,10 test.txt          'RND<CR><LF>' to a file called text.txt
    rnd -b 0-31                             0 to 31 control characters
    rnd -b 0-255                            all ASCII 8-bit characters


#### Unicode Bytes

    rnd -u 2000-2001                        Unicode multi-byte output of characters 2000 and 2001
    rnd -u 33-255                           display characters 33 to 255 (multi-byte: 892 bytes total)
    rnd -u 256-1500                         display characters 256 to 1500 (correct rendering dependent on installed character sets)
    rnd -u 8000-10000 > chars.txt           redirect characters 8000 to 10000 to a file called chars.txt
                                                (NotePad2 and Geany render and zoom such character files)
    rnd -u 240-255 | nc localhost 80        pipe byte sequence to 'netcat' to send to localhost, triggering an HTTP 400 in Apache/2.4.16


#### Version

    rnd -v


###### WARNING: For both of the fast file dump options, be careful of the amount of data generated in regards to the available memory of your PC (especially on 32-bit systems: ~3.25GB max; Windows: 1.8GB memory heap) and the age and performance of your hard-drive.


## Other

07 (BEL) is the bell code and usually creates audible noise in the Windows terminal. Low random characters can contain many 07. As well as noise, low characters can cause the terminal to lock or crash (especially on Windows).

RND generates pseudo-random data via the Win32 Crypto API or */dev/urandom* on Linux (**except** when using the *fast file dump* options). Providing the relevant API is available on the target system, the generated data should be suitable for cryptographic purposes. However, if the API is not available, RND will switch to the Mersenne Twister algorithm. Despite the strengths of this algorithm, it is not suitable for cryptographic purposes.


## Build

Install [FreeBASIC](http://www.freebasic.net/forum/viewforum.php?f=1) compiler (fbc).

(RND can be compiled with either x32 or x64 version of fbc.)

Ensure GCC is available: `whereis gcc`


### Linux

    make

or full process:

    make && make install


### Windows / Compile Manually

    fbc rnd.bas -gen gcc -O max


## Other

On both Linux and Windows, it's more convenient for RND to be available from any directory location via the PATH system variable (rather than copying the executable file to the directory where needed).


### Linux

    make install

Or move the *rnd* executable to a location such as */usr/local/bin* (location must be present in $PATH).


### Windows

[Windows key + Break] > Advanced tab > Environmental Variables button > click Path line > Edit button > Variable value - append at the end of existing line info: *C:\directory\path\to\rnd.exe\;*


## License

RND is released under the [GPL v.3](https://www.gnu.org/licenses/gpl-3.0.html).
