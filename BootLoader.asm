assume cs:code

code segment

;=======================��װ����==========================

  start:mov ax,cs     ;��������������д�������ĵ�һ����
	mov es,ax
	mov bx,offset lead
	mov al,1
	mov ch,0
	mov cl,1
	mov dl,0
	mov dh,0
	mov ah,3
	int 13h

	mov ax,cs     ;��ϵͳ��������д�������ĵڶ������Ժ��2������
	mov es,ax
	mov bx,offset main
	mov al,2
	mov ch,0
	mov cl,2
	mov dl,0
	mov dh,0
	mov ah,3
	int 13h

	mov ax,4c00h
	int 21h

;=======================��������==========================

   lead:mov ax,0      ;���Կ�������ִ�д˶δ���
	mov es,ax     ;�ѵڶ������Ժ��2�������Ĵ����ȡ���ڴ�0:7e00h��
	mov bx,7e00h
	mov al,2
	mov ch,0
	mov cl,2
	mov dl,0
	mov dh,0
	mov ah,2
	int 13h

	mov ax,7e00h  ;ִ��ϵͳ��������main
	jmp ax

;========================������===========================

   main:jmp near ptr mainstart
	
	choice0 db 'Welcome to the system of Mr.Yang',0  ;���˵�����
	choice1 db '1. restart pc',0
	choice2 db '2. start operating system',0
	choice3 db '3. show the datetime',0
	choice4 db '4. set the datetime',0
	choice5 db 'Please Enter Your Choice(1~4):',0
	choices dw offset choice0-offset main+7e00h
		dw offset choice1-offset main+7e00h
		dw offset choice2-offset main+7e00h
		dw offset choice3-offset main+7e00h
		dw offset choice4-offset main+7e00h
		dw offset choice5-offset main+7e00h
	cmos    db 9,8,7,4,2,0
	messag  db 'Press F1 to change color, press Esc to return.',0
	messag1 db 'Type 12 numbers and Enter to mofify the datetime.',0
	messag2 db 'Modified successfully! Press Esc to return.',0

mainstart:
	mov ax,0
	mov ds,ax
	mov ax,0b800h
	mov es,ax

	call clearscreen       ;�����Ļ��ʾ
	call showmenu          ;��ʾ���˵�

 select:mov ah,0               ;�ȴ��û�ѡ��
	int 16h

	cmp ah,02h
	je select1
	cmp ah,03h
	je select2
	cmp ah,04h
	je select3
	cmp ah,05h
	jne select
	jmp near ptr select4

;-----------------����1Ϊ���������------------------

select1:mov dl,'1'             ;��ʾ�û������ѡ��
	call useroption
	call restart           ;���������

;--------------����2Ϊ���뵱ǰ����ϵͳ---------------

select2:mov dl,'2'             ;��ʾ�û������ѡ��
	call useroption
	call startsystem       ;�������ϵͳ

;-------------����3Ϊ��̬��ʾ���ں�ʱ��--------------

select3:mov dl,'3'             ;��ʾ�û������ѡ��
	call useroption
	call clearscreen       ;�����Ļ��ʾ

	mov ah,2               ;�������ʾ����ǰ��
	mov bh,0
	mov dh,13
	mov dl,56
	int 10h

	mov bp,0               ;��ʾ��ʾ�ַ���
	mov di,160*13+10*2
	mov si,offset messag-offset main+7e00h
	call showline

  clock:mov di,160*10+23*2           ;��ʾ��ǰʱ��
	mov byte ptr es:[di+4],2fh   ;��ʾ'/'
	mov byte ptr es:[di+10],2fh  ;��ʾ'/'
	mov byte ptr es:[di+16],20h  ;��ʾ�ո�
	mov byte ptr es:[di+22],3ah  ;��ʾð��
	mov byte ptr es:[di+28],3ah  ;��ʾð��
	mov cx,6
	mov bx,offset cmos-offset main+7e00h
 clocks:mov al,ds:[bx]
	call getcmos
	add di,6
	inc bx
	loop clocks

	mov ah,1            ;�жϼ��̻������Ƿ�Ϊ��
	int 16h
	je clock
	mov ah,0            ;�ӻ�������ȡһ��ֵ
	int 16h

	cmp ah,3bh          ;����F1���ı���ɫ
	jne notf1
	mov di,160*10+23*2+1
	mov cx,17
chcolor:inc byte ptr es:[di]
	add di,2
	loop chcolor
	mov di,160*13+10*2+1
	mov cx,46
chcolor2:inc byte ptr es:[di]
	add di,2
	loop chcolor2
	jmp short clock
  notf1:cmp ah,01h
	jne clock
	jmp near ptr mainstart

;---------------����4Ϊ�޸����ں�ʱ��----------------

select4:mov dl,'4'          ;��ʾ�û������ѡ��
	call useroption
	call clearscreen    ;�����Ļ��ʾ

	mov bp,0            ;��ʾ��ʾ�ַ���
	mov di,160*7+10*2
	mov si,offset messag1-offset main+7e00h
	call showline

	mov si,200h
	mov dh,10
	mov dl,10
  input:mov ah,2            ;�����ڵ�10�е�10��
	mov bh,0
	int 10h

	mov ah,0            ;�ȴ��û�����12λ����ʱ��
	int 16h
	cmp ah,1            ;�ж��Ƿ���Esc
	je toesc
	cmp ah,0eh          ;�˸�
	je tobs
	cmp dl,22           ;�жϹ���Ƿ������һλ
	jb num
	cmp ah,1ch          ;�س�
	je enter
	jmp short input
    num:cmp al,30h          ;�ж��Ƿ�������
	jb input
	cmp al,39h
	ja input

	mov ah,0            ;����������֣���ʾ���������
	call charstack
	mov ah,2
	call charstack
	inc dl              ;������һλ
	jmp short input

  toesc:call resetcharstack ;��Esc�����ַ�ջ�󷵻�
	jmp near ptr mainstart

   tobs:mov ah,1            ;�˸�
	call charstack
	mov ah,2
	call charstack
	cmp dl,10
	jna toinput
	dec dl              ;���ǰ��һλ
