
'----------------------------------------------------------------------------------------------
'
' rnd.bas
'
' Purpose:      Random data generator (crypto-secure) and large file dump (non-crypto-secure).
' Copyright:    Martin Latter, June 2012.
' Version:      1.2
' License:      GNU GPL version 3.0 (GPL v3); http://www.gnu.org/licenses/gpl.html
' URL:          https://github.com/Tinram/RND.git
'
'----------------------------------------------------------------------------------------------


DECLARE SUB charGenerate(BYREF sPassGen AS CONST STRING = "")
DECLARE SUB byteSequenceGenerate()
DECLARE SUB unicodeSequenceGenerate()
DECLARE SUB stringGenerate()
DECLARE SUB displayAsciiCodes()
DECLARE SUB fallThrough()
DECLARE SUB standarderr(BYREF sMessage AS CONST STRING, BYVAL iEndPrint AS UINTEGER = 1)
DECLARE SUB inputDeath(BYVAL f AS UINTEGER = 0)
DECLARE SUB displayOptions()


#INCLUDE "includes/subs.bas"

CONST AS STRING RND_VERSION = "1.2.2.0"

#IFDEF __FB_64BIT__
	CONST AS STRING ARCH = "x64"
#ELSE
	CONST AS STRING ARCH = "x32"
#ENDIF

DIM AS STRING sCommand = LCASE(COMMAND(1))


'--------------------------
' MAIN
'--------------------------

IF sCommand = "-v" OR sCommand = "v" THEN

	PRINT
	PRINT "RND v." + RND_VERSION
	PRINT __DATE_ISO__
	PRINT
	PRINT "FBC v." + __FB_VERSION__ + " " + ARCH + " (" + UCASE(__FB_BACKEND__) + ")"
	#IFDEF __FB_UNIX__
		PRINT
	#ENDIF

ELSEIF sCommand = "" THEN

	displayOptions()

ELSEIF sCommand = "-c" THEN

	charGenerate()

ELSEIF sCommand = "-p" THEN

	charGenerate("passgen")

ELSEIF sCommand = "-b" THEN

	byteSequenceGenerate()

ELSEIF sCommand = "-u" THEN

	unicodeSequenceGenerate()

ELSEIF sCommand = "-s" THEN

	stringGenerate()

ELSEIF sCommand = "-a" THEN

	displayAsciiCodes()

ELSE

	fallThrough()

END IF

'--------------------------
