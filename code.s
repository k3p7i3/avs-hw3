	.file	"code.c"
	.intel_syntax noprefix

	.text
	#	объявление double EPS - погрешность вычислений
	.globl	EPS
	.data
	.align 8
	.type	EPS, @object
	.size	EPS, 8
EPS:
	#	судя по всему, компилятор использует эквивалентное двоичное представление, но в long'ах
	.long	3539053052
	.long	1062232653


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
	#	пролог входа в функцию (сохраняем прежний rbp на стеке, задаем новые указатели на границы фрейма)
	push	rbp
	mov	rbp, rsp
	sub	rsp, 48							#	rsp -= 48 (размер фрейма 56 байт)

	mov	QWORD PTR -40[rbp], rdi			#	первый аргумент функции file_name из rdi сохраняется на стек (-40[rbp])

	mov	rax, QWORD PTR fs:40			#	на стек (-8[rbp]) помещается канарейка для будущей проверки целостности стека		
	mov	QWORD PTR -8[rbp], rax
	xor	eax, eax

	#	C: FILE *istream = fopen(file_name, "r");
	mov	rax, QWORD PTR -40[rbp]			#	rax = file_name (pointer to str)
	lea	rsi, .LC0[rip]					#	rsi = "r" (.LC0) - второй аргумент
	mov	rdi, rax						#	rdi = file_name (-40[rbp]) - первый аргумент
	call	fopen@PLT					#	rax = fopen(rdi=file_name, rsi="r") - вызываем функцию
	mov	QWORD PTR -16[rbp], rax			#	iostream = fopen(file_name, "r") = rax - сохраняем результат в -16[rbp] на стеке
	
	#	C: if (!istream) 
	cmp	QWORD PTR -16[rbp], 0			#	cmp istream (-16[rbp]), 0
	jne	.L2								#	if (istream != 0) {goto .L2}

	#	if istream == 0 - не смогли открыть файл
	#	C: fprintf(stderr, "Input file isn't found");
	mov	rax, QWORD PTR stderr[rip]
	mov	rcx, rax						#	rcx = stderr - четвертый аргумент
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
	mov	rax, QWORD PTR -16[rbp]			
	lea	rsi, .LC2[rip]					#	rsi = "%lf" - второй аргумент (pointer to str)
	mov	rdi, rax						#	rdi = -16[rbp] = istream
	mov	eax, 0							#	eax = 0 - кол-во аргументов, передаваемы через xmm
	call	__isoc99_fscanf@PLT			#	fscanf(rdi=istream, rsi="%lf", rdx=&x)

	mov	rax, QWORD PTR -16[rbp]
	mov	rdi, rax						#	rdi = istream (-16[rbp]) - первый аргумент
	call	fclose@PLT					#	fclose(rdi = istream) - файл закрывается

	movsd	xmm0, QWORD PTR -24[rbp]	#	xmm0 = x (-24[rbp]) - перекладываем x из стека в регистр xmm0

	mov	rax, QWORD PTR -8[rbp]			#	проверяем, жива ли канарейка
	xor	rax, QWORD PTR fs:40
	je	.L4
	call	__stack_chk_fail@PLT		#	канарейка умерла -> оповещаем об утечке
