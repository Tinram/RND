
'-----------------------------------------------------------------------------------
'
' subs.bas
'
' Purpose:      Subroutines for rnd.bas
' Copyright:    Martin Latter, June 2012.
' Updated:      August 2023.
' License:      GNU GPL version 3.0 (GPL v3); https://www.gnu.org/licenses/gpl-3.0.html
' URL:          https://github.com/Tinram/RND.git
'
'-----------------------------------------------------------------------------------


SUB charGenerate(BYREF sPassGen AS CONST STRING)

	' subroutine to generate character output either as a stream or as a file

	DIM AS STRING sResult, sOutFile, sSizeChar, sPartNum, sCommand2 = COMMAND(2), sCommand3 = COMMAND(3), sCommand4 = COMMAND(4), sCommand5 = COMMAND(5)
	DIM AS UINTEGER i, iLowChar = 33, iHighChar = 126, iFileDump = 0
	DIM AS INTEGER iFreeFile
	DIM AS LONGINT iLimit = 255 ' 64-bit int; int and abs() safer than uint and culngint() (-ve value undefined)
	DIM AS UBYTE PTR p
	' DIM AS DOUBLE t1, t2 ' enable related comments for dev timing

	IF sPassGen = "passgen" THEN ' generate a 32-character password conveniently
		iLimit = 32
	END IF

	IF sCommand5 <> "" THEN
		iFileDump = 1
		sOutFile = sCommand5 ' 5th parameter for -c
	END IF

	IF sCommand2 <> "" THEN

		sSizeChar = LCASE(RIGHT(sCommand2, 1))

		IF sSizeChar = "k" OR sSizeChar = "m" OR sSizeChar = "g" THEN ' test for size character

			sPartNum = MID(sCommand2, 1, LEN(sCommand2) - 1)

			iLimit = ABS(CLNGINT(sPartNum))

			IF sSizeChar = "k" THEN iLimit = 1024 * iLimit
			IF sSizeChar = "m" THEN iLimit = 1024 * 1024 * iLimit
			IF sSizeChar = "g" THEN iLimit = 1024 * 1024 * 1024 * iLimit
				' easy to create 1GB+ file but beware RAM allocation for low memory PCs: see SPACE(iLimit) later
				' Windows: max 1.8GB file [as "m" MB option] thanks to 32-bit exe heap allocation
		ELSE

			iLimit = ABS(CLNGINT(sCommand2))

		END IF

	END IF

	IF iLimit = 0 THEN
		inputDeath(0)
		EXIT SUB
	END IF

	IF sCommand3 <> "" OR sCommand4 <> "" THEN

		iLowChar = ABS(CUINT(sCommand3))
		iHighChar = ABS(CUINT(sCommand4))

		IF iHighChar = 0 THEN
			IF iLowChar <> 0 THEN ' allow character 0 (NULL) to be created (-c 1k 0 0)
				inputDeath(1)
				EXIT SUB
			END IF
		ELSEIF iHighChar < iLowChar THEN
			inputDeath(2)
			EXIT SUB
		END IF

	END IF

	IF iFileDump = 0 THEN ' stream output

		RANDOMIZE(TIMER * 5000), 5 ' FB crypto random number generator (Win32 Crypto API, Linux /dev/urandom) - expensive operation: use here only when required

		' t1 = TIMER

		sResult = SPACE(iLimit)

		i = 0

		DO WHILE i < iLimit
			sResult[i] = CUINT(RND * (iHighChar - iLowChar) + iLowChar)
				' CUINT used: > 255 ASCII still possible; CUBYTE would return undefined
			i += 1
		LOOP

		IF sPassGen <> "passgen" THEN
			PRINT sResult;
		ELSE
			PRINT sResult ' line break for password output
		END IF

		CLEAR sResult[0], 0, iLimit

		' t2 = TIMER
		' PRINT t2 - t1

	ELSE ' file output (must be UBYTE; pointer is just over 2x faster than > redirect)

		iFreeFile = FREEFILE()

		RANDOMIZE(TIMER * 10000), 2 ' FB fast random number generator (~70x faster RND char operations than RANDOMIZE, 5)

		' t1 = TIMER

		iLimit += 1 ' to get right number of chars, without compromising -1 in pointer calculations below

		p = ALLOCATE(iLimit * SIZEOF(UBYTE)) ' using a memory block allocation is just slightly faster than an array buffer, even with a *CAST to 0

		IF (0 = p) THEN
			standarderr("Error: unable to allocate sufficient memory - quitting.")
			EXIT SUB
		END IF

		i = 0

		DO WHILE i < (iLimit - 1)
			p[i] = RND * (iHighChar - iLowChar) + iLowChar ' implicit cast
				' = CUBYTE(RND * (iHighChar - iLowChar) + iLowChar) ' (a bottleneck when using RANDOMIZE TIMER, 5)
			i += 1
		LOOP

		IF (OPEN(sOutFile, FOR BINARY ACCESS WRITE, AS #iFreeFile) <> 0) THEN
			standarderr("Error creating output file!")
			DEALLOCATE(p) ' avoid memory leak
			p = 0
			EXIT SUB
		END IF

		PUT #iFreeFile, 0, p[0], iLimit - 1
		CLOSE #iFreeFile

		DEALLOCATE(p)
		p = 0

		' t2 = TIMER
		' PRINT t2 - t1

	END IF

END SUB


SUB byteSequenceGenerate()

	' subroutine to generate a byte sequence either as a stream or as a file

	DIM AS STRING sDelimiter, sLast, sByteHold, sByteSeq = COMMAND(2), sOutfile = COMMAND(3)
	DIM AS INTEGER iDuplicate = 0, iPosition = 0, iFreeFile
	DIM AS UINTEGER i = 0, iLastMatch = 1, iCounter = 0, iByteCounter = 0, iFileDump = 0, iCharRange = 0, iLow = 0, iHigh = 0
	DIM AS UBYTE PTR p

	IF sByteSeq = "" THEN
		standarderr("No byte sequence string or numerical character range provided.")
		EXIT SUB
	END IF

	IF sOutfile <> "" THEN iFileDump = 1

	' byte delimiter can be comma, semi-colon, or pipe (last two: complete string must be quoted)
	IF INSTR(sByteSeq, ",") THEN
		sDelimiter = ","
	ELSEIF INSTR(sByteSeq, ";") THEN
		sDelimiter = ";"
	ELSEIF INSTR(sByteSeq, "|") THEN
		sDelimiter = "|"
	ELSEIF INSTR(sByteSeq, "-") THEN
		sDelimiter = "-"
		iCharRange = 1
	ELSE
		standarderr("No string delimiter or hyphen found in the parameter after -b")
		EXIT SUB
	END IF

	iDuplicate = INSTR(sByteSeq, (sDelimiter + sDelimiter))

	IF iDuplicate THEN
		standarderr("Malformed sequence string: duplicate separator found.")
		EXIT SUB
	END IF


	IF iCharRange = 0 THEN ' byte sequence string

		' count separators (+1) for allocate()
		iPosition = INSTR(sByteSeq, sDelimiter)

		IF iPosition = 1 THEN
			standarderr("Byte sequence string cannot start with a separator.")
			EXIT SUB
		END IF

		DO WHILE iPosition > 0
			iPosition = INSTR(iPosition + 1, sByteSeq, sDelimiter)
			iByteCounter += 1
		LOOP

		iPosition = INSTR(sByteSeq, sDelimiter)

		p = ALLOCATE((iByteCounter + 1) * SIZEOF(UBYTE))
		''

		IF (0 = p) THEN
			standarderr("Error: unable to allocate sufficient memory - quitting.")
			EXIT SUB
		END IF

		DO WHILE iPosition > 0
			sByteHold = MID(sByteSeq, iLastMatch, iPosition - iLastMatch)
			IF LEN(sByteHold) > 3 THEN
				standarderr("Malformed byte sequence string: invalid character found.")
				EXIT SUB
			END IF
			p[iCounter] = CUBYTE(sByteHold)
			iLastMatch = iPosition + 1
			iPosition = INSTR(iPosition + 1, sByteSeq, sDelimiter)
			iCounter += 1
		LOOP

		sLast = MID(sByteSeq, iLastMatch)

		IF sLast <> "" THEN
			p[iCounter] = CUBYTE(sLast)
		ELSE
			iCounter -= 1
		END IF

	ELSE ' character range low to high

		iPosition = INSTR(sByteSeq, sDelimiter)

		IF iPosition = 1 THEN
			standarderr("Character range cannot start with a minus / hyphen.")
			EXIT SUB
		END IF

		iLow = ABS(CUINT(LEFT(sByteSeq, iPosition - 1)))
		iHigh = ABS(CUINT(MID(sByteSeq, iPosition + 1)))

		IF iHigh < iLow THEN
			inputDeath(3)
			EXIT SUB
		END IF

		IF iHigh > 255 THEN
			inputDeath(4)
			EXIT SUB
		END IF

		IF iLow = iHigh THEN
			standarderr("Not possible for character range to be the same character.") ' bail before memory corruption via 1 byte allocation
			EXIT SUB
		END IF

		p = ALLOCATE(((iHigh - iLow) + 1) * SIZEOF(UBYTE))

		IF (0 = p) THEN
			standarderr("Error: unable to allocate sufficient memory - quitting.")
			EXIT SUB
		END IF

		FOR i = iLow TO iHigh
			p[iCounter] = CUBYTE(i)
			iCounter += 1
		NEXT i

		iCounter -=1

	END IF


	IF iFileDump = 0 THEN ' stream output

		FOR i = 0 TO iCounter
			PRINT CHR(p[i]);
		NEXT i

	ELSE ' file output

		iFreeFile = FREEFILE()

		IF (OPEN(sOutFile, FOR BINARY ACCESS WRITE, AS #iFreeFile) <> 0) THEN
			standarderr("Error creating output file!")
			DEALLOCATE(p) ' avoid memory leak
			p = 0
			EXIT SUB
		END IF

		PUT #iFreeFile, 0, p[0], iCounter + 1
		CLOSE #iFreeFile

	END IF

	DEALLOCATE(p)
	p = 0

END SUB


SUB unicodeSequenceGenerate()

	' subroutine to generate a unicode sequence as a stream
	' file output is temperamental - some characters interfere with output
	' (WSTRING is fixed length, cannot be created at runtime)

	DIM AS STRING sDelimiter = "-", sLast, sByteHold, sByteSeq = COMMAND(2)
	DIM AS INTEGER iDuplicate = 0, iPosition = 0
	DIM AS UINTEGER i = 0, iCounter = 0, iChars = 0, iLow = 0, iHigh = 0
	DIM AS WSTRING PTR p

	IF sByteSeq = "" THEN
		standarderr("No numerical character range provided.")
		EXIT SUB
	END IF

	IF INSTR(sByteSeq, sDelimiter) = 0 THEN
		standarderr("No hyphen found in the parameter after -u")
		EXIT SUB
	END IF

	iDuplicate = INSTR(sByteSeq, (sDelimiter + sDelimiter))

	IF iDuplicate THEN
		standarderr("Malformed sequence string: duplicate separator found.")
		EXIT SUB
	END IF

	iPosition = INSTR(sByteSeq, sDelimiter)

	IF iPosition = 1 THEN
		standarderr("Character range cannot start with a hyphen.")
		EXIT SUB
	END IF

	iLow = ABS(CUINT(LEFT(sByteSeq, iPosition - 1)))
	iHigh = ABS(CUINT(MID(sByteSeq, iPosition + 1)))

	IF iHigh < iLow THEN
		inputDeath(3)
		EXIT SUB
	END IF

	IF iLow = iHigh THEN
		standarderr("Not possible for character range to be the same character.")
		EXIT SUB
	END IF

	iChars = (iHigh - iLow)
	p = ALLOCATE(iChars * LEN(WSTRING) + 5) ' 5 extra bytes needed

	IF (0 = p) THEN
		standarderr("Error: unable to allocate sufficient memory - quitting.")
		EXIT SUB
	END IF

	FOR i = iLow TO iHigh
		p[iCounter] = WCHR(i)
		iCounter += 1
	NEXT i

	' stream output
	PRINT *p;

	DEALLOCATE(p)
	p = 0

END SUB


SUB stringGenerate()

	' subroutine to generate string output either as a stream or as a file

	DIM AS STRING sGarbage = "lorem ipsum ", sResult, sOutFile, sCommand2 = COMMAND(2), sCommand3 = COMMAND(3), sCommand4 = COMMAND(4)
	DIM AS UINTEGER i, j, iLimit = 255, iFileDump = 0, iGarbageLen = 0
	DIM AS INTEGER iFreeFile
	DIM AS UBYTE PTR p
	' DIM AS DOUBLE t1, t2

	IF sCommand2 <> "" THEN
		iLimit = ABS(CUINT(sCommand2)) ' CUINT does not make -10 = 0, but overflows: ABS is a reasonably effective kludge
		IF iLimit = 0 THEN
			inputDeath(0)
			EXIT SUB
		END IF
	END IF

	IF sCommand3 <> "" THEN sGarbage = sCommand3

	IF sCommand4 <> "" THEN
		iFileDump = 1
		sOutFile = sCommand4 ' 4th parameter for -s
	END IF

	IF iFileDump = 0 THEN ' stream output

		' t1 = TIMER

		i = 0

		DO WHILE i < iLimit
			sResult += sGarbage
			i += 1
		LOOP
			' (PRINT inside loop is considerably slower than concatenation within)

		PRINT sResult;

		CLEAR sResult[0], 0, iLimit

		' t2 = TIMER
		' PRINT t2 - t1

	ELSE ' file output (noticeably faster than redirection at a certain point e.g. over 50 million strings)

		' t1 = TIMER

		iFreeFile = FREEFILE()

		iGarbageLen = LEN(sGarbage)

		iLimit = iGarbageLen * iLimit

		p = ALLOCATE(iLimit * SIZEOF(UBYTE)) ' pointer is more robust than array buffer alternative in DO ... LOOP context below

		IF (0 = p) THEN
			standarderr("Error: unable to allocate sufficient memory - quitting.")
			EXIT SUB
		END IF

		i = 0

		DO WHILE i < iLimit
			FOR j = 0 TO iGarbageLen - 1
				p[i] = sGarbage[j]
				i += 1
			NEXT j
		LOOP

		IF (OPEN(sOutFile, FOR BINARY ACCESS WRITE, AS #iFreeFile) <> 0) THEN
			standarderr("Error creating output file!")
			DEALLOCATE(p) ' avoid memory leak
			p = 0
			EXIT SUB
		END IF

		PUT #iFreeFile, 0, p[0], iLimit
		CLOSE #iFreeFile

		DEALLOCATE(p)
		p = 0

		' t2 = TIMER
		' PRINT t2 - t1

	END IF

END SUB


SUB displayAsciiCodes()

	' subroutine to display decimal ASCII codes: control code acronyms 0 to 31 and characters 32 to 255

	DIM AS UINTEGER i = 0
	DIM AS STRING sSpacer = " ", sSpacer2 = "  "
	DIM AS STRING aControlCodes(0 TO ...) = {_
	 "NUL", "SOH", "STX", "ETX", "EOT", "ENQ", "ACK", "BEL", "BS", "TAB", "LF", "VT", "FF", "CR", "SO", "SI", "DLE", "DC1", "DC2", "DC3", "DC4", "NAK", "SYN", "ETB", "CAN", "EM", "SUB", "ESC", "FS", "GS", "RS", "US"_
	}

	PRINT

	FOR i = 0 TO UBOUND(aControlCodes)
		IF i < 10 THEN
			PRINT sSpacer2 & i & sSpacer + sSpacer + aControlCodes(i),
		ELSE
			PRINT sSpacer & i & sSpacer2 + aControlCodes(i),
		END IF
	NEXT i

	PRINT : PRINT

	FOR i = 32 TO 255
		IF i < 100 THEN sSpacer = " " ELSE sSpacer = ""
		IF i = 128 THEN PRINT : PRINT
		PRINT sSpacer & i & sSpacer2 + CHR(i), ' slow, but keeps OS LF/CR platform independent
	NEXT i

	PRINT

	#IFDEF __FB_UNIX__
		PRINT
	#ENDIF

END SUB


SUB fallThrough()

	' subroutine for exiting because of invalid parameters

	standarderr("Incorrect parameters!")

	displayOptions()

END SUB


SUB standarderr(BYREF sMessage AS CONST STRING, BYVAL iEndPrint AS UINTEGER = 1)

	' subroutine for sending messages to stderr

	PRINT

	OPEN ERR FOR INPUT AS #1

	#IFDEF __FB_UNIX__
		PRINT #1, sMessage
	#ELSE
		PRINT #1, sMessage;
	#ENDIF

	CLOSE

	IF iEndPrint THEN PRINT

END SUB


SUB inputDeath(BYVAL f AS UINTEGER = 0)

	' subroutine for exiting when invalid integer parameters are entered

	IF f = 0 THEN
		standarderr("[num] specified is not a number.")
	ELSEIF f = 1 THEN
		standarderr("[high] is not a number.")
	ELSEIF f = 2 THEN
		standarderr("[high] is less than [low] - invalid.")
	ELSEIF f = 3 THEN
		standarderr("<high> is less than <low> - invalid.")
	ELSEIF f = 4 THEN
		standarderr("<high> is too large.")
	END IF

	displayOptions()

END SUB


SUB displayOptions()

	' subroutine to display program options

	DIM AS STRING sOptions

	sOptions = !"RND\n\n"
	sOptions += !"Usage:\n"
	sOptions += !"\trnd -c [num] [low high] [file]\n"
	sOptions += !"\trnd -s [num] [\"string\"] [file]\n"
	sOptions += !"\trnd -b <n,n,n,n>        [file]\n"
	sOptions += !"\trnd -b <low>-<high>     [file]\n"
	sOptions += !"\trnd -u <low>-<high>\n"
	sOptions += !"\trnd -p\n"
	sOptions += !"\trnd -a\n"

	standarderr(sOptions, 0)

END SUB
