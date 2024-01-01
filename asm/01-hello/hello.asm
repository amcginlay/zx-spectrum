                                ; compile with "pasmo --name hello --tapbas hello.asm hello.tap"
                org  $FF58      ; address where you load the program (65368 as per machine-code-loader)

                ld   hl, msg    ; HL = address of first character of messsage
loop:           ld   a, (hl)    ; A = first character
                or   a          ; sets zero flag if NULL character reached
                jr   z, exit
                rst  $10        ; prints character
                inc  hl         ; move to next character
                jr   loop
exit:           ret

msg:            defm 'Hello ZX Spectrum Assembly', $00 ; NULL terminated string

                ;end  $FF58      ; determines if RAND USR added to BASIC stub