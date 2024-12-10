;
; KIM assembler Editor in ROM 6540-007, -008, -009 1977 
; Reconstructed from disassambly. with ROM dumps. Runs on KIM-1 Simulator.
; Code lives at E000-F7FF.
; V1.0 Hans Otten, 2024. Comments, labels, based upon the source of the Commodore assemblers at pagetable.com.
; Especially the closest in time, the PET Commodore Assembler
;
; From MOS KIM Assembler Guide 1977:
;
; DF E0 Symbol table start          (unused in this source)
; E1 E2 Symbol table upper limit    (unused in this source)
;
; or (used here)
; 62 63 Symbol table start
; 64 65 Symbol table upper limit  
;
; Start store address of editor asked for when editor is started
; Start of object in org statement *=IEXP
; 
; all zeropage used from 42 up
; E011 entry into assembler
;
; From KIM Text Editor User Manual 1977
;
; Editor start at F100, or F103 without setting up I/O vectors to KIM-1
; asks for BASE= Hex start address of text
; asks for N or O (New or Old)
; 
; I/O vector table
; 
; USRCMD ED, EE starting address user defined command default                   F617
; LINK   EB, EC starting address to jump to when exit command is issued         1C14  (KIM entry strart) 
; RESTREG E7, E8 RESTREG character subroutine address (should include break test) F6BA 
; INPUT  E5, E6 input character subroutine address								1E5A (KIM GETCH)								
; ENDLIN E9, EA end-of-line subroutine address 									1E2F (KIM CRLF)									
; 
; Page zero locations for user defined
; OT     DB, DC address of beginning of text				
; EOT    DD, DE address of end of text
; TXTBUF 84 -CB contents of last line typed by user
; 		 DB, DC address of beginnig of text line 
;		 DD, DE address of end of text file
;				last byte in text file is 1F 
;
; KIM-1 hardware and monitor 6530-002 
;
SAD     = $1740                 ; 6530 A DATA
PADD    = $1741                 ; 6530 A DATA DIRECTION
SBD     = $1742                 ; 6530 B DATA
PBDD    = $1743                 ; 6530 B DATA DIRECTION
CLK1T   = $1744                 ; DIV BY 1 TIME
CLK8T   = $1745                 ; DIV BY 8 TIME
CLK64T  = $1746                 ; DIV BY 64 TIME
CLKKT   = $1747                 ; DIV BY 1024 TIME
CLKRDI  = $1747                 ; READ TIME OUT BIT
CLKRDT  = $1746                 ; READ TIME
;       ** MPU REG.  SAVX AREA IN PAGE 0 **
PCL     = $EF                   ; PROGRAM CNT LOW
PCH     = $F0                   ; PROGRAM CNT HI
PREG    = $F1                   ; CURRENT STATUS REG
SPUSER  = $F2                   ; CURRENT STACK POINTER
ACC     = $F3                   ; ACCUMULATOR
YREG    = $F4                   ; Y INDEX
XREG    = $F5                   ; X INDEX
;       ** KIM FIXED AREA IN PAGE 0  **
CHKHI   = $F6
CHKSUM  = $F7
INL     = $F8                   ; INPUT BUFFER
INH     = $F9                   ; INPUT BUFFER
POINTL  = $FA                   ; LSB OF OPEN CELL
POINTH  = $FB                   ; MSB OF OPEN CELL
TEMPA	= $FC
TMPX    = $FD
CHAR    = $FE
MODE    = $FF
;       ** KIM FIXED AREA IN PAGE 23 **
CHKL    = $17E7
CHKH    = $17E8                 ; CHKSUM
SAVX    = $17E9                 ; (3-BYTES)
VEB     = $17EC                 ; VOLATILE EXEC BLOCK (6-B)
CNTL30  = $17F2                 ; TTY DELAY
CNTH30  = $17F3                 ; TTY DELAY
TIMH    = $17F4
SAL     = $17F5                 ; LOW STARTING ADDRESS
SAH     = $17F6                 ; HI STARTING ADDRESS
EAL     = $17F7                 ; LOW ENDING ADDRESS
EAH     = $17F8                 ; HI ENDING ADDRESS
ID      = $17F9                 ; TAPE PROGRAM ID NUMBER
;       ** INTERRUPT VECTORS **
NMIV    = $17FA                 ; STOP VECTOR (STOP=1C00)
RSTV    = $17FC                 ; RST VECTOR
IRQV    = $17FE                 ; IRQ VECTOR (BRK=1C00)
;
; KIM-1 ROM addressses
;
DUMPT 	= $1800					; start KIM dump tape
DUMPTA 	= $185C					; jump into KIM start
CHKT 	= $194C					; compute checksum
INTVEB  = $1932					; init VEB, SAL,H to VEB +1,2
INCVEB  = $19EA					; increment VEB+1,2
RST     = $1C22                 ; hardware reset 
KSTART  = $1C14					; save SP, Init and start
START   = $1C4F                 ; start KIM-1 processor, KDB selection
CRLF 	= $1E2F					; Print CR LF
GETCH   = $1E5A                 ; GETCH (serial, with hardware echo)
OUTCH   = $1EA0                 ; OUTCH (serial)
RUBOUT  = $1DE0                 ; rubout char
PACK    = $1FAC					; Pack A into INL, INH
;
; Constants
;
CR 		= $0D					; Carriage Return
SEMICL 	= $3B 					; semicolon 
BLANK 	= $20					; space 
COMMA 	= $2C					; comma
DOT 	= $2E					; .
LPAREN 	= $28					; left parenthesis
RPAREN 	= $29					; right parenthesis
EQUAL 	= $3D					; equal = 
MINUS 	= $2D					; -
PLUS 	= $2B					; +
EOT 	= $1F					; end of text marker
QUOTE 	= $27					; '
LESS 	= $3C					; <
MORE 	= $3E					; >
DOLLAR 	= $24					; $
;
; zeropage
          .segment	"zp" : zeropage
;
UNK0:	.res 1                  ; $43
UNK1:	.res 1	                ; $44
SYMTBL:	.res 2	                ; $45
PNT1:	.res 2	                ; $47
UNK2:	.res 2	                ; $49
COLCNT:	.res 1	                ; $4B
LINEH:	.res 1	                ; $4C
LINEL:	.res 1	                ; $4D
NOSYM:	.res 2	                ; $4E
UNK24:  .res 2                  ; $50   
IPC:	.res 2	                ; $52
IFLAGS:	.res 2	                ; $54
ICOLP:	.res 1	                ; $56
ICSB:   .res 1	                ; $57 
ICSE:	.res 1	                ; $58
ICSL:	.res 1	                ; $59	
ILSST:	.res 1	                ; $5A
IEXP:	.res 3	                ; $5B
IMAXCL: .res 1	                ; $5E
JLABL:	.res 1	                ; $5F
UNK17:	.res 1	                ; $60
UNK18:	.res 1	                ; $61
UNK19:	.res 1	                ; $62
ISYM:	.res 6	                ; $63 
TOPPNT:	.res 2	                ; $69
KLEN:   .res 1	                ; $6B	 
KBASE:	.res 1	                ; $6C
UNK20:	.res 1	                ; $6D
KLOW:	.res 1	                ; $6E
KHIGH:	.res 1	                ; $6F
KNVAL:	.res 2	                ; $70
RETURN:	.res 1	                ; $72
JOPBAS:	.res 1	                ; $73
JOPTEM:	.res 1	                ; $74
JOPLEN:	.res 1	                ; $75
JOPTYP:	.res 1	                ; $76
JNOPV:	.res 1	                ; $77
UNK21:	.res 1	                ; $78
UNK22:	.res 1	                ; $79
UNK23:	.res 1	                ; $7A
TEMP:	.res 9	                ; $7B
ICRD:	.res 72	                ; $84
UNK3:	.res 1                  ; $CC
UNK4:	.res 1	                ; $CD
UNK5:	.res 2	                ; $CE
UNK6:	.res 1	                ; $D0
SAVEX:	.res 1	                ; $D1
SAVEY:	.res 1	                ; $D2
UNK7:	.res 1	                ; $D3
UNK8:	.res 1	                ; $D4
UNK9:	.res 1	                ; $D5
UNK10:	.res 1	                ; $D6
UNK11:	.res 2	                ; $D7
UNK12:	.res 2	                ; $D9
UNK13:	.res 2	                ; $DB   
UNK14:	.res 2	                ; $DD
STSAVE:	.res 2	                ; $DF
UNK15:	.res 2	                ; $E1
UNK16:	.res 2	                ; $E3
IOVCTBL:
        .res 10	                ; $E5

;
; Start of Assembler/editor for KIM MOS Technology Commodore 1977
;
          .segment	"code"
;  
; clear working area
;  
LE000:    LDA #$00
          LDX #$06
LE004:    STA LINEH,X
          DEX
          BPL LE004
;		  
;   
;
          LDA #$02
          STA IPC+1
          LDA #$E4
          STA IFLAGS
          CLD
          JSR LF061
          LDX #$00
          JSR LED1F
          JSR LED4A
          LDX #$19
          JSR LED1F
          JSR LED4A
          JSR LF04F
LE028:    LDX #$FF
          TXS				; clear stack
          JSR LE031
          JMP LE028
;		  
; clear working space		  
;
LE031:    LDA #$00
          LDX #$0D
LE035:    STA IFLAGS+1,X
          DEX
          BPL LE035
          JSR LF064
          DEX
          DEX
          STX IMAXCL
;
          JSR LE584
          BCS LE054
;
; increment line number in decimal mode
;		  
          SED
          LDA LINEL
          ADC #$01
          STA LINEL
          LDA LINEH
          ADC #$00
          STA LINEH
          CLD
LE054:    JSR NFNDNB
          BCS LE061
;
; PAGE .SKIP .DBYT		  
		  
LE059:    LDY #$00
LE05B:    LDX #$00
          TXA
          JMP LTS1
;		  
LE061:    JSR LE584
          BCS LE086
          LDY #$00
          STY INL
          STY INH
LE06C:    JSR NUMRC
          BCC LE081
          JSR LF05B
          JSR LE5A1
          JSR LE594
          BCS LE059
          INY
          CPY #$04
          BCC LE06C
;
;  MAIN LINE BLOCK
;		  
LE081:    JSR NFNDNB		; blank card ?
          BCC LE059
LE086:    LDA ICRD,X
          CMP #SEMICL       ; if terminator card	
          BEQ LE059
          JSR NFNDEN
          BCS LE09A
LE091:    LDA #$03
LE093:    LDY #$03
LE095:    LDX ICSB
          JMP LTS1
LE09A:    LDX ICSB
          LDA ICRD,X
          CMP #DOT			; . ?
          BNE LE0A5			; not assem direct
          JMP LE1F5			; an assemble direct
;
; EVALUATE '*' ASSEMBLY COUNTER		  
;
LE0A5:    CMP #'*'			; = * ?
          BNE LE0AC			; not an org
          JMP LE150
; 		  
LE0AC:    LDY ICSL
          CPY #$07			; 7 chars?
          BCC LE0B9
          LDA #$09
LE0B4:    LDY #$03
          JMP LTS1			; redefine org
;		  
LE0B9:    STY KLEN			; length of symbol
          JSR CONSYM		; construct the symbol
          BCS LE0C4			; no errors in CONSYM
          LDA #$10
          BNE LE0B4
		  
LE0C4:    LDA ICSL			; Length of string
          CMP #$03			; right length for label
          BNE LE0D2			; label process-over 3
          JSR NOPFND		; find a mnemonic
          BCC LE0D2			; failed must be a label
          JMP LE36E			; an opcode
;		
; label processing
;  
LE0D2:    LDA JLABL			; JLABL
          BNE LE091
          INC JLABL
          LDX ICOLP
          JSR NALPH1
          BCS LE0E3
          LDA #$08
          BNE LE0B4