.L4:
	leave								#	восстанавливаем границы фрейма
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
	sub	rsp, 32							#	rsp-=32 (размер фрейма 40 байтов)

	#	аргументы из регистров сохраняются на стек
	movsd	QWORD PTR -24[rbp], xmm0	#	сохраняем первый аргумент функции x из регистра xmm0 на стек (-24[rbp]) 
	mov	QWORD PTR -32[rbp], rdi			#	сохраняем второй аргумент функции file_name из регистра rdi на стек (-32[rbp])
	
	#	C: FILE *ostream = fopen(file_name, "w");
	mov	rax, QWORD PTR -32[rbp]
	lea	rsi, .LC3[rip]					#	rsi = "w" (pointer to str) - второй аргумент
	mov	rdi, rax						#	rdi = -32[rbp] = file_name - первый аргумент
	call	fopen@PLT					#	rax = fopen(rdi=file_name, rsi="w") - открывается файл для записи
	mov	QWORD PTR -8[rbp], rax			#	ostream = fopen(file_name, "w") - сохраняем на стек (-8[rbp]) указатель на файл
	
	#	C: if (!ostream)
	cmp	QWORD PTR -8[rbp], 0			#	cmp ostream (-8[rbp]), 0		
	jne	.L6								#	if (ostream) {goto .L6}

	#	if ostream == 0 - не смогли открыть файл
	#	C: fprintf(stderr, "Output file isn't found");
	mov	rax, QWORD PTR stderr[rip]
	mov	rcx, rax						#	rcx = stderr - четвертый аргумент (поток вывода)
	mov	edx, 23							#	edx = 23 - кол-во символов (третий аргумент)
	mov	esi, 1							#	esi = 1 - размер выводимых объектов (второй аргумент)
	lea	rdi, .LC4[rip]					#	rdi = "Output file isn't found" (pointer to str) - первый аргумент
	call	fwrite@PLT					#	fwrite(rdi, esi, edx, rcx) = fprintf(stderr, "Output file isn't found");

	#	C: exit(-1);
	mov	edi, -1							
	call	exit@PLT					#	exit(edi = -1) - аварийный выход из программы

.L6:
	#	C: fprintf(ostream, "%lf", x);
	mov	rdx, QWORD PTR -24[rbp]			#	rdx = double x (-24[rbp])
	mov	rax, QWORD PTR -8[rbp]			
	movq	xmm0, rdx					#	xmm0 = rdx = x - третий аргумент (первый с плавающей точкой)
	lea	rsi, .LC2[rip]					#	rsi = "%lf" (pointer to str) - второй аргумент
	mov	rdi, rax						#	rdi = ostream (-8[rbp]) - первый аргумент
	mov	eax, 1							#	eax = 1 - кол-во аргументов, передаваемых через xmm
	call	fprintf@PLT					#	fprintf(rdi=ostream, rsi="%lf", xmm0=x) - вызов функции

	mov	rax, QWORD PTR -8[rbp]
	mov	rdi, rax						#	rdi = ostream (-8[rbp]) - первый аргумент
	call	fclose@PLT					#	fclose(rdi = ostream) - закрытие файла

	nop
	leave								#	возвращаем границы фрейма на место
	ret
	.size	write_data, .-write_data

	#	функция double generate_random()
	.globl	generate_random
	.type	generate_random, @function
generate_random:						#	точка входа в функцию generate_random
	#	генерация рандомного числа для входных данных
	#	пролог входа в функцию (сохраняем прежний rbp на стеке, задаем новые указатели на границы фрейма)
	push	rbp
	mov	rbp, rsp
	sub	rsp, 16							#	rsp-=16 (размер фрейма 24 байтов)

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
	movapd	xmm1, xmm0					#	xmm1 = xmm0 = rand() / RAND_MAX
	movsd	xmm0, QWORD PTR .LC6[rip]	#	xmm0 = 20.0 (загружаем литерал типа double)
	mulsd	xmm0, xmm1					#	xmm0 = xmm1 * xmm0 = rand() / RAND_MAX * 20.0 - число в интервале [0, 20]
	movsd	xmm1, QWORD PTR .LC7[rip]	#	xmm1 = 10.0 (загружаем литерал типа double)
	subsd	xmm0, xmm1					#	xmm0 = xmm0 - xmm1 = rand() / RAND_MAX * 20.0 - 10.0 - число в интервале [-10, 10]
	movsd	QWORD PTR -8[rbp], xmm0		#	x = xmm0 = rand() / RAND_MAX * 20.0 - 10.0  - сохраняется на стеке (-8[rbp])
	
	#	C: if (!x)
	pxor	xmm0, xmm0					#	xmm0 = 0 (побитовый xor с самим собой)
	ucomisd	xmm0, QWORD PTR -8[rbp]		#	cmp xmm0 = 0, -8[rbp] = x
	jp	.L8								#	if unordered (pf = 1) then goto { .L8} (то есть что-то из аргументов NaN)
	pxor	xmm0, xmm0					
	ucomisd	xmm0, QWORD PTR -8[rbp]		#	cmp xmm0 = 0, -8[rbp] = x
	jne	.L8								#	if (x != 0) then {goto .L8}

	#	C:  x = rand() % 10 + 1;
	#	тут компилятор снова колдует что-то, чтобы оптимизировать взятие по остатку
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
	cvtsi2sd	xmm0, eax				#	xmm0 = double (eax = rand() %10 + 1) - конвертируем int в double на регистре xmm0
	movsd	QWORD PTR -8[rbp], xmm0		#	x = double(rand % 10 + 1) - сохраняется на стеке

