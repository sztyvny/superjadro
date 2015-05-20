.386P
INCLUDE STRUKT.TXT
DANE    SEGMENT USE16
	GDT_NULL 	DESKR <0,0,0,0,0,0>
	GDT_DANE 	DESKR <DANE_SIZE-1,0,0,92H,0,0>		;8
	GDT_PROGRAM DESKR <PROGRAM_SIZE-1,0,0,98H,0,0>		;16
	GDT_STOS 	DESKR <767,0,0,92H,0,0>			;24
	GDT_EKRAN 	DESKR <4095,8000H,0BH,92H,0,0>		;32
	GDT_TSS_0	DESKR <103,0,0,89H,0,0>			;40
	GDT_TSS_1	DESKR <103,0,0,89H,0,0>			;48
	GDT_TSS_2	DESKR <103,0,0,89H,0,0>			;56
	GDT_SIZE = $ - GDT_NULL 
;Tablica deskryptorÛw przerwaÒ IDT
	IDT	LABEL WORD
	INCLUDE PM_IDT.TXT
	IDT_0	INTR <PROC_0>
	IDT_1	INTR <PROC_1>
	IDT_SIZE = $ - IDT
	PDESKR	DQ 	0
	ORG_IDT	DQ	0
	TEKST	DB 'TRYB CHRONIONY'
	TEKST1	DB 'PRZERWANIE'
   	INCLUDE PM_DATA.TXT
	INFO	DB 'POWROT Z TRYBU CHRONIONEGO $'
	T0_ADDR	DW 0,40
	T1_ADDR	DW 0,48
	T2_ADDR	DW 0,56
	TSS_0	DB 104 DUP (0)
	TSS_1	DB 104 DUP (0)
	TSS_2	DB 104 DUP (0)
	INF_0	DB 'PROGRAM GLOWNY'
	INF_1	DB 'ZADANIE NR 1'
	INF_2	DB 'ZADANIE NR 2'

	KOLOR	DB 0H
	POZYCJA	DW 0
	POZYCJA2	DW 78

	TIM_SEC	DW 0
	TIM_MIN	DW 0
	TIM_H	DW 0
	DZIELNIK DB 10
	
DANE_SIZE=$-GDT_NULL
DANE	ENDS

PROGRAM	SEGMENT 'CODE' USE16
        ASSUME CS:PROGRAM, DS:DANE, SS:STK
POCZ	LABEL WORD
INCLUDE PM_EXC.TXT
INCLUDE MAKRA.TXT
PROC_0	PROC
PROC_0	ENDP
;Procedura obs≥ugi przerwania od klawiatury (przerwanie nr 1)
PROC_1	PROC
	PUSH AX
	PUSH DX
	IN AL,60H	;Pobranie kodu klawisza
	MOV DL,AL
	IN AL,61H	;Potwierdzenie pobrania numeru klawisza
	OR AL,80H
	OUT 61H,AL
	AND AL,7FH
	OUT 61H,AL
	MOV AL,20H	;Sygna≥ koÒca obs≥ugi przerwania
	OUT 20H,AL
	CMP DL,2	;Klawisz '1'
	JE TSK0
	CMP DL,3	;Klawisz '2'
	JE TSK1
	CMP DL,0BH	;Klawisz '0'
	JE TSK2
	JMP OUT_P1
   TSK0:	JMP DWORD PTR T0_ADDR	;Prze≥πczenie zadania na zadanie 
					;nr 0 (program g≥Ûwny)
	JMP out_p1
   TSK1:	JMP DWORD PTR T1_ADDR	;Prze≥πczenie zadania na zadanie nr 1
	JMP OUT_P1
   TSK2:	JMP DWORD PTR T2_ADDR	;Prze≥πczenie zadania na zadanie nr 2
   OUT_P1:	POP DX
	POP AX
	IRETD
PROC_1	ENDP

START:	
	INICJOWANIE_DESKRYPTOROW
   PM_TSS0_I_TSS1 TSS_0,TSS_1,GDT_TSS_0,GDT_TSS_1
	XOR EAX,EAX
	MOV AX,OFFSET TSS_2
	ADD EAX,EBP
	MOV BX,OFFSET GDT_TSS_2
	MOV [BX].BASE_1,AX
	ROL EAX,16
	MOV [BX].BASE_M,AL
	MOV WORD PTR TSS_1+4CH,16		
	MOV WORD PTR TSS_1+20H,OFFSET ZADANIE1
	MOV WORD PTR TSS_1+50H,24		
	MOV WORD PTR TSS_1+38H,256
	MOV WORD PTR TSS_1+54H,8
	MOV WORD PTR TSS_1+48H,32
	STI
	PUSHFD
	POP EAX
	MOV DWORD PTR TSS_1+24H,EAX
	MOV WORD PTR TSS_2+4CH,16		
	MOV WORD PTR TSS_2+20H,OFFSET ZADANIE2
	MOV WORD PTR TSS_2+50H,24		
	MOV WORD PTR TSS_2+38H,512
	MOV WORD PTR TSS_2+54H,8
	MOV WORD PTR TSS_2+48H,32
	MOV DWORD PTR TSS_2+24H,EAX

	CLI
	INICJACJA_IDTR
	KONTROLER_PRZERWAN_PM 0FDH
	AKTYWACJA_PM
	MOV AX,32
	MOV ES,AX
	MOV GS,AX
	MOV FS,AX
	MOV AX,40			;Za≥adowanie rejestru zadania (TR)
	LTR AX				;deskryptorem segmentu stanu 