LE0E3:    LDA ISYM+1
          CMP #BLANK		; is blank 
          BNE LE104
          LDA ISYM
          CMP #$41		; A ssembler
          BEQ LE0FF
          CMP #'X'
          BEQ LE0FF
          CMP #'Y'
          BEQ LE0FF
          CMP #'S'		; S tatus
          BEQ LE0FF
          CMP #'P'	        ; P rint
          BNE LE104
LE0FF:    LDA #BLANK
          JMP LE0B4
		  
LE104:    STX ILSST
          LDX #$00			; save the symbol	  
LE108:    LDA ISYM,X		; ISYM
          PHA
          INX
          CPX #$06
          BNE LE108
		  
          LDA ICSL			; SAVE ICSL 
          PHA
          LDX ICSE			; Save ICSE
          INX
          STX ICOLP
          JSR NFNDNB
          BCC LE123			; only blanks found
          LDA ICRD,X
          CMP #EQUAL		; = ?
          BEQ LE169
;		  
LE123:    JSR NFIND			; NFIND
          BCC LE139
          LDA KNVAL			; KNVAL
          CMP IPC+1			; IPC+1
          BNE LE134
          LDA KNVAL+1		; KNVAL + 1
          CMP IPC			; IPC?
          BEQ LE144
		  
LE134:    LDY #$03
          JMP LE1E0
;		  
LE139:    LDA IPC+1
          STA KNVAL
          LDA IPC
          STA KNVAL+1
          JSR NSERT
		  
LE144:    LDX ICSB
          CPX ILSST
          BEQ LE14D
          JMP LE086
LE14D:    JMP LE059
LE150:    INC UNK17
          INC ICOLP
          STX ILSST
          JSR NFNDNB
          BCS LE15E
          JMP LE3A1
		  
LE15E:    LDA ICRD,X
          CMP #EQUAL		; = ?
          BEQ LE169
          LDA #$22
          JMP LE0B4
		  
LE169:    INC UNK17
          JSR LE5A1
          STX ICOLP
          BCC LE175
          JMP LE3A1
LE175:    JSR NFNDNB
          BCS LE17F
          LDY #$00
          JMP LE394
LE17F:    JSR EVAL
          LDA RETURN
          BMI LE192
          BNE LE18D
          LDA #$11
          JMP LE3F8
LE18D:    LDA #$13
          JMP LE3F8
LE192:    LDA UNK17
          CMP #$01
          BEQ LE1C2
          LDA #$01
          AND IFLAGS+1
          BEQ LE1B0
          LDX ICSB
          LDA #$21
          LDY #$00
          JSR LEAB6
          LDX #$00
          STX IPC
          STX IPC+1
          JMP LE580
LE1B0:    LDX #$00
          TXA
          TAY
          JSR LEAB6
          LDA IEXP
          STA IPC+1
          LDA IEXP+1
          STA IPC
          JMP LE580
LE1C2:    PLA
          STA ICSL
          LDX #$05
LE1C7:    PLA
          STA ISYM,X
          DEX
          BPL LE1C7
          JSR NFIND
          BCC LE1E7
          LDA KNVAL
          CMP IEXP
          BNE LE1DE
          LDA KNVAL+1
          CMP IEXP+1
          BEQ LE1F2
LE1DE:    LDY #$00
LE1E0:    LDA #$02
          LDX ILSST
          JMP LTS1
LE1E7:    LDA IEXP
          STA KNVAL
          LDA IEXP+1
          STA KNVAL+1
          JSR NSERT
LE1F2:    JMP LE059
LE1F5:    LDX ICSB
          INX
          LDA LEFD4
          STA UNK2
          LDA LEFD4+1
          STA UNK2+1
          LDA #$03
          STA KLEN
          JSR CONSYM
          DEX
LE20A:    JSR LE5A1
          BCS LE215
          LDA ICRD,X
          CMP #BLANK		; blank ?
          BNE LE20A
LE215:    STX ICOLP
          BCS LE220
LE219:    LDY #$00
          LDA #$14
          JMP LE095
LE220:    LDX #$13
LE222:    LDY #$02
LE224:    LDA ISYM,Y
          CMP (UNK2),Y
          BNE LE240
          DEY
          BPL LE224
          TXA
          ASL A
          TAX
          LDA ASMJMP,X
          STA UNK2
          LDA ASMJMP+1,X
          STA UNK2+1
          LDA IFLAGS
          JMP (UNK2)
LE240:    LDA UNK2
          CLC
          ADC #$03
          STA UNK2
          BCC LE24B
          INC UNK2+1
LE24B:    DEX
          BPL LE222
          BMI LE219
;
; Byte, Word, Dbyte Processing
;

LE250:    LDY #$01			; byte
          BNE LE256
LE254:    LDY #$02			; word
;
LE256:    STY UNK18			; JBYWOR
          JSR NFNDNB
          BCS LE260
          JMP LE394
;
LE260:    JSR EVAL
          LDA RETURN
          BEQ LE2B1
          BPL LE2B6
          LDX UNK18
          LDY #$00
          LDA IEXP+1
          STA (IPC),Y
          CPX #$02
          BNE LE27A
          LDA IEXP
          INY
          STA (IPC),Y
LE27A:    LDA IFLAGS+1
          AND #$09
          BNE LE288
          CPX #$01
          BNE LE291
          LDA IEXP
          BEQ LE291
LE288:    LDY UNK18
          LDA #$04
          LDX ICSB
          JMP LE295
LE291:    LDY UNK18
LE293:    LDA #$00
LE295:    JSR LEAB6
LE298:    JSR NFNCMP
          BCS LE2A0
          JMP LE580
LE2A0:    CMP #COMMA
          BNE LE298
          JSR LE5A1
          STX ICOLP
          JSR NFNDNB
          BCS LE260
          JMP LE3A1
LE2B1:    LDA #$06
          JMP LE2C8
LE2B6:    LDA ICRD,X
          CMP #QUOTE
          BNE LE2C6
          CPX ICSB
          BNE LE2C6
          LDY UNK18
          CPY #$01
          BEQ LE2CF
LE2C6:    LDA #$13
LE2C8:    LDY UNK18
          LDX UNK22
          JMP LE295
LE2CF:    STX ICOLP
          LDY #$00
LE2D3:    LDX ICOLP
          JSR LE5A1
          STX ICOLP
          BCC LE2DF
          JMP LE3A3
LE2DF:    LDA ICRD,X
          CMP #QUOTE
          BNE LE2F4
          LDX ICOLP
          JSR LE5A1
          STX ICOLP
          BCS LE293
          LDA ICRD,X
          CMP #QUOTE
          BNE LE293
LE2F4:    CMP #BLANK
          BCC LE2FC
          CMP #$60
          BCC LE2FE
LE2FC:    LDA #$00
LE2FE:    STA (IPC),Y
          INY
          JMP LE2D3
; .OPT		  
		  
LE304:    JSR NFNDNB
          BCS LE30C
          JMP LE059
LE30C:    LDX ICSB
          LDA #$03
          STA KLEN
          JSR CONSYM
          BCS LE31A
          JMP LE219
LE31A:    LDA LEFD6
          STA UNK2
          LDA LEFD6+1
          STA UNK2+1
          LDX #$0C
          JMP LE222
		  
; GEN
		  
LE329:    AND #$7F
          JMP LE358
		  
; NOGEN
		  
LE32E:    ORA #$80
          JMP LE358
		
; SYMBOL
		
LE333:    ORA #$40
          JMP LE358

; NOSYMBOL
		  
LE338:     AND #$BF
	      JMP LE358

; ERR
 
LE33D:    ORA #$10
          JMP LE358
	
; NOERR
	
LE342:    AND #$EF
          JMP LE358
		  
		  ; TAB
		  
LE347:    ORA #BLANK
          JMP LE358
		  
		  ; NOT
		  
LE34C:    AND #$DF
          JMP LE358
		  
		  ; LIST
		  
LE351:    ORA #$04
          JMP LE358
		  
		  ; NO LIST
		  
LE356:    AND #$FB		; turn off print file

LE358:    STA IFLAGS		
LE35A:    JSR NFNCMP	; look for comma and start again
          BCS LE362		; comma or right paren
LE35F:    JMP LE059		; none found

LE362:    LDA ICRD,X
          CMP #COMMA		; = , ?
          BNE LE35F		; no
          INX
          STX ICOLP		; yes
          JMP LE304
		  
LE36E:    LDA #$00
          STA JOPTYP
          STA JOPLEN
          STA JNOPV
          LDY #$00
          LDA JOPBAS
          STA (IPC),Y
          LDA JOPTEM
          CMP #$14
          BNE LE387
LE382:    LDY #$01
          JMP LE05B
		  
LE387:    LDA ICSE			; pntr to last character
          STA ICOLP
          INC ICOLP			; next char
          JSR NFNDNB		; find start of operand
          BCS LE39B
          LDY #$03
LE394:    LDA #$07
          LDX ICSE
          JMP LTS1			; error no operand

; PROCESS OPERAND FIELD
		  
LE39B:    LDA ICRD,X		; first char
          CMP #SEMICL		; see if comment
          BNE LE3A8
LE3A1:    LDY #$03
LE3A3:    LDA #$07
          JMP LE095			; error no operand


; AN OPERAND-CHECK .A MODE FIRST

		  
LE3A8:    CMP #'A'
          BNE LE3CC			;NOT ACCUMULATOR MODE
          CPX IMAXCL		;SEE IF OFF END
          BEQ LE3B6
          LDY ICRD+1,X		;AFTER THE 'A'
          CPY #BLANK		;MUST BE BLANK
          BNE LE3CC			;NOT .A MODE
		  
LE3B6:    LDY JOPTEM		;.A MODE - PROCESS
          LDA KLTBL-1,Y
          BMI LE3C7			;.A MODE NOT VALID
          CLC
          ADC JOPBAS		;COMPUTE REAL OPCODE
          LDY #$00
          STA (IPC),Y
          JMP LE382			;DONE WITH THIS OPCODE

LE3C7:    LDA #$05
          JMP LE093
		  
LE3CC:    CMP #'#'			; check immediate mode
          BNE LE3D5
		  
          LDA #$0A			; opcode type
          JMP LE3DB
		  
LE3D5:    CMP #LPAREN		; check for indirect mode
          BNE LE3E7
		  
          LDA #$05			; set op type
LE3DB:    STA JOPTYP
          INC ICSB
          JSR LE5A1
          BCC LE3E7
          JMP LE3A1			;RAN OFF END
		  
LE3E7:    JSR EVAL			;EVAL THE OPERAND
          LDA RETURN
          BMI LE434
          BEQ LE42E
		  
          LDA JOPTYP
          CMP #$0A
          BEQ LE3FD
LE3F6:    LDA #$13
LE3F8:    LDX UNK22
          JMP LE0B4			; bad expression

; IMMIDIATE ASCII OPERATION
		  
LE3FD:    LDA ICRD,X
          CMP #QUOTE		; apostrophe?
          BNE LE3F6
          JSR LE5A1
          BCC LE40B
          JMP LE3A1		
		  
LE40B:    LDA ICRD,X
          CMP #BLANK
          BCC LE415
          CMP #$60
          BCC LE417
LE415:    LDA #$00
LE417:    STA IEXP+1
          JSR LE5A1
          BCS LE434
		  
          LDA ICRD,X		;OFF END OF CARD?
          CMP #BLANK
          BEQ LE434
          CMP #QUOTE
          BEQ LE434
          INC UNK22
          INC UNK22
          BNE LE3F6
LE42E:    INC JNOPV
          LDA #$02			;LENGTH OF OPERAND
          STA JOPLEN
LE434:    JSR NFNCMP		; COMMA OR PAREN
          BCC LE484			; no indexing
		  
          LDA ICRD,X		; ) ?
          CMP #RPAREN		; RIGHT PAREN - ADD TO OPTYPE
          BNE LE451
          INC JOPTYP
          INC JOPTYP
          LDA JOPBAS		; jump instruction
          CMP #$4C
          BEQ LE48A
          JSR LE5A1
          BCC LE451
          JMP LE3A1
		  