.L8:
	movsd	xmm0, QWORD PTR -8[rbp]		#	xmm0 = x (-8[rbp]) - переносим возвращаемое значение из стека на регистр xmm0
	leave
	ret									#	return xmm0
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
	sub	rsp, 80							#	rsp-=80 (размер фрейма 88 байтов)

	movsd	QWORD PTR -72[rbp], xmm0	#	первый(and only) аргумент x из xmm0 сохраняется на стек (-72[rbp])
	
	#	C: if (!x) - проверяем domain
	pxor	xmm0, xmm0					#	xmm0 = 0
	ucomisd	xmm0, QWORD PTR -72[rbp]	#	cmp 0, x (-72[rbp])
	jp	.L13							#	if (not ordered (x = NaN)) then {goto .L13}

	pxor	xmm0, xmm0
	ucomisd	xmm0, QWORD PTR -72[rbp]	#	cmp 0, x (-72[rbp])
	jne	.L13							#	if (x != 0) {then goto .L13}

	#	x == 0 -> x not in domain (there's no cth(0))
	#	C: fprintf(stderr, "X is out of domain.");
	mov	rax, QWORD PTR stderr[rip]
	mov	rcx, rax						#	rcx = stderr - четвертый аргумент (поток вывода)
	mov	edx, 19							#	edx = 19 - кол-во символов (третий аргумент)
	mov	esi, 1							#	esi = 1 - размер "объектов" (второй аргумент)
	lea	rdi, .LC9[rip]					#	rdi = "X is out of domain." - первый аргумент
	call	fwrite@PLT					#	fwrite(rdi, esi=1, edx=19, rcx=stderr)
	#	C: exit(-1);
	mov	edi, -1
	call	exit@PLT					#	exit(edi = -1) - аварийный выход

.L13:
	#	C:	double exp = 1; 
	movsd	xmm0, QWORD PTR .LC10[rip]	#	xmm0 = 1.0
	movsd	QWORD PTR -48[rbp], xmm0	#	exp = 1.0 - локальная переменная на стеке (-48[rbp])
	#	C: double exp_member = 1;
	movsd	xmm0, QWORD PTR .LC10[rip]
	movsd	QWORD PTR -40[rbp], xmm0	#	exp_member = 1.0 - локальная переменная на стеке (-40[rbp])
	#	C:	double exp_reverse = 1;
	movsd	xmm0, QWORD PTR .LC10[rip]
	movsd	QWORD PTR -32[rbp], xmm0	#	exp_reverse = 1.0 - локальная переменная на стеке (-32[rbp])
	#	C: double exp_reverse_member = 1;
	movsd	xmm0, QWORD PTR .LC10[rip]
	movsd	QWORD PTR -24[rbp], xmm0	#	exp_reverse_member = 1.0 - локальная переменная на стеке (-24[rbp])
	
	#	C:  unsigned int step = 0;
	mov	DWORD PTR -52[rbp], 0			#	step = 0 - локальный счетчик на стеке (-52[rbp])
	#	C: double prev_result = 0;
	pxor	xmm0, xmm0
	movsd	QWORD PTR -16[rbp], xmm0	#	prev_result = 0.0 = xmm0 - локальная переменная на стеке (-16[rbp])
	#	C: double cur_result = 0;
	pxor	xmm0, xmm0
	movsd	QWORD PTR -8[rbp], xmm0		#	cur_result = 0.0 = xmm0 - локальная переменная на стеке (-8[rbp])
	jmp	.L15							#	goto условие цикла while

.L20:									#	тело цикла while
	#	C: ++step;
	add	DWORD PTR -52[rbp], 1			#	step += 1 (-52[rbp])


	#	C: exp_member *= x / step; - вычисляем след. член степенного ряда
	mov	eax, DWORD PTR -52[rbp]	
	test	rax, rax					#	test step, step
	js	.L16							#	if (signed flag = 1 (step < 0)) {goto .L16} 
	cvtsi2sd	xmm0, rax				#	xmm0 = double (step)
	jmp	.L17
