##  Копырина Полина Ивановна, группа БПИ213   
##  Контакты для коммуникации: @apollo_k в Телеграме
#   Индивидуальное домашнее задание №3. Вариант 14.

## Задание:
###    Разработать программу, вычисляющую с помощью степенного ряда с точностью не хуже 0,1% значение функции гиперболического котангенса cth (x) = (e^x+e^(−x))/(e^x−e^(−x)) для заданного параметра x.

##  4 балла

### **Программа на языке Си**

**Файл code.c содержит решение задачи на языке Си на 8 баллов.**

В программе реализованы:
1. Функция для ввода числа с плавающей точкой из файла
> double read_data(char *file_name);
2. Функция для вывода числа с плавающей точкой в файл
>  void write_data(double x, char *file_name);
3. Функция для генерации числа типа double в интервале [-10; 10], не равное нулю
>  double generate_random();
4. Функция для вычисления cth(x) с помощью степенных рядов
>  double calculate(double x);
5. Функция main
>  int main(int argc, char **argv)

**Функция calculate**

Есть глобальная переменная EPS типа _double_, задающая точность вычислений (она равна 0.001, т.к Александр Иванович писал в беседе, что можно сравнивать по абсолютному значению, поделив проценты на 100).
> double EPS = 0.001;

В самой функции **calculate** мы должны сделать хотя бы две итерации (что-бы у нас было два приблизительных результата для сравнения). На каждой итерации мы вычисляем новые приближенные значения _e^(x)_ и _e^(-x)_, а по ним по формуле уже считаем новое значение _cth(x)_.

Из математики: 
>   _e^x = 1 + x + x^2/2! + x^3/3! + ... x^n/n!, n->inf_

Поэтому на каждой итерации мы считаем новый член степенных рядов (отдельно храним сумму и последний член степенного ряда, для получения нового члена просто умножаем на x/step, где step - номер итерации).

Стоит упомянуть, что _cth(x)_ не определена при _x = 0_ (действительно, можно посчитать по формуле). В функции _calculate_ это условие проверяется.

При _x->0 cth(x)_ может принимать довольно большие абсолютные значения, которые могут не помещаться в тип double (но при локальном тестировании таких проблем не было обнаружено, программа давала разумные ответы на _x ~ 10^(-7)_, так что входные данные должны быть ну ооочень маленьким числом).

Было замечено, что чем входные данные дальше от 0, тем дольше времени уходит на выполнение вычислений. В связи с этим были поставлены ограничения на генератор данных - генерируемое число может быть в пределах интервала _[-10; 10]_. Но на входные данные таких ограничений, конечно, нет (просто будьте морально готовы, что программа может работать долго).


***

### **Запуск исполняемого файла** 

Для получения исполняемого файла в терминале выполняем команду:
> gcc code.c -o code

Передача аргументов в программу осуществляется через командную строку.
Для корректной работы программы необходимо передать имя файла с входными данными в качестве **первого** аргумента, а также
имя файла для вывода данных в качестве **второго** аргумента.

Пример запуска исполняемого файла:
> ./code input.txt output.txt

В программе предоставлена опция сгенерировать входное число с помощью рандома, не считывая его из входного файла. Сгенерированное число будет принадлежать интервалу _[-10, 10]_, исключая число 0 (т.к оно вне области определения _cth(x)_).
Для этого надо прописать опцию **_--rand_**.

Сгенерированное число выводится в файл, указанный в качестве файла с входными данными, то есть указанный в качестве первого аргумента при запуске программы (для того, чтобы у пользователя был доступ к сгенерированной строке и для генерации рандомных тестов, что расширяет возможности тестирования).

Пример запуска программы с генерацией рандомной строки:
> ./code input.txt output.txt --rand

В данном случае программа сгенерирует число типа double от -10 до 10 и выведет его в _input.txt_. В файл _output.txt_ будет выведен гиперболический котангенс от этого числа.

Также предусмотрена возможность замера времени исполнения той части программы, которая выполняет вычисления
(имеется в виду выполнение функции _calculate_). При замере времени этот блок зацикливается 1000000 раз, чтобы сделать разницу во времени нагляднее.

Для замера времени нужно при запуске программы добавить опцию **_--time_**. Результат замера времени будет выведен в консоль.

Пример запуска программы с замером времени:
> ./code input.txt output.txt --time

Рандомную генерацию входных данных и замеры времени можно совмещать:
> ./code input.txt output.txt --rand --time

***

### **Компиляция в ассемблер**

С помощью gcc получим программу на языке ассемблера из нашего решения на языке Си.
Для этого введем в терминал следующую команду:
  
  > **gcc -O0 -Wall -masm=intel -S -fno-asynchronous-unwind-tables -fcf-protection=none code.c -o code.s**
  
За счет использования вышеперечисленных аргументов командной строки наша программа станет более компактной,
так как будут убраны лишние макросы.

**В файле _code.s_ содержится программа на языке ассемблера, полученная с помощью команды, приведенной выше, с комментариями, поясняющими эквивалентное представление кода в программе на языке Си (code.c), а также передачу фактических параметров и перенос возвращаемого результата при вызове функций.**

Для получения исполняемого файла из ассемблерной программы необходимо выполнить в терминале команду.
> gcc code.s -o asm_code