LE451:    LDA ICRD,X
          CMP #COMMA		; comma?
          BNE LE46A
          LDA JOPBAS
          CMP #$4C
          BNE LE462
LE45D:    LDA #$18
          JMP LE093
		  
LE462:    JSR LE5A1
          BCC LE46A
          JMP LE3A1
		  
LE46A:    LDA ICRD,X
          CMP #'X'				; index X
          BNE LE475
          INC JOPTYP
          JMP LE4A8
LE475:    CMP #'Y'				; index Y
          BEQ LE47E
          LDA #$12
          JMP LE0B4				; invalid index register
		  
LE47E:    INC JOPTYP			;INDEX REG Y-ADD 2 TO OPTYPE
          INC JOPTYP
          BNE LE4A8
		  
LE484:    LDA JOPBAS			;IF A JUMP INSTRUCTION CHECK
          CMP #$4C
          BNE LE4A8
		  
LE48A:    LDA JOPTYP			; type 0 .. OK
          BNE LE495
LE48E:    LDY #$02
          STY JOPLEN
          JMP LE53F
		  
LE495:    CMP #$07				; type 7 .. OK
          BNE LE45D
          LDA #BLANK
          JSR LE5A1				; bad jump
          BCS LE48E
		  
          LDY ICRD,X
          CPY #BLANK
          BEQ LE48E
          BNE LE45D
LE4A8:    LDA JNOPV
          BNE LE4F8
          LDA #$02				; LENGTH OF OPERAND
          STA JOPLEN

          LDA JOPTEM			;opcode template
          CMP #$0E
          BNE LE4CC
		  
          LDA IPC
          STA TEMP
          LDA IPC+1
          STA TEMP+1
          JSR LE5B6
          BCS LE4C8
          LDA #$17
          JMP LE093
		  
LE4C8:    LDA #$00
          STA IEXP

; CHECK INDIRECT ADDRESS ERROR
; ERROR INDICATED BY EXPR OVER 254
; OR OPTYPE >= 6 AND <= 9
		  
LE4CC:    LDA JOPTYP
          CMP #$06
          BCC LE4E0		; no
          CMP #$0A
          BCS LE4E0		; not indirect
          JSR LE5A8
          BCS LE4E0
          LDA #$19
          JMP LE3F8
		  
LE4E0:    LDA IEXP		; check value of expression
          BNE LE4F8		; error over 255
 
; 1 BYTE OPERAND - CHECK IF VALID
         LDA #$01
          STA JOPLEN
          LDA JOPTYP
          CLC
          ADC #$02
          STA JOPTYP	
LE4EF:    CMP #$0D			; max address mode
          BCC LE503
          LDA #$15			; bad operand flag
          JMP LE093
		  
LE4F8:    LDA JOPTYP		;PROCESS 2 BYTE OPERANDS	
          CLC
          ADC #$0D
          STA JOPTYP
LE4FF:    CMP #$10			; over 15 could be bad
          BCS LE511			; might be page 0

; SEE IF OPERAND IS VALID FOR OPCODE.
		  
LE503:    TAY				; first suscript
          DEY
          LDA KLUDG,Y
          CLC
          ADC JOPTEM		; second subscript
          TAY				; opcode base increment
          LDA KLTBL,Y		;
          BPL LE53F			; pos operand type valid
		  
; OPERAND NOT VALID FIRST TRY. TRY 2 BYTE OPERAND.

LE511:    LDA JNOPV			; operand vlue
          BEQ LE52A			; yes
		  
          LDA JOPLEN		;NO OPERAND VAL-TRY 1 BYTE INSTR
          CMP #$02
          BEQ LE51E			; was 2 try as 1
          JMP LE45D			;1 BYTE NOVALUE OPERAND-FLG ERROR
							;INVALID OPERAND

LE51E:    DEC JOPLEN		;ABS MODE AS PAGE ZERO MODE
          LDA JOPTYP
          SEC
          SBC #$0B
          STA JOPTYP		; new op type
          JMP LE4EF
		  
LE52A:    LDA JOPLEN		; had an operand vlue
          CMP #$01			; 1 byte long
          BEQ LE533			; try 2 bytes
          JMP LE45D			;OPERAND 2 BYTES - FLAG AS ERROR
		  
LE533:    INC JOPLEN		; op length to 2
          LDA JOPTYP
          CLC
          ADC #$0B
          STA JOPTYP
          JMP LE4FF
		  

; VALID OPERAND - COMPUTE OPCODE AND PUT IN MEMORY MAP
		  
		  
LE53F:    CLC
          ADC JOPBAS		; kludge + base opcode
          LDY #$00
          STA (IPC),Y

; OPERAND VALUE - ENTER INTO MEMORY MAP
		  
          LDA JNOPV			; operand flag
          BNE LE578
          INY				; operand value
          LDA IEXP+1		; low byte of expression
          STA (IPC),Y
          INY
          LDA JOPLEN
          CMP #$01			; if 1 byte then done
          BEQ LE55A
          LDA IEXP			; 2 byte= hi-byte to memory
          STA (IPC),Y
LE55A:    LDA #$09
          AND IFLAGS+1
          BEQ LE568
LE560:    LDY JOPLEN
          INY
          LDA #$04
          JMP LE095
		  
LE568:    LDA JOPLEN
          CMP #$01
          BNE LE572
          LDA IEXP
          BNE LE560
LE572:    LDY JOPLEN
          INY
          JMP LE05B
		  
LE578:    LDA #$01
          JMP LE0B4
		  
LTS1:     JSR LEAB6
LE580:    LDX #$FD
          TXS
          RTS
		  
LE584:    LDA UNK16
          CMP #<LED50
          BNE LE590
          LDA UNK16+1
          CMP #>LED50
          BEQ LE592
LE590:    CLC
          RTS
LE592:    SEC
          RTS

LE594:    STX $5D
          STX ICOLP
          LDA INH
          STA LINEH
          LDA INL
          STA LINEL
          RTS
		  
LE5A1:    INX
          CPX IMAXCL
          BNE LE5A7
          CLC
LE5A7:    RTS

LE5A8:    LDA IEXP
          BEQ LE5AE
LE5AC:    CLC
          RTS
LE5AE:    LDA IEXP+1
          CMP #$FF
          BEQ LE5AC
          SEC
          RTS
LE5B6:    CLC
          LDA TEMP
          ADC #$02
          STA TEMP+3
          LDA TEMP+1
          ADC #$00
          STA TEMP+2
          SEC
          LDA IEXP+1
          SBC TEMP+3
          STA IEXP+1
          TAY
          LDA IEXP
          SBC TEMP+2
          STA IEXP
          BNE LE5D8
          TYA
          BMI LE5DF
LE5D6:    SEC
          RTS
LE5D8:    CMP #$FF
          BNE LE5DF
          TYA
          BMI LE5D6
LE5DF:    CLC
          RTS
NFNDNB:    LDA IMAXCL
          BMI LE5FD
          LDX ICOLP
LE5E7:    CPX IMAXCL
          BEQ LE5ED
          BCS LE5FD
LE5ED:    LDA ICRD,X
          CMP #BLANK
          BEQ LE5F7
          STX ICSB
          SEC
          RTS
LE5F7:    INX
          STX ICOLP
          JMP LE5E7
LE5FD:    CLC
          RTS
NFNDEN:    LDY #$00
          STY ICSL
          LDX ICOLP
LE605:    CPX IMAXCL
          BEQ LE60B
          BCS LE622
LE60B:    LDA ICRD,X
          CMP #BLANK
          BEQ LE619
          CMP #EQUAL
          BEQ LE619
          CMP #SEMICL
          BNE LE628
LE619:    CPY #$00
          BNE LE633
LE61D:    DEX
          STX ICSE
          SEC
          RTS
LE622:    CPY #$00
          BEQ LE61D
          CLC
          RTS
LE628:    CMP #QUOTE
          BNE LE633
          INY
          CPY #$02
          BNE LE633
          LDY #$00
LE633:    INX
          INC ICSL
          JMP LE605
;
; Find non-embedded "'" or ")' carry set if found
;		  
		  
		  
NFNCMP:    LDX ICOLP			; NFNCMP lok for comma ICOLP
LE63B:    CPX IMAXCL			; IMAXCL
          BEQ LE641			; yes
          BCS LE66E			; end of card
LE641:    LDA ICRD,X			; ICRD
          CMP #QUOTE			; string apstrophe?
          BNE LE65A	
LE647:    JSR LE5A1
          STX ICOLP		 
          BCS LE66E
          LDA ICRD,X			; new character
          CMP #QUOTE			; closing quote apostrophe
          BNE LE647
          INX
		  STX ICOLP			; ICOLP
          JMP LE63B
		  
LE65A:    LDA ICRD,X			; another character
	      CMP #BLANK			; blank?
          BEQ LE66E
          CMP #RPAREN			; ) ?
          BEQ LE66F
          CMP #COMMA			; , ?
          BEQ LE66F
          INX
          STX ICOLP
          JMP LE63B
		  
LE66E:    CLC
LE66F:    RTS
NALPH:    JSR NALPH1
          BCC NUMRC
          RTS
NALPH1:    LDA ICRD,X
          CMP #$41
          BCC LE681
          CMP #$5B		; 
          BCC LE682
          CLC
LE681:    RTS
LE682:    SEC
          RTS
NUMRC:    LDA ICRD,X
          CMP #$30
          BCC LE68F
          CMP #$3A
          BCC LE690
          CLC
LE68F:    RTS
LE690:    SEC
          RTS

; *********************************
; * CONSTRUCTS A SYMBOL
; * NON-ALPHABETIC CAUSES CARRY CLR
; * OTHERWISE CARRY SET .X IS INDEX
; *********************************		  
		  
CONSYM:   LDY #$FF			; Y is counter
LE694:    INY	
          CPY #$06			; amx symbol length
          BEQ LE6A3
          CPY KLEN
          BCS LE6AC			; succesful construct
          JSR NALPH			; all chars to SYM
          BCS LE6A4			
          CLC
LE6A3:    RTS

LE6A4:    LDA ICRD,X		; next char of symbol
          STA ISYM,Y
          INX				; next column of source
          BCS LE694
LE6AC:    LDA #BLANK			; fill in with blanks
          STA ISYM,Y
          BCS LE694
; **********************************************************************
;
;    EVALUATES AN EXPRESSION
;
; REG X CONTAINS INDEX TO START OF EXPRESSION TO BE EVALUATED.
; UPON RTN FROM ROUTINE X CONTAINS POINTER TO FIRST CHARACTER
; BEYOND END, OR ON ERROR RETURN, CONTAINS POINTER TO BAD PORTION.
;
; RETURN SET AS FOLLOWS:
;
;   0  --  STRING COULD BE EVALUATED (IEXP = VALUE OF THE STRING)
;   1  --  UNDEFINED SYMBOL
;   2  --  EXPRESSION IS BAD
;
; **********************************************************************
		  
EVAL:     LDA #$00
          STA IEXP
          STA IEXP+1
          LDA #$01
          STA RETURN
          LDA #$FE
          AND IFLAGS+1
          STA IFLAGS+1
          STX UNK22
          STX UNK21
          JSR ENDTST
          BCC LE6CD
          RTS
;
; GET INITIAL OPERATION
;		  
LE6CD:    LDY #PLUS			;UNARY MINUS?
          CMP #MINUS
          BNE LE6DB
          LDY #MINUS
LE6D5:    JSR LE5A1
          BCC LE6DB
          RTS

;
; SEARCH FOR '<' & '>' FLAG
;	
		  
LE6DB:    STY UNK20
          STX UNK22
          LDA #$00
          STA KLOW		; <> flags
          STA KHIGH
          JSR ENDTST
          BCC LE6EB
          RTS
	  
LE6EB:    CMP #LESS		; <
          BNE LE6F4
          INC KLOW
          JMP LE6FA
