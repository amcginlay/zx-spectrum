                                ; compile with "pasmo --name left-pxl --tapbas left-pxl.asm left-pxl.tap"
                org  $FF58      ; address where you load the program (65368 as per machine-code-loader)

                                ; NOTES:
                                ; 0x4000 (16384) marks tha start of screen RAM, with one byte per location
                                ; the screen is made up from 32x24 characters, each of them one byte squares
                                ; **IF** there was a second screen it would start at exactly 16384+(32*24*8)=22528
                                ; this means the last byte of screen RAM is one before this number at 22527
                                ; despite screen layout being less than obvious, visiting every byte in the range 16384 to 22527 will cover all of screen RAM
                                ; https://www.overtakenbyevents.com/lets-talk-about-the-zx-specrum-screen-layout-part-two

                ld   hl, 22527  ; start at the last byte of screen RAM
                ld   c, 192     ; the screen is 8x24=192 pixels high
next_line:      ld   b, 32      ; the screen is 8x32=256 pixels wide, BUT each screen RAM localtion is 8 bits so 32 is the key number for width
                or   a          ; reset flags, this prevents interference from carry flag set by last byte of previous line
                                ; NOTE: use of "a" register here is circumstantial and not operationally important
next_byte:      rl   (hl)       ; rotate/shift the bits to the left - displaced high bits end up in carry flag
                dec  hl         ; move to the previous screen RAM location
                djnz next_byte  ; 'djnz' decrements the b register until one screen entire width of 32 characters has been back-traversed
                dec  c          ; the combination of 'dec c' and 'jr nz' performs the same logic as above, but on the c register
                jr   nz, next_line ;  32x192 is the number of operations required
                ret

                ;end  $FF58      ; determines if RAND USR added to BASIC stub
