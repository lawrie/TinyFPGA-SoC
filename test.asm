;;Test program.
;;By Lawrie Griffiths

	processor 6502
	include "vcs.h"
	include "macro.h"
	
	seg.u vars
	org $80

	seg Code
	org $FF00		
	
Start:	
    SEI
	CLD
	
	LDX    #$28                ;Clear TIA Registers   
    LDA    #$00                ;&04-&2C i.e. blank   
ResetAll:
    STA    NUSIZ0,X            ;Everything And Turn. 
    DEX                        ;Everything Off.  
    BPL    ResetAll                                                                                       
    TXS                        ;Reset Stack
SetupVars:
    STA    VSYNC,X             ;Clear &80 to &FF User Vars.                                               ;4    
    DEX                                                                                                   ;2    
    BMI    SetupVars 
	
	LDA #70		               ;Set background colour
	STA COLUBK
Start_Frame:	

	jmp Start_Frame		
	

	echo "----",($FFFC - *) ," bytes left"
	
	org $FFFC
	.word Start
	.word Start