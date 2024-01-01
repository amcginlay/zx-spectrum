                                ; compile with "pasmo --name shiver-pxl --tapbas shiver-pxl.asm shiver-pxl.tap"
                org  $FF58      ; address where you load the program (65368 as per machine-code-loader)

zero_out_lastk: ld   hl, 23560  ; lastk                                        
                ld   a, 255                                           
                ld   (hl), a          

start:
left:           ld   hl, 22527
                ld   c, 192
next_line_l:    ld   b, 32
                or   a
next_byte_l:    rl   (hl)
                dec  hl
                djnz next_byte_l
                dec  c
                jr   nz, next_line_l

right:          ld   hl, 16384
                ld   c, 192
next_line_r:    ld   b, 32
                or   h
next_byte_r:    rr   (hl)
                inc  hl
                djnz next_byte_r
                dec  c
                jr   nz, next_line_r      
                                
check_key:      ld   hl, 23560 ; lastk
                cp   (hl)                                            
                jr   z, start  ; 255 means no key pressed -> continue                                   

                ret

                ;end  $FF58      ; determines if RAND USR added to BASIC stubs