;wyczyszczenie ekranu
	
   CZYSC:
	MOV AL,0			;wypisanie pustego znaku	
	MOV AH,KOLOR			;wypelnienie czarnym
	MOV BX,POZYCJA			
	MOV ES:[BX],AX
	ADD POZYCJA,2
	CMP POZYCJA,0			;wypelnienie calego ekranu
	JNZ CZYSC
	
	MOV CX, 25
   PRZEDZIALEK:
	MOV AL,0			;wypisanie pustego znaku	
	MOV AH,70H			;wypelnienie szarym
	MOV BX,POZYCJA2			
	MOV ES:[BX],AX
	ADD POZYCJA2,2
	MOV AL,0			;wypisanie pustego znaku	
	MOV AH,70H			;wypelnienie szarym
	MOV BX,POZYCJA2			
	MOV ES:[BX],AX
	ADD POZYCJA2, 158
	
	DEC CX
	CMP CX,0			;wypelnienie calego ekranu paskiem
	JNZ PRZEDZIALEK


   WYPISZ_N_ZNAKOW_Z_ATRYBUTEM TEKST,14,704,ATRYB
	STI
   C1:

   
	MOV AX,0FFFFH			;W programie g≥Ûwnym wykonywana jest
   PTL1:	
	SUB AX,1
	CMP AX,0
	JNZ PTL1
MOV AX,0FFFFH			;W programie g≥Ûwnym wykonywana jest
   PTL2:	
	SUB AX,1
	CMP AX,0
	JNZ PTL2
MOV AX,0FFFFH			;W programie g≥Ûwnym wykonywana jest
   PTL3:	
	SUB AX,1
	CMP AX,0
	JNZ PTL3
MOV AX,0FFFFH			;W programie g≥Ûwnym wykonywana jest
   PTL4:	
	SUB AX,1
	CMP AX,0
	JNZ PTL4



	ADD TIM_SEC, 1
	CMP TIM_SEC, 60
	JE  C2
	JMP C_WYSW
;byla minuta
   C2:	MOV TIM_SEC, 0
	ADD TIM_MIN, 1
	CMP TIM_MIN, 60
	JE  C3
	JMP C_WYSW

   C3:	MOV TIM_MIN,0
	ADD TIM_H, 1
	CMP TIM_H, 24
	JE  C4
	JMP C_WYSW
   C4:  MOV TIM_H, 0
;====== wyswietlanie zegara
   C_WYSW:			; wyswietlanie zegara, ale jeszcze nie ogarniete
	
;====== sekundy
	MOV AX, TIM_SEC	
				;wypisanie sekundy dziesietnej
	DIV DZIELNIK
	ADD AL, 48
	MOV AH,71H			;kolor
	MOV BX,910			
	MOV ES:[BX],AX

  	MOV AX,TIM_SEC			;wypisanie sekundy dziesietnej
	DIV DZIELNIK
	MUL DZIELNIK	
	MOV BX, AX
	MOV AX,TIM_SEC	
	SUB AX, BX
	ADD AL, 48
	MOV AH,71H			;kolor
	MOV BX,912			
	MOV ES:[BX],AX
;====== dwukropek
	MOV AL, 58
	MOV AH,71H			;kolor
	MOV BX,908			
	MOV ES:[BX],AX

;====== minuty

	MOV AX, TIM_MIN	
				;wypisanie sekundy dziesietnej
	DIV DZIELNIK
	ADD AL, 48
	MOV AH,71H			;kolor
	MOV BX,904			
	MOV ES:[BX],AX

  	MOV AX,TIM_MIN			;wypisanie sekundy dziesietnej
	DIV DZIELNIK
	MUL DZIELNIK	
	MOV BX, AX
	MOV AX,TIM_MIN	
	SUB AX, BX
	ADD AL, 48
	MOV AH,71H			;kolor
	MOV BX,906			
	MOV ES:[BX],AX

;====== dwukropek
	MOV AL, 58
	MOV AH,71H			;kolor
	MOV BX,902			
	MOV ES:[BX],AX

;====== godziny
	MOV AX, TIM_H	
				;wypisanie sekundy dziesietnej
	DIV DZIELNIK
	ADD AL, 48
	MOV AH,71H			;kolor
	MOV BX,900			
	MOV ES:[BX],AX

  	MOV AX,TIM_H			;wypisanie sekundy dziesietnej
	DIV DZIELNIK
	MUL DZIELNIK	
	MOV BX, AX
	MOV AX,TIM_H	
	SUB AX, BX
	ADD AL, 48
	MOV AH,71H			;kolor
	MOV BX,898			
	MOV ES:[BX],AX




	JMP C1
				;koniec wyswietlania zegara
	
ZADANIE1 PROC
   A1:	MOV AH,71H
	MOV CX,2
   A2:	PUSH CX
	MOV DI,800
	MOV CX,12
	MOV SI,OFFSET INF_1
   A3:	MOV AL,[SI]
	MOV ES:[DI],AX
	INC SI
	ADD DI,2
	PUSH CX
	MOV ECX,0FFFFFFH	;OP”èNIENIE
   A4:	MOV DX,0FFFEH
	ADD DX,1
	DB 67H
	LOOP A4
	POP CX	
	LOOP A3
	POP CX
	MOV AH,17H
	LOOP A2
	JMP A1
ZADANIE1 ENDP

ZADANIE2 PROC
	CLI			;WYZEROWANIE ZNACZNIKA ZEZWOLENIA NA PRZERWANIE
	ETYKIETA_POWROTU_DO_RM:
	KONTROLER_PRZERWAN_RM
	MIEKI_POWROT_RM
	POWROT_DO_RM 0,1
ZADANIE2 ENDP

PROGRAM_SIZE=$-POCZ
PROGRAM ENDS
STK	SEGMENT STACK 'STACK'
	DB 256*3 DUP(0)
STK	ENDS
END START

