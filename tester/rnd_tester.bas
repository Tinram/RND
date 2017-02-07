
'--------------------------------------------------------------------------------------------------------
'
' rnd_tester.bas
'
' Purpose:      Batch command-line parameter testing of RND executable.
' Output:       View file dumps produced in a robust text editor such as VIM or NotePad++ (not NotePad).
'               All file outputs as direct file dump, not a redirect.
' Compile:      fbc rnd_tester.bas -gen gcc -O max
' Copyright:    Martin Latter.
' License:      GNU GPL version 3.0 (GPL v3); http://www.gnu.org/licenses/gpl.html
' URL:          https://github.com/Tinram/RND.git
'
'--------------------------------------------------------------------------------------------------------


CONST AS STRING EXECUTABLE_NAME = "rnd"


#INCLUDE "dir.bi"


#IFDEF __FB_UNIX__
	CONST AS STRING EXE = "./" + EXECUTABLE_NAME ' execute in same directory as rnd
	CONST AS STRING REALEXENAME = EXECUTABLE_NAME
	CONST AS STRING DIRSEP = "\"
#ENDIF

#IFDEF __FB_WIN32__
	CONST AS STRING EXE = EXECUTABLE_NAME + ".exe"
	CONST AS STRING REALEXENAME = EXE
	CONST AS STRING DIRSEP = "/"
#ENDIF


CONST AS BYTE attrib_mask = FBDIRECTORY
CONST AS BYTE attrib_mask2 = FBNORMAL
CONST AS STRING SEPARATOR = "-------------------------------------------------"
CONST AS STRING FILE_DIR = "rnd_test_files"
CONST AS STRING PATH = FILE_DIR + DIRSEP


DIM AS INTEGER iResult, iDirCreated, iFileExists = 0
DIM AS UINTEGER i
DIM AS STRING sDirMatch = DIR(FILE_DIR, FBDIRECTORY)
DIM AS STRING sFileMatch = DIR(REALEXENAME, FBNORMAL)


' check for executable file existence
IF sFileMatch = REALEXENAME THEN
	iFileExists = 1
END IF

IF 1 <> iFileExists THEN
	PRINT "Error: " + REALEXENAME + " executable does not exist in this folder."
	END
END IF


' create new folder or use existing if present
IF sDirMatch = FILE_DIR THEN
	iDirCreated = 0
ELSE
	iDirCreated = MKDIR(FILE_DIR)
END IF

IF 0 <> iDirCreated THEN
	PRINT "Error: unable to create test file folder."
	END
END IF


DIM AS STRING aArgs(0 TO ...) = {_
	_
	"-a",_ ' ASCII 8-bit table dump
	_
	"-b 82,78,68,13,10",_ ' RND<CR><LF>
	"-b 82,78,68,13,10 " + PATH + "bytes1.txt",_ ' RND<CR><LF> to file
	"-b 82,78,68,13,10, " + PATH + "bytes2.txt",_ ' RND<CR><LF> to file, despite trailing delimiter
	"-b 82,78,68,13,10,, ",_ ' error: duplicate separator found
	"-b 82,78,,68,13,10 ",_ ' error: duplicate separator found
	"-b 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31 " + PATH + "controlcode_seq_literal.txt",_
	"-b 0-31 " + PATH + "controlcode_seq_range1.txt",_ ' 0-31 control character range (view with: xxd -i controlcode_seq_range1.txt)
	"-b 0-255 " + PATH + "controlcode_seq_range2.txt",_ ' 0-255 character range
	_
	"-c",_ ' 255 random printable characters 33-126 (! to ~)
	"-c 38",_ ' 38 random characters 33-126
	"-c 38 49 57",_ ' 38 random characters 49-57 (0-9)
	"-c 38 65 90",_ ' 38 random characters 65-90 (A-Z)
	"-c 38 0 255",_ ' 38 random characters 0-255
	"-c 0 45 90",_ ' error: 0 (characters to be generated) is not a number
	"-c 0",_ ' error: 0 is not a number
	"-c 38 50 40",_ ' error: [high] is less than [low]
	"-c 38 -2 -5",_ ' negative made positive by program, 38 random characters 2-5
	"-c 1k 0 0 " + PATH + "nulls.txt",_ ' 1kB of nulls (0) to file (use xxd -i nulls.txt)
	"-c 1k 0 31 " + PATH + "controlcodes.txt",_ ' 1kB of random control codes (0-31) to file
	"-c 672 65 90 " + PATH + "672_bytes.txt",_ ' 672 bytes of A-Z to file
	"-c 1k 33 126 " + PATH + "ascii_7bit.txt",_ ' 1kB of random 7-bit ASCII printable characters (33-126) to file
	"-c 1k 33 255 " + PATH + "latin1_8bit.txt",_ ' 1kB of random 8-bit ASCII characters (33-255) to file
	"-c 1k 33 1024 " + PATH + "highchars.txt",_ ' single byte output in multi-byte realm to file
	_
	"-p",_ ' 32-character password, printable characters 33-126
	_
	"-s",_ ' 255x 'lorem ipsum '
	"-s 5 test",_ ' 5x 'test'
	"-s -2",_ ' 2x 'lorem ipsum '
	"-s 4 -2",_ '-2-2-2-2'
	"-s 0",_ ' error: 0 is not a number
	"-s 255 test " + PATH + "stringtest.txt",_ ' 255x 'test' to file
	"-s 1k",_ ' = 1x 'lorem ipsum '
	_
	"-u",_ ' error: no hyphen found in the parameter (no range given)
	"-u -",_ ' error: character range cannot start with a hyphen
	"-u -z",_ ' error: character range cannot start with a hyphen
	"-u -40",_ ' error: character range cannot start with a hyphen
	"-u 40-",_ ' error: no high character (high character is less than low character)
	"-u 40-1",_ ' error: high character is less than low character
	"-u 2000-2000",_ ' error: not possible for character range to be the same character
	"-u 2000-2001",_ ' multi-byte Unicode output of characters 2000 and 2001
	"-u 33-255",_ ' Unicode output of characters 33-255 in Linux terminal (rather than usual mangled ASCII 8-bit > character 127)
	"-u 256-1500",_ ' Unicode output of characters 256-1500 (character rendering dependent on installed character sets)
	"-u 8000-10000"_ ' Unicode output of characters 8000-10000, displaying some common emojis
}


PRINT SEPARATOR
PRINT


FOR i = 0 TO UBOUND(aArgs)

	PRINT
	PRINT aArgs(i)
	PRINT

	iResult = EXEC(EXE, aArgs(i))

	IF iResult > -1 THEN
		PRINT SEPARATOR
	ELSE
		PRINT "executable failed"
	END IF

NEXT i
