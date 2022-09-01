section .data
    endl db 0xA
    one db '1'

    msgBase db "Base: "
    msgBaseLen equ ($-msgBase)
    msgDegree db "Degree: "
    msgDegreeLen equ ($-msgDegree)

    msgErr db "Invalid input", 0xA
    msgErrLen equ ($ - msgErr) 

    msgOverflow db "Too large number (overflow)", 0xA
    msgOverflowLen equ ($ - msgOverflow)

section .bss
    baseStr resb 8
    degreeStr resb 8
    base resd 1
    degree resd 1
    power resd 1 
    number resb 10      
    number_len resb 1
    counter resb 1

section .text

;проверяет, представляет ли строка число
;принимает адрес строки
isnumber:

    ;пролог
    push ebp
    mov ebp, esp

    mov esi, [ebp + 8]   ;в esi адрес строки
    mov eax, 1           ;возвращаем ответ в eax
    .isdigit:
        cmp byte [esi], 0xA   ;проверяем на конец строки
        je .quit
        cmp byte [esi], 48    ;если меньше '0'
        jb .not_a_number      ;то это не число
        cmp byte [esi], 57    ;если больше '9'
        ja .not_a_number      ;то это не число
        
        inc esi          ;следующий символ
        jmp .isdigit

    .not_a_number:
        xor eax, eax    ;если не число, возвращаем 0
    .quit:
        ;эпилог
        mov esp, ebp
        pop ebp
        ret             ;выход из подпрограммы


;преобразовывает строку в число
;принимает адрес строки и адрес числовой переменной
atoi:
    ;пролог
    push ebp
    mov ebp, esp    

    mov esi, [ebp + 12] ;кладем в esi адрес строки
    xor eax, eax        ;зануляем регистр, в котором будет результат
    mov ebx, 10         
    .digit:
        cmp byte [esi], 0xA   ;если конец строки
        je .quit              ;то выходим из цикла
        
        movzx ecx, byte [esi] ;кладем в ecx след. символ цифры
        sub ecx, 48           ;превращаем его в число
        mul ebx               ;умножаем предыдущее значение eax на 10 (сдвигаем справа налево)
        add eax, ecx          ;добавляем к eax новую цифру
        inc esi               ;подбираем адрес следующего символа
        jmp .digit


    .quit:
        mov esi, [ebp + 8] ;кладем в esi адрес числовой переменной
        mov [esi], eax     ;возвращаем результат в переменную

        ;эпилог
        mov esp, ebp
        pop ebp
        ret                ;выход из подпрограммы


global _start
_start:
    mov eax, 4              ;функция записи в поток sys_write()        
    mov ebx, 1              ;id потока вывода (в терминал/консоль)
    mov ecx, msgBase        ;адрес строки на вывод
    mov edx, msgBaseLen     ;адрес переменной, в которой длина строки
    int 0x80            

    mov eax, 3              ;функция чтения с потока sys_read()
    xor ebx, ebx            ;id потока ввода (с терминала/консоли)
    mov ecx, baseStr        ;адрес памяти на запись
    mov edx, 8              ;количество байт на запись 
    int 0x80

    mov eax, 4              ;функция записи в поток sys_write()
    mov ebx, 1              ;id потока вывода (в терминал/консоль)
    mov ecx, msgDegree      ;адрес строки на вывод
    mov edx, msgDegreeLen   ;адрес переменной, в которой длина строки
    int 0x80

    mov eax, 3              ;функция чтения с потока sys_read()
    xor ebx, ebx            ;id потока ввода (с терминала/консоли)
    mov ecx, degreeStr      ;адрес памяти на запись
    mov edx, 8              ;количество байт на запись 
    int 0x80

    push degreeStr          ;передача адреса переменной ч/з стек
    call isnumber           ;вызов подпрограммы
    add esp, 4              ;очищение стека от аргумента
    test eax, eax           ;проверка возвращаемого значения
    jz error                ;если ноль, то ошибка

    push degreeStr          ;передача адреса переменной ч/з стек
    push degree             ;передача адреса переменной ч/з стек
    call atoi               ;вызов подпрограммы
    add esp, 8              ;чистим стек от аргументов

    cmp dword [degree], 0   ;если возводим в нулевую степень
    je print_one            ;то выводим '1'

    push baseStr            ;передача адреса переменной ч/з стек
    call isnumber           ;вызов подпрограммы
    add esp, 4              ;очищение стека от аргумента
    test eax, eax           ;проверка возвращаемого значения
    jz error                ;если ноль, то ошибка


    push baseStr            ;передача адреса переменной ч/з стек
    push base               ;передача адреса переменной ч/з стек
    call atoi               ;вызов подпрограммы
    add esp, 8              ;чистим стек от аргументов


    mov ebx, [degree]       ;ebx-счётчик внешнего цикла
    mov eax, [base]         ;eax-собирает в себе результат
make_power:
    dec ebx                 ;вычитая 1, получаем количество умножений (счётчик внешнего цикла)
    cmp ebx, 0              ;пока ebx > 0
    jle .stop

    mov ecx, [base]         ;base определяет количество итераций внутреннего цикла
    mov edx, eax            ;помещаем в edx значение base
    .multiplication:
        dec ecx             ;декремент счётчика
        cmp ecx, 0          ;если счётчик меньше либо равен 0
        jle make_power      ;переходим на make_power
        add eax, edx        ;выполняем умножением сложением в цикле
        jc overflow         ;если произошло переполнение, то прыгаем на overflow
        jmp .multiplication ;повторяем умножение сложением

    .stop:
    mov [power], eax        ;сохраняем результат в переменную


    xor ecx, ecx            ;зануляем счётчик
    mov ebx, dword 10       ;делитель числа
num_to_str:    
    xor edx, edx            
    div ebx                 ;делим eax на 10
    
    push edx                ;кладем остаток на стек
    inc ecx                 ;увеличиваем счётчик цифр числа

    test eax, eax           ;пока eax!=0
    jnz num_to_str          ;повторяем деление

    xor ebx, ebx            ;индекс по массиву
    .build_digits_array:
        pop eax                     ;подбираем цифру со стека
        mov [number + ebx], al      ;кладем её в массив
        add byte [number + ebx], 48 ;делаем её символом
        inc ebx                     ;переход на след. ячейку массива
        cmp ebx, ecx                ;пока индекс не равен числу цифр
        jnz .build_digits_array     ;повторяем добавление цифр в строку

    mov [number_len], cl            ;запоминаем количество цифр в переменную

;вывод результата
print:
    mov eax, 4                               
    mov ebx, 1
    mov ecx, number
    mov edx, number_len
    int 0x80    

;переход на новую строку
print_endl:
    mov eax, 4
    mov ebx, 1
    mov ecx, endl
    mov edx, 1
    int 0x80

;завершение программы
exit:   
    mov eax, 1          ;системный вызов завершения процесса
    xor ebx, ebx        ;возвращаем 0 по завершении программы
    int 0x80 

;вывод '1' как результат
print_one:
    mov eax, 4
    mov ebx, 1
    mov ecx, one
    mov edx, 1
    int 0x80
    jmp print_endl

;вывод сообщения об ошибке
error: 
    mov eax, 4                
    mov ebx, 1
    mov ecx, msgErr
    mov edx, msgErrLen
    int 0x80
    jmp exit

;вывод сообщения о получении слишком большого числа
overflow:
    mov eax, 4
    mov ebx, 1
    mov ecx, msgOverflow
    mov edx, msgOverflowLen
    int 0x80
    jmp exit