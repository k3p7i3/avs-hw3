	.file	"main.s"
	.intel_syntax noprefix

	.text
	#	объявление double EPS - погрешность вычислений
	.globl	EPS
	.data
	.align 8
	.type	EPS, @object
	.size	EPS, 8
EPS:
	#	double 0.001
	.long	3539053052
	.long	1062232653

    .extern read_data
    .extern write_data
    
    .text
	#	функция double generate_random()
	.globl	generate_random
	.type	generate_random, @function
generate_random:						#	точка входа в функцию generate_random
	#	генерация рандомного числа для входных данных
	#	пролог входа в функцию (сохраняем прежний rbp на стеке, задаем новые указатели на границы фрейма)
	push	rbp
	mov	rbp, rsp

	#	C: srand(time(NULL));
	mov	edi, 0
	call	time@PLT					#	eax = time(edi=NULL)
	mov	edi, eax						#	edi = time(NULL) - первый аргумент
	call	srand@PLT					#	srand(edi=time(NULL))

	#	C: double x = (((double)rand() / RAND_MAX) * 20) - 10;
	call	rand@PLT					#	eax = rand() - генерируется число int от 0 до RAND_MAX
	cvtsi2sd	xmm0, eax				#	xmm0 = eax - конвертируем число int eax в double и помещаем в xmm0
	movsd	xmm1, QWORD PTR .LC5[rip]	#	xmm1 = RAND_MAX (но в типе double)
	divsd	xmm0, xmm1					#	xmm0 = xmm0/xmm1 = rand() / RAND_MAX - число в интервале [0, 1]
	movsd	xmm1, QWORD PTR .LC6[rip]	#	xmm1 = xmm0 = rand() / RAND_MAX
	mulsd	xmm0, xmm1					#	xmm0 = xmm1 * xmm0 = rand() / RAND_MAX * 20.0 - число в интервале [0, 20]
	movsd	xmm1, QWORD PTR .LC7[rip]	#	xmm1 = 10.0 (загружаем литерал типа double)
	subsd	xmm0, xmm1					#	double x = xmm0 = xmm0 - xmm1 = rand() / RAND_MAX * 20.0 - 10.0 - число в интервале [-10, 10]
	
	#	C: if (!x)
	pxor	xmm1, xmm1					#	xmm1 = 0 (побитовый xor с самим собой)
	ucomisd	xmm0, xmm1		            #	cmp xmm0 = x,xmm1 = 0
	jne	.L8								#	if (x != 0) then {goto .L8}

	#	C:  x = rand() % 10 + 1;
	#	тут компилятор оптимизирует взятие по остатку, не будем замедлять программу и оставим оптимизацию :))
	call	rand@PLT					#	eax = rand()
	mov	ecx, eax						
	movsx	rax, ecx					#	rax = signed long long (rand()) - расширение
	imul	rax, rax, 1717986919		#	rax = rand() * 1717986919; 1717986919 ~ (2^34)/10 -> rax ~ rand() * (2^34)/10
	shr	rax, 32							#	rax >>= 32 -> rax = rand/10 * (2^34) / (2^32) = 4 * rand / 10
	mov	edx, eax						#	edx = eax = 4*rand / 10 
	sar	edx, 2							#	edx = rax / 4 = rand() // 10
	mov	eax, ecx						#	eax = rand()
	sar	eax, 31							#	eax = rand() >> 31 = старший бит rand (равен нулю, т.к rand отрицательные числа не генерирует)
	sub	edx, eax						
	mov	eax, edx						#	eax = edx = rand() // 10
	sal	eax, 2							#	eax *= 4 -> eax = 4 * rand // 10
	add	eax, edx						#	eax = rand//10 + 4*rand//10 = 5 * rand//10
	add	eax, eax						#	eax = 10 * (rand//10)
	sub	ecx, eax						#	ecx = rand() - 10*(rand()//10) = rand()%10
	mov	edx, ecx						
	lea	eax, 1[rdx]						#	eax = rand()%10 + 1

	cvtsi2sd	xmm0, eax				#	double x = xmm0 = double (eax = rand() %10 + 1) - конвертируем int в double на регистре xmm0