LE6F4:    CMP #MORE		; >
          BNE LE700
          INC KHIGH
LE6FA:    JSR LE5A1
          BCC LE700
          RTS

;
; CONSTANT NUMBER ?
;
		  
LE700:    STX UNK22
          JSR NUMRC			;CHAR NUMERIC
          BCC LE70C  		;NO...NOT BASE 10
          LDY #$0A			;BASE 10
          JMP LE791			;EVALUATE THE NUMBER
		  
LE70C:    CMP #DOLLAR		;HEX?
          BNE LE715			;NO...NOT BASE 16
          LDY #$10			;BASE 16
          JMP LE783			;GET NEXT CHAR
		  
LE715:    CMP #'@'			;OCTAL?
          BNE LE71E			;NO...NOT BASE 8
          LDY #$08			;BASE 8
          JMP LE783
		  
LE71E:    CMP #'%'			; Binary
          BNE LE727			; no not base 2
          LDY #$02
          JMP LE783

;
; SYMBOLS ?
;

LE727:    JSR NALPH1
          BCC LE772
          JSR LE867
          CMP #$07
          BCC LE734
          RTS
		  
LE734:    JSR CONSYM
          JSR NFIND
          BCC LE73F
          JMP LE79C
		  
LE73F:    BVS LE744
          JSR LE9FF
LE744:    LDA UNK18
          BNE LE76A
          LDA UNK17
          BNE LE76A
          LDA IEXP+1
          BNE LE771
          LDA IEXP
          BNE LE771
          LDA UNK20
          CMP #$2B
          BNE LE76D
          STX UNK22
          DEX
          JSR LE5A1
          BCS LE767
          JSR ENDTST
          BCC LE771
LE767:    JSR LEA0E
LE76A:    JMP LE862

LE76D:    LDX UNK21
          STX UNK22
LE771:    RTS
LE772:    CMP #'*'
          BEQ LE777
          RTS
		  
LE777:    LDA IPC
          STA KNVAL+1
          LDA IPC+1
          STA KNVAL
          INX
          JMP LE79C
LE783:    JSR LE5A1
          BCC LE789
          RTS
LE789:    STX UNK22
          JSR NALPH
          BCS LE791
          RTS
LE791:    STY KBASE
          JSR LE867
          JSR NUMBER
          BCS LE79C
          RTS
LE79C:    LDA KLOW
          BEQ LE7A7
          LDA #$00
          STA KNVAL
          JMP LE7B3
LE7A7:    LDA KHIGH
          BEQ LE7B3
          LDA KNVAL
          STA KNVAL+1
          LDA #$00
          STA KNVAL
LE7B3:    LDA UNK20
          CMP #$2B
          BNE LE7FD
;
; '+' = ADDITION
;

          LDA IEXP+1		; low byte of expression
          CLC
          ADC KNVAL+1
          STA IEXP+1
          LDA IEXP			; low byte of number
          ADC KNVAL
          STA IEXP			; high byte of number
          LDA #$00
          ROL A
          TAY
          LDA #$01
          AND IFLAGS+1
          ASL A
          STA TEMP
          LDA #$02
          AND IFLAGS+1
          EOR TEMP
          BNE LE7E8
          TYA
          BNE LE7DF
          JMP LE84B
LE7DF:    LDA #$08
          ORA IFLAGS+1
          STA IFLAGS+1
          JMP LE84B
LE7E8:    TYA
          BEQ LE7F4
          LDA #$FE
          AND IFLAGS+1
          STA IFLAGS+1
          JMP LE84B
LE7F4:    LDA #$01
          ORA IFLAGS+1
          STA IFLAGS+1
          JMP LE84B				; continue
		  
LE7FD:    CMP #MINUS				; subtract
          BEQ LE806
          LDX UNK21
          STX UNK22
          RTS

;
; '-' = SUBTRACTION
;
		  
LE806:    LDA IEXP+1		; get low byte
          SEC
          SBC KNVAL+1
          STA IEXP+1		; low byte
          LDA IEXP
          SBC KNVAL
          STA IEXP			; high byte
          LDA #$00
          ROL A
          TAY
          LDA #$01
          AND IFLAGS+1
          ASL A
          STA TEMP
          LDA #$02
          AND IFLAGS+1
          EOR TEMP
          BNE LE83B
          TYA
          BEQ LE832
          LDA #$FE
          AND IFLAGS+1
          STA IFLAGS+1
          JMP LE84B
LE832:    LDA #$01
          ORA IFLAGS+1
          STA IFLAGS+1
          JMP LE84B
LE83B:    STY TEMP
          LDA #$01
          AND IFLAGS+1
          EOR TEMP
          BEQ LE84B
          LDA #$08
          ORA IFLAGS+1
          STA IFLAGS+1
		  
; END OF OPERATION.  DO END CHECK & IF END THEN DO '<' & '>'

LE84B:    CPX IMAXCL		; start next field
          BEQ LE851			; not end of card
          BPL LE85D			; yes end of card
LE851:    JSR ENDTST		; end expression?
          BCS LE85D			; yes bad
          LDY ICRD,X		; (operation)
          STX UNK21
		  
		  ; operation continued
		  
          JMP LE6D5
		  
		  ; returns set code and return
		  
LE85D:    LDA #$FF			; bad return
          STA RETURN
          RTS

LE862:    LDA #$00			; good return
          STA RETURN
          RTS
		  
LE867:    JSR LE5A1
          BCS LE871
          JSR NALPH
          BCS LE867
LE871:    TXA
          SEC
          SBC UNK22
          STA KLEN
          LDX UNK22
          RTS

; TEST FOR THE END OF A STRING (FINDS BLANK, COMMA, RIGHT PAREN)
; CARRY SET IF FOUND, CARRY CLEAR IF NONE FOUND
; X POINTS TO CHAR IN ICRD
		  
ENDTST:    LDA ICRD,X
          CMP #BLANK
          BEQ LE88D
          CMP #COMMA
          BEQ LE88D
          CMP #RPAREN
          BEQ LE88D
          CMP #SEMICL
          BEQ LE88D
          CLC
LE88D:    RTS


; CONVERT BASE 8,10,16 TO BINARY
; CARRY SET IF SUCCESSFUL CONVERSION, CARRY CLEAR IF ERROR.
; X MUST POINT TO CHARACTER


NUMBER:    LDA #$00			;VALUE OF NUMBER IS 0
          STA KNVAL
          STA KNVAL+1
LE894:    LDA ICRD,X		; character
          JSR NUMRC			; see if numeric
          BCC LE8A1			; not
          SEC
          SBC #$30			; remove zone
          JMP LE8A9
LE8A1:    JSR NALPH1		; check alphabetic
          BCC LE8AD			; no eror
          SEC
          SBC #$37			; alpha, remove zone
LE8A9:    CMP KBASE			; Base valid
          BCC LE8AF
LE8AD:    CLC				; invalid base
          RTS
		  
LE8AF:    STA COLCNT
          TXA
          PHA				; put pointer on stack
          LDY KBASE			; base
          CPY #$02			; binary?
          BNE LE8BE
          LDX #$01			; shift 1
          JMP LE8DE
LE8BE:    CPY #$08			; octal?
          BNE LE8C7
          LDX #$03			; shift 3
          JMP LE8DE
LE8C7:    CPY #$10			; hex?
          BNE LE8D0
          LDX #$04			; shift 4
          JMP LE8DE
LE8D0:    CPY #$0A			; decimal?
          BNE LE8AD
          LDA KNVAL
          STA TEMP
          LDA KNVAL+1
          STA TEMP+1
          LDX #$03			; decimal 3 + 1 shifts
LE8DE:    ASL KNVAL+1
          ROL KNVAL
          BCC LE8EA
          LDA IFLAGS+1
          ORA #$08
          STA IFLAGS+1
LE8EA:    DEX
          BNE LE8DE
          CPY #$0A			; decimal does another
          BNE LE912
          ASL TEMP+1
          ROL TEMP
          BCC LE8FD			; did not overflow?
          LDA IFLAGS+1
          ORA #$08
          STA IFLAGS+1
LE8FD:    LDA KNVAL+1		; add to finish
          CLC
          ADC TEMP+1
          STA KNVAL+1
          LDA KNVAL
          ADC TEMP
          STA KNVAL
          BCC LE912			; overflow?
          LDA IFLAGS+1
          ORA #$08
          STA IFLAGS+1
LE912:    LDA COLCNT
          CLC
          ADC KNVAL+1
          STA KNVAL+1
          LDA KNVAL
          ADC #$00
          STA KNVAL
          BCC LE927
          LDA IFLAGS+1
          ORA #$08
          STA IFLAGS+1
LE927:    PLA
          TAX
          INX
          DEC KLEN			; length of number
          BEQ LE931
          JMP LE894
		  
LE931:    SEC				; success
          RTS

; SEARCH SYM TAB FOR CURRENT SYM. SEARCH IS LINEAR.
; CARRY SET IF FOUND. CARRY CLEAR IF NOT FOUND.

NFIND:    LDA STSAVE
          STA SYMTBL
          LDA STSAVE+1
          STA SYMTBL+1
          LDA #$01
          STA TOPPNT+1
          LDA #$00
          STA TOPPNT
LE943:    CLV
          LDA TOPPNT
          CMP NOSYM
          BCC LE954
          BNE LE975
          LDA TOPPNT+1
          CMP NOSYM+1
          BEQ LE954
          BCS LE975
LE954:    LDY #$05
LE956:    LDA (SYMTBL),Y
          BPL LE95F
          AND #$7F
          BIT KLUDG
LE95F:    CMP ISYM,Y
          BNE LE977
          DEY
          BPL LE956
          LDY #$06
          LDA (SYMTBL),Y
          STA KNVAL
          INY
          LDA (SYMTBL),Y
          STA KNVAL+1
          BVS LE975
          RTS
LE975:    CLC
          RTS
		  
LE977:    LDA SYMTBL
          CLC
          ADC #$08
          STA SYMTBL
          BCC LE982
          INC SYMTBL+1
LE982:    INC TOPPNT+1
          BNE LE943
          INC TOPPNT
          JMP LE943
NSERT:    LDA SYMTBL+1
          CMP UNK15+1
          BCC LE999
          BNE LE9BF
          LDA SYMTBL
          CMP UNK15
          BCS LE9BF
		  
LE999:    LDY #$05				; put sym into table
LE99B:    LDA ISYM,Y
          STA (SYMTBL),Y
          DEY
          BPL LE99B
          BVC LE9AB
          JSR LEA25
          BIT KLUDG
		  
LE9AB:    LDY #$06
          LDA KNVAL
          STA (SYMTBL),Y
          INY
          LDA KNVAL+1
          STA (SYMTBL),Y
          BVS LE9BE
          INC NOSYM+1
          BNE LE9BE
          INC NOSYM
LE9BE:    RTS

LE9BF:    LDX #$37
          JSR LED1F
          JSR LF061
          JMP LF04C

; SEARCH OPCODE TAB FOR OPCODE
; CARRY SET IF OPCODE FOUND, CARRY CLEAR IF OPCODE NOT FOUND.
		  
NOPFND:    LDA LEFD2
          STA PNT1
          LDA LEFD2+1
          STA PNT1+1
          LDX #$00
LE9D6:    LDY #$02
LE9D8:    LDA ISYM,Y
          CMP (PNT1),Y
          BNE LE9ED
          DEY
          BPL LE9D8
          LDA KLTMP,X			; template
          STA JOPTEM
          LDA KLTMP1,X			; base opcode
          STA JOPBAS
          RTS
;
; NO MATCH
;
		  
LE9ED:    LDA PNT1
          CLC
          ADC #$03
          STA PNT1
          BCC LE9F8
          INC PNT1+1
LE9F8:    INX
          CPX #$39
          BMI LE9D6
          CLC				; opcode not found
          RTS
		  
LE9FF:    LDA #$FF
          STA KNVAL
          STA KNVAL+1
          LDA ISYM
          ORA #$80
          STA ISYM
          JMP NSERT
		  
