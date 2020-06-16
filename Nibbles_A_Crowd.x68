;-----------------------------------------------------------
; Title      :
; Written by :
; Date       :
; Description:
;-----------------------------------------------------------

    ORG    $1000
CR          EQU     $0D                 
LF          EQU     $0A                 
HT          EQU     $05   

START:                  
    
DISASSEMBLER        LEA     DISASSEMBLER_DISPLAY,A1 ;opening
                    MOVE.B  #14,D0
                    TRAP    #15

STARTREAD           LEA     STARTMESSAGE,A1 ;start address
                    MOVE.B  #14,D0
                    TRAP    #15
                    JSR     convertAddress                          
                    MOVEA.L D0,A2                                 

ENDREAD             LEA     ENDMESSAGE,A1 ;end address
                    MOVE.B  #14,D0
                    TRAP    #15
                    JSR     convertAddress                          
                    MOVE.L  D0,A3                       
                    
                    MOVE.L  A2,D1
                    SUB.L   D1,D0
                    CMP.L   #2,D0
                    BGE     ADDRESSLOOP
                    JSR     ERROR_DISPLAY
                    BRA     STARTREAD
                
ADDRESSLOOP         CMP.L   #10,A4                  ;reads in 10 lines
                    BNE     CONTINUE_PRINTING
                    LEA     CONTINUE_ADDRESSES,A1   
                    MOVE.B  #14,D0
                    TRAP    #15
                    MOVE.B  #5,D0
                    TRAP    #15
                    MOVE.L  #0,A4

CONTINUE_PRINTING   JSR     READIN          ;raw dissasembler
                    JSR     PRINT_DISASSEMBLE
                    ADD.L   #1,A4
			  CMP.L   A2,A3           
                    BGT     ADDRESSLOOP       
                    LEA     QUIT_PROMPT,A1 ;quit prompt     
                    MOVE.B  #14,D0
                    TRAP    #15
                    MOVE.B  #5,D0               
                    TRAP    #15
                    CMP.B   #$59,D1    ;user check          
                    BEQ     FINISH        
                    CMP.B   #$79,D1
                    BNE     STARTREAD
                                                                                           
FINISH        SIMHALT


convertAddress         MOVEM.L     D1-D7/A0-A6,-(SP)
                       CLR.L       D1
                       LEA         INPUT_SIZE,A1
                       MOVE.B      #2,D0
                       TRAP        #15
                       BRA         ASCII_REG
                        
convertAddress_POST    MOVEM.L     (SP)+,D1-D7/A0-A6
                       RTS
                        
ASCII_REG       CLR.L       D0
                MOVE.L      #8,D0   ;ascii format
                CMP.B       D0,D1
                BEQ         ASCII_FORMAT
                SUB.L       D1,D0
                SUB.L       D0,A1
                MOVE.B      #6,D1

                        
ASCII_FORMAT    CMP.B       #0,D1
                BEQ         toHex
                MOVE.B      (A1)+, D2
                JSR         toHexNumber
                ASL.B       #4, D2
                MOVE.B      D2, D0
                ASL.L       #4, D0
                SUBI.B      #1, D1
                BRA         ASCII_FORMAT
                                
toHex   	    MOVE.B     (A1)+, D2
                JSR         toHexNumber
                ASL.B       #4, D2
                ADD.B       D2, D0
                MOVE.B      (A1)+, D2
                JSR         toHexNumber
                ADD.B       D2, D0
                JMP         convertAddress_POST

toHexNumber     CMP.B       #$39, D2                ;error checking
                BGT         toHexFromUpper
                SUBI.B      #$30, D2                ;convert the address into hexadecimal num by subtracting 48
                RTS
                    
toHexFromUpper  CMP.B       #$60, D2        ;error checking
                BGT         toHexFromLower         
                SUBI.B      #$37, D2            ; convert the address into hexadecimal num by subtracting 55
                RTS
                
toHexFromLower  SUBI.B      #$57,D2             ; convert the address into hexadecimal num by subtracting 97
				RTS

INVALIDADDRESS   MOVEM.L     D0-D7/A0-A6, -(SP)
                 LEA         ERROR_DISPLAY, A1
                 MOVE.B      #14,D0
                 TRAP        #15
                 MOVEM.L    (SP)+,D0-D7/A0-A6
                 RTS

READIN:          
        
        CLR.L   D7
        CLR.L      D2 
        MOVE.W    (A2),D2  ;
        SWAP       D2
        ROL.L      #2, D2 ;OP FOR MOVE
        AND.B      #$03,D2 ;MASK 
        CMP.B      #$0,D2
        BEQ        OP_00__ ;OP_00__, MOVE, MOVEA

        CLR.L       D2
        MOVE.W     (A2),D2 
        SWAP        D2 ;SWAP ADDRESS TO REVERSE NIBBLES PER INPUT
        ROL.L       #4, D2 ;BRING THE FIRST 4 MSB OF THE INSTRUCTION TO THE FRONT
        AND.B       #$0F,D2 ; MASK 

  
        CMP.B       #%1000, D2
        BEQ         OP_OR ;OR
	  CMP.B       #%0101, D2  
        BEQ         OP_0101 ;ADDQ 
        CMP.B       #%0111, D2
        BEQ         OP_0111 ;MOVEQ
	  CMP.B       #%1001, D2
        BEQ         OP_1001 ;SUB
        CMP.B       #%1110, D2
        BEQ         OP_1110  ;ASd,ROd,LSd  ,SHIFT
	  CMP.B       #%1100, D2 
        BEQ         OP_1100 ;MAY BE IT'S AND
        CMP.B       #%1101, D2 
        BEQ         OP_1101 ;ADDA, ADD
	  CMP.B       #%0110, D2
        BEQ         OP_0110 ;BRA, BGT, BEQ
        CMP.B       #%0100,D2
        BEQ         OP_0100 ;NOT, NOP, RTS, MOVEM, LEA, JSR 

 
        
OP_INVALID      MOVE.B   #5, D7 ; A WRONG INSTRUCTION 'KEY'
                MOVEA.L  A2, A6 ;MOVING THE MEMORY ADDRESS INTO A6 WHEN INSTRUCTION IS WRONG 
                MOVE.W  (A2),D6 ;MOVE MEMORY ADDRESS INTO D6, AND INCREMENT A2 BY WORD
                RTS

OP_00__         CLR.L   D2
                MOVE.W  (A2),D2
                SWAP    D2 ;flip to obtain last 4 nibble
                ROL.L   #4,D2 ;ROLL THE 4 MSB TO THE FRONT 
                AND.B   #$0F,D2 ;MASK
                CMP.B   #$0, D2 ;immediate instructions 
                BEQ     OP_INVALID 
               
                CLR.L   D2
                MOVE.W  (A2),D2
                LSR.W   #6, D2 ;op to msb
                AND.B   #$07, D2 ;MASK OTHER BITS
                CMP.B   #$01, D2 ;
                BEQ     OP_MOVEA

                