.L8:
	leave
	ret									#	return xmm0 = x
	.size	generate_random, .-generate_random


	#	функция double calculate(double x);
	.section	.rodata
.LC9:
	.string	"X is out of domain."
	.text
	.globl	calculate
	.type	calculate, @function
calculate:								#	точка входа в calculate
	#	вычисление cth(x) с помощью степенных рядов
	#	пролог входа в функцию (сохраняем прежний rbp на стеке, задаем новые указатели на границы фрейма)
	push	rbp
	mov	rbp, rsp
	sub	rsp, 16							#	rsp-=16 (размер фрейма 24 байтов)
	
	#	C: if (!x) - проверяем domain
	pxor	xmm1, xmm1					#	xmm1 = 0
	ucomisd	xmm0, xmm1	                #	cmp 0, x (xmm0)
	jp	.L13							#	if (not ordered (x = NaN)) then {goto .L13}

	ucomisd	xmm0, xmm1	                #	cmp 0, x (xmm0)
	jne	.L13							#	if (x != 0) {then goto .L13}

	#	x == 0 -> x not in domain (there's no cth(0))
	#	C: fprintf(stderr, "X is out of domain.");
	mov	rcx, QWORD PTR stderr[rip]		#	rcx = stderr - четвертый аргумент (поток вывода)
	mov	edx, 19							#	edx = 19 - кол-во символов (третий аргумент)
	mov	esi, 1							#	esi = 1 - размер "объектов" (второй аргумент)
	lea	rdi, .LC9[rip]					#	rdi = "X is out of domain." - первый аргумент
	call	fwrite@PLT					#	fwrite(rdi, esi=1, edx=19, rcx=stderr)
	#	C: exit(-1);
	mov	edi, -1
	call	exit@PLT					#	exit(edi = -1) - аварийный выход

.L13:
	#	C:	double exp = 1; 
	movsd	xmm3, QWORD PTR .LC10[rip]	#	exp = 1.0 - локальная переменная на регистре xmm3
	#	C: double exp_member = 1;
	movapd	xmm4, xmm3                  #	exp_member = 1.0 - локальная переменная на регистре xmm4
	#	C:	double exp_reverse = 1;
	movapd	xmm5, xmm3                  #	exp_reverse = 1.0 - локальная переменная на регистре xmm5
	#	C: double exp_reverse_member = 1;
	movapd	xmm6, xmm3                  #	exp_reverse_member = 1.0 - локальная переменная на регистре xmm6
	
	#	C:  unsigned int step = 0;
	pxor xmm7, xmm7			            #	step = 0 - сохраняем  в регистре xmm7 (в формате double)
	#	C: double prev_result = 0;
	movsd	QWORD PTR -16[rbp], xmm7	#	prev_result = 0.0 - локальная переменная на стеке (-16[rbp])
	#	C: double cur_result = 0;
	pxor	xmm1, xmm1                  #   xmm1 = cur_result = 0
	jmp	.L15							#	goto условие цикла while

