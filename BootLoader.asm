assume cs:code

code segment

;=======================安装程序==========================

  start:mov ax,cs     ;把启动引导代码写入软驱的第一扇区
	mov es,ax
	mov bx,offset lead
	mov al,1
	mov ch,0
	mov cl,1
	mov dl,0
	mov dh,0
	mov ah,3
	int 13h

	mov ax,cs     ;把系统引导代码写入软驱的第二扇区以后的2个扇区
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

;=======================引导程序==========================

   lead:mov ax,0      ;电脑开机后，先执行此段代码
	mov es,ax     ;把第二扇区以后的2个扇区的代码读取到内存0:7e00h处
	mov bx,7e00h
	mov al,2
	mov ch,0
	mov cl,2
	mov dl,0
	mov dh,0
	mov ah,2
	int 13h

	mov ax,7e00h  ;执行系统引导代码main
	jmp ax

;========================主程序===========================

   main:jmp near ptr mainstart
	
	choice0 db 'Welcome to the system of Mr.Yang',0  ;主菜单内容
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

	call clearscreen       ;清空屏幕显示
	call showmenu          ;显示主菜单

 select:mov ah,0               ;等待用户选择
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

;-----------------输入1为重启计算机------------------

select1:mov dl,'1'             ;显示用户输入的选项
	call useroption
	call restart           ;重启计算机

;--------------输入2为进入当前操作系统---------------

select2:mov dl,'2'             ;显示用户输入的选项
	call useroption
	call startsystem       ;进入操作系统

;-------------输入3为动态显示日期和时间--------------

select3:mov dl,'3'             ;显示用户输入的选项
	call useroption
	call clearscreen       ;清空屏幕显示

	mov ah,2               ;将光标显示在最前面
	mov bh,0
	mov dh,13
	mov dl,56
	int 10h

	mov bp,0               ;显示提示字符串
	mov di,160*13+10*2
	mov si,offset messag-offset main+7e00h
	call showline

  clock:mov di,160*10+23*2           ;显示当前时间
	mov byte ptr es:[di+4],2fh   ;显示'/'
	mov byte ptr es:[di+10],2fh  ;显示'/'
	mov byte ptr es:[di+16],20h  ;显示空格
	mov byte ptr es:[di+22],3ah  ;显示冒号
	mov byte ptr es:[di+28],3ah  ;显示冒号
	mov cx,6
	mov bx,offset cmos-offset main+7e00h
 clocks:mov al,ds:[bx]
	call getcmos
	add di,6
	inc bx
	loop clocks

	mov ah,1            ;判断键盘缓冲区是否为空
	int 16h
	je clock
	mov ah,0            ;从缓冲区读取一个值
	int 16h

	cmp ah,3bh          ;输入F1，改变颜色
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

;---------------输入4为修改日期和时间----------------

select4:mov dl,'4'          ;显示用户输入的选项
	call useroption
	call clearscreen    ;清空屏幕显示

	mov bp,0            ;显示提示字符串
	mov di,160*7+10*2
	mov si,offset messag1-offset main+7e00h
	call showline

	mov si,200h
	mov dh,10
	mov dl,10
  input:mov ah,2            ;光标放在第10行第10列
	mov bh,0
	int 10h

	mov ah,0            ;等待用户输入12位日期时间
	int 16h
	cmp ah,1            ;判断是否是Esc
	je toesc
	cmp ah,0eh          ;退格
	je tobs
	cmp dl,22           ;判断光标是否在最后一位
	jb num
	cmp ah,1ch          ;回车
	je enter
	jmp short input
    num:cmp al,30h          ;判断是否是数字
	jb input
	cmp al,39h
	ja input

	mov ah,0            ;输入的是数字，显示输入的数字
	call charstack
	mov ah,2
	call charstack
	inc dl              ;光标后移一位
	jmp short input

  toesc:call resetcharstack ;是Esc重置字符栈后返回
	jmp near ptr mainstart

   tobs:mov ah,1            ;退格
	call charstack
	mov ah,2
	call charstack
	cmp dl,10
	jna toinput
	dec dl              ;光标前移一位
toinput:jmp short input

  enter:mov al,0            ;回车
	mov ah,0
	call charstack
	mov ah,2
	call charstack
	call resetcharstack ;重置字符栈
	call savetocmos     ;将时间写入CMOS

	mov bp,0            ;显示修改成功字符串
	mov di,160*13+10*2
	mov si,offset messag2-offset main+7e00h
	call showline

 tomenu:mov ah,0            ;按Esc返回主菜单
	int 16h
	cmp ah,1
	jne tomenu
	jmp near ptr mainstart

;-----------------以下为调用的子程序-----------------

clearscreen:                ;清空屏幕显示
	mov cx,2000
	mov di,0
 clears:mov byte ptr es:[di],' '
	mov byte ptr es:[di+1],7
	add di,2
	loop clears
	ret

showmenu:                   ;显示主菜单
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
	mov ah,2            ;将光边置于最后
	mov bh,0
	mov dh,14
	mov dl,41
	int 10h
	ret

showline:                   ;显示一行字符串
	mov al,cs:[si]
	cmp al,0
	je lineend
	mov es:[bp+di],al
	inc si
	add bp,2
	jmp short showline
lineend:ret

restart:mov ax,0ffffh       ;重启计算机
	push ax
	mov ax,0
	push ax
	retf
	ret

useroption:                 ;显示用户输入的选项
	mov ah,9
	mov al,dl
	mov bl,7
	mov bh,0
	mov cx,1
	int 10h
	ret

startsystem:                ;把c盘1扇区的内容读取到0:7c00h处
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

	mov ax,0            ;进入操作系统
	push ax
	mov ax,7c00h
	push ax
	retf
	ret

getcmos:push bx             ;显示CMOS中的时间参数
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

charstack:                  ;显示输入的字符串
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

resetcharstack:             ;重置字符栈
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

savetocmos:                 ;将时间写入CMOS
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

 chcmos:push cx             ;修改CMOS的时间
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

