; -----------------------------------------------
;  PS/2 Mouse to CPC Symbiface II Mouse Converter
; -----------------------------------------------
;  Copyright (C) 2023 Dimitris Kefalas
;  Version: V1.0 (7-Feb-2023)
;  
;  Based on "PS/2 Mouse to Amiga Mouse Converter" by Nevenko Baričević

;  This program is free software: you can redistribute it and/or modify
;  it under the terms of the GNU General Public License as published by
;  the Free Software Foundation, either version 3 of the License, or
;  (at your option) any later version.

;  This program is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU General Public License for more details.

;  You should have received a copy of the GNU General Public License
;  along with this program.  If not, see <http://www.gnu.org/licenses/>.
	list    p=p16f84a
	#include <p16f84a.inc>
	
	__CONFIG   _CP_OFF & _WDT_OFF & _PWRTE_ON & _RC_OSC	

; ---------- registers definition -----------

byte    equ     0x0c		; byte to receive or send
parity  equ     0x0d		; parity bit is held here
parcnt  equ     0x0e		; counter for calculating parity
roller  equ     0x0f		; help for 8 data bits to byte conversion
devid	equ	0x10		; mouse device id
mkeys   equ     0x11		; 1st byte of mouse data packet
xpos    equ     0x12		; 2nd byte of mouse data packet
ypos    equ     0x13		; 3rd byte of mouse data packet
zpos	equ	0x14		; 4th byte of mouse data packet
count   equ     0x15		; packet counter
delcnt  equ     0x16		; delay counter
rkeys   equ     0x17		; real key status
okeys   equ     0x18		; old real key status

; --------- entry point -----------

	org     0
		
	goto	main

; --------- interrupt service routine -----------
	org	4
		
	movf    count,W
	xorlw   0x00		; if count is 00 read mouse
	btfsc   STATUS,Z
	goto    RD_M
	movf    count,W
	xorlw   0x01		; if count is 01 set port b to xpos
	btfsc   STATUS,Z
	goto    SETX
	movf    count,W
	xorlw   0x02		; if count is 02 set port b to ypos
	btfsc   STATUS,Z
	goto    SETY
	movf    count,W
	xorlw   0x03		; if count is 03 set port b to zpos
	btfsc   STATUS,Z
	goto	ZSET
	goto	SETK		; if count is 04 set port b to mkeys

RD_M:   clrf	PORTB		; set mouse data to 0
	bcf	PORTA,2
	incf    count		; packet counter = 01		
	movlw   0xeb		; "Read Data " command to mouse
	call    SENDCMD
	call    REC		; receive byte1 from mouse packet
	call    INHIB
	movf    byte,W
	movwf   mkeys
	andlw	0x07		; get real keys status
	iorlw	0xc0
	movwf	rkeys
	call    REL
	call    REC		; receive byte2 from mouse packet
	call    INHIB
	movf    byte,W
	movwf   xpos
	call    REL
	call    REC		; receive byte3 from mouse packet
	call    INHIB
	movf    byte,W
	movwf   ypos
	call    REL
	movfw	devid		; test if mouse supports 4th byte
	xorlw	0x00
	btfsc	STATUS,Z
	;goto	GOON
	goto    SETX
	call    REC		; receive byte4 from mouse packet
	call    INHIB
	movf    byte,W
	movwf   zpos
	call    REL
	movfw	devid		; test if mouse supports 4th, 5th button
	xorlw	0x04
	btfsc	STATUS,Z
	goto	GOON
	btfsc	zpos,4
	bsf	rkeys,3
	btfsc	zpos,5
	bsf	rkeys,4
	;goto	GOON

SETX:   incf	count 
	movf    xpos,W	
	andlw   0xff		; if xpos=0 go to ypos
	btfsc   STATUS,Z
	goto    SETY
	movf    xpos,W		; set portb to 01(xpos)
	btfsc   mkeys,4		; check if move to right or left
	goto	SETX2
	andlw   0xe0		; check if x overflow right
	btfss   STATUS,Z
	goto    SETX3
	movf    xpos,W
	andlw	0x1f
	iorlw	0x40
	goto    SETX1
SETX3:  movlw   0x5f
	goto    SETX1
