                                ; compile with "pasmo --name list-vars --tapbas list-vars.asm list-vars.tap"
                org  $FF58      ; address where you load the program (65368 as per machine-code-loader)

                res  0, (iy + 2)
                ld   hl, (23627)
next_variable:  ld   a, 13
                rst  16
                ld   a, 32
                rst  16
                ld   a, (hl)
                cp   128
                ret  z
                bit  7, a
                jr   z, bit_5
                bit  6, a
                jr   z, next_bit
                bit  5, a
                jr   z, string_array
                sub  128
                ld   de, 19
print:          rst  16
                add  hl, de
                jr   next_variable
string_array:   sub  96
                rst  16
                ld   a, 36
brackets:       rst  16
                ld   a, 40
                rst  16
                ld   a, 41
pointers:       inc  hl
                ld   e, (hl)
                inc  hl
                ld   d, (hl)
                inc  hl
                jr   print
next_bit:       bit  5, a
                jr   z, array
                sub  64
                rst  16
next_character: inc  hl
                ld   a, (hl)
                bit  7, a
                jr   nz, last_character
                rst  16
                jr   next_character
last_character: sub  128
jump:           ld   de, 6
                jr   print
array:          sub  32
                jr   brackets
bit_5:          bit  5, a
                jr   nz, jump
                add  a, 32
                rst  16
                ld   a, 36
                jr   pointers

                ;end  $FF58      ; determines if RAND USR added to BASIC stub