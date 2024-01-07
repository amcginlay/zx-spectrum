                                ; compile with "pasmo --name coords --tapbas coords.asm coords.tap"
                org  $FF58      ; address where you load the program (65368 as per machine-code-loader)

                                ; target the FIRST y-position in RAM bank 1-of-3 ($00,$00) - start of screen RAM
                ld   hl, $0000  ; clear out destination "address"
                ld   c, $00     ; put x-pos in c - left to right character in range 0-32 (lowest 5 bits are relevant)
                ld   b, $00     ; put y-pos in b - top to bottom pixel in range 0-191 (all bits are relevant)
                call coords
                ld   (hl), %10000000 ; write to screen RAM at the resolved location
                
                                ; target the NINTH y-position in RAM bank 1-of-3 ($00,$08)
                ld   hl, $0000
                ld   c, $00
                ld   b, $08     ; or %00001000
                call coords
                ld   (hl), %01000000

                                ; target the SECOND y-position in RAM bank 1-of-3 ($00,$01)
                ld   hl, $0000
                ld   c, $00
                ld   b, $01     ; or %00000001
                call coords
                ld   (hl), %00100000

                                ; target the LAST y-position position in RAM bank 1-of-3 ($00,$3F)
                ld   hl, $0000
                ld   c, $00
                ld   b, $3F     ; or %00111111 (63)
                call coords
                ld   (hl), %00010000

                                ; target the FIRST y-position position in RAM bank 2-of-3 ($00,$40)
                ld   hl, $0000
                ld   c, $00
                ld   b, $40     ; or %01000000 (64)
                call coords
                ld   (hl), %00001000

                                ; target the FIRST y-position position in RAM bank 3-of-3 ($00,$80)
                ld   hl, $0000
                ld   c, $00
                ld   b, $80
                call coords
                ld   (hl), %00000100

                ret
                
                                ; see https://www.overtakenbyevents.com/lets-talk-about-the-zx-specrum-screen-layout-part-three
coords:         ld   a,b        ; Work on the upper byte of the address
                and  %00000111  ; a = Y2 Y1 y0
                or   %01000000  ; first three bits are always 010
                ld   h,a        ; store in h
                ld   a,b        ; get bits Y7, Y6
                rra             ; move them into place
                rra
                rra
                and  %00011000   ; mask off
                or   h           ; a = 0 1 0 Y7 Y6 Y2 Y1 Y0
                ld   h,a         ; calculation of h is now complete
                ld   a,b ; get y
                rla
                rla
                and  %11100000   ; a = y5 y4 y3 0 0 0 0 0
                ld   l,a         ; store in l
                ld   a,c
                and  %00011111   ; a = X4 X3 X2 X1
                or   l           ; a = Y5 Y4 Y3 X4 X3 X2 X1
                ld   l,a         ; calculation of l is complete
                ret

                ;end  $FF58      ; determines if RAND USR added to BASIC stubs