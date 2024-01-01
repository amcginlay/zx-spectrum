org  $8000      ; address where you load the program
ld   hl, msg    ; HL = address of first character of messsage

Loop:
ld   a, (hl)    ; A = first character
or   a          ; sets zero flag if NULL character reached
jr   z, Exit
rst  $10        ; prints character
inc  hl         ; move to next character
jr   Loop

Exit:
ret
msg: defm 'Hello ZX Spectrum Assembly', $00 ; NULL terminated string
end  $8000