;===========================================================
; MOVE, 01,11,10
;
;===========================================================        
            
OP_MOVE         LEA     MOVE_DISPLAY, A6 ;OUTPUT LINE
				JSR	EA_OP_00__ 
                MOVE.W (A2),D2 ;
                LSR     #8,D2  ;MAKE A TOTAL OF 12 OP_1110  TO PUSH 12,AND 13 BIT TO FRONT
                LSR     #4, D2 ;REMOVE REGISTER 
                AND.B   #$03, D2 ;MASK 
                CMP.B   #$01, D2
                BEQ     BYTE_SIZE
                CMP.B   #$03,D2
                BEQ     WORD_SIZE
                CMP.B   #$02, D2
                BEQ     LONG_SIZE
                JMP     WRONG_SIZE
                 
                 
WRONG_SIZE      MOVE.B  #5, D7 ;ELSE IT'S WRONG SIZE
                MOVEA.L  A2, A6 
                MOVE.W  (A2),D6 
                RTS          
 
BYTE_SIZE       ADD.B #1, D7
                RTS 
   
WORD_SIZE       ADD.B  #2, D7
                RTS
                
LONG_SIZE       ADD.B  #4, D7
                RTS
            
;===========================================================
; MOVEA, 01,11,10
;
;===========================================================  

OP_MOVEA        LEA     MOVEA_DISPLAY, A6
                JSR	EA_OP_00__ 
		    MOVE.W (A2),D2 ;
                LSR.L   #8, D2 ;GET THE 13, 12 BITS FOR SIZE
                LSR.L   #4, D2 ;TOTAL OF 11 OP_1110 S 
                AND.B   #$03,D2 ;MASK THE BITS OTHER THAN SIZE BITS
                CMP.B   #$03, D2 
                BEQ     WORD_SIZE 
                CMP.B   #$02,D2
                BEQ     LONG_SIZE                 
                JMP     WRONG_SIZE 
           
;===========================================================
; ADDQ , 01,11,10
;
;===========================================================  

OP_0101                 CLR.L        D2
                        MOVE.W       (A2),D2
                        BTST         #8,D2 ;INSTRUCTION FORMAT
                        BEQ          OP_ADDQ ; == 0
                        JMP          OP_INVALID

OP_ADDQ                 CLR.L       D2
                        MOVE.W      (A2),D2
                        LSR.L       #6,D2
                        AND.B       #$03,D2
                        CMP.B       #$03,D2
                        BEQ         OP_INVALID 
                        LEA         ADDQ_DISPLAY, A6 
                        JSR         EA_OP_1101
						
                        MOVE.W      (A2),D2
                        LSR.L        #6, D2
                        AND.B        #$03, D2
                        CMP.B        #$00,D2
                        BEQ          BYTE_SIZE
                        CMP.B        #$1, D2
                        BEQ          WORD_SIZE
                        CMP.B        #$2, D2
                        BEQ          LONG_SIZE
                        JMP          WRONG_SIZE

;===========================================================
; MOVEQ
;
;===========================================================        
OP_0111                 LEA     MOVEQ_DISPLAY, A6
                        MOVE.B  #0, D7 
				JSR     EA_OP_0111
                        RTS

OP_OR                   MOVE.W  (A2),D2
                        LSR.L   #3, D2
                        AND.B   #$0F,D2
                        CMP.B   #$3, D2
                        BEQ     OP_INVALID ;DIVU && DIVS
                        MOVE.W  (A2),D2
                        LSR.L   #4,D2
                        AND.B   #$1F,D2
                        CMP.B   #$10,D2
                        BEQ     OP_INVALID ; SBCD
                        
                        LEA     OR_DISPLAY, A6  ;ELSE IT IS OR INSTRUCTION
                        JSR     EA_ARITHMETIC
OP_SIZE                                     ;OPERAND
                        MOVE.W  (A2),D2
                        LSR.L   #6,D2
                        AND.B   #$07,D2
                        CMP.B   #$0,D2
                        BEQ     BYTE_SIZE
                        CMP.B   #$4, D2 
                        BEQ     BYTE_SIZE

                        CMP.B   #$1, D2
                        BEQ     WORD_SIZE
                        CMP.B   #$5, D2
                        BEQ     WORD_SIZE

                        CMP.B   #$2, D2
                        BEQ     LONG_SIZE
                        CMP.B   #$6, D2
                        BEQ     LONG_SIZE
                        JMP     WRONG_SIZE


;===========================================================
; SUB
;
;===========================================================  
 
OP_1001                 MOVE.W  (A2),D2
                        LSR.L   #6,D2
                        AND.B   #$03,D2
                        CMP.B   #$3,D2
                        BEQ     OP_INVALID 
                        MOVE.W  (A2),D2
                        BTST    #8,D2 
                        BNE     OP_INVALIDSUB

OP_SUBOUTPUT            LEA     SUB_DISPLAY, A6
                        JSR     EA_ARITHMETIC
                        JMP     OP_SIZE
                        
OP_INVALIDSUB           MOVE.W  (A2),D2
                        LSR.L    #4,D2
                        AND.B    #$03,D2
                        CMP.B    #$0,D2
                        BEQ       OP_INVALID    
                        JMP       OP_SUBOUTPUT     

;===========================================================
; ADD
;
;===========================================================   

OP_1100                 CLR.L      D2
                        MOVE.W     (A2),D2
                        LSR.L      #6,D2
                        AND.B      #$03,D2
                        CMP.B      #$03,D2
                        BEQ        OP_INVALID 
                        MOVE.W     (A2),D2
                        BTST       #8,D2
                        BNE        OP_INVALIDADD     
                                   
OP_ANDOUTPUT            LEA   AND_DISPLAY,A6
                        JSR   EA_ARITHMETIC
                        JMP    OP_SIZE 
                        
OP_INVALIDADD           CLR.L      D2
                        MOVE.W     (A2),D2
                        LSR.L      #4,D2
                        AND.B      #$03,D2
                        CMP.B      #$0,D2
                        BEQ        OP_INVALID 
                        JMP        OP_ANDOUTPUT
                
;===========================================================
; ADD, ADDA
;
;=========================================================== 
OP_1101             CLR.L     D2
                    MOVE.W   (A2),D2
                    BTST     #8,D2 
                    BEQ      ADDA_CHECK   
    
OP_ADDA             LSR      #6, D2
                    AND.B    #$07, D2 ;MASK
                    CMP.B    #$03, D2 ; 011 || 111 == ADDA
                    BEQ     OP_ADDAOUTPUT
                    CMP.B    #$07, D2  
                    BEQ      OP_ADDAOUTPUT