.L16:
	mov	rdx, rax
	shr	rdx								#	rdx = step // 2
	and	eax, 1							#	eax = step % 2
	or	rdx, rax						#	rdx = step // 2 | step % 2 
	cvtsi2sd	xmm0, rdx				
	addsd	xmm0, xmm0					#	xmm0 = 2 * xmm0 = step - ((step % 4 - 2) % 2)

.L17:
	movsd	xmm1, QWORD PTR -72[rbp]	#	xmm1 = x (-72[rbp])
	divsd	xmm1, xmm0					
	movapd	xmm0, xmm1					#	xmm0 = xmm1 = x / step
	movsd	xmm1, QWORD PTR -40[rbp]	#	xmm1 = exp_member
	mulsd	xmm0, xmm1					#	xmm0 = exp_member * x / step
	movsd	QWORD PTR -40[rbp], xmm0	#	exp_member = exp_member * x / step (-40[rbp])


	#	C:	exp_reverse_member *= (-x) / step; - вычисляем след. член степенного ряда
	movsd	xmm0, QWORD PTR -72[rbp]	#	xmm0 = x (-72[rbp])
	movq	xmm1, QWORD PTR .LC11[rip]	#	xmm1 = 0x10000000...00 - побитовая маска для выделения знака
	xorpd	xmm1, xmm0					#	xmm1 = xmm0 xor xmm1 = -x
	mov	eax, DWORD PTR -52[rbp]			#	eax = step (-52[rbp])
	test	rax, rax
	js	.L18							#	if (signed flag = 1 (step < 0)) {goto .L18} 
	cvtsi2sd	xmm0, rax				#	xmm0 = double (step)
	jmp	.L19
.L18:
	mov	rdx, rax
	shr	rdx								#	rdx = step // 2
	and	eax, 1							#	eax = step % 2
	or	rdx, rax						#	rdx = step // 2 | step % 2
	cvtsi2sd	xmm0, rdx				
	addsd	xmm0, xmm0					#	xmm0 = 2 * xmm0 = step - ((step % 4 - 2) % 2)
.L19:
	divsd	xmm1, xmm0					
	movapd	xmm0, xmm1					#	xmm0 = -x / step
	movsd	xmm1, QWORD PTR -24[rbp]	#	xmm1 = exp_reverse_member
	mulsd	xmm0, xmm1					#	xmm0 = exp_reverse_member * (-x) / step
	movsd	QWORD PTR -24[rbp], xmm0	#	exp_reverse_member =  exp_reverse_member * (-x) / step (-24[rbp])


	#	C:	exp += exp_member; - обновляем экспоненту
	movsd	xmm0, QWORD PTR -48[rbp]	#	xmm0 = exp (-48[rbp])
	addsd	xmm0, QWORD PTR -40[rbp]	#	xmm0 += exp_member (-40[rbp])
	movsd	QWORD PTR -48[rbp], xmm0	#	exp = exp + exp_member - сохраняется на стеке (-48[rbp])

	#	C: exp_reverse += exp_reverse_member; - обновляем экспоненту с (-x)
	movsd	xmm0, QWORD PTR -32[rbp]	#	xmm0 = exp_reverse (-32[rbp])
	addsd	xmm0, QWORD PTR -24[rbp]	#	xmm0 += exp_reverse_member (-24[rbp])
	movsd	QWORD PTR -32[rbp], xmm0	#	exp_reverse = exp_reverse + exp_reverse_member - сохраняется на стеке (-32[rbp])
	
	#	C:  prev_result = cur_result;
	movsd	xmm0, QWORD PTR -8[rbp]		#	xmm0 = cur_result (-8[rbp])
	movsd	QWORD PTR -16[rbp], xmm0	#	(-16[rbp]) prev_result = cur_result

	#	C: cur_result = (exp + exp_reverse) / (exp - exp_reverse);
	movsd	xmm0, QWORD PTR -48[rbp]	#	xmm0 = exp (-48[rbp])
	addsd	xmm0, QWORD PTR -32[rbp]	#	xmm0 = exp + exp_reverse (-32[rbp])
	movsd	xmm1, QWORD PTR -48[rbp]	#	xmm1 = exp
	subsd	xmm1, QWORD PTR -32[rbp]	#	xmm1 = exp - exp_reverse (-32[rbp])
	divsd	xmm0, xmm1					#	xmm0 = xmm0 / xmm1 = (exp + exp_reverse) / (exp - exp_reverse)
	movsd	QWORD PTR -8[rbp], xmm0		#	(-8[rbp]) cur_result = xmm0 = (exp + exp_reverse) / (exp - exp_reverse)