LEA0E:    LDY #$01
          LDA KNVAL
          STA (IPC),Y
          INY
          LDA KNVAL+1
          STA (IPC),Y
          LDY #$06
          LDA IPC
          STA (SYMTBL),Y
          INY
          LDA IPC+1
          STA (SYMTBL),Y
          RTS
		  
LEA25:    LDY #$06
          LDA (SYMTBL),Y
          STA TEMP+2
          INY
          LDA (SYMTBL),Y
          STA TEMP+3
LEA30:    LDA TEMP+2
          CMP #$FF
          BNE LEA3D
          LDA TEMP+3
          CMP #$FF
          BNE LEA3D
          RTS
		  
LEA3D:    LDA TEMP+2
          STA TEMP
          LDA TEMP+3
          STA TEMP+1
          LDA KNVAL
          STA IEXP
          LDA KNVAL+1
          STA IEXP+1
          LDY #$00
          LDA (TEMP),Y
          CMP #BLANK
          BEQ LEA9C
          AND #$0F
          BNE LEA6C
          LDA (TEMP),Y
          AND #$10
          BEQ LEA89
          JSR LE5B6
          BCS LEA92
          LDA #$17
          JSR LECEC
          JMP LEA92
		  
LEA6C:    CMP #$01
          BNE LEA7D
          JSR LE5A8
          BCS LEA92
          LDA #$19
          JSR LECEC
          JMP LEA92
		  
LEA7D:    CMP #$09
          BCC LEA89
          BNE LEA9C
          LDA (TEMP),Y
          AND #$10
          BNE LEA9C
LEA89:    LDA KNVAL
          BEQ LEA92
          LDA #$04
          JSR LECEC
LEA92:    LDA IEXP+1
          STA IEXP
          LDA #$EA
          STA IEXP+1
          BNE LEAA4
LEA9C:    LDA KNVAL
          STA IEXP+1
          LDA KNVAL+1
          STA IEXP
LEAA4:    LDY #$02
LEAA6:    LDA (TEMP),Y
          STA TEMP+1,Y
          LDA ILSST,Y
          STA (TEMP),Y
          DEY
          BNE LEAA6
          JMP LEA30
		  
LEAB6:    PHA
          STY TEMP+4
          STX TEMP+5
          LDA IPC
          STA TEMP+6
          LDA IPC+1
          STA TEMP+7
          PLA
          STA TEMP+8
          TYA
          CLC
          ADC IPC
          STA IPC
          BCC LEAD0
          INC IPC+1
LEAD0:    LDA TEMP+8
          CMP #$02
          BCS LEAE0
          LDA #$04
          AND IFLAGS
          BEQ LEADF
          JMP LEBAD
LEADF:    RTS
LEAE0:    STA UNK23
          LDA #$14
          AND IFLAGS
          BEQ LEADF
          JSR LEBAD
          JMP LECCE

LEAEE:    LDA STSAVE
          STA SYMTBL
          LDA STSAVE+1
          STA SYMTBL+1
          LDA #$01
          STA TOPPNT+1
          LDA #$00
          STA TOPPNT
          STA KLEN
LEB00:    CLV
          LDA TOPPNT
          CMP NOSYM
          BEQ LEB0A
          BCC LEB12
LEB09:    RTS
; print symbol

LEB0A:    LDA TOPPNT+1
          CMP NOSYM+1
          BEQ LEB12
          BCS LEB09
LEB12:    JSR LED3D
          LDY #$00
LEB17:    LDA (SYMTBL),Y
          BPL LEB20
          AND #$7F
          BIT KLUDG
LEB20:    JSR LF058
          INY
          CPY #$06
          BNE LEB17
          JSR LED3A
          BVC LEB35
          LDY #$04
          JSR LEB69
          JMP LEB40
		  
LEB35:    LDA (SYMTBL),Y
          JSR LF05E
          INY
          LDA (SYMTBL),Y
          JSR LF05E
LEB40:    INC KLEN
          LDA KLEN
          CMP #$04
          BEQ LEB4E
          JSR LED34
          JMP LEB55
LEB4E:    LDA #$00
          STA KLEN
          JSR LF061
LEB55:    LDA SYMTBL
          CLC
          ADC #$08
          STA SYMTBL
          BCC LEB60
          INC SYMTBL+1
LEB60:    INC TOPPNT+1
          BNE LEB00
          INC TOPPNT
          JMP LEB00
LEB69:    LDA #$2A
          JSR LED3F
          DEY
          BNE LEB69
          RTS
		  
; .END		  
		  
LEB72:    LDX #$00			
          TXA
          TAY
          JSR LEAB6
          JSR LED44
          LDX #$4D
          JSR LED1F
          LDA UNK24
          JSR LF05E
          LDA UNK24+1
          JSR LF05E
          JSR LED44
          LDA #$40
          AND IFLAGS
          BEQ LEBA2
          LDX #$67
          JSR LED1F
          JSR LED4A
          JSR LEAEE
          JSR LED44
LEBA2:    LDX #$57
          JSR LED1F
          JSR LF061
          JMP LF04C
		  
LEBAD:    LDA TEMP+6
          STA IPC
          LDA TEMP+7
          STA IPC+1
          LDA TEMP+4
LEBB7:    PHA
          LDA #$00
          STA COLCNT
          JSR LED3D
          LDA LINEH
          JSR LED2D
          LDA LINEL
          JSR LED2D
          JSR LED3A
          LDA IPC+1
          JSR LED2D
          LDA IPC
          JSR LED2D
          JSR LED3A
          PLA
          TAX
          CMP #$04
          BCC LEBE7
          LDX #$02
          SEC
          SBC #$02
          JMP LEBE9
LEBE7:    LDA #$00
LEBE9:    PHA
LEBEA:    DEX
          BMI LEC15
          LDY #$00
          LDA (IPC),Y
          PHA
          LDA TEMP+8
          CMP #$01
          BNE LEC05
          CPX #$02
          BEQ LEC05
          LDY #$02
          JSR LEB69
          PLA
          JMP LEC09
LEC05:    PLA
          JSR LED2D
LEC09:    JSR LED3D
          INC IPC
          BNE LEBEA
          INC IPC+1
          JMP LEBEA
LEC15:    LDA UNK19
          BNE LEC3A
          LDX IMAXCL
          BMI LEC3A
LEC1D:    JSR LED3D
          LDY COLCNT
          CPY #$19
          BNE LEC1D
          LDA TEMP+8
          CMP #$02
          BCS LEC32
          LDA IFLAGS
          AND #BLANK
          BNE LEC37
LEC32:    JSR LEC58
          BCS LEC3A
LEC37:    JSR LEC68
LEC3A:    JSR LF061
          INC UNK19
          PLA
          BEQ LEC57
          TAX
          LDA #$80
          AND IFLAGS
          BNE LEC4D
          TXA
          JMP LEBB7
LEC4D:    CLC
          TXA
          ADC IPC
          STA IPC
          BCC LEC57
          INC IPC+1
LEC57:    RTS
LEC58:    LDX #$FF
LEC5A:    JSR LE5A1
          BCS LEC67
LEC5F:    LDA ICRD,X
          JSR LF058
          JMP LEC5A
LEC67:    RTS
LEC68:    LDX IEXP+2
          STX ICOLP
          JSR NFNDNB
          BCC LECA8
          CMP #SEMICL
          BEQ LEC5F
          LDY JLABL
          BEQ LEC8D
LEC79:    JSR LED3F
          JSR LE5A1
          BCS LECA8
          JSR NALPH
          BCS LEC79
          STX ICOLP
          JSR NFNDNB
          BCC LECA8
LEC8D:    JSR LED3D
          LDA COLCNT
          CMP #BLANK
          BCC LEC8D
LEC96:    LDA ICRD,X
          CMP #BLANK
          BEQ LECA9
          CMP #SEMICL
          BEQ LECC2
          JSR LED3F
          JSR LE5A1
          BCC LEC96
LECA8:    RTS
LECA9:    STX ICOLP
          JSR LED3D
          JSR NFNDNB
          BCC LECA8
LECB3:    LDA ICRD,X
          CMP #SEMICL
          BEQ LECC2
          JSR LED3F
          JSR LE5A1
          BCC LECB3
          RTS
LECC2:    JSR LED3D
          LDA COLCNT
          CMP #$30
          BCC LECC2
          JMP LEC5F
LECCE:    JSR LED03
          LDX #$0A
LECD3:    JSR LED3D
          DEX
          BNE LECD3
          LDX TEMP+5
LECDB:    DEX
          BMI LECE4
          JSR LED3D
          JMP LECDB
LECE4:    LDA #'^'
          JSR LF058
          JMP LF061
LECEC:    STA UNK23
          JSR LED03
          LDX #$13
          JSR LED1F
          LDA TEMP+1
          JSR LF05E
          LDA TEMP
          JSR LF05E
          JMP LF061
LED03:    LDX #$07
          JSR LED1F
          LDA UNK23
          JSR LF05E
          SED
          CLC
          LDA UNK24+1
          ADC #$01
          STA UNK24+1
          LDA UNK24
          ADC #$00
          STA UNK24
          CLD
          JMP LED3A
LED1F:    LDA MESSAGE,X
          CMP #$25
          BEQ LED2C
          JSR LF058
          INX
          BNE LED1F
LED2C:    RTS
LED2D:    INC COLCNT
          INC COLCNT
          JMP LF05E
LED34:    JSR LED3D
          JSR LED3D
LED3A:    JSR LED3D
LED3D:    LDA #BLANK
LED3F:    INC COLCNT
          JMP LF058
LED44:    JSR LF061
          JSR LF061
LED4A:    JSR LF061
          JMP LF061

LED50:    LDY #$00
          LDA (UNK12),Y
          CMP #EOT
          BNE LED5B
          JMP LF04C
LED5B:    STA LINEH
          INY
          LDA (UNK12),Y
          STA LINEL
          JSR LF055
          TYA
          TAX
          DEX
LED68:    LDA (UNK12),Y
          STA TEMP+7,Y
          DEY
          CPY #$02
          BCS LED68
          JMP LF052
;
; Assembler tables
;		  
ASMJMP:
		.word	LE356	; NOLIST
		.word   LE351	; LIST
		.word	LE34C	; NOT
		.word	LE347	; TAB
		.word	LE342	; NOERR
		.word	LE33D	; ERR
		.word	LE35A	; CONT
		.word	LE35A	; CNT
		.word	LE35A	; NOCNT
		.word	LE338	; NOSYMBOL
		.word	LE333	; SYMBOL
		.word	LE32E	; NOGEN
		.word	LE329	; GEN
		  
		.word	LE304	; .OPT
		.word	LEB72	; .END
		.word	LE059	; .PAGE
		.word	LE059	; .SKIP
		.word	LE059	; .DBYT
		.word	LE254	; .WORD
		.word	LE250	; .BYTE
;
; pseudo text
;
PSEUDO1:
	.byte "BYT"
	.byte "WOR"
	.byte "DBY"
	.byte "SKI"
	.byte "PAG"
	.byte "END"
	.byte "OPT"
PSEUDO2:
	.byte "GEN"
	.byte "NOG"
	.byte "SYM"
	.byte "NOS"
	.byte "NOC"
	.byte "CNT"
	.byte "COU"
	.byte "ERR"
	.byte "NOE"
	.byte "TAB"
	.byte "NOT"
	.byte "LIS"
	.byte "NOL"
	