OP_ADD              LEA     ADD_DISPLAY, A6 ;PUT ADD_DISPLAY INTO A6 FOR PRINT
                    JSR     EA_ARITHMETIC
                    JMP     OP_SIZE ;OPERAND SIZE
          
;===========================================================
; ADDA, 011,111
;
;=========================================================== 

OP_ADDAOUTPUT   LEA     ADDA_DISPLAY, A6
		    JSR     EA_ADDA_LEA 
                MOVE.W  (A2),D2
                LSR.L   #6,D2
                AND.B   #$07,D2 ;MASK 
                CMP.B   #$03, D2 
                BEQ     WORD_SIZE 
                CMP.B   #$07, D2 
                BEQ     LONG_SIZE
                JMP     WRONG_SIZE

ADDA_CHECK      MOVE.W  (A2),D2
                LSR.L   #4,D2
                AND.B   03,D2
                CMP.B   #$0,D2
                BEQ     OP_INVALID 
                MOVE.W  (A2),D2
                JMP     OP_ADDA 

           
;===========================================================
; MEMORY SHIFT ALd,ROd, LSd
;
;=========================================================== 

OP_1110          CLR.L     D2
                 MOVE.W    (A2),D2 ;
                 LSR       #6, D2 ;MOVE THE 6,AND 7 BITS TO THE FRONT
                 AND.B     #$03, D2  ;MASK THE OTHER BITS
                 CMP.B     #$03, D2 ; CHECK IF OP_1110 TO FIND MEMORTY SHIFT 
                 BEQ       MEMORY_SHIFT   
                       
OP_1110_REG     CLR.L   D2
                MOVE.W  (A2),D2
                LSR     #3, D2 ;SHIFT TYPE FOR SHIFT 
                AND.B   #$03, D2 ;MASK OTHER BITS 
                CMP.B   #$00, D2
                BEQ     ALDESTINATION_REGISTER 
                CMP.B   #$01,D2
                BEQ     LSDESTINATION_REGISTER 
                CMP.B   #$03, D2
                BEQ     RODESTINATION_REGISTER 
                JMP     OP_INVALID 
              
ALDESTINATION_REGISTER  CLR.L       D2
                        MOVE.W     (A2),D2
                        BTST       #8,D2 ;TEST THE 8TH BIT FOR DIRECTION
                        BNE        OP_ASL_REG 
                        LEA        ASR_DISPLAY,A6
                        JSR        EA_SHIFT

SIZE_REG                CLR.L      D2
                        MOVE.W     (A2),D2
                        LSR.W      #6, D2 ; THE 7TH SND 6TH BITS ARE SIZE BITS, MOVE THEM TO THE FRONT 
                        AND.B      #$03,D2 ; MASK
                         

REG_SIZE                CMP.B      #$0,D2
                        BEQ        BYTE_SIZE 
                        CMP.B      #$01,D2
                        BEQ        WORD_SIZE 
                        CMP.B      #$02,D2
                        BEQ        LONG_SIZE                         
                        JMP        WRONG_SIZE  
                      
OP_ASL_REG              LEA     ASL_DISPLAY, A6
                        JSR     EA_SHIFT
				JMP     SIZE_REG ;DETERMINE SIZE OF THE OPERANDS 
       
LSDESTINATION_REGISTER  CLR.L    D2
                        MOVE.W  (A2),D2
                        BTST    #8,D2 
                        BNE     OP_LSL_REG
                        LEA     LSR_DISPLAY, A6
                        JSR     EA_SHIFT
				JMP     SIZE_REG 
                        
OP_LSL_REG              LEA     LSL_DISPLAY, A6
                        JSR     EA_SHIFT
				JMP     SIZE_REG 

RODESTINATION_REGISTER   CLR.L      D2
                         MOVE.W     (A2),D2
                         BTST       #8, D2
                         BNE        OP_ROL_REG
                         LEA        ROR_DISPLAY, A6
                         JSR        EA_SHIFT
				 JMP        SIZE_REG     

OP_ROL_REG         LEA     ROL_DISPLAY, A6
                   JSR     EA_SHIFT
				   JMP     REG_SIZE 
             
 
MEMORY_SHIFT       CLR.L     D2
                   MOVE.W    (A2),D2
                   LSR       #8, D2 
                   LSR       #1, D2 
                   AND.B     #$07,D2
                   CMP.B     #$00,D2
                   BEQ       ASd_MEM 
                   CMP.B     #$01, D2
                   BEQ       LSd_MEM 
                   CMP.B     #$03, D2
                   BEQ       MEMORY_ROTATE 
                   JMP       OP_INVALID 
                            
ASd_MEM            CLR.L      D2
                   MOVE.W     (A2),D2
                   BTST       #8, D2 
                   BNE        OP_ASL_MEM    
                   LEA        ASR_DISPLAY, A6
	             JSR        EA_MEMORY 

    
NO_SIZE             MOVE.B  #0, D7 ;MOVE 0 INTO D7, TO INDICATE NO SIZE NEEDED 
                    RTS
                                             

OP_ASL_MEM              LEA     ASL_DISPLAY, A6 
                        JSR     EA_MEMORY 
				JMP     NO_SIZE 
  
LSd_MEM                 CLR.L   D2
                        MOVE.W  (A2),D2
                        BTST    #8, D2
                        BNE     OP_LSL_MEM  
                        LEA     LSR_DISPLAY, A6
				JSR     EA_MEMORY 
                        JMP     NO_SIZE 
                   
OP_LSL_MEM              LEA     LSL_DISPLAY, A6
				JSR     EA_MEMORY 
                        JMP     NO_SIZE 
                        

MEMORY_ROTATE           CLR.L     D2
                        MOVE.W    (A2),D2
                        BTST      #8,D2      
                        BNE       OP_ROL_MEM 
                    

                        LEA     ROR_DISPLAY, A6
				JSR     EA_MEMORY 
                        JMP     NO_SIZE 
                        

OP_ROL_MEM              LEA     ROL_DISPLAY, A6
				JSR     EA_MEMORY 
                        JMP     NO_SIZE 
                 
;===========================================================
; BRANCH BRA, BGT, BLE, BEQ, RTS,
;=========================================================== 

          

OP_0110                 CLR.L   D2
                        MOVE.W  (A2),D2
                        LSR.L   #8, D2
                        AND.B   #$0F,D2 ;MASK 
                        CMP.B   #$00,D2
                        BEQ     OP_BRA ;BRA
                        CMP.B   #$0E, D2
                        BEQ     OP_BGT ;BGT
                        CMP.B   #$0F, D2
                        BEQ     OP_BLE ;BLE
                        CMP.B   #$07, D2 
                        BEQ     OP_BEQ ;BEQ
                        JMP     OP_INVALID                        
                       