.L15:									#	условие цикла while
	#	C:  while (step < 2 || EPS <= fabs(cur_result - prev_result))
	#	step < 2
	cmp	DWORD PTR -52[rbp], 1			#	cmp step(-52[rbp]), 1
	jbe	.L20							#	if (step <= 1) then {goto .L20 - тело цикла}
	#	
	movsd	xmm0, QWORD PTR -8[rbp]		#	xmm0 = cur_result (-8[rbp])
	subsd	xmm0, QWORD PTR -16[rbp]	#	xmm0 = cur_result - prev_result
	movq	xmm1, QWORD PTR .LC12[rip]	#	xmm1 = 0x0111111....1 - побитовая маска для взятия абсолютного значения
	andpd	xmm0, xmm1					#	xmm0 &= xmm1 -> xmm0 = fabs(xmm0) (применили побитовую маску)
	movsd	xmm1, QWORD PTR EPS[rip]	#	xmm1 = EPS 
	comisd	xmm0, xmm1					# 	cmp |cur_result-prev_result|, EPS
	jnb	.L20							#	if (|cur_result-prev_result| >= EPS) then {goto .L20 - тело цикла}
	
	movsd	xmm0, QWORD PTR -8[rbp]		#	xmm0 = cur_result - возвращаемое значение
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
	sub	rsp, 96							#	rsp-=96 (размер фрейма 104 байт)

	mov	DWORD PTR -84[rbp], edi			#	первый аргумент argc сохраняется из edi на стек -84[rbp]
	mov	QWORD PTR -96[rbp], rsi			#	второй аргумент agv сохраняется из rdi На стек -96[rbp]

	#	C: if (argc < 3)
	cmp	DWORD PTR -84[rbp], 2			#	cmp argc, 2
	jg	.L24							#	if (argc > 2) {goto .L24}
	#	слишком мало аргументов - выводим ошибку и завершаем программу
	#	C: fprintf(stderr, "At least 2 argements excepted - input file and output file");
	mov	rax, QWORD PTR stderr[rip]
	mov	rcx, rax						#	rcx = stderr - четвертый аргумент (поток)
	mov	edx, 58							#	edx = 58 - кол-во символов - третий аргумент
	mov	esi, 1							#	esi = 1 - размер символов - второй аргумент
	lea	rdi, .LC13[rip]					#	rdi = "At least 2 argements excepted - input file and output file" - первый аргумент
	call	fwrite@PLT					#	fwrite(rdi, esi=1, edx=58, rcx=stderr)
	#	C: exit(-1)
	mov	edi, 1							
	call	exit@PLT					#	exit(edi=-1)

.L24:
	#	C:	char *input = argv[1];
	mov	rax, QWORD PTR -96[rbp]			#	rax = argv (-96[rbp])
	mov	rax, QWORD PTR 8[rax]			#	rax = argv[1] = *(argv + 8)
	mov	QWORD PTR -48[rbp], rax			#	input = argv[1] - лок. переменная сохраняется на стеке -48[rbp]

	#	C:	char *output = argv[2];
	mov	rax, QWORD PTR -96[rbp]			
	mov	rax, QWORD PTR 16[rax]			#	rax = argv[2] = *(argv + 16)
	mov	QWORD PTR -40[rbp], rax			#	output = argv[2] - лок переменная сохраняется на стеке -40[rbp]

	#	C:	char time_flag = 0;
	mov	BYTE PTR -70[rbp], 0			#	time_flag = 0 - флаг сохраняется на стеке (-70[rbp])
	#	C:	char random_flag = 0;
	mov	BYTE PTR -69[rbp], 0			#	random_flag = 0 - флаг сохраняется на стеке (-69[rbp])

	#	C: size_t i = 3 - начало цикла for
	mov	QWORD PTR -64[rbp], 3			#	i = 3 (-64[rbp]) - локальный счетчик на стеке
	jmp	.L25