OPTDIR:	
	.byte "ADC"
	.byte "AND"
	.byte "ASL"
	.byte "BCC"
	.byte "BCS"
	.byte "BEQ"
	.byte "BIT"
	.byte "BMI"
	.byte "BNE"
	.byte "BPL"
	.byte "BRK"
	.byte "BVC"
	.byte "BVS"
	.byte "CLC"
	.byte "CLD"
	.byte "CLI"
	.byte "CLV"
	.byte "CMP"
	.byte "CPX"
	.byte "CPY"
	.byte "DEC"
	.byte "DEX"
	.byte "DEY"
	.byte "EOR"
	.byte "INC"
	.byte "INX"
	.byte "INY"
	.byte "JMP"
	.byte "JSR"
	.byte "LDA"
	.byte "LDX"
	.byte "LDY"
	.byte "LSR"
	.byte "NOP"
	.byte "ORA"
	.byte "PHA"
	.byte "PHP"
	.byte "PLA"
	.byte "PLP"
	.byte "ROL"
	.byte "ROR"
	.byte "RTI"
	.byte "RTS"
	.byte "SBC"
	.byte "SEC"
	.byte "SED"
	.byte "SEI"
	.byte "STA"
	.byte "STX"
	.byte "STY"
	.byte "TAX"
	.byte "TAY"
	.byte "TSX"
	.byte "TXA"
	.byte "TXS"
	.byte "TYA"

; Constant tables

KLUDG:            
		.byte $FF
        .byte $0D
        .byte $1B
        .byte $29
        .byte $37
        .byte $45
        .byte $53
        .byte $61
        .byte $6F
        .byte $7D
        .byte $8B
        .byte $99
        .byte $A7
        .byte $B5
LEE8F:  .byte $C3

 
KLTBL:    .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $04    ;%00000100
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
LEE99:    .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $04    ;%00000100
          .byte $04    ;%00000100
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $00
          .byte $04    ;%00000100
          .byte $00
          .byte $04    ;%00000100
          .byte $00
          .byte $00
          .byte $04    ;%00000100
          .byte $00
          .byte $FF    ;%11111111
          .byte $00
          .byte $14    ;%00010100
          .byte $14    ;%00010100
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
		  .byte $10
		  .byte $FF
          .byte $FF    ;%11111111
          .byte $14    ;%00010100
          .byte $FF    ;%11111111
		  .byte $10
		  .byte $FF
		  .byte $10
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
		  .byte $10
		  .byte $FF
          .byte $14    ;%00010100
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $00
          .byte $00
		  .byte $20
		  
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte	$10
          .byte	$10
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $08
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
LEF2E:    .byte $FF    ;%11111111
          .byte $00
          .byte $FF    ;%11111111
          .byte $00
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $00
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $0C    ;%00001100
          .byte $0C    ;%00001100
          .byte $00
          .byte $00
          .byte $08
          .byte $0C    ;%00001100
          .byte $08
          .byte $0C    ;%00001100
          .byte $08
          .byte $08
          .byte $0C    ;%00001100
          .byte $08
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $1C    ;%00011100
          .byte $1C    ;%00011100
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $18
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $1C    ;%00011100
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $18
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $18
          .byte $18
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $1C    ;%00011100
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
          .byte $FF    ;%11111111
		  
KLTMP:		  
        .byte $01
        .byte $01
        .byte $05
        .byte $0E
        .byte $0E
        .byte $0E
        .byte $07
        .byte $0E
        .byte $0E
        .byte $0E
        .byte $14
        .byte $0E
        .byte $0E
        .byte $14
        .byte $14
        .byte $14
        .byte $14
        .byte $01
        .byte $06
        .byte $06
        .byte $0C
        .byte $14
        .byte $14
        .byte $01
        .byte $0C
        .byte $14
        .byte $14
        .byte $03
        .byte $04
        .byte $01
        .byte $0B
        .byte $08
        .byte $05
        .byte $14
        .byte $01
        .byte $14
        .byte $14
        .byte $14
        .byte $14
        .byte $05
        .byte $05
        .byte $14
        .byte $14
        .byte $01
        .byte $14
        .byte $14
        .byte $14
        .byte $02
        .byte $09
        .byte $0A
        .byte $14
        .byte $14
        .byte $14
        .byte $14
        .byte $14
        .byte $14
		
KLTMP1: .byte $61
        .byte $21
        .byte $06
        .byte $90
        .byte $B0
        .byte $F0
        .byte $24
        .byte $30
        .byte $D0
        .byte $10
        .byte $00
        .byte $50
        .byte $70
        .byte $18
        .byte $D8
        .byte $58
        .byte $B8
        .byte $C1
        .byte $E0
        .byte $C0
        .byte $C6
        .byte $CA
        .byte $88
        .byte $41
        .byte $E6
        .byte $E8

LEFB4:   
        .byte $C8
        .byte $4C
        .byte $20
        .byte $A1
        .byte $A2
        .byte $A0
        .byte $46
        .byte $EA
        .byte $01
        .byte $48
        .byte $08
        .byte $68
        .byte $28
        .byte $26
        .byte $66
        .byte $40
        .byte $60
        .byte $E1
        .byte $38
        .byte $F8
        .byte $78
        .byte $81
        .byte $86
        .byte $84
        .byte $AA
        .byte $A8
        .byte $BA
        .byte $8A
        .byte $9A
        .byte $98

LEFD2:  .word OPTDIR    	; ####
		
LEFD4:  .word PSEUDO1

LEFD6:  .word PSEUDO2

; Messages
	
MESSAGE:
	.byte "KIMASM%"
	.byte "***ERROR # %"
	.byte "PC = %"
	.byte "LINE # LOC     CODE      LINE%"
	.byte "SYMBOL TABLE OVERFLOW%"
	.byte "ERRORS = %"
	.byte "END OF ASSEMBLY%"
	.byte "SYMBOL TABLE%"

; jump table
;		  
LF04C:    JMP LF237
LF04F:    JMP LF5C1
LF052:    JMP LF5DA
LF055:    JMP LF5FA
LF058:    JMP PRCHAR
LF05B:    JMP LF664
LF05E:    JMP NUMA
LF061:    JMP LF690

LF064:    JMP (UNK16)

;
; table?  PROBABLY JUNK BYTES!
;
LF067:  .byte $34
        .byte $7C
        .byte $6C
        .byte $00
        .byte $05
        .byte $A6
        .byte $88
        .byte $32
        .byte $06
        .byte $10
        .byte $36
        .byte $21
        .byte $6A
        .byte $92
        .byte $B6
        .byte $2E
        .byte $08
        .byte $21
        .byte $37
        .byte $04
        .byte $22
        .byte $8A
        .byte $32
        .byte $06
        .byte $00
        .byte $B3
        .byte $1A
        .byte $7F
        .byte $53
        .byte $57 
        .byte $52
        .byte $C7
        .byte $5D
        .byte $D6
        .byte $15
        .byte $D3
        .byte $8E
        .byte $19
        .byte $55
        .byte $39
        .byte $E1
        .byte $5D
        .byte $4E
        .byte $60
        .byte $40
        .byte $65
        .byte $DD
        .byte $3F
        .byte $5F
        .byte $71
        .byte $94
        .byte $DB
        .byte $42
        .byte $45
        .byte $FF
        .byte $59
        .byte $9D
        .byte $FD
        .byte $D3
        .byte $DB
        .byte $35
        .byte $DD
        .byte $7D
        .byte $DD
        .byte $EE
        .byte $D5
        .byte $85
        .byte $2A
        .byte $0C
        .byte $74
        .byte $7F
        .byte $1D
        .byte $CD
        .byte $19
        .byte $1F
        .byte $DA
        .byte $80
        .byte $FB
        .byte $AD
        .byte $49
        .byte $FF
        .byte $71
        .byte $0B
        .byte $E7
        .byte $D5
        .byte $E1
        .byte $FD
        .byte $EB
        .byte $DF
        .byte $5F
        .byte $50
        .byte $D7
        .byte $34
        .byte $CC
        .byte $78
        .byte $F8
        .byte $ED
        .byte $F7
        .byte $C3
        .byte $D6
        .byte $14
        .byte $3C
        .byte $7F
        .byte $67
        .byte $6F
        .byte $72
        .byte $12
        .byte $FF
        .byte $31
        .byte $B9
        .byte $F5
        .byte $41
        .byte $6D
        .byte $6E
        .byte $D2
        .byte $7D
        .byte $CD
        .byte $ED
        .byte $E5
        .byte $F3
        .byte $DD
        .byte $7E
        .byte $4D
        .byte $EF
        .byte $F5
        .byte $7C
        .byte $FB
        .byte $D9
        .byte $F5
        .byte $F7
        .byte $CD
        .byte $FD
        .byte $A0
        .byte $DB
        .byte $CB
        .byte $D7
        .byte $FC
        .byte $DB
        .byte $8E
        .byte $4A
        .byte $50
        .byte $F5
        .byte $9F
        .byte $DB
        .byte $FE
        .byte $D5
        .byte $07
        .byte $F4
        .byte $D5
        .byte $E7
        .byte $FD
        .byte $F5
        .byte $F9

;
; Cold and warm start of editor
;		 
		 
COLDEDT:  JSR VECTORF
WARMEDT:  LDA #$00
          STA UNK4
LF107:    CLD
          JSR LF690
          LDX #$0C
          JSR LF524
          LDX #$00
          JSR LF451
          LDX #$00
LF117:    LDA ICRD,X
          JSR LF664
          CMP #$00
          BNE LF107
          INX
          CPX #$04
          BNE LF117
          LDA INL
          STA UNK13
          LDA INH
          STA UNK13+1
          JSR LF5C1
LF130:    LDX #$12
          JSR LF524
          LDX #$00
          JSR LF451
          LDA ICRD
          CMP #'N'
          BEQ LF174
          CMP #'O'
          BNE LF130
          JSR LF35A
          JSR LF2CE
          JSR LF5C1
LF14D:    LDA UNK4
          BEQ LF154
          JSR PRCHAR
LF154:    LDX #$00
          JSR LF451
          LDA ICRD
          CMP #$30
          BMI LF163
          CMP #$3A
          BMI LF19D
LF163:    LDY #$00
LF165:    LDA LF1A3,Y
          CMP #$FF
          BEQ LF17F
          CMP ICRD
          BEQ LF187
          INY
          JMP LF165
LF174:    LDY #$00
          STY UNK10
          LDA #EOT
          STA (UNK12),Y
          JMP LF14D
LF17F:    LDX #$00
          JSR LF524
          JMP LF14D
LF187:    TYA
          ASL A
          TAY
          LDA LF1B1,Y
          STA UNK11
          LDA LF1B1+1,Y
          STA UNK11+1
          JSR LF19A
          JMP LF14D
LF19A:    JMP (UNK11)
LF19D:    JSR LF2F8
          JMP LF14D
; table		  
LF1A3:  .byte $50
        .byte $46
        .byte $53
        .byte $52
        .byte $51
        .byte $45
        .byte $3F
        .byte $58
        .byte $41
        .byte $0B
        .byte $14
        .byte $54
        .byte $2A
        .byte $FF
LF1B1:  .word LF3FC
        .word LF280
        .word LF2CE
        .word LF23D
        .word LF107
        .word LF237
        .word LF229
        .word LF226
        .word LF219
        .word LF213
        .word LF1E0
        .word LF1CB
        .word LF1DF

LF1CB:    JSR LF1D5  
          LDA #$41
          STA ICRD+2
          JSR LF3FC
LF1D5:    LDX #$14
          LDA #$00
LF1D9:    JSR PRCHAR
          DEX
          BNE LF1D9
LF1DF:    RTS

LF1E0:    LDA ICRD+1
          CMP #$0D
          BEQ LF210
          ASL A
          ASL A
          ASL A
          ASL A
          STA ID
          LDA ICRD+2
          CMP #$0D
          BEQ LF210
          AND #$0F
          ORA ID
          STA ID
          LDX #$03
LF1FD:    LDA UNK13,X
          STA SAL,X
          DEX
          BPL LF1FD
          INC EAL
          BNE LF20D
          INC EAH
LF20D:    JMP DUMPT
;
LF210:    JMP LF44B

LF213:    LDX #$FF
          TXS
          JMP KSTART

LF219:    LDA #<LED50
          STA UNK16
          LDA #>LED50
          STA UNK16+1
          PLA
          PLA
LF223:    JMP LE000
		  