SETX2:	andlw   0xe0		; check if x overflow left
	xorlw   0xe0
	btfsc   STATUS,Z
	goto    SETX4
	movlw   0x60
	goto    SETX1
SETX4:  movf    xpos,W
	andlw	0x1f
	iorlw	0x60
SETX1:  movwf   PORTB
	bcf	PORTA,2		; lsb is PORTA bit 2
	btfsc	xpos,0
	bsf	PORTA,2
	goto	GOON

SETY:   incf	count 
	movf    ypos,W	
	andlw   0xff		; if ypos=0 go to zset
	btfsc   STATUS,Z
	goto    ZSET
	movf    ypos,W		; set portb to 10(xpos)
	btfsc   mkeys,5		; check if move to up or down
	goto	SETY2
	andlw   0xe0		; check if y overflow up
	btfss   STATUS,Z
	goto    SETY3
	movf    ypos,W
	andlw	0x1f
	iorlw	0x80
	goto    SETY1
SETY3:  movlw   0x9f
	goto    SETY1
SETY2:	andlw   0xe0		; check if y overflow down
	xorlw   0xe0
	btfsc   STATUS,Z
	goto    SETY4
	movlw   0xa0
	goto    SETY1
SETY4:  movf    ypos,W
	andlw	0x1f
	iorlw	0xa0
SETY1:  movwf   PORTB
	bcf	PORTA,2		; lsb is PORTA bit 2
	btfsc	ypos,0
	bsf	PORTA,2
	goto	GOON

ZSET:	incf	count
	movf    zpos,W	
	andlw   0x0f		; if zpos=0 go to mkeys
	btfsc   STATUS,Z
	goto    SETK
	movf	zpos,W
	andlw	0x0f
	xorlw   0x0f		; 2's complement
	addlw   0x01		;
	iorlw	0xe0
	movwf	PORTB
	bcf	PORTB,4		; expand sign bit
	btfss	zpos,3
	bsf	PORTB,4
	bcf	PORTA,2		; lsb is PORTA bit 2
	btfsc	zpos,0
	bsf	PORTA,2
	goto	GOON

SETK:   clrf	count
	movf	okeys,W		; check if keys status has changed
	xorwf	rkeys,W
	btfsc	STATUS,Z
	goto	RD_M
	movfw   rkeys		; set portb to 11000kkk
	movwf	okeys		; set old keys status = real keys status
	movwf   PORTB
	bcf	PORTA,2		; lsb is PORTA bit 2
	btfsc	rkeys,0
	bsf	PORTA,2 

GOON:  	bcf     INTCON,INTF     ;INTF - clear int flag
	retfie			; return from int

;---------------------- main routine -------------------

main:   bsf     STATUS,RP0	; page 1
	bsf     TRISA,0		; port A, bit 0 is input
	bsf     TRISA,1		; port A, bit 1 is input
	bcf     TRISA,2		; port A, bit 2 is output - lsb of mouse -
	clrf    TRISB		; port B is all outputs
	bsf     TRISB,0		; port B, bit 0 is input - interrupt -
	bcf     STATUS,RP0	; page 0
	clrf    PORTB		; port B all pins to 0
	bcf	PORTA,2		; port A pin 2 to 0
	clrf    count		; packet counter = 00
	movlw   0xc0
	movwf	rkeys		; real keys status = 11000000
	movwf	okeys		; old real keys status = 11000000

	movlw   0xff		; "Reset" command to mouse
	call    SENDCMD
		
	call    REC		; receive byte from mouse	
	call    INHIB		; pull CLK low to inhibit furhter sending	
	movf    byte,W
	xorlw   0xaa		; if it's $AA mouse self test passed
	btfss   STATUS,Z
	goto    IERROR
	call    REL		; release CLK (allow mouse to send)
	call    REC		; receive byte from mouse
	call    INHIB
	movf    byte,W
	xorlw   0x00		; mouse ID code should be $00
	btfss   STATUS,Z
	goto    IERROR

