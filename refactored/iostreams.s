	.file	"iostreams.s"
	.intel_syntax noprefix
    
    #	функция double read_data(char *file_name);
	.section	.rodata
.LC0:
	.string	"r"
.LC1:
	.string	"Input file isn't found"
.LC2:
	.string	"%lf"
	.text
	.globl	read_data
	.type	read_data, @function
read_data:								#	точка входа в функцию read_data
	#	ввод числа с плавающей точкой из файла
	#	пролог входа в функцию (сохраняем прежний rbp, rbx на стеке, задаем новые указатели на границы фрейма)
	push	rbp
    mov	rbp, rsp
    push rbx
	sub	rsp, 24							#	rsp-=24 (размер фрейма 24+16=40 байт)

	mov	rax, QWORD PTR fs:40			#	на стек (-16[rbp]) помещается канарейка для будущей проверки целостности стека		
	mov	QWORD PTR -16[rbp], rax
	xor	eax, eax

	#	C: FILE *istream = fopen(file_name, "r");
	lea	rsi, .LC0[rip]					#	rsi = "r" (.LC0) - второй аргумент
	call	fopen@PLT					#	rax = fopen(rdi=file_name, rsi="r") - вызываем функцию (rdi=file_name после затрется, но нам это больше не нужно)
	mov	rbx, rax			            #	iostream = fopen(file_name, "r") - сохраняем результат в регистр  rbx
	
	#	C: if (!istream) 
	cmp	rbx, 0			                #  	cmp istream (rbx), 0
	jne	.L2								#	if (istream != 0) {goto .L2}

	#	if istream == 0 - не смогли открыть файл - обработка ошибки
	#	C: fprintf(stderr, "Input file isn't found");
	mov	rcx, QWORD PTR stderr[rip]		#	rcx = stderr - четвертый аргумент
	mov	edx, 22							#	edx = 22 - количество символов для вывода (третий аргумент)
	mov	esi, 1							#	esi = 1 - размер выводимых "единиц" (второй аргумент)
	lea	rdi, .LC1[rip]					#	rdi = "Input file isn't found" (pointer to str) - первый аргумент
	call	fwrite@PLT					#	fwrite(rdi, esi, edx, rcx) = fprintf(stderr, "Input file isn't found");

	#	C: exit(-1);
	mov	edi, -1
	call	exit@PLT					#	exit(edi = -1)

.L2:
	#	C: fscanf(istream, "%lf", &x);
	lea	rdx, -24[rbp]					#	rdx = &x - третий аргумент (переменная x будет храниться на стеке в -24[rbp])	
	lea	rsi, .LC2[rip]					#	rsi = "%lf" - второй аргумент (pointer to str)
	mov	rdi, rbx						#	rdi = rbx = istream
	xor eax, eax						#	eax = 0 - кол-во аргументов, передаваемы через xmm
	call	__isoc99_fscanf@PLT			#	fscanf(rdi=istream, rsi="%lf", rdx=&x)

    mov	rdi, rbx						#	rdi = istream (rbx) - первый аргумент
	call	fclose@PLT					#	fclose(rdi = istream) - файл закрывается

	movsd	xmm0, QWORD PTR -24[rbp]	#	xmm0 = x (-24[rbp]) - перекладываем x из стека в регистр xmm0

	mov	rax, QWORD PTR -16[rbp]			#	проверяем, жива ли канарейка
	xor	rax, QWORD PTR fs:40
	je	.L4
	call	__stack_chk_fail@PLT		#	канарейка умерла -> оповещаем об утечке
.L4:
	add rsp, 24								#	восстанавливаем границы фрейма
	pop rbx
    pop rbp
    ret									#	return xmm0 = x
	.size	read_data, .-read_data


	#	функция void write_data(double x, char *file_name);
	.section	.rodata
.LC3:
	.string	"w"
.LC4:
	.string	"Output file isn't found"
	.text
	.globl	write_data
	.type	write_data, @function
write_data:								#	точка входа в функцию write_data
	#	вывод числа с плавающей точкой
	#	пролог входа в функцию (сохраняем прежний rbp на стеке, задаем новые указатели на границы фрейма)
	push	rbp	
	mov	rbp, rsp
    push rbx
    sub rsp, 8                          #   rsp-=8 (размер фрейма 8+16=24 байт)

	movsd QWORD PTR -16[rbp], xmm0	    #	сохраняем первый аргумент функции x из регистра xmm0 на стек в -16[rbp] (чтобы не затерся при вызове fopen)
	
	#	C: FILE *ostream = fopen(file_name, "w");
	lea	rsi, .LC3[rip]					#	rsi = "w" (pointer to str) - второй аргумент
	call	fopen@PLT					#	rax = fopen(rdi=file_name, rsi="w") - открывается файл для записи (rdi=file_name затрется, но он нам больше не нужен)
	mov	rbx, rax			            #	ostream = fopen(file_name, "w") - сохраняем в регистр rbx указатель на файл
	
	#	C: if (!ostream)
	cmp	rbx, 0			                #	cmp ostream (rbx), 0		
	jne	.L6								#	if (ostream) {goto .L6}

	#	if ostream == 0 - не смогли открыть файл
	#	C: fprintf(stderr, "Output file isn't found");
	mov	rcx, QWORD PTR stderr[rip]		#	rcx = stderr - четвертый аргумент (поток вывода)
	mov	edx, 23							#	edx = 23 - кол-во символов (третий аргумент)
	mov	esi, 1							#	esi = 1 - размер выводимых объектов (второй аргумент)
	lea	rdi, .LC4[rip]					#	rdi = "Output file isn't found" (pointer to str) - первый аргумент
	call	fwrite@PLT					#	fwrite(rdi, esi, edx, rcx) = fprintf(stderr, "Output file isn't found");

	#	C: exit(-1);
	mov	edi, -1							
	call	exit@PLT					#	exit(edi = -1) - аварийный выход из программы

.L6:
	#	C: fprintf(ostream, "%lf", x);		
	movq xmm0, QWORD PTR -16[rbp]		#	xmm0 = = x - третий аргумент (первый с плавающей точкой)
	lea	rsi, .LC2[rip]					#	rsi = "%lf" (pointer to str) - второй аргумент
	mov	rdi, rbx						#	rdi = ostream (rbx) - первый аргумент
	mov	eax, 1							#	eax = 1 - кол-во аргументов, передаваемых через xmm
	call	fprintf@PLT					#	fprintf(rdi=ostream, rsi="%lf", xmm0=x) - вызов функции

	mov	rdi, rbx						#	rdi = ostream (-8[rbp]) - первый аргумент
	call	fclose@PLT					#	fclose(rdi = ostream) - закрытие файла

	nop
	add rsp, 8							#	возвращаем границы фрейма на место
	pop rbx
    pop rbp
    ret
	.size	write_data, .-write_data