.L20:									#	тело цикла while
	#	C: ++step;
	addsd	xmm7, QWORD PTR .LC10[rip]			#	step += 1 (1.0 считаем в double)

	#	C: exp_member *= x / step; - вычисляем след. член степенного ряда
    divsd xmm4, xmm7                    #   exp_member /= step
    mulsd xmm4, xmm0                    #   exp_member *= x

	#	C:	exp_reverse_member *= (-x) / step; - вычисляем след. член степенного ряда
    movsd xmm2, QWORD PTR .LC11[rip]    #   .LC11 = 0x10000000...00 - побитовая маска для смены знака
    pxor xmm6, xmm2                     #   xmm6 ^ .LC11 = -xmm6
    divsd xmm6, xmm7                    #   exp_reverse_member /= step
    mulsd xmm6, xmm0                    #   exp_reverse_member *= x

	#	C:	exp += exp_member; - обновляем экспоненту
	addsd	xmm3, xmm4	                #	exp += exp_member

	#	C: exp_reverse += exp_reverse_member; - обновляем экспоненту с (-x)
	addsd	xmm5,  xmm6	                #	exp_reverse += exp_reverse_member
	
	#	C:  prev_result = cur_result;
	movsd	QWORD PTR -16[rbp], xmm1	#	(-16[rbp]) prev_result = cur_result = xmm1

	#	C: cur_result = (exp + exp_reverse) / (exp - exp_reverse);
    movapd  xmm1, xmm3                  #   xmm1 = exp
    addsd   xmm1, xmm5                  #   xmm1 = exp + exp_reverse
    movapd  xmm2, xmm3
    subsd   xmm2, xmm5                  #   xmm2 = exp - exp_reverse
    divsd   xmm1, xmm2                  #   cur_result = xmm1/xmm2 = (exp+exp_reverse)/(exp-exp_reverse)  

.L15:									#	условие цикла while
	#	C:  while (step < 2 || EPS <= fabs(cur_result - prev_result))
	#	step < 2
	comisd	xmm7, QWORD PTR .LC10[rip]  #	cmp step(xmm7), 1.0
	jbe	.L20							#	if (step <= 1) then {goto .L20 - тело цикла}
	#	
	movapd	xmm2, xmm1		            #  	xmm2 = cur_result (xmm1)
	subsd	xmm2, QWORD PTR -16[rbp]	#	xmm0 = cur_result - prev_result
	andpd	xmm2, .LC12[rip]			#	.LC12 =0x0111111....1 - побитовая маска для взятия абсолютного значения -> xmm2 = fabs(xmm2)
	comisd	xmm2, QWORD PTR EPS[rip]	# 	cmp |cur_result-prev_result|, EPS
	jnb	.L20							#	if (|cur_result-prev_result| >= EPS) then {goto .L20 - тело цикла}
	
	movapd	xmm0, xmm1		            #	xmm0 = cur_result - возвращаемое значение
	leave
	ret
	.size	calculate, .-calculate


	#	функция int main(int argc, char **argv)
	.section	.rodata
	.align 8
.LC13:
	.string	"At least 2 argements excepted - input file and output file"
.LC14:
	.string	"--rand"
.LC15:
	.string	"--time"
.LC17:
	.string	"Process time:%f seconds\n"
	.text
	.globl	main
	.type	main, @function
main:									#	точка входа в main
	#	точка начала программы и обработка опций
	#	пролог входа в функцию (сохраняем прежний rbp на стеке, задаем новые указатели на границы фрейма)
	push	rbp
	mov	rbp, rsp
    push rbx
    push r12
    push r13
    push r14
	sub	rsp, 16							#	rsp-=16 (размер фрейма 5*8+16 = 56 байт)

    xor r12, r12
	mov	r12d, edi			            #	первый аргумент argc сохраняется из edi в r12d
	mov	r13, rsi			            #	второй аргумент agv сохраняется из rdi в r13

	#	C: if (argc < 3)
	cmp	r12d, 2			                #	cmp argc, 2
	jg	.L24							#	if (argc > 2) {goto .L24}
	#	слишком мало аргументов - выводим ошибку и завершаем программу
	#	C: fprintf(stderr, "At least 2 argements excepted - input file and output file");
	mov	rcx, QWORD PTR stderr[rip]		#	rcx = stderr - четвертый аргумент (поток)
	mov	edx, 58							#	edx = 58 - кол-во символов - третий аргумент
	mov	esi, 1							#	esi = 1 - размер символов - второй аргумент
	lea	rdi, .LC13[rip]					#	rdi = "At least 2 argements excepted - input file and output file" - первый аргумент
	call	fwrite@PLT					#	fwrite(rdi, esi=1, edx=58, rcx=stderr)
	#	C: exit(-1)
	mov	edi, 1							
	call	exit@PLT					#	exit(edi=-1)