.L28:
	#	C:	if (!strcmp(argv[i], "--rand"))
	mov	rax, QWORD PTR -64[rbp]			
	lea	rdx, 0[0+rax*8]					#	rdx = 8*rax = 8*i
	mov	rax, QWORD PTR -96[rbp]			#	rax = argv (-96[rbp])
	add	rax, rdx						#	rax = argv + 8*i = &(argv[i])
	mov	rax, QWORD PTR [rax]			#	rax = argv[i]
	lea	rsi, .LC14[rip]					#	rsi = "--rand" - второй аргумент
	mov	rdi, rax						#	rdi = argv[i] - первый аргумент
	call	strcmp@PLT					#	eax = srtcmp(rdi=argv[i], rsi="--rand") - вызов функции
	test	eax, eax					
	jne	.L26							#	if (argv[i] != "--rand") {goto .L26}

	#	C:	 random_flag = 1;
	mov	BYTE PTR -69[rbp], 1			#	random_flag = 1 (-69[rbp])
.L26:
	#	C:	if (!strcmp(argv[i], "--time"))
	mov	rax, QWORD PTR -64[rbp]			#	rax = i
	lea	rdx, 0[0+rax*8]
	mov	rax, QWORD PTR -96[rbp]			
	add	rax, rdx						#	rax = argv + 8*i = &(argv[i])
	mov	rax, QWORD PTR [rax]			
	lea	rsi, .LC15[rip]					#	rsi = "--time" - второй аргумент
	mov	rdi, rax						#	rdi = argv[i] - первый аргумент
	call	strcmp@PLT					#	eax = srtcmp(rdi=argv[i], rsi="--time") - вызов функции 
	test	eax, eax
	jne	.L27							#	if (argv[i] != "--time") {goto .L27}

	#	C:	time_flag = 1;
	mov	BYTE PTR -70[rbp], 1			#	time_flag = 1 (-70[rbp])
.L27:
	add	QWORD PTR -64[rbp], 1			#	C:	++i (-64[rbp])

.L25:
	#	C: i < argc - условие цикла for
	mov	eax, DWORD PTR -84[rbp]			#	eax = argc (-84[rbp])
	cdqe								#	eax -> rax - расширение
	cmp	QWORD PTR -64[rbp], rax			#	cmp i, argc
	jb	.L28							#	if (i < argc) {goto .L28 - тело цикла for}

	#	C:	double x = 0;
	pxor	xmm0, xmm0
	movsd	QWORD PTR -56[rbp], xmm0	#	-56[rbp] = x = 0.0 - сохраняем на стек локальную переменную

	#	C: if (random_flag)
	cmp	BYTE PTR -69[rbp], 0			#	cmp random_flag, 0
	je	.L29							#	if (random_flag == 0) {goto .L29} - ввод через файл

	#	random_flag = 1 - генерируем число случайно
	#	C:	x = generate_random();
	mov	eax, 0							#	0 аргументов через xmm
	call	generate_random				#	xmm0 = generate_random() - вызов функции
	movq	rax, xmm0					
	mov	QWORD PTR -56[rbp], rax			#	-56[rbp] = x = generate_random()
	#	C:	write_data(x, input);
	mov	rdx, QWORD PTR -48[rbp]			
	mov	rax, QWORD PTR -56[rbp]			
	mov	rdi, rdx						#	rdi = input (-48[rbp]) - второй аргумент (через общие регистры)
	movq	xmm0, rax					#	xmm0 = x - первый аргумент (через регистры xmm)
	call	write_data					#	write_data(xmm0 = x, rdi = input)
	jmp	.L30

.L29:
	#	random_flag = 0 - вводим из файла
	mov	rax, QWORD PTR -48[rbp]
	mov	rdi, rax						#	rdi = input (-48[rbp])
	call	read_data					#	xmm0 = read_data(rdi=input)
	movq	rax, xmm0
	mov	QWORD PTR -56[rbp], rax			#	-56[rbp] = x = read_data(input)

