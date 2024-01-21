ENTRYPOINT      equ  $8000      ; 32768 - user memory starts here
                org  ENTRYPOINT 

                ld   hl, msg    ; HL = address of first character of messsage
loop:           ld   a, (hl)    ; A = first character
                or   a          ; sets zero flag if NULL character reached
                jr   z, exit
                rst  $10        ; prints character
                inc  hl         ; move to next character
                jr   loop
exit:           ret

msg:            defm 'Hello ZX Spectrum Assembly!!!!', $00 ; NULL terminated string

                end  ENTRYPOINT