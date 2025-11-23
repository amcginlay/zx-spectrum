; -----------------------------------------------------------------------------
; move-pixel.asm — move a single screen pixel with O P Q A, SPACE exits
; -----------------------------------------------------------------------------
; Assemble with:
;   pasmo --name move-pixel --tapbas move-pixel.asm move-pixel.tap
; Control:
;   Spectrum cursor keys (numbers): 5 = left, 8 = right, 7 = up, 6 = down. SPACE exits.
; Implementation:
;   No ROM calls in the main loop. Keyboard read uses matrix ports directly.
;   Pixel writes use direct screen memory addressing; only the targeted byte
;   is touched for erase/draw.
; -----------------------------------------------------------------------------

ENTRYPOINT      equ     $8000
SCREEN_BASE     equ     $4000
ATTR_BASE       equ     $5800
SCREEN_BYTES    equ     6912
ATTR_BYTES      equ     768
LAST_K          equ     $5C08          ; ROM system variable "last key"

BG_ATTR         equ     %01000111      ; Paper black, bright white ink for visibility

INIT_X          equ     128            ; Starting pixel X (0-255)
INIT_Y          equ     96             ; Starting pixel Y (0-191)

                org     ENTRYPOINT

start:
                ei
                call    clear_screen
                call    clear_attrs

                ld      a,INIT_X
                ld      (pixel_x),a
                ld      a,INIT_Y
                ld      (pixel_y),a
                call    place_pixel

main_loop:
                halt                    ; 50 Hz pacing
                call    read_inputs     ; A = dir mask, bit7 = exit
                bit     7,a
                jr      nz,exit_game
                call    update_position ; Uses mask in A
                jr      main_loop

exit_game:
                ret

; -----------------------------------------------------------------------------
; update_position
; A = direction mask (bit0 left, bit1 right, bit2 up, bit3 down)
; Moves one pixel per frame; supports diagonal input.
; -----------------------------------------------------------------------------
update_position:
                ld      b,a

                ld      a,(pixel_x)
                ld      h,a             ; original X
                ld      c,a             ; working X
                ld      a,(pixel_y)
                ld      l,a             ; original Y
                ld      d,a             ; working Y

                ; Horizontal
                ld      e,0
                bit     1,b             ; right
                jr      z,no_right
                inc     e
no_right:
                bit     0,b             ; left
                jr      z,no_left
                dec     e
no_left:
                ld      a,e
                cp      1
                jr      nz,maybe_left_move
                ld      a,c
                cp      255
                jr      z,skip_h_move
                inc     c
                jr      h_move_done
maybe_left_move:
                cp      $FF             ; -1
                jr      nz,skip_h_move
                ld      a,c
                or      a
                jr      z,skip_h_move
                dec     c
h_move_done:
skip_h_move:

                ; Vertical
                ld      e,0
                bit     3,b             ; down
                jr      z,no_down
                inc     e
no_down:
                bit     2,b             ; up
                jr      z,no_up
                dec     e
no_up:
                ld      a,e
                cp      1
                jr      nz,maybe_up_move
                ld      a,d
                cp      191
                jr      z,skip_v_move
                inc     d
                jr      v_move_done
maybe_up_move:
                cp      $FF             ; -1
                jr      nz,skip_v_move
                ld      a,d
                or      a
                jr      z,skip_v_move
                dec     d
v_move_done:
skip_v_move:

                ; Any change?
                ld      a,c
                cp      h
                jr      nz,do_move
                ld      a,d
                cp      l
                ret     z               ; No move

do_move:
                ; Erase old pixel using original X/Y in H/L
                push    bc              ; preserve new X in C
                push    de              ; preserve new Y in D
                ld      b,h             ; B = old X
                ld      c,l             ; C = old Y
                call    erase_at_bc
                pop     de
                pop     bc

                ld      a,c
                ld      (pixel_x),a
                ld      a,d
                ld      (pixel_y),a
                call    place_pixel
                ret

; -----------------------------------------------------------------------------
; place_pixel: compute address/mask, store them, and set the pixel on.
; -----------------------------------------------------------------------------
place_pixel:
                call    calc_pixel_ptr  ; HL = addr, A = bit mask
                ld      c,a
                ld      a,(hl)
                or      c
                ld      (hl),a
                ret