Исполняемый файл из ассемблерной программы запускается точно так же, как и исполняемый файл, полученный из программы на Си. Более подробная инфорация о формате команды для запуска программы содержится в разделе "Запуск исполняемого файла".

***
### **Тестирование**

Все тесты лежат в папке **testing/tests**. Часть тестов была создана вручную, часть была создана с помощью возможности генерации рандомной строки в написанной программе.
Так же был создан скрипт на Python **createTests.py**, который автоматизирует создание нескольких тестов (нужно указать, сколько тестов уже создано и сколько тестов нужно создать)

Результаты тестирования программы на Си (code.c) лежат в папке **testing/results/c**

Результаты тестирования программы на ассемблере, полученной компилятором(code.s) лежат в папке **testing/results/asm**

Результаты тестирования оптимизированной программы на ассемблере(/optimized) лежат в папке **testing/results/optimized**

Также был создан скрипт на Python **runTests.py**, который прогоняет все тесты из папки testing/tests на всех трех вариантах программ.

Для проверки того, что результаты всех тестов совпадают и программы работают одинаково можно использовать скрипт **checkTests.py** - при запуске он выводит вердикт для каждого теста (скрипт проверяет, что результаты отличаются не более чем на 0.001 - из-за работы с числами с плавающей точкой возможна погрешность).

***


##  5 баллов
Программа на ассемблере подробно прокомментирована, поясняется почти каждая операция. В программе используются локальные переменные (на ассемблере они хранятся либо на стеке, либо в регистрах). Данные в функции передаются через параметры.

***
## 6 баллов
### **Рефакторинг ассемблерной программы**
  
В папке **refactored** содержатся ассемблерные файлы, полученные после рефакторинга ассемблерной программы за счет максимального использования регистров процессора.

При рефакторинге программа была разбита на две единицы компиляции: 
1. iostreams.s - тут находятся функции, связанные с вводом/выводом в файлы:
    - read_data
    - write_data
3.  main.s - основная работа с числами с плавающей точкой (cpu bound), тут находятся функции: 
    - generate_random
    - calculate
    - main

Описание функций можно посмотреть в разделе "Программа на языке Си".
Все ассемблерные файлы содержат комментарии, поясняющие связь между ассемблерной программой и программой на языке си (а так же сам ход ассемблерной программы).

Запустив скрипт **checkTests.py** в папке testing можно убедиться, что оптимизированная программа работает корректно и результаты тестов совпадают.

Давайте сравним размеры исполняемых файлов двух ассемблерных программ:
- Программа до рефакторинга (созданная компилятором) весит 16.8KB, точнее - 17,216 байт
- Программа после рефакторинга (где по максимуму используются регистры) весит 16.8KB, точнее - 17,248 байт.

Как видно, размеры почти не отличаются (у отрефакторенной программы размер даже чуть-чуть больше).

Для получения исполняемого файла необходимо запустить команду
> **gcc fileStreams.s countLetters.s main.s -o refactored**

## 7 баллов
Оптимизированная программа разделена на несколько единиц компиляции.

### Работа с файлами
В программе используются файлы для ввода/вывода данных. Информация о том, как работать с ними, содержится в разделе "Запуск исполняемого файла", но напишем об этом и здесь.

При запуске исполняемого файла необходимо передать как минимум 2 аргумента в командной строке:
1. Первый аргумент обязательно должен быть именем файла, в котором содержатся входные данные. При рандомной генерации данных сгенерированное число как раз будет выведено в этот файл.
2. Второй по порядку аргумент обязательно должен быть именем файла, в который будет выведен результат работы программы.
Имена файлов должны быть заданы с учетом "вашего положения" в директории, откуда вы запускаете исполняемый файл.

Примеры см. в разделе "Запуск исполняемого файла".
Примеры входных/выходных файлов можно посмотреть в папке testing (там хранятся все тесты).

## 8 баллов

### Генератор случайных вхожных данных
Есть возможность случайно сгенерировать рандомные входные данные, добавив опцию "--rand" при запуске исполняемого файла.
Будет сгенерировано число типа double в диапазоне от _-10_ до _10_ (причина этого - чем дальше число от 0, тем дольше работает программа)
Примеры запуска см. в разделе "Запуск исполняемого файла".


### Замеры времени
Есть возможность измерить время работы программы. Для этого нужно указать опцию "--time" в командной строке (без дополнительных аргументов).
Тогда выполнение функции calculate зациклится 1000000 раз (для более наглядного результата).
Затраченное время будет выведено в консоли.

### Сравнение производительности

Сравним время работы оптимизированной программы и созданной компилятором.
Для этого запустим обе программы на трех тестах c данными входными данными: 
1. > 296.0342

2. > 405.0302

3. > 337.3062

Для программы, созданной комплилятором
> ./asm_code input.txt output.txt --time

Результаты замеров:
1. Process time: 1.737379 seconds
2. Process time: 2.402079 seconds
3. Process time: 1.933740 seconds

В среднем работа на данных порядка 10^3 занимает около 2.0243993 секунд.

Для отрефакторенной программы
> ./refactored input.txt output.txt --time
1. Process time: 1.657338 seconds
2. Process time: 2.189144 seconds
3. Process time: 1.846150 seconds

Среднее время работы уже 1.897544.
Время работы улучшилось примерно на 7%, что, в целом, уже лучшке, чем ничего (учитывая время, которое было потрачено :")).

Спасибо за внимание!!