;---------------- check if mouse supports z position and 4th, 5th button -----------
	movlw   0xf3		; "Set sample rate" command to mouse
	call    SENDCMD
	movlw   0xc8		; "Sample rate=200" command to mouse
	call    SENDCMD
	movlw   0xf3		; "Set sample rate" command to mouse
	call    SENDCMD
	movlw   0xc8		; "Sample rate=200" command to mouse
	call    SENDCMD
	movlw   0xf3		; "Set sample rate" command to mouse
	call    SENDCMD
	movlw   0x50		; "Sample rate=80" command to mouse
	call    SENDCMD
	movlw   0xf2		; "Get Device ID" command to mouse
	call    SENDCMD
	call    REC		; receive byte from mouse
	call    INHIB
	movf    byte,W
	movwf	devid
	xorlw   0x04		; mouse ID code should be $04
	btfsc   STATUS,Z
	goto    MSET
	movlw   0xf3		; "Set sample rate" command to mouse
	call    SENDCMD
	movlw   0xc8		; "Sample rate=200" command to mouse
	call    SENDCMD
	movlw   0xf3		; "Set sample rate" command to mouse
	call    SENDCMD
	movlw   0x64		; "Sample rate=100" command to mouse
	call    SENDCMD
	movlw   0xf3		; "Set sample rate" command to mouse
	call    SENDCMD
	movlw   0x50		; "Sample rate=80" command to mouse
	call    SENDCMD
	movlw   0xf2		; "Get Device ID" command to mouse
	call    SENDCMD
	call    REC		; receive byte from mouse
	call    INHIB
	movf    byte,W
	movwf	devid

MSET:   ;movlw   0xf3		; "Set sample rate" command to mouse
	;call    SENDCMD
	;movlw   0x0a		; "Sample rate=10" command to mouse
	;call    SENDCMD
	movlw   0xe8		; "Set resolution" command to mouse
	call    SENDCMD
	movlw   0x00		; "Resolution=x count/mm" (0=1, 1=2, 2=4, 3=8) command to mouse
	call    SENDCMD
	movlw   0xf0		; "Set Remote Mode" command to mouse
	call    SENDCMD

	bsf     INTCON,GIE	;GIE \96 Global interrupt enable (1=enable)
	bsf     INTCON,INTE     ;INTE - RB0 interrupt enable (1=enable)
    	bcf     INTCON,INTF     ;INTF - clear int flag

WINT:   goto    WINT    	; wait for int

	
; ----------- error handler -----------------------------

PERROR: nop
RERROR: nop
IERROR: bcf	PORTA,2
	clrf    PORTB		; port B all pins to 00000000
E_LOOP: goto    IERROR		;E_LOOP

; ---------- delay routine ----------------------------

DEL10:  nop			; delay 10us
	return
DEL200: movlw   0x32		; delay 200us
	movwf   delcnt
DEL2:   decfsz  delcnt
	goto    DEL2
	return

; --------- byte receiving subroutine -------------

REC:    btfsc   PORTA,0		; wait clock (start bit)
	goto    REC	
RL1:    btfss   PORTA,0
	goto    RL1	
	call    RECBIT		; receive 8 data bits
	call    RECBIT
	call    RECBIT
	call    RECBIT
	call    RECBIT
	call    RECBIT
	call    RECBIT
	call    RECBIT
RL2:    btfsc   PORTA,0		; receive parity bit
	goto    RL2
	btfsc   PORTA,1
	goto    RL3
	bcf     parity,0
RL4:    btfss   PORTA,0		; receive stop bit
	goto    RL4
STP:    btfsc   PORTA,0
	goto    STP
	btfss   PORTA,1
	goto    RERROR
RL8:    btfss   PORTA,0
	goto    RL8
	return
RL3:    bsf     parity,0
	goto    RL4

; ---------- bit receiving subroutine ------------

RECBIT: btfsc   PORTA,0
	goto    RECBIT
	movf    PORTA,W
	movwf   roller
	rrf     roller
	rrf     roller
	rrf     byte
RL5:    btfss   PORTA,0
	goto    RL5
	return

; ---------- subroutines -----------------

INHIB:  call    CLKLO		; inhibit mouse sending (CLK low)
	call    DEL200
	return
REL:    call    CLKHI		; allow mouse to send data
	return
CLKLO:  bsf     STATUS,RP0	; CLK low
	bcf     TRISA,0
	bcf     STATUS,RP0
	bcf     PORTA,0
	return