OP_BRA                           LEA    BRA_DISPLAY, A6 
                                 JSR    OP_RTS
                                 RTS    
                        
OP_BGT                           LEA    BGT_DISPLAY,A6 
                                 JSR    OP_RTS
                                 RTS              
                        
OP_RTS                           MOVE.B  #8,D7
                                 MOVE.W  (A2),D6
                                 RTS  
                
OP_BLE                           LEA     BLE_DISPLAY,A6 
                                 JSR     OP_RTS
                                 RTS
                
OP_BEQ                           LEA    BEQ_DISPLAY,A6 
                                 JSR    OP_RTS 
                                 RTS
;===========================================================
; NOP, LEA, JSR
;
;=========================================================== 
          
OP_0100         CLR.L   D2
                MOVE.W (A2),D2
                CMP.W  #$4E71, D2 ;NOP 
                BEQ    OP_NOP
                CMP.W  #$4E75,D2 ;RTS 
                BEQ    OP_RTSOUTPUT     
                CLR.L  D2
                MOVE.W (A2),D2
                LSR.L  #8, D2
                AND.B  #$0F,D2
                CMP.B  #$06,D2
                BEQ    OP_NOT ;NOT                   
                 

                CLR.L  D2
                MOVE.W (A2),D2
                LSR.L    #6, D2
                AND.B  #$07,D2
                CMP.B  #$07,D2
                BEQ    OP_LEA ;LEA
    
                MOVE.W (A2),D2
                LSR.L  #8, D2 
                LSR.L  #1,D2
                AND.B  #$07,D2 ;MASK
                CMP.B  #$07, D2 
                BEQ    OP_JSR ;JSR
                                 
MOVEM_CHECK     MOVE.W (A2),D2
                BTST   #11,D2
                BNE    OP_MOVEM
                JMP OP_INVALID  
                             

OP_JSR          MOVE.W  (A2),D2
                LSR.L   #6,D2 
                AND.B   #$07,D2 ;MASK 
                CMP.B   #$02,D2 ;CHECK IF JSR
                BEQ     OP_JSROUTPUT                
                JMP     MOVEM_CHECK 
                  
OP_NOP          LEA     NOP_DISPLAY, A6
                CLR.B   D6              
                JMP     NO_SIZE 
              

OP_RTSOUTPUT    LEA     RTS_DISPLAY, A6 
                CLR.B   D6           
                JMP     NO_SIZE 
              
OP_NOT          LEA      NOT_DISPLAY,  A6
		    JSR      EA_MEMORY 
                MOVE.W  (A2),D2
                LSR.L    #6,D2
                AND.B    #$03,D2
                CMP.B    #$0,D2
                BEQ      BYTE_SIZE 
                CMP.B    #$01,D2
                BEQ      WORD_SIZE 
                CMP.B    #$02,D2
                BEQ      LONG_SIZE 
                JMP      WRONG_SIZE 


OP_JSROUTPUT    LEA     JSR_DISPLAY, A6
				JSR     EA_MEMORY 
                JMP     NO_SIZE      

OP_LEA          LEA     LEA_DISPLAY, A6
				JSR     EA_ADDA_LEA 
                JMP     NO_SIZE                      
 
;=========================================================
; MOVEM
;
;=========================================================== 
OP_MOVEM          MOVE.W     (A2),D2
                  LSR.L      #7,D2
                  AND.B      #$07,D2
                  CMP.B      #$1,D2 ;check invalid EXT
                  BEQ        OP_MOVEMINVALID ;FURTHER CHECK FOR VALIDATION  
                  JMP        OP_INVALID


OP_MOVEMINVALID   MOVE.W     (A2),D2
                  LSR.L      #3,D2
                  AND.B      #$07,D2
                  CMP.B      #$0,D2
                  BEQ        OP_INVALID 
                      
                  MOVE.W    (A2),D2
                  BTST      #10,D2 ;CHECK MEMORY MANIPULATION
                  BEQ       MOVEM_MEM_MANIPULATION 
                      
                      
;===========================================================
; MOVEM MANIPULATION
;0 == W
;1 == L
;=========================================================== 
                
MOVEM_MEM_MANIPULATION     BTST  #6,D2  
                           BEQ   MOVEM_WORD ;WORD SIZE
                           JMP   MOVEM_LONG ;LONG SIZE   
 
MOVEM_WORD                 LEA MOVEM_DISPLAY,A6
                           MOVE.B  #7, D7 ;OPERAND SIZEING
						   JSR	MOVEM_EA
                           RTS 
                    
MOVEM_LONG                 LEA MOVEM_DISPLAY,A6 
                           MOVE.B  #9, D7 ;OPERAND SIZEING ACCOUNTING SHIFT
						   JSR	 MOVEM_EA
                           RTS
                                           
;===========================================================
; EA modes
;=========================================================== 
	
IMMEDIATE             MOVE.B  #10,D7
                      CMP     #0,D6
                      BEQ     FORMAT_DATA
                      BRA     FORMAT_POP

FORMAT_DATA          MOVEQ   #8,D6
FORMAT_POP           RTS
 
EA_ARITHMETIC       MOVE.W  (A2),D1                 
                    MOVE.W  (A2),D2                 
                    ANDI.B  #%00111111,D1    ;source EA    
                    ANDI.W  #%00000111000000000,D2  ;locate source    
                    MOVE.B  #9,D3                   
                    LSR.W   D3,D2                   
                    ANDI.B  #%11000111,D2      ;EA mode     
                    MOVE.W  (A2),D3
                    BTST    #8,D3                   
                    BEQ     EA_ARITHMETIC_MODE_ZERO ;opmode           

EA_ARITHMETIC_MODE_ZERO     MOVE.W  D1,D6  ;source         
                            MOVE.W  D2,D5  ;destination         
                
EA_ARITHMETIC_END   ORI.B   #%11000000,D6  ;size and dir    
                    JSR     CHECK_EA_MODE              
                    RTS
        
EA_SHIFT            MOVE.W  (A2),D6         
                    ANDI.W  #%00000111000000000,D6    ;get source bits  
                    MOVE.B  #9,D3                   ;shift bits
                    LSR.W   D3,D6                   ;bits to lsb
                    MOVE.W  (A2),D3
                    BTST    #5,D3           ;if immediate adressing
                    BEQ     EA_SHIFT_IMMEDIATE
 
EA_SHIFT_REGISTER   ORI.B   #%11000000,D6   ;size and direction bits
                    BRA     EA_SHIFT_END         
                
EA_SHIFT_IMMEDIATE  MOVE.B  #10,D7          
                    JSR     IMMEDIATE
                
EA_SHIFT_END        MOVE.W  (A2),D5       ;get destination bits  
                    AND.B   #%00000111,D5
                    JSR     CHECK_EA_MODE              
                    RTS
   
