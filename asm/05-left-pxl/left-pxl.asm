                                ; compile with "pasmo --name left-pxl --tapbas left-pxl.asm left-pxl.tap"
                org  $FF58      ; address where you load the program (65368 as per machine-code-loader)

                ld   hl, 22527
                ld   c, 192
next_line:      ld   b, 32
                or   a
next_byte:      rl   (hl)
                dec  hl
                djnz next_byte
                dec  c
                jr   nz, next_line
                ret

                ;end  $FF58      ; determines if RAND USR added to BASIC stub
