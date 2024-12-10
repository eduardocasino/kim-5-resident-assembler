.OPT ERRORS, NOLISTING, SYMBOLS
; VISUALLY DISPLAYS DISTRIBUTION OF THE PRIME NUMBERS BETWEEN 1 AND 128000
; (EXCEPT FOR "2") USING A SIEVE ALGORITHM.
;
; REQUIRES KIM-1 WITH A K-1008 VISABLE MEMORY CARD
;
; BASED ON THE DESCRIPTION OF A SIMILAR PROGRAM THAT MTU'S HAL CHAMBERLIN
; WROTE FOR THE MTU-130
;
; BE SURE YOUR INTERRUPT VECTOR (AT L7FE AND 17FF) IS SET TO ADDRESS $1C00
;
; 04 FEB. 2024 - EDUARDO CASINO (MAIL@EDUARDOCASINO.ES)
;
; THIS PROGRAM IS IN THE PUBLIC DOMAIN
;
VMORG  = $A000        ; VISUAL MEMORY LOCATION
; NX     = 320        ; NUNMBER OF BITS IN A ROW
; NY     = 200        ; NUMBER OF ROWS
NPIX   = 64000        ; NUMBER OF PIXELS
FIRST  = 3            ; FIRST CANDIDATE TO CHECK
LAST   = 357          ; LAST CANDIDATE TO CHECK:
;                         SCREEN SIZE IS 64000, LAST ODD
;                         INTEGER THAT FITS IS 127999:
;                           TRUNC(127999/2) = 63999
;                         SO LAST INT TO CHECK:
;                           TRUNC(SQRT(127999)) = 357
;
       *= $A0
;
ADP1   *=*+2            ADDRESS POINTER    
CNDATE *=*+2            CANDIDATE COUNTER
CNDP   *=*+2            MULTIPLE OF CANDIDATE PIXEL
BTPT   *=*+1            BIT NUMBER
;
       *= $200
;
       JSR FILSCR
;
       LDA #FIRST       INITIALIZE CANDIDATES COUNTER AND
       STA CNDATE       POSITION
       LDA #0
       STA CNDATE+1
;
CHECK  LDA CNDATE+1
       LSR A
       STA CNDP+1
       LDA CNDATE
       ROR A
       STA CNDP
       JSR PIXADR       GET PIXEL ADDR AND BIT POS
       LDY BTPT
       LDA MSKTB1,Y     GET PIXEL MASK
       LDY #0 
       AND (ADP1),Y     SET?
       BEQ NEXT         NO, CHECK NEXT CANDIDATE
;
; CLEAR MULTIPLES
;
CLRMUL CLC              ADVANCE CNDATE POSITIONS
       LDA CNDATE
       ADC CNDP
       STA CNDP
       LDA CNDATE+1
       ADC CNDP+1
       STA CNDP+1
;
       LDA #>NPIX-1     COMPARE TO SCREEN SIZE
       CMP CNDP+1
       BCC NEXT         GREATER, NEXT CANDIDATE
       BNE CLRMU1       SMALLER, CONTINUE
       LDA #<NPIX-1
       CMP CNDP
       BCC NEXT         GREATER, NEXT CANDIDATE
CLRMU1 JSR PIXADR       GET PIXEL ADDR AND BIT MASK
       LDY BTPT
       LDA MSKTB2,Y     GET INVERTED PIXEL MASK
       LDY #0 
       AND (ADP1),Y     CLEAR PIXEL
       STA (ADP1),Y
       JMP CLRMUL       ADVANCE TO NEXT MULTIPLE
;
NEXT   CLC
       LDA #2
       ADC CNDATE
       STA CNDATE
       BCC ISBGR
       INC CNDATE+1
;
ISBGR  LDA #>LAST+1    COMPARE TO LAST CANDIDATE
       CMP CNDATE+1
       BCC DONE         GREATER, DONE 
       BNE CHECK        LOWER, LOOP
       LDA #<LAST+1
       CMP CNDATE
       BCS CHECK        LOWER, LOOP
;
DONE   BRK              YES, WE'RE DONE!
;
;        THESE ROUTINES ARE ADAPTED FROM THE K-1008 GRAPHICS SOFTWARE PACKAGE
;
;        FILL ENTIRE SCREEN ROUTINE
;
FILSCR LDY #0           INITIALIZE ADDRESS POINTER
       STY ADP1         AND ZERO Y
       LDA #>VMORG
       STA ADP1+1
       CLC              COMPUTE END ADDRESS
       ADC #NPIX/8/256
       TAX              KEEP IT IN X
SET1   LDA #$FF         SET A BYTE
       STA (ADP1),Y
       INC ADP1         NEXT LOCATION
       BNE SET2
       INC ADP1+1
SET2   LDA ADP1         DONE?
       CMP #<NPIX/8
       BNE SET1         LOOP IF NOT
       CPX ADP1+1
       BNE SET1
       RTS
;
;       FIND THE ADDRESS AND BIT NUMBER OF THE PIXEL REPRESENTING
;       THE CANDIDATE. TAKES CANDIDATE POSITION AT CNDP AND PUTS
;       THE BYTE ADDRESS IN ADP1 AND BIT MASK (BIT 0 IS LEFTMOST)
;       IN BTPT.
;
PIXADR LDA CNDP         TRANSFER POSITION TO ADP1
       STA ADP1
       LDA CNDP+1
       STA ADP1+1
       LDA ADP1         COMPUTE BIT ADDRESS
       AND #$07
       STA BTPT
       LSR ADP1+1       COMPUTE BYTE ADDRESS
       ROR ADP1
       LSR ADP1+1
       ROR ADP1
       LSR ADP1+1
       ROR ADP1
       CLC
       LDA #>VMORG      ADD BASE ADDRESS
       ADC ADP1+1
       STA ADP1+1
       RTS
;
;        MASK TABLES FOR INDIVIDUAL PIXEL SUBROUTINES
;        MSKTB1 IS A TABLE OF 1 BITS CORRESPONDING TO BIT NUMBERS
;        MSKTB2 IS A TABLE OF 0 BITS CORRESPONDING TO BIT NUMBERS
;
MSKTB1 .BYTE $80,$40,$20,$10
       .BYTE $08,$04,$02,$01
MSKTB2 .BYTE $7F,$BF,$DF,$EF
       .BYTE $F7,$FB,$FD,$FE
;
       .END