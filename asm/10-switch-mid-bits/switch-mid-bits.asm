ENTRYPOINT      equ  $8000      ; 32768 - user memory starts here
                org  ENTRYPOINT 

; use "unused" register to pass arg to machine code
                ld    hl, ($5C80) ; http://www.users.globalnet.co.uk/~jg27paw4/yr03/yr03_97.htm
                
; take lowest three bits of high byte to form highest three bits of low byte, store in c
                ld   a, h
                rra             ; carry provides ninth bit so rotate 4 times
                rra
                rra
                rra
                and  %11100000
                ld   c, a

; take highest three bits of low byte to form lowest three bits of high byte, store in b
                ld   a, l
                rla
                rla
                rla
                rla             ; carry provides ninth bit so rotate 4 times
                and  %00000111
                ld   b, a

; patch in the original high bits of the high byte
                ld   a, h
                and  %11111000
                or   b
                ld   b, a

; patch in the original low bits of the low byte
                ld   a, l
                and  %00011111
                or   c
                ld   c, a

                ret

                end  ENTRYPOINT

// the BASIC statemnts to reproduce the above machine code routine are as follows
100 DIM EP=32768
101 POKE EP+0, 42
101 POKE EP+01, 128
101 POKE EP+02, 92
101 POKE EP+03, 124
101 POKE EP+04, 31
101 POKE EP+05, 31
101 POKE EP+06, 31
101 POKE EP+07, 31
101 POKE EP+08, 230
101 POKE EP+09, 224
101 POKE EP+10, 79
101 POKE EP+11, 125
101 POKE EP+12, 23
101 POKE EP+13, 23
101 POKE EP+14, 23
101 POKE EP+15, 23
101 POKE EP+16, 230
101 POKE EP+17, 7
101 POKE EP+18, 71
101 POKE EP+19, 124
101 POKE EP+20, 230
101 POKE EP+21, 248
101 POKE EP+22, 176
101 POKE EP+23, 71
101 POKE EP+24, 125
101 POKE EP+25, 230
101 POKE EP+26, 31
101 POKE EP+27, 177
101 POKE EP+28, 79
101 POKE EP+29, 201

