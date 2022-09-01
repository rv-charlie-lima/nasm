section .data
array_size dd 10
array dd 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

error_message db "Incorrect data has passed", 0xA
error_message_len equ $ - error_message

space db ' '
minus db '-'

endl db 0xA

section .bss
buffer resb 16

section .text

get_int:
    ;пролог
    push ebp
    mov ebp, esp

        xor ecx, ecx
    .get_digit:
        ;пока не достигли конца буффера, считываем новый символ
        cmp ecx, BYTE 16
        jge .process
        push ecx

        ;читаем очередной символ
        mov eax, 3
        xor ebx, ebx 
        lea ecx, [buffer + ecx]
        mov edx, 1
        int 0x80
        
        pop ecx
        ;читаем пока не пробел или Enter
        cmp [buffer + ecx], BYTE ' '
        je .process
        cmp [buffer + ecx], BYTE 0xA
        je .process
        inc ecx
        jmp .get_digit

    .process:

    xor eax, eax            ;в процессе будем аккумулировать число в eax
    mov ebx, 10             ;множитель
    xor ecx, ecx            ;ecx - индекс по строке buffer
    
    xor edi, edi
    cmp [buffer + ecx], BYTE '-'
    jne .num_building       ;если число неотрицательное, то сразу переходим на num_building
    inc edi                 ;в конце, если esi=1, сделаем число отрицательным
    inc ecx                 ;адрес след. символа (первой цифры после минуса)

    .num_building:
        ;если число закончилось; попали на пробел/новую строку,
        ;осталось установить знак числа
        cmp [buffer + ecx], BYTE " "
        je .sign_setting
        cmp [buffer + ecx], BYTE 0xA
        je .sign_setting        
        
        ;если очередной символ не цифра, то данные некорректны
        cmp [buffer + ecx], BYTE "0"
        jb .incorrect_data_quit
        cmp [buffer + ecx], BYTE "9"
        ja .incorrect_data_quit

        movzx esi, BYTE[buffer + ecx]   ;кладем в отдельный регистр, чтобы сделать add "dword", "byte"
        sub esi, '0'
        mul ebx
        add eax, esi
        inc ecx
        jmp .num_building

    .sign_setting:
        cmp edi, 1      ;если до этого определили знак числа как минус
        jne .quit       
        neg eax         ;то меняем число в eax на отрицательное

    .quit:
        mov esi, [ebp + 8]   ;кладем в esi переданный адрес переменной
        mov [esi], eax       ;чтобы положить в нее результат
        mov eax, 1           ;возвращаем в eax 1, если всё прошло хорошо
        
        ;эпилог
        mov esp, ebp
        pop ebp
        ret

    .incorrect_data_quit:
        xor eax, eax        ;если считано нечисло, то возвращем по завершении 0
        mov esp, ebp
        pop ebp
        ret


print_int:
    ;пролог
    push ebp
    mov ebp, esp    
    mov ebx, DWORD 10   ;делитель
    xor esi, esi        ;счетчик цифр
    xor edi, edi        ;индекс по buffer


    cmp [ebp + 8], DWORD 0  ;если переданное число меньше нуля, то выводим минус
    jge .push_digits

    mov eax, DWORD [ebp + 8]
    neg eax                 ;меняем знак на "+", чтобы получать нужные цифры числа
    mov [buffer], BYTE '-'
    inc edi

        .push_digits:
            xor edx, edx
            div ebx

            push edx
            inc esi

            test eax, eax   ;пока не закончились цифры в числе
            jnz .push_digits

        .print:
            pop eax                 ;достаем цифру
            add eax, '0'            ;превращем ее в символ
            mov [buffer + edi], al  ;кладем в buffer

            inc edi                 
            dec esi                 
            test esi, esi           ;пока счетчик цифр не обнулился
            jnz .print

            ;выводим итоговое число
            mov eax, 4
            mov ebx, 1
            mov ecx, buffer
            mov edx, edi
            int 0x80

    .quit:
        ;эпилог
        mov esp, ebp
        pop ebp
        ret

global _start
_start:

;eax = x
;ebx = j
;ecx = i
;edx - промежуточная ячейка, для смещения элементов

    mov ecx, 1
get_int_loop:
    cmp ecx, DWORD [array_size]
    jge .quit
    
    lea eax, [array + ecx*4]      ;вычисляем адрес ячейки на запись числа
    push ecx                      ;сохраняем счетчик цикла
    push eax                      ;передаем адрес ячейки
    call get_int                  ;читаем число с консоли
    add esp, 4                    ;очищаем стек
    pop ecx                       ;возвращаем значение счетчика

    test eax, eax                 ;если считали не число
    jz error                      

    inc ecx                       ;+1 счетчик
    jmp get_int_loop

    .quit:

    mov ecx, 2                     ;ecx = i
insert_sort:
    cmp ecx, DWORD [array_size]          ;пока i < array_size
    ja .quit

    mov eax, [array + ecx*4]       ;eax = x = a[i]
    mov [array], eax               ;a[-1] = x
    mov ebx, ecx                   ;ebx = i
    dec DWORD ebx                  ;ebx = i-1

    .shift_loop:
        cmp [array + ebx*4], eax   ;пока a[j] > x
        jng .insert                

        mov edx, [array + ebx*4]       ;edx = a[j]
        mov [array + ebx*4 + 4], edx   ;a[j+1] = a[j]
        dec DWORD ebx                  ;j = j-1
        jmp .shift_loop

    .insert:
        mov [array + ebx*4 + 4], eax   ;a[j+1] = x
        inc DWORD ecx                  ;i = i+1
        jmp insert_sort

    .quit:


    mov ecx, 1
print_array:
    cmp ecx, [array_size]
    jge exit

    mov eax, DWORD [array + 4*ecx]    ;кладем в eax очередное число-агрумент для print_int
    push ecx                          ;сохраняем счетчик
    push eax                          ;передаем аргумент (по значению)
    call print_int  
    add esp, 4                  
    
    ;выводим пробел, чтобы отделить числа
    mov eax, 4
    mov ebx, 1
    mov ecx, space
    mov edx, 1
    int 0x80

    pop ecx          ;вовзвращаем значение счетчика цикла
    inc ecx          

    jmp print_array



exit:

    mov eax, 4
    mov ebx, 1
    mov ecx, endl
    mov edx, 1
    int 0x80


    mov eax, 1
    xor ebx, ebx
    int 0x80


error:
    mov eax, 4
    mov ebx, 1
    mov ecx, error_message
    mov edx, error_message_len
    int 0x80
    jmp exit