.L24: 
	#	C:	char time_flag = 0;
	mov	bh, 0			                #	time_flag = 0 - флаг сохраняется в регистре bh
	#	C:	char random_flag = 0;
	mov	bl, 0			                #	random_flag = 0 - флаг сохраняется в регистре bl

	#	C: size_t i = 3 - начало цикла for
	mov	r14, 3			                #	i = 3 (r14) - локальный счетчик на регистре
	jmp	.L25
.L28:
	#	C:	if (!strcmp(argv[i], "--rand"))
	mov	rdi, QWORD PTR [r13 + 8*r14]	#	rdi = argv[i] (argv = r13, r14 = i) - первый аргумент
	lea	rsi, .LC14[rip]					#	rsi = "--rand" - второй аргумент
	call	strcmp@PLT					#	eax = srtcmp(rdi=argv[i], rsi="--rand") - вызов функции
	test	eax, eax					
	jne	.L26							#	if (argv[i] != "--rand") {goto .L26}

	#	C:	 random_flag = 1;
	mov	bl, 1			                #	random_flag = 1 (bl)
.L26:
	#	C:	if (!strcmp(argv[i], "--time"))
	lea	rsi, .LC15[rip]					#	rsi = "--time" - второй аргумент
	mov	rdi, QWORD PTR [r13 + 8*r14]	#	rdi = argv[i] - первый аргумент
	call	strcmp@PLT					#	eax = srtcmp(rdi=argv[i], rsi="--time") - вызов функции 
	test	eax, eax
	jne	.L27							#	if (argv[i] != "--time") {goto .L27}

	#	C:	time_flag = 1;
	mov	bh, 1			                #	time_flag = 1 (-70[rbp])
.L27:
	add	r14, 1			                #	C:	++i (-64[rbp])

.L25:
	#	C: i < argc - условие цикла for
	cmp	r14, r12			            #	cmp i, argc
	jb	.L28							#	if (i < argc) {goto .L28 - тело цикла for}

	#	C: if (random_flag)
	test    bl, bl			            #	cmp random_flag, 0
	je	.L29							#	if (random_flag == 0) {goto .L29} - ввод через файл

	#	random_flag = 1 - генерируем число случайно
	#	C:	x = generate_random();
	mov	eax, 0							#	0 аргументов через xmm
	call	generate_random				#	xmm0 = generate_random() - вызов функции
	movq	rax, xmm0					
	mov	QWORD PTR -48[rbp], rax			#	-48[rbp] = x = generate_random()

	#	C:	write_data(x, input);
	mov	rdi, QWORD PTR [r13 + 8]	    #	rdi = argv[1] = input - второй аргумент (через общие регистры)
	call	write_data					#	write_data(xmm0 = x, rdi = input) (xmm0 = x сохранился с прошлого вызова)
	jmp	.L30

.L29:
	#	random_flag = 0 - вводим из файла
	mov	rdi, QWORD PTR [r13 + 8]		#	rdi = argv[1] = input - первый аргумент
	call	read_data					#	xmm0 = read_data(rdi=input)
	movq	rax, xmm0
	mov	QWORD PTR -48[rbp], rax			#	-48[rbp] = x = read_data(input)

