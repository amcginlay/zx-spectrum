                                ; compile with "pasmo --name shiver-pxl --tap shiver-pxl.asm shiver-pxl.tap"
                org  $FF58      ; address where you load the program (65368 as per machine-code-loader)

next_iter:
                ld   hl, 22527
                ld   c, 192
next_line_l:    ld   b, 32
                or   a
next_byte_l:    rl   (hl)
                dec  hl
                djnz next_byte_l
                dec  c
                jr   nz, next_line_l

                ld   hl, 16384
                ld   c, 192
next_line_r:    ld   b, 32
                or   h
next_byte_r:    rr   (hl)
                inc  hl
                djnz next_byte_r
                dec  c
                jr nz, next_line_r

                jp next_iter

                ret

;                end  $FF58