EA_MEMORY           MOVE.W  (A2),D6
                    ANDI.B  #%00111111,D6       
                    ORI.B   #%10000000,D6
                    JSR     CHECK_EA_MODE              
                    RTS

EA_ADDA_LEA         MOVE.W  (A2),D1     ;get source bits     
                    ANDI.B  #%00111111,D1       ;size and direction bits
                    ORI.B   #%11000000,D1       ; for output
                    MOVE.B  D1,D6                   
                    MOVE.W  (A2),D1         
        
                    ANDI.W  #%00000111000000000,D1   ;data register mask
                    MOVE.B  #9,D2                   ;shift values to lsb
                    LSR.W   D2,D1                  
                    ANDI.B  #%11001111,D1           
                    ORI.B   #%00001000,D1          ;get the dest mode 
                    MOVE.B  D1,D5                   ;output to D5
                    JSR     CHECK_EA_MODE              
                    RTS
        
EA_OP_00__          MOVE.W  (A2),D1
                    ANDI.B  #%00111111,D1           
                    ORI.B   #%11000000,D1           
                    MOVE.B  D1,D6                   
                    MOVE.W  (A2),D1         
                    MOVE.W  (A2),D2 
                    ANDI.W  #%00000111000000000,D1  ;mask 
                    MOVE.B  #9,D3                   
                    LSR.W   D3,D1                   ;shift
                    ANDI.W  #%0000000111000000,D2   
                    LSR.W   #3,D2                  ;destination bits
                    OR.W    D2,D1
                    MOVE.B  D1,D5                   
                    JSR     CHECK_EA_MODE          ;output    
                    RTS
   
EA_OP_1101          MOVE.W  (A2),D6                 
                    ANDI.W  #%00000111000000000,D6      
                    MOVE.B  #9,D3                   ;shift
                    LSR.W   D3,D6                   ;lsb to right
                    MOVE.W  (A2),D5                 
                    ANDI.B  #%00111111,D5       ;destination bits
                    JSR     IMMEDIATE           ;check immediate addressing
                    JSR     CHECK_EA_MODE              
                    RTS                                    
        
EA_OP_0111          MOVE.W  (A2),D6        ;MOVEQ destination reg         
                    AND.W   #$00FF,D6       ;mask                                           
                    MOVE.W  (A2),D5                 
                    ANDI.W  #%00000111000000000,D5 ;MOVEQ destination reg      
                    MOVE.B  #9,D3              ;shift     
                    LSR.W   D3,D5                   
                    MOVE.B  #10,D7
                    JSR     CHECK_EA_MODE             
                    RTS                                 

MOVEM_EA            MOVE.W  (A2),D6
                    ANDI.W  #%00111111,D6   ;EA bit
                    MOVE.W  (A2),D0             
                    BTST    #10,D0          ;destination bit    
                    BEQ     MOVEM_DESTINATION

MOVEM_SOURCE        BSET    #7,D6              
                    BRA     MOVEM_EA_END
            
MOVEM_DESTINATION   BSET    #6,D6              
                
MOVEM_EA_END        JSR     EA_MODE_ONE
                    RTS

CHECK_EA_MODE   MOVE.W  #0,A5        ;validity bit       
                MOVE.B  D6,D1              
                JSR     VALID_EA
                MOVE.B  D5,D1      ;destination         
                JSR     VALID_EA
                RTS
                
EA_MODE_ONE     MOVE.W  #0,A5               
                MOVE.B  D6,D1      ;source         
                JSR     VALID_EA
                RTS
         
VALID_EA        MOVE.B  D1,D0
                LSR     #3,D0
                ANDI.B  #%00000111,D0
                CMP.B   #%00000101,D0
                BEQ     EA_INVALID
                CMP.B   #%00000110,D0
                BEQ     EA_INVALID
                CMP.B   #%00000111,D0
                BEQ     EA_CHECK_FULL
                RTS
                
                
EA_CHECK_FULL   MOVE.B  D1,D0
                ANDI.B  #%00000111,D0
                CMP.B   #%00000010,D0
                BEQ     EA_INVALID
                CMP.B   #%00000011,D0
                BEQ     EA_INVALID
                RTS
                
EA_INVALID      JSR     OP_INVALID
                RTS              

  
;===========================================================
; PRINT_DISASSEMBLE       
;=========================================================== 

                            
PRINT_DISASSEMBLE       MOVEM.L     A0-A1/A3-A6/D0-D7,-(SP)     ; BACKUP REGISTERS
                        MOVE.W  D5,D0    
                        MOVE.L  A2,D5          
                        MOVE.B  #4,D3           
                        JSR     PRINT_HEX       
                        JSR     PRINT_TAB
                        MOVE.W  D0,D5
                        ADD.L   #2,A2           ; increment pointer
                        CMP.W   #5,A5                           
                        BEQ     PRINT_DATA
                        CMP.B   #5,D7                           
                        BEQ     PRINT_DATA                       
                        CMP.B   #7,D7                           
                        BEQ     MOVEM_OUTPUT
                        CMP.B   #8,D7                           
                        BEQ     BRA_OUTPUT
                        CMP.B   #9,D7                           
                        BEQ     MOVEM_OUTPUT
                        CMP.B   #10,D7                           ;ADDQ
                        BEQ     OP_OUTPUT
                        CMP.B   #11,D7                           ;Arithmetic/Logical shift||R||BYTE
                        BEQ     OP_OUTPUT
                        CMP.B   #12,D7                           ;Arithmetic/Logical shift||R||WORD
                        BEQ     OP_OUTPUT
                        CMP.B   #14,D7                           ;Arithmetic/Logical shift||R||LONG
                        BEQ     OP_OUTPUT
                                                
TOSTRING_OUTPUT         JSR     PRINT_TAB
                        MOVE.L  A6,A1                       ; PRINT INSTRUCTION
                        MOVE.B  #14,D0
                        TRAP    #15
                        
                        BTST    #7,D6       ;check source EA               
                        BEQ     TOSTRING_RETURN    ;print post increment
                        JSR     PRINT_SIZE      ;format
                        JSR     PRINT_TAB
                        MOVE.B  D6,D4
                        JSR     EA_DISPLAY                    ; output source EA
                        
                        BTST    #6,D6                       ; check destination EA
                        BEQ     TOSTRING_RETURN    ;print post increment
                        JSR     PRINT_COMMA ;format
                        MOVE.B  D5,D4
                        JSR     EA_DISPLAY                    ;output destination EA
                        
TOSTRING_RETURN         JSR         PRINT_NEXTLINE
                        MOVEM.L     (SP)+,A0-A1/A3-A6/D0-D7
                        RTS                         ;return to isntruction readout

