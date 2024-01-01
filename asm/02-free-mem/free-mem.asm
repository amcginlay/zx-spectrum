                                ; compile with "pasmo --name free-mem --tapbas free-mem.asm free-mem.tap"
                org  $FF58      ; address where you load the program (65368 as per machine-code-loader)

                ld   hl, 0
                add  hl, sp
                ld   de, (23653)
                and  a
                sbc  hl, de
                ld   b, h
                ld   c, l
                ret

                ;end  $FF58      ; determines if RAND USR added to BASIC stub