toinput:jmp short input

  enter:mov al,0            ;�س�
	mov ah,0
	call charstack
	mov ah,2
	call charstack
	call resetcharstack ;�����ַ�ջ
	call savetocmos     ;��ʱ��д��CMOS

	mov bp,0            ;��ʾ�޸ĳɹ��ַ���
	mov di,160*13+10*2
	mov si,offset messag2-offset main+7e00h
	call showline

 tomenu:mov ah,0            ;��Esc�������˵�
	int 16h
	cmp ah,1
	jne tomenu
	jmp near ptr mainstart

;-----------------����Ϊ���õ��ӳ���-----------------

clearscreen:                ;�����Ļ��ʾ
	mov cx,2000
	mov di,0
 clears:mov byte ptr es:[di],' '
	mov byte ptr es:[di+1],7
	add di,2
	loop clears
	ret

showmenu:                   ;��ʾ���˵�
	mov bx,offset choices-offset main+7e00h
	mov di,160*4+10*2
	mov cx,6
showmenus:
	mov si,cs:[bx]
	mov bp,0
	call showline
	add bx,2
	add di,320
	loop showmenus
	mov ah,2            ;������������
	mov bh,0
	mov dh,14
	mov dl,41
	int 10h
	ret

showline:                   ;��ʾһ���ַ���
	mov al,cs:[si]
	cmp al,0
	je lineend
	mov es:[bp+di],al
	inc si
	add bp,2
	jmp short showline
lineend:ret

restart:mov ax,0ffffh       ;���������
	push ax
	mov ax,0
	push ax
	retf
	ret

useroption:                 ;��ʾ�û������ѡ��
	mov ah,9
	mov al,dl
	mov bl,7
	mov bh,0
	mov cx,1
	int 10h
	ret

startsystem:                ;��c��1���������ݶ�ȡ��0:7c00h��
	mov ax,0
	mov es,ax
	mov bx,7c00h
	mov al,1
	mov ch,0
	mov cl,1
	mov dl,80h
	mov dh,0
	mov ah,2
	int 13h

	mov ax,0            ;�������ϵͳ
	push ax
	mov ax,7c00h
	push ax
	retf
	ret

getcmos:push bx             ;��ʾCMOS�е�ʱ�����
	push cx
	out 70h,al
	in al,71h
	mov ah,al
	mov cl,4
	shr ah,cl
	and al,00001111b
	add ah,30h
	add al,30h
	mov bx,0b800h
	mov es,bx
	mov byte ptr es:[di],ah
	mov es:[di+2],al
	pop cx
	pop bx
	ret

charstack:                  ;��ʾ������ַ���
	jmp short charstart

	table dw offset charpush-offset main+7e00h
	      dw offset charpop-offset main+7e00h
	      dw offset charshow-offset main+7e00h
	top dw 0

charstart:
	push bx
	push dx
	push di
	push es
	push bp

	cmp ah,2
	ja sret
	mov bl,ah
	mov bh,0
	add bx,bx
	jmp word ptr cs:[bx+offset table-offset main+7e00h]

charpush:
	mov bp,offset top-offset main+7e00h
	mov bx,cs:[bp]
	mov cs:[bx+si],al
	inc word ptr cs:[bp]
	jmp sret

charpop:
	mov bp,offset top-offset main+7e00h
	cmp word ptr cs:[bp],0
	je sret
	dec word ptr cs:[bp]
	jmp sret

charshow:
	mov bx,0b800h
	mov es,bx
	mov di,160*10+10*2
	mov bx,0
charshows:
	mov bp,offset top-offset main+7e00h
	cmp bx,cs:[bp]
	jne noempty
	mov byte ptr es:[di],' '
	jmp sret
noempty:
	mov al,cs:[bx+si]
	mov es:[di],al
	mov byte ptr es:[di+2],' '
	inc bx
	add di,2
	jmp charshows 

   sret:pop bp
	pop es
	pop di
	pop dx
	pop bx
	ret

resetcharstack:             ;�����ַ�ջ
	push bx
	push cx
	mov bx,offset top-offset main+7e00h
	mov word ptr cs:[bx],0
	mov bx,0
	mov si,200h
	mov cx,15
wipestack:
	mov byte ptr [si][bx],0
	inc bx
	loop wipestack
	pop cx
	pop bx
	ret

savetocmos:                 ;��ʱ��д��CMOS
	push bx
	push cx
	mov di,160*10+10*2
	mov cx,6
	mov bx,offset cmos-offset main+7e00h
chcmoss:mov dh,cs:[bx]
	call chcmos
	add di,4
	inc bx
	loop chcmoss
	pop cx
	pop bx
	ret

 chcmos:push cx             ;�޸�CMOS��ʱ��
	mov ah,es:[di]
	sub ah,30h
	mov cl,4
	shl ah,cl
	mov al,es:[di+2]
	sub al,30h
	add ah,al
	mov al,dh
	out 70h,al
	mov al,ah
	out 71h,al
	pop cx
	ret

code ends

end start