; -----------------------------------------------------------------------------
; erase_at_bc: erase pixel at X in B, Y in C
; -----------------------------------------------------------------------------
erase_at_bc:
                push    bc              ; save caller BC
                call    calc_pixel_ptr_bc ; HL, A = mask for B,C
                ld      c,a
                cpl
                ld      b,a             ; B = inverted mask
                ld      a,(hl)
                and     b
                ld      (hl),a
                pop     bc
                ret

; -----------------------------------------------------------------------------
; calc_pixel_ptr
; Inputs: pixel_x, pixel_y
; Outputs: HL = address of byte containing pixel, A = bit mask for pixel.
; -----------------------------------------------------------------------------
calc_pixel_ptr:
                ld      a,(pixel_x)
                ld      b,a
                ld      a,(pixel_y)
                ld      c,a
                jr      calc_pixel_ptr_bc

; -----------------------------------------------------------------------------
; calc_pixel_ptr_bc
; Inputs: B = pixel X (0-255), C = pixel Y (0-191)
; Outputs: HL = address, A = bit mask for pixel.
; -----------------------------------------------------------------------------
calc_pixel_ptr_bc:
                ld      a,b              ; A = X
                and     7
                ld      e,a
                ld      d,0
                ld      hl,mask_table
                add     hl,de
                ld      a,(hl)           ; A = mask
                ld      (pixel_mask),a   ; stash mask safely

                ld      a,c              ; A = Y
                and     7
                ld      h,a
                ld      l,0              ; HL = (y&7)<<8

                ld      a,c
                and     $38
                add     a,a
                add     a,a              ; *4
                ld      d,0
                ld      e,a
                add     hl,de

                ld      a,c
                and     $C0              ; top two bits
                ld      d,0
                ld      e,a
                rl      e
                rl      d
                rl      e
                rl      d
                rl      e
                rl      d
                rl      e
                rl      d
                rl      e
                rl      d                ; <<5 -> *32
                add     hl,de

                ld      a,b
                srl     a
                srl     a
                srl     a                ; x >> 3
                ld      d,0
                ld      e,a
                add     hl,de

                ld      de,SCREEN_BASE
                add     hl,de

                ld      a,(pixel_mask)   ; restore mask to A
                ret

; -----------------------------------------------------------------------------
; read_inputs: returns mask in A
; bit0 left (5), bit1 right (8), bit2 up (7), bit3 down (6), bit7 exit (SPACE)
; -----------------------------------------------------------------------------
read_inputs:
                xor     a                ; mask result in A

                ; LEFT = '5' on row 1-5 (A12 low -> $F7FE), bit4 = 5
                ld      bc,$F7FE
                in      l,(c)
                bit     4,l
                jr      nz,skip_left
                set     0,a
skip_left:

                ; 6/7/8 on row 6-0 (A11 low -> $EFFE):
                ; bit4=6 (down), bit3=7 (up), bit2=8 (right)
                ld      bc,$EFFE
                in      l,(c)
                bit     3,l              ; 7 = up
                jr      nz,skip_up
                set     2,a
skip_up:
                bit     4,l              ; 6 = down
                jr      nz,skip_down
                set     3,a
skip_down:
                bit     2,l              ; 8 = right
                jr      nz,skip_right
                set     1,a
skip_right:

                ; SPACE to exit (row SPACE,SYM,M,N,B -> $7FFE, bit0 = SPACE)
                ld      bc,$7FFE
                in      l,(c)
                bit     0,l
                jr      nz,skip_space
                set     7,a
skip_space:

                ret

; -----------------------------------------------------------------------------
; clear_screen: zero pixel memory
; -----------------------------------------------------------------------------
clear_screen:
                ld      hl,SCREEN_BASE
                ld      de,SCREEN_BASE+1
                ld      bc,SCREEN_BYTES-1
                xor     a
                ld      (hl),a
                ldir
                ret

; -----------------------------------------------------------------------------
; clear_attrs: fill attribute area with background colour
; -----------------------------------------------------------------------------
clear_attrs:
                ld      hl,ATTR_BASE
                ld      de,ATTR_BASE+1
                ld      bc,ATTR_BYTES-1
                ld      a,BG_ATTR
                ld      (hl),a
                ldir
                ret

; -----------------------------------------------------------------------------
; Data
; -----------------------------------------------------------------------------

pixel_x:        defb    0
pixel_y:        defb    0
pixel_ptr:      defw    0
pixel_mask:     defb    0

mask_table:                             ; Bit masks for X mod 8
                defb    %10000000,%01000000,%00100000,%00010000
                defb    %00001000,%00000100,%00000010,%00000001

                end     ENTRYPOINT