OP_OUTPUT        		JSR         PRINT_TAB
                        MOVE.L      A6,A1                   ;prepare reg
                        MOVE.B      #14,D0
                        TRAP        #15
                        SUB.B       #10,D7
                        JSR         PRINT_SIZE              
                        JSR         PRINT_TAB               
                        
                        CLR.L       D1
                        JSR         PRINT_POUND        
                        MOVE.B      D6,D1                   
                        MOVE.L      #3,D0
                        TRAP        #15
                        JSR         PRINT_COMMA                                     
                        
                        MOVE.B      D5,D4
                        JSR         EA_DISPLAY                ;output jump                        
                        JMP         TOSTRING_RETURN
;===========================================================
; MOVEM OUTPUT
;=========================================================== 

MOVEM_OUTPUT            JSR     PRINT_TAB                    
                        MOVE.L  A6,A1                       ; MOVEM instruction
                        MOVE.B  #14,D0
                        TRAP    #15
                    
                        MOVE.W  (A2)+,D2                    ;adjust mask
                        SUB.B   #5,D7                       ;print to adjust size
                        JSR     PRINT_SIZE                  
                        JSR     PRINT_TAB
                        BTST    #7,D6
                        BEQ     MOVEM_OUTPUT_MASK            ;output the mask 
                        MOVE.B  D6,D4
                        JSR     EA_DISPLAY            ;format
                        JSR     PRINT_COMMA
                    
MOVEM_OUTPUT_MASK       MOVE.W  D2,D4
                        JSR     PRINT_MASK
                        BTST    #7,D6                       ; check process of mask to register selected
                        BNE     TOSTRING_RETURN
                        
                        JSR     PRINT_COMMA
                        MOVE.B  D6,D4
                        JSR     EA_DISPLAY
                        JMP     TOSTRING_RETURN

;===========================================================
;BRA
;byte def , word 00 , long ff
;=========================================================== 


BRA_OUTPUT      JSR         PRINT_TAB
                MOVE.L      A6,A1           
                MOVE.B      #14,D0
                TRAP        #15
                JSR         PRINT_TAB       
                
                MOVE.L      A2,D2           ; assign register
                CLR.L       D1
                CMP.B       #$00,D6                 ;word following 16 bit displacement
                BEQ         WORD_UPDATE
                CMP.B       #$FF,D6                 ; long, if 8th bit is all ones
                BEQ         LONG_UPDATE
                
                MOVE.B      D6,D1                   ; test byte displacement
                BTST        #7,D1                
                BEQ         BRA_OUTPUT_RETURN        ; positive == output
                
                NOT.B       D1                      ;ones complement of the destination
                ADD.W       #$1,D1                   ;+1 for twos complement
                NEG.L       D1                       ; reverse polarity
                BRA         BRA_OUTPUT_RETURN

WORD_UPDATE       MOVE.W      (A2)+,D1          
                        BTST        #15,D1
                        BEQ         BRA_OUTPUT_RETURN        ; positive == output
                        NOT.W       D1                      ;ones complement of the destination
                        ADD.L       #$1,D1                   ;+1 for twos complement
                        NEG.L       D1                       ; reverse polarity
                        BRA         BRA_OUTPUT_RETURN

LONG_UPDATE       MOVE.L      (A2)+,D1         
    
BRA_OUTPUT_RETURN       JSR     PRINT_DOLLAR
                        ADD.L   D2,D1
                        MOVE.L  D1,D5
                        MOVE.L  #4,D3
                        JSR     PRINT_HEX
                        JMP     TOSTRING_RETURN
;===========================================================
;DATA DISPLAY       
;=========================================================== 

PRINT_DATA      JSR     PRINT_TAB
                LEA     DATA_DISPLAY,A1 ;unsupported prints
                MOVE.B  #14, D0
                TRAP    #15
                JSR     PRINT_TAB
                MOVE.W  D6,D5
                MOVE.B  #2,D3
                JSR     PRINT_HEX
                JMP     TOSTRING_RETURN                

                        
;===========================================================
; MASK
;memory to register
;register to memory
;=========================================================== 

PRINT_MASK              MOVEM.L     D0-D7/A0-A6 ,-(SP)
                        MOVE.B      D6,D2                   ;masking check
                        AND.B       #$38,D2
                        CMP.B       #$20,D2
                        BNE         toREG
    
toMEM                   MOVE.L      #15,D1              ;initial index flip 
                    
FLIP_DIRECTION          CMP.B       #0,D1
                        BLT         toMEMO_CHECK
                        MOVE.B      #31,D0
                        SUB.B       D1,D0           ;flip bits remaining
                        BTST        D1,D4           ;test mask
                        BNE         FLIP_SET

COUNTER                 CMP.B   #16,D3                  
                        BEQ     MASK_INTI
                        BTST    D3,D4
                        BEQ     COUNTER_INCREMENT
                        ADD.W   #1,A3
COUNTER_INCREMENT       ADD.B   #1,D3
                        BRA     COUNTER

SWAP_INDEX              BCLR        D0,D4
                        BRA         LOOP_INCREMENT
FLIP_SET                BSET        D0,D4                    

LOOP_INCREMENT          SUB.B   #1,D1
                        BRA     FLIP_DIRECTION 

toMEMO_CHECK            SWAP    D4              ;swaps at index
toREG                   MOVE.B  #0,D3
                        MOVE.W  #0,A3
                    

MASK_INTI               MOVE.B  #0,D3           * PRINTING THE REGISTERS
PRINT_MASK_LOOP         CMP.B   #16, D3
                        BEQ     PRINT_MASK_RETURN
                        BTST    D3,D4
                        BNE     SET_MASK
                        BRA     MASK_INCREMENT

SET_MASK                CMP.B   #7,D3
                        BGT     ADDRESS_REGISTER

DESTINATION_REGISTER    MOVE.B  #$D0, D1                    
                        ADD.B   D3,D1               ;isolate destination reg
                        JSR     PRINT_REGISTOR
                        BRA     PRINT_SLASHS

ADDRESS_REGISTER        MOVE.B  #$98,D1                 
                        ADD.B   D3,D1           ;isolate destination reg
                        JSR     PRINT_REGISTOR

PRINT_SLASHS            CMP.W   #1,A3                   
                        BEQ     MASK_INCREMENT
                        JSR     PRINT_SLASH
                        SUB.W   #1,A3

MASK_INCREMENT          ADD.B   #1,D3
                        SUB.B   #1,D1
                        BRA     PRINT_MASK_LOOP

PRINT_MASK_RETURN       MOVEM.L     (SP)+, D0-D7/A0-A6       * RETURNING
                        RTS
;===========================================================
;HEX to ASCII       
;=========================================================== 
                