.L30:
	#	C: clock_t time_start = clock(); - начало замера
	call	clock@PLT					
	mov	QWORD PTR -32[rbp], rax			#	time_start = clock() - сохраняем на стек -32[rbp] переменную

	#	C: double cth = calculate(x); - главные вычисления
	mov	rax, QWORD PTR -56[rbp]			
	movq	xmm0, rax					#	xmm0 = x (-56[rbp])
	call	calculate					#	xmm0 = calculate(xmm0 = x)
	movq	rax, xmm0
	mov	QWORD PTR -24[rbp], rax			#	cth = calculate(x) = xmm0 (-24[rbp]) - результат сохранен на стеке

	#	C:	if (time_flag)
	cmp	BYTE PTR -70[rbp], 0			#	cmp time_flag, 0
	je	.L31							#	if (time_flag == 0) {goto .L31 - Замеры не нужны}

	#	time_flag = 1 - замеряем время зацикливанием
	#	инициализация цикла for int i = 0;
	mov	DWORD PTR -68[rbp], 0			#	i = 0 - счетчик сохранен на стек (-68[rbp])
	jmp	.L32
.L33:
	mov	rax, QWORD PTR -56[rbp]			
	movq	xmm0, rax					#	xmm0 = x (-56[rbp]) - первый аргумент
	call	calculate					#	calculate(xmm0 = x)

	add	DWORD PTR -68[rbp], 1			#	i += 1 - инкремент цикла for
.L32:									#	условие цикла for i < 1000000;
	cmp	DWORD PTR -68[rbp], 999999		#	cmp i (-68[rbp]), 999999
	jle	.L33							#	if (i <= 999999) {goto .L33 - тело цикла for}

.L31:
	#	C:	 clock_t time_end = clock();
	call	clock@PLT	
	mov	QWORD PTR -16[rbp], rax			#	time_end = clock() - сохраняется на стеке -16[rbp]

	#	C: write_data(cth, output);
	mov	rdx, QWORD PTR -40[rbp]			#	rdx = output (-40[rbp])	
	mov	rax, QWORD PTR -24[rbp]			#	rax = cth (-24[rbp])
	mov	rdi, rdx						#	rdi = output - второй аргумент (через общие регистры)
	movq	xmm0, rax					#	xmm0 = cth - первый аргумент (через регистры xmm)
	call	write_data					#	write_data(xmm0 = cth, rdi = output)


	cmp	BYTE PTR -70[rbp], 0			#	cmp time_flag, 0
	je	.L34							#	if (time_flag == 0) {goto .L34 - не нужно выводить замеры времени}

	#	time_flag = 1 -> выводим замеры времени
	#	C: double cpu_time_used = ((double)(time_end - time_start)) / CLOCKS_PER_SEC;
	mov	rax, QWORD PTR -16[rbp]			
	sub	rax, QWORD PTR -32[rbp]			#	rax = time_end - time_start
	cvtsi2sd	xmm0, rax				#	xmm0 = double (time_end - time_start)
	movsd	xmm1, QWORD PTR .LC16[rip]	#	xmm1 = (double) CLOCKS_PER_SEC
	divsd	xmm0, xmm1					#	xmm0 = (time_end - time_start) / CLOCKS_PER_SEC
	movsd	QWORD PTR -8[rbp], xmm0		#	cpu_time_used = xmm0 = (time_end - time_start) / CLOCKS_PER_SEC - сохранили на стеке -8[rbp]
	
	#	C:	printf("Process time:%f seconds\n", cpu_time_used);
	mov	rax, QWORD PTR -8[rbp]				
	movq	xmm0, rax					#	xmm0 = cpu_time_used (-8[rbp]) - второй аргумент
	lea	rdi, .LC17[rip]					#	rdi = "Process time:%f seconds\n" - первый аргумент
	mov	eax, 1							#	кол-во аргументов, передаваемых через xmm = 1
	call	printf@PLT					#	printf(rdi = "Process time:%f seconds\n", xmm0=cpu_time_used)

.L34:
	mov	eax, 0
	leave
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