CLKHI:  bsf     STATUS,RP0	; CLK high
	bsf     TRISA,0
	bcf     STATUS,RP0
	return
DATLO:  bsf     STATUS,RP0	; DATA low
	bcf     TRISA,1
	bcf     STATUS,RP0
	bcf     PORTA,1
	return
DATHI:  bsf     STATUS,RP0	; DATA high
	bsf     TRISA,1
	bcf     STATUS,RP0
	return

; ------------- send to mouse --------------

SEND:   call    INHIB		; CLK low
	call    DEL10
	call    DATLO		; DATA low
	call    DEL10
	call    REL		; CLK high
SL1:    btfsc   PORTA,0		; wait for CLK
	goto    SL1
	call    SNDBIT		; send 8 data bits
SS1:    btfss   PORTA,0
	goto    SS1
SS2:    btfsc   PORTA,0
	goto    SS2
	call    SNDBIT
SS3:    btfss   PORTA,0
	goto    SS3
SS4:    btfsc   PORTA,0
	goto    SS4
	call    SNDBIT
SS5:    btfss   PORTA,0
	goto    SS5
SS6:    btfsc   PORTA,0
	goto    SS6
	call    SNDBIT
SS7:    btfss   PORTA,0
	goto    SS7
SS8:    btfsc   PORTA,0
	goto    SS8
	call    SNDBIT
SS9:    btfss   PORTA,0
	goto    SS9
SS10:   btfsc   PORTA,0
	goto    SS10
	call    SNDBIT
SS11:   btfss   PORTA,0
	goto    SS11
SS12:   btfsc   PORTA,0
	goto    SS12
	call    SNDBIT
SS13:   btfss   PORTA,0
	goto    SS13
SS14:   btfsc   PORTA,0
	goto    SS14
	call    SNDBIT
SS15:   btfss   PORTA,0
	goto    SS15
SS16:   btfsc   PORTA,0
	goto    SS16
	call    SNDPAR		; send parity bit
SS17:   btfss   PORTA,0
	goto    SS17
SS18:   btfsc   PORTA,0
	goto    SS18
	call    DATHI		; release bus
SL4:    btfss   PORTA,0
	goto    SL4
SL5:    btfsc   PORTA,0
	goto    SL5
	btfsc   PORTA,1
	goto    RERROR
SL7:    btfss   PORTA,0
	goto    SL7
SL8:    btfss   PORTA,1
	goto    SL8
	return

; -------------- subroutines --------------

SNDBIT: rrf     byte		; send data bit
	btfsc   STATUS,C
	goto    DHIGH
	call    DATLO
SL2:    return
DHIGH:  call    DATHI
	goto    SL2
SNDPAR: btfsc   parity,0	; send parity bit
	goto    PHIGH
	call    DATLO
SP1:    return
PHIGH:  call    DATHI
	goto    SP1
CLCPAR: movlw   0		; calculate parity bit
	movwf   parcnt
	btfsc   byte,0
	incf    parcnt
	btfsc   byte,1
	incf    parcnt
	btfsc   byte,2
	incf    parcnt
	btfsc   byte,3
	incf    parcnt
	btfsc   byte,4
	incf    parcnt
	btfsc   byte,5
	incf    parcnt
	btfsc   byte,6
	incf    parcnt
	btfsc   byte,7
	incf    parcnt
	return
NEWPAR: call    CLCPAR
	btfss   parcnt,0
	goto    PARONE
	bcf     parity,0
	return
PARONE: bsf     parity,0
	return
CHKPAR: call    CLCPAR		; check parity
	movf    parcnt,W
	andlw   0x01
	movwf   parcnt
	movf    parity,W
	xorwf   parcnt
	btfss   STATUS,Z
	return
	call    PERROR
	return

; --------- command send subroutine -------------

SENDCMD:movwf   byte
	call    NEWPAR		; get parity for command byte
	call    REL
	call    DEL200
	call    SEND		; send command to mouse
	call    REC		; receive acknowledge ($FA) from mouse)
	call    INHIB
	movf    byte,W
	xorlw   0xfa
	btfss   STATUS,Z
	goto    IERROR
	call    REL
	return

	end