PRINT_HEX               MOVEM.L     D0-D7/A0-A6,-(SP)
                        LEA         PRINT_BUFFER, A1        
                        ADD.L       #10,A1
                        MOVE.B      #0,-(A1)                
                        BRA         DISPLAY_BUFFER
                
PRINT_HEX_RETURN        MOVE.B      #14,D0
                        TRAP        #15
                        MOVEM.L     (SP)+,D0-D7/A0-A6
                        RTS
                               
DISPLAY_BUFFER          CMP.B       #0,D3
                        BEQ         PRINT_HEX_RETURN
                        MOVE.B      #$0F,D4 ;allocate 
                        AND.B       D5,D4
                        ROR.B       #4,D5 ;lower bits
                        JSR         toASCII          
                        MOVE.B      D4,-(A1)
                        MOVE.B      D5,D4
                        AND.B       #$0F,D4
                        JSR         toASCII
                        MOVE.B      D4,-(A1)
                        LSR.L       #8,D5 ;upper
                        SUB.B       #1,D3
                        BRA         DISPLAY_BUFFER

toASCII                 MOVEM.L     A0-A6/D0-D2/D5-D7,-(SP)
                        CMP.B       #9,D4
                        BLE         intToASCII
                        ADD.B       #$37,D4  ;upper end ASCII
toASCII_RETURN          MOVEM.L     (SP)+,A0-A6/D0-D2/D5-D7
                        RTS
                
intToASCII              ADD.B       #$30,D4         ;to number
                        BRA         toASCII_RETURN
                    

;===========================================================
;PRINT SIZE     
;=========================================================== 
                
PRINT_SIZE          MOVEM.L D0-D7/A0-A6,-(SP)
                    MOVE.B  #14,D0
                    CMP.B   #0, D7                  ;NO_SIZE
                    BEQ     PRINT_SIZE_RETURN
                    CMP.B   #1, D7
                    BNE     SIZE_CHECK_W            ;If size 01 word
                    LEA     BYTE_DISPLAY,A1          ;else, byte        
                    TRAP    #15
                    BRA     PRINT_SIZE_RETURN       ;post incerment reg
                
SIZE_CHECK_W        CMP.B   #2,D7                   ;compare size 10, long 
                    BNE     PRINT_LONG          
                    LEA     WORD_DISPLAY, A1            ;WORD_DISPLAY
                    TRAP    #15
                    BRA     PRINT_SIZE_RETURN           ;post incerment reg

PRINT_LONG          LEA     LONG_DISPLAY, A1                ;LONG_DISPLAY
                    TRAP    #15                    
                
PRINT_SIZE_RETURN   MOVEM.L (SP)+,D0-D7/A0-A6
                    RTS

;===========================================================
;PRINT EA     
;=========================================================== 
    
EA_DISPLAY          MOVEM.L A0-A1/A3-A6/D0-D7,-(SP)
                    MOVE.B  #$38,D3
                    AND.B   D4,D3
                    AND.B   #$7, D4
                
                    CMP.B   #$0, D3
                    BNE     EA_ARD
                    ADD.B   #$D0, D4
                    CLR.L   D1
                    MOVE.B  D4, D1
                    JSR     PRINT_REGISTOR              ; Data Register Direct
                    BRA     EA_DISPLAY_RETURN

EA_ARI_POST         CMP.B   #$18,D3
                    BNE     EA_ARI_PRE
                    JSR     PRINT_OPEN      
                    ADD.B   #$A0, D4
                    CLR.L   D1
                    MOVE.B  D4, D1
                    JSR     PRINT_REGISTOR              ; Address Register Indirect with Post-incrementing
                    JSR     PRINT_CLOSED    
                    JSR     PRINT_POST                  
                    BRA     EA_DISPLAY_RETURN

EA_ALA              CMP.B   #$39, D3
                    BNE     EA_IA
                    JSR     PRINT_DOLLAR       
                    MOVE.L  (A2)+,D5            ; Absolute Long Address
                    MOVE.B  #4,D3
                    JSR     PRINT_HEX
                    BRA     EA_DISPLAY_RETURN

EA_ARI_PRE          CMP.B   #$20,D3
                    BNE     EA_AWA           
                    JSR     PRINT_PRE                 
                    JSR     PRINT_OPEN      
                    ADD.B   #$A0, D4
                    CLR.L   D1
                    MOVE.B  D4, D1
                    JSR     PRINT_REGISTOR              ; Address egister IndireRct with Pre-decrementing
                    JSR     PRINT_CLOSED    
                    BRA     EA_DISPLAY_RETURN

EA_ARD              CMP.B   #$8, D3
                    BNE     EA_ARI
                    ADD.B   #$A0, D4
                    CLR.L   D1
                    MOVE.B  D4, D1
                    JSR     PRINT_REGISTOR          ; Address Register Direct
                    BRA     EA_DISPLAY_RETURN
                   
                    
EA_IA               CMP.B   #4,D7
                    BNE     EA_WB_IA 
                    JSR     PRINT_POUND    
                    JSR     PRINT_DOLLAR        
                    MOVE.L  (A2)+,D5            ; .L Immediate Addressing
                    MOVE.B  #4,D3               ; space differential
                    JSR     PRINT_HEX
                    BRA     EA_DISPLAY_RETURN
                   
EA_ARI              CMP.B   #$10, D3
                    BNE     EA_ARI_POST
                    JSR     PRINT_OPEN      
                    ADD.B   #$A0, D4
                    CLR.L   D1
                    MOVE.B  D4, D1
                    JSR     PRINT_REGISTOR              ; Address Register Indirect
                    JSR     PRINT_CLOSED    
                    BRA     EA_DISPLAY_RETURN
                        
EA_AWA              ADD.B   D4,D3
                    CMP.B   #$38,D3     
                    BNE     EA_ALA
                    JSR     PRINT_DOLLAR        
                    MOVE.W  (A2)+,D5            ; Absolute Word Address
                    MOVE.B  #2,D3
                    JSR     PRINT_HEX
                    BRA     EA_DISPLAY_RETURN
                          
EA_WB_IA            JSR     PRINT_POUND     
                    JSR     PRINT_DOLLAR        
                    MOVE.W  (A2)+,D5            ; .W && .B Immediate Addressing
                    MOVE.B  #2,D3
                    JSR     PRINT_HEX

EA_DISPLAY_RETURN   MOVEM.L     (SP)+,A0-A1/A3-A6/D0-D7   ;return for output 
                    RTS

