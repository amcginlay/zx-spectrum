                                ; compile with "pasmo --name prog-len --tap prog-len.asm prog-len.tap"
                org  $FF58      ; address where you load the program (65368 as per machine-code-loader)

                ld   hl, (23627)
                ld   de, (23635)
                and  a
                sbc  hl, de
                ld   b, h
                ld   c, l

                ret

                end  $FF58