LF226:    JMP (IOVCTBL+8)
LF229:    LDA ICRD+1
          CMP #$0D
          BEQ LF232
          STA UNK4
          RTS
		  
LF232:    LDA #$3F
          STA UNK4
          RTS
		  
LF237:    LDX #$FF
          TXS
          JMP LF6A2
LF23D:    JSR LF35A
          LDA UNK5
          CMP #BLANK
          BPL LF210
          JSR LF5C1
          LDA #$00
          STA UNK5
          STA UNK5+1
          LDA #$05
          STA UNK3
LF253:    LDY #$00
          LDA (UNK12),Y
          CMP #EOT
          BEQ LF26D
          JSR LF26E
          LDA UNK5
          STA (UNK12),Y
          INY
          LDA UNK5+1
          STA (UNK12),Y
          JSR LF5DA
          JMP LF253
LF26D:    RTS

LF26E:    SED
          CLC
          LDA UNK5+1
          ADC UNK3
          STA UNK5+1
          BCC LF27E
          LDA UNK5
          ADC #$00
          STA UNK5
LF27E:    CLD
          RTS

LF280:    LDA ICRD+1
          CMP #BLANK
          BNE LF2C9
          LDA #$0D
          STA UNK3
          LDX #$02
          STX UNK7
          JSR LF604
          CPY #$00
          BEQ LF2C9
          STY UNK8
          JSR LF5C1
          LDY #$00
          LDA (UNK12),Y
          CMP #EOT
          BEQ LF2C4
          JSR LF555
          BEQ LF2BE
LF2A7:    JSR LF5DA
          LDA (UNK12),Y
          CMP #EOT
          BEQ LF2C4
          JSR LF555
          BNE LF2A7
          JSR LF5EC
LF2B8:    JSR LF4EA
          JMP LF2A7

LF2BE:    JSR LF5C1
          JMP LF2B8
LF2C4:    LDX #$08
          JMP LF2CB
LF2C9:    LDX #$00
LF2CB:    JMP LF524

LF2CE:    LDA UNK13+1
          JSR NUMA
          LDA UNK13
          JSR NUMA
          JSR PRBLANK
          LDA UNK14+1
          JSR NUMA
          LDA UNK14
          JSR NUMA
          JSR PRBLANK
          JSR LF35A
          LDA UNK5
          JSR NUMA
          LDA UNK5+1
          JSR NUMA
          JMP LF690

LF2F8:    JSR LF575
          LDA #$04
          STA UNK3
          JSR LF507
          CMP #$00
          BNE LF359
          JSR LF5C1
          LDA UNK10
          BEQ LF33E
LF30D:    JSR LF4B4
          BEQ LF38D
          BCS LF37B
          LDA UNK7
          CMP #$05
          BEQ LF359
          SEC
          SBC #$02
          STA UNK9
          LDY #$00
          LDA (UNK12),Y
          STA UNK6
          LDA #$0F
          STA (UNK12),Y
          LDA UNK14
          STA UNK11
          LDA UNK14+1
          STA UNK11+1
          JSR LF62D
          LDA UNK6
          STA (UNK11),Y
          JSR LF4D2
          JMP LF3F0

LF33E:    INC UNK10
          LDA UNK7
          CMP #$05
          BEQ LF378
LF346:    JSR LF4D2
          INY
          LDA #EOT
          STA (UNK12),Y
          JSR LF5DA
LF351:    LDA UNK12
          STA UNK14
          LDA UNK12+1
          STA UNK14+1
LF359:    RTS

LF35A:    LDA #$00
          STA UNK5
          STA UNK5+1
          JSR LF5C1
          LDA #$01
          STA UNK3
LF367:    LDY #$00
          LDA (UNK12),Y
          CMP #EOT
          BEQ LF351
          JSR LF26E
          JSR LF5DA
          JMP LF367

LF378:    DEC UNK10
          RTS

LF37B:    JSR LF5DA
          LDA (UNK12),Y
          CMP #EOT
          BNE LF30D
          LDA UNK7
          CMP #$05
          BEQ LF359
          JMP LF346
LF38D:    JSR LF5FA
          LDA UNK7
          CMP #$05
          BEQ LF3C9
          DEY
          STY UNK9
          LDA UNK7
          SEC
          SBC #$04
          STA UNK8
          SBC UNK9
          BCS LF3DA
          SEC
          LDA UNK9
          SBC UNK8
          STA UNK9
          CLC
          LDA UNK8
          ADC UNK12
          STA UNK11
          LDA UNK12+1
          BCC LF3B8
          ADC #$00
LF3B8:    STA UNK11+1
          JSR LF618
          JSR LF4D2
LF3C0:    LDA UNK11
          STA UNK14
          LDA UNK11+1
          STA UNK14+1
          RTS

LF3C9:    INY
          STY UNK9
          LDA UNK12
          STA UNK11
          LDA UNK12+1
          STA UNK11+1
          JSR LF618
          JMP LF3C0

LF3DA:    STA UNK9
          LDY #$02
          LDA #$0F
          STA (UNK12),Y
          LDA UNK14
          STA UNK11
          LDA UNK14+1
          STA UNK11+1
          JSR LF62D
          JSR LF4D2
LF3F0:    CLC
          LDA UNK9
          ADC UNK14
          STA UNK14
          BCC LF3FB
          INC UNK14+1
LF3FB:    RTS

LF3FC:    JSR LF5C1
          LDX #$02
          LDA ICRD,X
          CMP #$41			; % ?
          BEQ LF43E
          CMP #$30			; number?
          BMI LF44B
          CMP #$3A
          BPL LF44B
          LDA #$86
          STA UNK11
          JSR LF579
          LDA #$06
          STA UNK3
          LDX #$02
          JSR LF509
          CMP #$00
          BNE LF3FB
LF423:    LDY #$00
          LDA (UNK12),Y
          CMP #EOT			; end of text? 
          BEQ LF446
          JSR LF4B4
          BEQ LF43E
          BCC LF43E
          JSR LF5DA
          JMP LF423
;		  
LF438:    JSR LF4EA
          JSR LF5DA
LF43E:    LDY #$00
          LDA (UNK12),Y
          CMP #EOT			; end of text ?
          BNE LF438
LF446:    LDX #$08
          JMP LF524
		  
LF44B:    LDX #$00
          JSR LF524
          RTS
		  
LF451:    LDA #$07			; init PIA
          STA SBD
          LDA #$11
          JSR PRCHAR
LF45B:    LDX #$00
LF45D:    JSR INKEY
          CMP #$00
          BEQ LF45D
          CMP #BLANK
          BEQ LF45D
          CMP #$0A
          BEQ LF45D
          BNE LF481
LF46E:    STA ICRD,X
          INX
          CPX #$47
          BNE LF47E
LF475:    JSR INKEY
          CMP #$0D
          BNE LF475
          BEQ LF4A2
LF47E:    JSR INKEY
LF481:    CMP #$7F
          BEQ LF47E
          CMP #$18
          BNE LF48F
          JSR LF690
          JMP LF45B
LF48F:    CMP #$5F
          BEQ LF497
          CMP #$08
          BNE LF49E
LF497:    CPX #$00
          BEQ LF47E
          DEX
          BPL LF47E
LF49E:    CMP #$0D
          BNE LF46E
LF4A2:    STA ICRD,X
          INX
          STX UNK7
          LDA #QUOTE
          STA SBD			; init PIA
          LDA #$13
          JSR PRCHAR
          JMP LF690
LF4B4:    SEC
          LDY #$01
          LDA (UNK12),Y
          SBC INL
          DEY
          LDA (UNK12),Y
          SBC INH
          BCC LF4CC
          BNE LF4D0
          INY
          LDA (UNK12),Y
          CMP INL
          BNE LF4D0
          RTS
LF4CC:    LDA #$01
          SEC
          RTS
LF4D0:    CLC
          RTS
LF4D2:    LDY #$00
          LDA INH
          STA (UNK12),Y
          INY
          LDA INL
          STA (UNK12),Y
          LDX #$04
LF4DF:    INY
          LDA ICRD,X
          STA (UNK12),Y
          INX
          CPX UNK7
          BNE LF4DF
LF4E9:    RTS
LF4EA:    LDY #$00
          LDA (UNK12),Y
          JSR NUMA
          INY
          LDA (UNK12),Y
          JSR NUMA
LF4F7:    INY
          LDA (UNK12),Y
          CMP #$0D
          BEQ LF504
          JSR PRCHAR
          JMP LF4F7
;
LF504:    JMP LF690
;
LF507:    LDX #$00
LF509:    LDA ICRD,X
          CMP #$3A
          BPL LF51C
          JSR LF664
          CMP #$00
          BNE LF51C
          INX
          CPX UNK3
          BNE LF509
          RTS

LF51C:    LDX #$1A
          JMP LF524
LF521:    JSR PRCHAR			; answer required? 
LF524:    LDA MSGTXT,X
          CMP #$0D
          BEQ LF504
          CMP #$FF
          BEQ LF4E9
          INX
          BNE LF521
; 
; messages
;	
MSGTXT:	.byte "BAD COM"
		.byte CR
		.byte "*ET"
		.byte CR
		.byte "BASE="
		.byte $FF
		.byte "N OR O?"
		.byte $FF
		.byte "BAD NUM."
		.byte CR
;		  
LF555:    LDX UNK7
          LDY #$00
LF559:    LDA (UNK12),Y
          CMP #$0D
          BEQ LF569
          CMP ICRD,X
          BEQ LF56C
          JSR LF5CA
          JMP LF555
LF569:    LDA #$01
          RTS
	  
LF56C:    INX
          INY
          CPY UNK8
          BNE LF559
          LDA #$00
          RTS
LF575:    LDA #$84
          STA UNK11
LF579:    LDA #$00
          STA UNK11+1
          LDY #$FF
LF57F:    INY
          LDA (UNK11),Y
          CMP #$30
          BMI LF58A
          CMP #$3A
          BMI LF57F
LF58A:    CPY #$04
          BPL LF5AE
          DEY
          LDA LF5AF,Y
          STA UNK6
          LDY UNK7
          CLC
          ADC UNK7
          TAX
          STA UNK7
          DEY
          STY UNK5
          DEX
          STX UNK5+1
          JSR LF5B2
          LDY UNK6
          LDA #$30
LF5A9:    DEY
          STA (UNK11),Y
          BNE LF5A9
LF5AE:    RTS

LF5AF:    .byte $03    ;%00000011
          .byte $02    ;%00000010
          .byte $01

LF5B2:	  LDY UNK5
		  LDA (UNK11),Y	
          LDY UNK5+1
          STA (UNK11),Y
          DEC UNK5+1
          DEC UNK5
		  BPL LF5B2
          RTS
		  
LF5C1:    LDA UNK13
          STA UNK12
          LDA UNK13+1
          STA UNK12+1
          RTS
		  
LF5CA:    INC UNK12
          BNE LF5D0
          INC UNK12+1
LF5D0:    RTS

LF5D1:    LDA UNK12
          BNE LF5D7
          DEC UNK12+1
LF5D7:    DEC UNK12
          RTS

LF5DA:    LDY #$00
LF5DC:    LDA (UNK12),Y
          CMP #$0D
          BEQ LF5E8
          JSR LF5CA
          JMP LF5DC
LF5E8:    JSR LF5CA
          RTS
		  
LF5EC:    LDY #$00
LF5EE:    LDA (UNK12),Y
          CMP #$0D
          BEQ LF5E8
          JSR LF5D1
          JMP LF5EE
LF5FA:    LDY #$FF
LF5FC:    INY
          LDA (UNK12),Y
          CMP #$0D
          BNE LF5FC
          RTS

LF604:    LDY #$00
LF606:    LDA ICRD,X
          CMP UNK3
          BEQ LF617
          CMP #$0D
          BEQ LF615
          INY
          INX
          JMP LF606
LF615:    LDY #$FF
LF617:    RTS