.L30:
	#	C: clock_t time_start = clock(); - начало замера
	call	clock@PLT
    xor r12, r12	
	sub	r12, rax			            #	r12 = -time_start = -clock()- сохраняем на регистр r12 (argc нам больше не пригодится)

	#	C: double cth = calculate(x); - главные вычисления
	movsd	xmm0, QWORD PTR -48[rbp]	#	xmm0 = x (-48[rbp])
	call	calculate					#	xmm0 = calculate(xmm0 = x)
	movq	rax, xmm0
	mov	QWORD PTR -40[rbp], rax			#	cth = calculate(x) = xmm0 (-48[rbp]) - результат сохранен на стеке

	#	C:	if (time_flag)
	test bh, bh			                #	cmp time_flag, 0
	je	.L31							#	if (time_flag == 0) {goto .L31 - Замеры не нужны}

	#	time_flag = 1 - замеряем время зацикливанием
	#	инициализация цикла for int i = 0;
	mov	r14, 0			                #	i = 0 - счетчик сохранен на регистр r14
	jmp	.L32
.L33:
	movsd	xmm0, QWORD PTR -48[rbp]	#	xmm0 = x (-48[rbp])
	call	calculate					#	calculate(xmm0 = x)

	add	r14, 1			                #	i += 1 - инкремент цикла for
.L32:									#	условие цикла for i < 1000000;
	cmp	r14, 999999		                #	cmp i (r14), 999999
	jle	.L33							#	if (i <= 999999) {goto .L33 - тело цикла for}

.L31:
	#	C:	 clock_t time_end = clock();
	call	clock@PLT	
	add	r12, rax			            #	r12 = time_end - time_start - сохраняется на регистр r12

	#	C: write_data(cth, output);
	mov	rdi, QWORD PTR [r13 + 16]		#	rdi = output = argv[2] - второй аргумент (через общие регистры)
	movq	xmm0, QWORD PTR -40[rbp]	#	xmm0 = cth (-40[rbp]) - первый аргумент (через регистры xmm)
	call	write_data					#	write_data(xmm0 = cth, rdi = output)


	test bh, bh			                #	cmp time_flag, 0
	je	.L34							#	if (time_flag == 0) {goto .L34 - не нужно выводить замеры времени}

	#	time_flag = 1 -> выводим замеры времени
	#	C: double cpu_time_used = ((double)(time_end - time_start)) / CLOCKS_PER_SEC;	#	rax = time_end - time_start
	cvtsi2sd	xmm0, r12				#	xmm0 = double (time_end - time_start)
	movsd	xmm1, QWORD PTR .LC16[rip]	#	xmm1 = (double) CLOCKS_PER_SEC
	divsd	xmm0, xmm1					#	xmm0 = (time_end - time_start) / CLOCKS_PER_SEC
	
	#	C:	printf("Process time:%f seconds\n", cpu_time_used);
	lea	rdi, .LC17[rip]					#	rdi = "Process time:%f seconds\n" - первый аргумент
	mov	eax, 1							#	кол-во аргументов, передаваемых через xmm = 1
	call	printf@PLT					#	printf(rdi = "Process time:%f seconds\n", xmm0=cpu_time_used (сохранился с прошлого вычисления))

.L34:
	mov	eax, 0
	add rsp, 16
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
	ret									#	return 0 - выход из программы
	.size	main, .-main


	.section	.rodata
	.align 8
.LC5:								#	(double) RAND_MAX
	.long	4290772992
	.long	1105199103
	.align 8
.LC6:								#	20.0 - double
	.long	0
	.long	1077149696
	.align 8
.LC7:								#	10.0 - double
	.long	0
	.long	1076101120
	.align 8
.LC10:
	.long	0						#	1.0 - double
	.long	1072693248
	.align 16
.LC11:								#	0x10000000...00 - побитовая маска для выделения знака (double)
	.long	0
	.long	-2147483648
	.long	0
	.long	0
	.align 16
.LC12:								#	0x0111111....1 - побитовая маска для взятия абсолютного значения (double)
	.long	4294967295
	.long	2147483647
	.long	0
	.long	0
	.align 8
.LC16:								# (double) CLOCKS_PER_SEC 
	.long	0
	.long	1093567616
	.ident	"GCC: (Ubuntu 9.4.0-1ubuntu1~20.04.1) 9.4.0"
	.section	.note.GNU-stack,"",@progbits
