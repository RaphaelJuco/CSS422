*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
START:  	EQU	$00009000	
   ORG	start
        BRA TEST1
TEST1
        BGT TEST2
TEST2
        BLE TEST3
TEST3
        BEQ TEST4
TEST4
        JSR TEST5
TEST5

    

    NOP
    
    MOVE.B  D4, D2       
    MOVE.B  #$01, D1     
    MOVE.B  #$C0,(A0)+
    MOVE.W  (A5), D0           
    MOVE.W  (A5)+, D0      
    MOVE.W  -(A5), D0    
    MOVE.W  $4333, -(A1)     
    MOVE.L  (A3)+, (A5)     
    MOVE.L  -(A2), (A3)      
    MOVE.L  $1004, (A1)    
    MOVE.L  $1083, $FFFF
    MOVE.W    D1,$10(A1)
    
    MOVEQ.L  #3,D5
    MOVEQ.L  #%1001,D2
    MOVEQ.L  #$FF,D6
    MOVEQ.L  #1,D1
    MOVEQ.L  #%1001,D2
    
    MOVEM.W  D1-D6,(A1)
    MOVEM.L  D1-D6,-(A1)
    MOVEM.W $FFFF, D0-D7/A0-A7
    MOVEM.L $FFFF, D0-D7/A0-A7
    MOVEM.W D0-D7/A0-A7, (A0)
    MOVEM.L D0-D7/A0-A7, (A4)
    MOVEM.W (A0)+,D0-D7/A0-A7
    MOVEM.L (A0)+,D0-D7/A0-A7

    MOVEA.W  D0,A0
    MOVEA.W  A1,A2
    MOVEA.W  D1,A2
    MOVEA.L  (A4),A5
    MOVEA.L  (A1)+,A0
    MOVEA.L  -(A1),A0
    MOVEA.W  $FFA1,A1
    
    ADD.B  $FFA1,D0
    ADD.W  D0,D1
    ADD.L  (A0),D0
    ADD.L  D0,-(A6)
    ADD.W  D0,(A6)+

    ADDA.W  D0,A0
    ADDA.L  (A4),A5
    ADDA.W  (A0)+,A1
    ADDA.W  -(A1),A0
    ADDA.L  $FF00,A1
    
    
    ADDQ.B  #%0001,D0
    ADDQ.W  #%0011,A1
    ADDQ.W  #%0111,(A2)
    ADDQ.W  #%0111,(A3)+
    ADDQ.L  #%0001,-(A4)

    SUB.W  D1,D1
    SUB.W  D0,D3
    SUB.W  A3,D1
    SUB.B   D1, D2
    SUB.B   (A0), D3
    SUB.B   (A0)+, D4

    LEA  (A0),A1
    LEA  $FF00,A1
    LEA  $FFFF0000,A1
    
    AND.B  D1,D1
    AND.B  D0,D1
    AND.W  (A1),D1
    AND.W  (A1)+,D1
    AND.W  -(A1),D1
    AND.L  D1,$FF00
    
    OR.B  D1,D1
    OR.B  D0,D1
    OR.W  (A1),D1
    OR.W  (A1)+,D1
    OR.W  -(A1),D1
    OR.L  D1,$FF00

    NOT.B  D1
    NOT.B  D1
    NOT.W  (A1)
    NOT.W  (A1)+
    NOT.W  -(A1)
    NOT.L  $FF00
    
    LSL.B   #1 ,D1
    LSL.W   (A1)
    LSL.W   (A5)+
    LSL.W   -(A3)
    LSL.W   (A2)

    LSR.B   #1 ,D1
    LSR.W   (A1)
    LSR.W   (A5)+
    LSR.W   -(A3)
    LSR.W   (A2)

    ASL.B   #1 ,D1
    ASL.W   (A1)
    ASL.W   (A5)+
    ASL.W   -(A3)
    ASL.W   (A2)

    ASR.B   #1 ,D1
    ASR.W   (A1)
    ASR.W   (A5)+
    ASR.W   -(A3)
    ASR.W   (A2)

    ROL.B   #1 ,D1
    ROL.W   (A1)
    ROL.W   (A5)+
    ROL.W   -(A3)
    ROL.W   (A2)

    ROR.B   #1 ,D1
    ROR.W   (A1)
    ROR.W   (A5)+
    ROR.W   -(A3)
    ROR.W   (A2)

    DIVS.W  D1, D2
    SUBQ.B  #$01, D1
    MULS.W  D0,D1
    CMP.B   #1, D0
    
    NOP
    MOVE.B  D0,D1
    MOVE.W  #100,D1
    MOVE.L  D0,D1
    MOVEQ   #$0,D1
    MOVEQ   #200,D2
    MOVEM.W   D0-D7,(A1)
    MOVEM.L   D0-D7,(A1)
    MOVEA.W   #$00001234,A1
    MOVEA.L D0,A0
    ADD.B     D0,D1
    ADD.W   D1,D2
    ADD.L   D1,-(A1)
    ADDA.W    A1,A5
    ADDA.L  D1,A2
    ADDQ    #1,(A2)
    SUB.B     D2,D3
    SUB.W   D2,D5
    SUB.L   D1,D3
    LEA     $00009999,A1
    AND.B     D0,D1
    AND.W   D2,D1
    AND.L   D3,D4
    OR.B      D1,D2
    OR.W    D2,D3    
    OR.L    D3,D4
    NOT     (A0)
    LSL.B     #$02,D5
    LSL.W   #2,D3
    LSL.L   #5,D4
    LSR.B     #$02,D2 
    LSR.W   #1,D5
    LSR.L   #2,D3
    ASL.B     #02,D3
    ASL.W   D1,D2
    ASL.L   D2,D3
    ASR     #02,D4
    ASR.B   #1,D5
    ASR.W  #1,D3
    ASR.L   #2,D2
    ROL     D0,D1
    ROR     #02,D5
    CMP     #$0020,D0
    BGT     TEST
    
    CMP     #$0020,D0
    BLE     TEST
    CMP     #$0020,D0
    BEQ     TEST
    JSR     (A1)
    RTS
    BRA     TEST

    
    RTS 
 * Put program code here
TEST
    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source