LF618:    LDY UNK9
          LDA (UNK11),Y
          LDY #$00
          STA (UNK11),Y
          CMP #EOT
          BEQ LF617
          INC UNK11
          BNE LF618
          INC UNK11+1
          JMP LF618
		  
LF62D:    LDY #$00
          LDA (UNK11),Y
          LDY UNK9
          STA (UNK11),Y
          CMP #$0F
          BEQ LF617
          LDA UNK11
          BNE LF63F
          DEC UNK11+1
LF63F:    DEC UNK11
          JMP LF62D
		  
SAVEREG:   STA UNK0
          PHP
          PLA
          STA UNK1
          LDA UNK0
          STY SAVEY
          STX SAVEX
          RTS

; Print character		
		
PRBLANK:   LDA #BLANK		; print blank
PRCHAR:    JSR SAVEREG
          JSR OUTCHAR
RESTREG:   LDA UNK1
          PHA
          PLP
          LDA UNK0
LF65F:    LDY SAVEY
          LDX SAVEX
          RTS

LF664:    JSR SAVEREG
          JSR PACK
          JMP LF65F
		  
INKEY:    STY SAVEY
          JSR INCHAR
          LDY SAVEY
          RTS

; PRINT HEX NUMBER IN A

		  
NUMA:     JSR SAVEREG
          LSR A
          LSR A
          LSR A
          LSR A
          JSR NOUT
NOUT:     AND #$0F
          CMP #$0A
          CLC
          BMI LF688
          ADC #$07
LF688:    ADC #$30
          JSR OUTCHAR
          JMP RESTREG
		  
LF690:    JSR SAVEREG
          JSR PRCRLF
          JMP RESTREG
;
; Jump into vector table
;		  

INCHAR:   JMP (IOVCTBL)			; getch
OUTCHAR:  JMP (IOVCTBL+2)		; outch with break
PRCRLF:   JMP (IOVCTBL+4)		; CRLF
LF6A2:    JMP (IOVCTBL+6)		; monitor
	
;
; Fill vector table with KIM-1 defaults for I/O
;
VECTORF:  LDX #$09
LF6A7:    LDA VCTBL,X
          STA IOVCTBL,X
          DEX
          BPL LF6A7
          RTS
VCTBL:		  
        .word	GETCH	; KIM-1 input getch character
        .word 	LF6BA	; KIM-1 ouch character with break test
        .word	CRLF	; print CRLF
        .word	KSTART	; jump to KIM-1 monitor
        .word	LF617	; user exit
;
; print character with break test on KIM-1
;
LF6BA:    PHA
          CMP #$13		; Return?
          BEQ LF6DF
          LDA SBD		
          AND #$DF
LF6C4:    STA SBD
          LDA SAD		; break test
          BMI LF6DF
LF6CC:    LDA SAD		; break test end
          BPL LF6CC
          LDA #$FF
          JSR OUTCH		; get character
          LDX #$FF		; if break clear stack 
          TXS
          JSR CRLF
          JMP LF14D		; back to editor
LF6DF:    PLA
          JMP OUTCH		; print character and return from there
;
; table 
;		  
        .byte $08
        .byte $CA
        .byte $08
        .byte $70
        .byte $DC
        .byte $F8
        .byte $FB
        .byte $74
        .byte $DB
        .byte $3A
        .byte $F4
        .byte $A9
        .byte $18
        .byte $68
        .byte $5D
        .byte $AD
        .byte $99
        .byte $34
        .byte $78
        .byte $24
        .byte $19
        .byte $CB
        .byte $1E
        .byte $F8
        .byte $3F
        .byte $40
        .byte $88
        .byte $62
;		
; KIM tape dump routine		
; callable as subroutine
;  
          SEC
          LDA #$AD
          STA VEB
          JSR INTVEB 
          LDA #QUOTE
          STA POINTH
          LDA #$BF
          STA PBDD
          LDX #$64
          LDA #$16		; sync pulses
          JSR LF761
          LDA #$2A		; start of tape
          JSR LF788
          LDA ID
          JSR LF770
          LDA SAL
          JSR LF76D
          LDA SAH
          JSR LF76D
LF72F:    JSR VEB		; dump bytes to tape
          JSR LF76D
          JSR INCVEB
          LDA VEB+1		; all done? 
          CMP EAL
          LDA VEB+2		
          SBC EAH
          BCC LF72F
          LDA #$2F		; end of tape 
          JSR LF788
          LDA CHKL
          JSR LF770
          LDA CHKH
          JSR LF770
          LDX #$02
          LDA #$04
          JSR LF761
          JMP DUMPTA	; contine in KIM-1 monitor
		  
LF761:    STX POINTL
LF763:    PHA
          JSR LF788
          PLA
          DEC POINTL
          BNE LF763
          RTS
LF76D:    JSR CHKT		; compute checksum

LF770:    PHA
          LSR A
          LSR A
          LSR A
          LSR A
          JSR LF77D
          PLA
          JSR LF77D
          RTS

LF77D:    AND #$0F
          CMP #$0A
          CLC
          BMI LF786
          ADC #$07
LF786:    ADC #$30
LF788:    LDY #$08
          STY TEMPA
LF78C:    LDY #$02
          STY TMPX
LF790:    LDX LF7BE,Y
          PHA
LF794:    BIT CLKKT			; time elapsed?
          BPL LF794
          LDA LF7BF,Y
          STA CLK1T
          LDA POINTH
          EOR #$80
          STA SBD
          STA POINTH
          DEX
          BNE LF794
          PLA
          DEC TMPX
          BEQ LF7B5
          BMI LF7B9
          LSR A
          BCC LF790
LF7B5:    LDY #$00
          BEQ LF790
LF7B9:    DEC TEMPA
          BNE LF78C
          RTS
		  
LF7BE:  .byte $02
LF7BF:  .byte $C3
        .byte $03
        .byte $7E
        .byte $F1
        .byte $D2
        .byte $7C
        .byte $D9
        .byte $F1
        .byte $79
        .byte $E5
        .byte $FF
        .byte $A8
        .byte $99
        .byte $B4
        .byte $D2
        .byte $88
        .byte $DD
        .byte $A1
        .byte $B5
        .byte $62
        .byte $7F
        .byte $A5
        .byte $C8
        .byte $E5
        .byte $E9
        .byte $E7
        .byte $95
        .byte $28
        .byte $11
        .byte $3A
        .byte $B4
        .byte $F3
        .byte $88
        .byte $EB
        .byte $49
        .byte $A9
        .byte $06
        .byte $EE
        .byte $0A
        .byte $E6
        .byte $4E
        .byte $6C
        .byte $57 
        .byte $79
        .byte $0F
        .byte $E2
        .byte $36
        .byte $A7
        .byte $14
        .byte $AF
        .byte $89
        .byte $3E
        .byte $11
        .byte $39
        .byte $91
        .byte $EC
        .byte $8E
        .byte $23
        .byte $17
        .byte $22
        .byte $93
        .byte $38
        .byte $99
        .byte $52
        .byte $96
;
; Differences between 6540-007 .. -009 ROM and EPROMS
;
;   
; WARMEDT LDA #$00 -> $3A 
; E586   C9 50                CMP #$50 (EPROM)
; E586   C9 4E                CMP #NOSYM (6540)
;
; F219 A9 50                 LDA #NOSYM (EPROM
; F219 A9 4E                 LDA #$50  (6540)
;  
; 6540 
; F20D 4C 00 18    LF20D     JMP DUMPT
;   
; KIM EPROM
; F20D 4C A9 F7   LF20D      JMP LF7A9
;
; F7A9  20  E3 F6            JSR LF6E3   (a KIM tape dump routine as subroutine)
;        4C  4D F1			 JMP LF14D


; A kim tape dump routine as subroutine
;
; F6E3   A9 AD                LDA #$AD
; F6E5   8D EC 17             STA $17EC
; F6E8   20 32 19             JSR $1932
; F6EB   A9 27                LDA #QUOTE
; F6ED   85 F5                STA $F5
; F6EF   A9 BF                LDA #$BF
; F6F1   8D 43 17             STA $1743
; F6F4   A2 64                LDX #$64
; F6F6   A9 16                LDA #$16
; F6F8   20 44 F7             JSR LF744
; F6FB   A9 2A                LDA #$2A
; F6FD   20 6C F7             JSR LF76C
; F700   AD F9 17             LDA $17F9
; F703   20 53 F7             JSR LF753
; F706   AD F5 17             LDA $17F5
; F709   20 50 F7             JSR LF750
; F70C   AD F6 17             LDA $17F6
; F70F   20 50 F7             JSR LF750
; F712   20 EC 17   LF712     JSR $17EC
; F715   20 50 F7             JSR LF750
; F718   20 EA 19             JSR $19EA
; F71B   AD ED 17             LDA $17ED
; F71E   CD F7 17             CMP $17F7
; F721   AD EE 17             LDA $17EE
; F724   ED F8 17             SBC $17F8
; F727   90 E9                BCC LF712
; F729   A9 2F                LDA #$2F
; F72B   20 6C F7             JSR LF76C
; F72E   AD E7 17             LDA $17E7
; F731   20 53 F7             JSR LF753
; F734   AD E8 17             LDA $17E8
; F737   20 53 F7             JSR LF753
; F73A   A2 02                LDX #$02
; F73C   A9 04                LDA #$04
; F73E   20 44 F7             JSR LF744
; F741   60                   RTS
; F742   EA                   NOP
; F743   EA                   NOP
; F744   86 F1      LF744     STX $F1
; F746   48         LF746     PHA
; F747   20 6C F7             JSR LF76C
; F74A   68                   PLA
; F74B   C6 F1                DEC $F1
; F74D   D0 F7                BNE LF746
; F74F   60                   RTS
; F750   20 4C 19   LF750     JSR $194C
; F753   48         LF753     PHA
; F754   4A                   LSR A
; F755   4A                   LSR A
; F756   4A                   LSR A
; F757   4A                   LSR A
; F758   20 60 F7             JSR LF760
; F75B   68                   PLA
; F75C   20 60 F7             JSR LF760
; F75F   60                   RTS
; F760   29 0F      LF760     AND #$0F
; F762   C9 0A                CMP #$0A
; F764   18                   CLC
; F765   30 03                BMI LF76A
; F767   EA                   NOP
; F768   69 07                ADC #$07
; F76A   69 30      LF76A     ADC #$30
; F76C   A0 07      LF76C     LDY #$07
; F76E   84 F2                STY $F2
; F770   A0 02      LF770     LDY #$02
; F772   84 F3                STY $F3
; F774   BE A4 F7   LF774     LDX $F7A4,Y
; F777   48                   PHA
; F778   2C 47 17   LF778     BIT $1747
; F77B   10 FB                BPL LF778
; F77D   B9 A5 F7             LDA $F7A5,Y
; F780   8D 44 17             STA $1744
; F783   A5 F5                LDA $F5
; F785   49 80                EOR #$80
; F787   8D 42 17             STA $1742
; F78A   85 F5                STA $F5
; F78C   CA                   DEX
; F78D   D0 E9                BNE LF778
; F78F   68                   PLA
; F790   C6 F3                DEC $F3
; F792   F0 07                BEQ LF79B
; F794   EA                   NOP
; F795   30 08                BMI LF79F
; F797   EA                   NOP
; F798   4A                   LSR A
; F799   90 D9                BCC LF774
; F79B   A0 00      LF79B     LDY #$00
; F79D   F0 D5                BEQ LF774
; F79F   C6 F2      LF79F     DEC $F2
; F7A1   10 CD                BPL LF770
; F7A3   60                   RTS
; F7A4   02                   ???                ;%00000010
; F7A5   C3                   ???                ;%11000011
; F7A6   03                   ???                ;%00000011
; F7A7   7E FF 20             ROR BLANKFF,X
; F7AA   E3                   ???                ;%11100011
; F7AB   F6 4C                INC LINEH,X
; F7AD   4D F1 FF             EOR $FFF1
; 
          .END

