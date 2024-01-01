                                ; compile with "pasmo --name right-pxl --tapbas right-pxl.asm right-pxl.tap"
                org  $FF58      ; address where you load the program (65368 as per machine-code-loader)

                ld   hl, 16384
                ld   c, 192
next_line:      ld   b, 32
                or   h
next_byte:      rr   (hl)
                inc  hl
                djnz next_byte
                dec  c
                jr nz, next_line
                ret
                
                ;end  $FF58      ; determines if RAND USR added to BASIC stub