;===========================================================
;PRINT EA     
;=========================================================== 
PRINT_REGISTOR      MOVEM.L     D0-D7/A0-A6,-(SP)       ; backup registers
                    MOVE.W      #00,-(SP)           
                    MOVE.W      #$f0,D2             
                    AND.W       D1,D2
                    ASR.W       #4,D2
                    JSR         CONVERT_ADDRESS_BACK           ;convert initial
                    ASL.W       #8,D2
                    
                    AND.W       #$F,D1              ;lsb
                    MOVE.B      D1,D2               
                    JSR         CONVERT_ADDRESS_BACK           ;toString values
                    MOVE.W      D2,-(SP)            ;stack as a register
                    
                    MOVE.L      SP,A1               ;set stack to output register
                    MOVE.B      #14,D0
                    TRAP        #15
                    MOVE.L      (SP)+, D5           ; shift stack pointer

PRINT_REGISTOR_RETURN       MOVEM.L (SP)+,D0-D7/A0-A6   ;returning the original val
                            RTS

CONVERT_ADDRESS_BACK        CMP.B   #9,D2               ; check if number or ascii
                            BGT     STRINGS                 
                            ADD.B   #$30,D2             ; revert numb
                            RTS

STRINGS                     ADD.B   #$37,D2             ; revert letter
                            RTS   
;===========================================================
;PRINT SYMBOLS     
;=========================================================== 

        
PRINT_POST      
		    MOVEM.L     D0-D7/A0-A6, -(SP)
                LEA         POST, A1
                MOVE.B      #14,D0
                TRAP        #15
                MOVEM.L     (SP)+,D0-D7/A0-A6
                RTS
        
PRINT_PRE       
		    MOVEM.L     D0-D7/A0-A6, -(SP)
                LEA         PRE, A1
                MOVE.B      #14,D0
                TRAP        #15
                MOVEM.L     (SP)+,D0-D7/A0-A6
                RTS
             
PRINT_SLASH     
		    MOVEM.L     D0-D7/A0-A6,-(SP)
                LEA         SLASH, A1
                MOVE.B      #14,D0
                TRAP        #15
                MOVEM.L     (SP)+,D0-D7/A0-A6
                RTS
						
PRINT_TAB       
		    MOVEM.L     D0-D7/A0-A6,-(SP)
                LEA         TAB, A1
                MOVE.B      #14,D0
                TRAP        #15
                MOVEM.L     (SP)+,D0-D7/A0-A6
                RTS
        
PRINT_NEXTLINE      
		    MOVEM.L     D0-D7/A0-A6,-(SP)
                LEA         NEXTLINE, A1
                MOVE.B      #14,D0
                TRAP        #15
                MOVEM.L     (SP)+,D0-D7/A0-A6
                RTS
PRINT_COMMA         
		    MOVEM.L     D0-D7/A0-A6,-(SP)
                LEA         COMMA, A1
                MOVE.B      #14,D0
                TRAP        #15
                MOVEM.L     (SP)+,D0-D7/A0-A6
                RTS
                
PRINT_POUND         
		    MOVEM.L     D0-D7/A0-A6,-(SP)
                LEA         POUND, A1
                MOVE.B      #14,D0
                TRAP        #15
                MOVEM.L     (SP)+,D0-D7/A0-A6
                RTS
        
PRINT_DOLLAR        
                MOVEM.L     D0-D7/A0-A6,-(SP)
                LEA         DOLLAR, A1
                MOVE.B      #14,D0
                TRAP        #15
                MOVEM.L     (SP)+,D0-D7/A0-A6
                RTS

PRINT_OPEN  	
		    MOVEM.L     D0-D7/A0-A6, -(SP)
                LEA         OPEN, A1
                MOVE.B      #14,D0
                TRAP        #15
                MOVEM.L     (SP)+,D0-D7/A0-A6
                RTS
       
PRINT_CLOSED   		        
		    MOVEM.L     D0-D7/A0-A6, -(SP)
                LEA         CLOSED, A1
                MOVE.B      #14,D0
                TRAP        #15
                MOVEM.L     (SP)+,D0-D7/A0-A6
                RTS   

PRINT_BUFFER    	      DS.B    10
INPUT_VALUE  		DC.B    '00000000'
INPUT_SIZE    		DS.B    15

NEXTLINE         	     DC.B    CR,LF,0
POST           		DC.B    '+',0
PRE           		DC.B    '-',0
OPEN        		DC.B    '(',0
CLOSED      		DC.B    ')',0
POUND      			DC.B    '#',0
DOLLAR          	      DC.B    '$',0
SLASH   			DC.B    '/',0
TAB         		DC.B    $9,0
SPACE       		DC.B    '   ',0
COMMA       		DC.B    ',',0

BYTE_DISPLAY        DC.B    '.B',0
WORD_DISPLAY        DC.B    '.W',0
LONG_DISPLAY        DC.B    '.L',0

DATA_DISPLAY        DC.B    'DATA',0
ADDA_DISPLAY        DC.B    'ADDA',0
ADDQ_DISPLAY        DC.B    'ADDQ',0
SUB_DISPLAY         DC.B    'SUB',0
BGT_DISPLAY         DC.B    'BGT',0
BLE_DISPLAY         DC.B    'BLE',0
BEQ_DISPLAY         DC.B    'BEQ',0
JSR_DISPLAY         DC.B    'JSR',0
NOP_DISPLAY         DC.B    'NOP',0
MOVE_DISPLAY        DC.B    'MOVE',0
MOVEA_DISPLAY       DC.B    'MOVEA',0
MOVEQ_DISPLAY       DC.B    'MOVEQ',0
MOVEM_DISPLAY       DC.B    'MOVEM',0
ADD_DISPLAY         DC.B    'ADD',0
RTS_DISPLAY         DC.B    'RTS',0
BRA_DISPLAY         DC.B    'BRA',0
LSR_DISPLAY         DC.B    'LSR',0
ASL_DISPLAY         DC.B    'ASL',0
ASR_DISPLAY         DC.B    'ASR',0
ROL_DISPLAY         DC.B    'ROL',0
ROR_DISPLAY         DC.B    'ROR',0
LEA_DISPLAY         DC.B    'LEA',0
AND_DISPLAY         DC.B    'AND',0
OR_DISPLAY          DC.B    'OR',0
NOT_DISPLAY         DC.B    'NOT',0
LSL_DISPLAY         DC.B    'LSL',0

DISASSEMBLER_DISPLAY	DC.B    LF,'DISASSEMBLER',0
STARTMESSAGE        	DC.B    ''
				DC.B    '',CR,LF
				DC.B    LF,'Enter the start address:  ',0
ENDMESSAGE          	DC.B    LF,'Enter the end address:    ',0
ERROR_DISPLAY       	DC.B    LF,'INVALID',CR,LF,CR,LF,0
CONTINUE_ADDRESSES  	DC.B    LF,'press ANYKEY to CONTINUE',CR,LF,0
QUIT_PROMPT         	DC.B    LF,'',LF,CR
				DC.B    'Y == EXIT',LF,CR
				DC.B    'press ANYKEY TO CONTINUE with NEW ADDRESSES,  ',0


    END    START        ; last line of source
