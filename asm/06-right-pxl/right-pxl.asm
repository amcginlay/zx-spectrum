                                ; compile with "pasmo --name right-pxl --tapbas right-pxl.asm right-pxl.tap"
                org  $FF58      ; address where you load the program (65368 as per machine-code-loader)

                                ; NOTES:
                                ; refer to and compare notes from left-pxl.asm - this time:
                                ; - instead of counting DOWN from 22527, we count UP from 16384
                                ; - instead of rotating the bits left (rl) we rotate the bits right (rr)
                                ; it is otherwise functionally equivalent



                ld   hl, 16384
                ld   c, 192
next_line:      ld   b, 32
                or   h

next_byte:      rr   (hl)
                inc  hl
                djnz next_byte
                dec  c
                jr   nz, next_line
                ret
                
                ;end  $FF58      ; determines if RAND USR added to BASIC stub
