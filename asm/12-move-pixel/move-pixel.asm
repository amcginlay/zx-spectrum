; -----------------------------------------------------------------------------
; move-pixel.asm — move a single screen pixel with O P Q A, SPACE exits
; -----------------------------------------------------------------------------
; Assemble with:
;   pasmo --name move-pixel --tapbas move-pixel.asm move-pixel.tap
; Control:
;   Controls: O = left, P = right, Q = up, A = down. Diagonals allowed. SPACE exits.
; Implementation:
;   No ROM calls in the main loop. Keyboard read uses matrix ports directly.
;   Pixel writes use direct screen memory addressing; only the targeted byte
;   is touched for erase/draw.
; -----------------------------------------------------------------------------

ENTRYPOINT      equ     $8000          ; Load address for the routine
SCREEN_BASE     equ     $4000          ; Start of bitmap memory
ATTR_BASE       equ     $5800          ; Start of attribute memory
SCREEN_BYTES    equ     6912           ; Size of bitmap area
ATTR_BYTES      equ     768            ; Size of attribute area
BG_ATTR         equ     %01000111      ; Paper black, bright white ink for visibility

INIT_X          equ     128            ; Starting pixel X (0-255)
INIT_Y          equ     96             ; Starting pixel Y (0-191)

                org     ENTRYPOINT      ; Set assembly origin

start:
                ei                      ; Enable interrupts for HALT timing
                call    clear_screen    ; Blank bitmap
                call    clear_attrs     ; Paint attributes to known colors

                ld      a,INIT_X        ; A = initial X
                ld      (pixel_x),a     ; Store current X
                ld      a,INIT_Y        ; A = initial Y
                ld      (pixel_y),a     ; Store current Y
                call    place_pixel     ; Draw initial pixel

main_loop:
                halt                    ; Wait one frame (50 Hz)
                call    read_inputs     ; Get direction mask in A
                bit     7,a             ; Test exit flag (SPACE)
                jr      nz,exit_game    ; Quit if set
                call    update_position ; Move/draw according to mask
                jr      main_loop       ; Loop forever

exit_game:
                ret                     ; Return to BASIC

; -----------------------------------------------------------------------------
; update_position
; A = direction mask (bit0 left, bit1 right, bit2 up, bit3 down)
; Moves one pixel per frame; supports diagonal input.
; -----------------------------------------------------------------------------
update_position:
                ld      b,a             ; Save direction mask in B

                ld      a,(pixel_x)     ; Fetch current X
                ld      h,a             ; H = old X (for erase)
                ld      c,a             ; C = new X working copy
                ld      a,(pixel_y)     ; Fetch current Y
                ld      l,a             ; L = old Y (for erase)
                ld      d,a             ; D = new Y working copy

                ; Horizontal delta accumulation
                ld      e,0             ; E = horizontal delta
                bit     1,b             ; Right pressed?
                jr      z,no_right      ; Skip if not
                inc     e               ; E = +1
no_right:
                bit     0,b             ; Left pressed?
                jr      z,no_left       ; Skip if not
                dec     e               ; E = -1 (or 0 if both pressed)
no_left:
                ld      a,e             ; A = horizontal delta
                cp      1               ; Is delta +1?
                jr      nz,maybe_left_move ; If not, maybe -1 or 0
                ld      a,c             ; A = current X
                cp      255             ; At right edge?
                jr      z,skip_h_move   ; If at edge, skip move
                inc     c               ; Otherwise X++
                jr      h_move_done
maybe_left_move:
                cp      $FF             ; Delta -1?
                jr      nz,skip_h_move  ; If 0, skip
                ld      a,c             ; A = current X
                or      a               ; At left edge?
                jr      z,skip_h_move   ; If at 0, skip
                dec     c               ; Otherwise X--
h_move_done:
skip_h_move:

                ; Vertical delta accumulation
                ld      e,0             ; E = vertical delta
                bit     3,b             ; Down pressed?
                jr      z,no_down       ; Skip if not
                inc     e               ; E = +1
no_down:
                bit     2,b             ; Up pressed?
                jr      z,no_up         ; Skip if not
                dec     e               ; E = -1 (or 0)
no_up:
                ld      a,e             ; A = vertical delta
                cp      1               ; Is delta +1?
                jr      nz,maybe_up_move ; If not, maybe -1 or 0
                ld      a,d             ; A = current Y
                cp      191             ; At bottom edge?
                jr      z,skip_v_move   ; Skip if at limit
                inc     d               ; Otherwise Y++
                jr      v_move_done
maybe_up_move:
                cp      $FF             ; Delta -1?
                jr      nz,skip_v_move  ; If 0, skip
                ld      a,d             ; A = current Y
                or      a               ; At top edge?
                jr      z,skip_v_move   ; Skip if at 0
                dec     d               ; Otherwise Y--
v_move_done:
skip_v_move:

                ; Any change from old H/L?
                ld      a,c             ; Compare new X to old X
                cp      h
                jr      nz,do_move      ; If different, move
                ld      a,d             ; Compare new Y to old Y
                cp      l
                ret     z               ; If both same, nothing to do

do_move:
                ; Erase old pixel using original X/Y in H/L
                push    bc              ; Preserve new X (C) and mask (B)
                push    de              ; Preserve new Y (D)
                ld      b,h             ; B = old X
                ld      c,l             ; C = old Y
                call    erase_at_bc     ; Clear old pixel
                pop     de              ; Restore new Y
                pop     bc              ; Restore new X/mask

                ld      a,c             ; A = new X
                ld      (pixel_x),a     ; Store new X
                ld      a,d             ; A = new Y
                ld      (pixel_y),a     ; Store new Y
                call    place_pixel     ; Draw at new coords
                ret                     ; Done for this frame

; -----------------------------------------------------------------------------
; place_pixel: compute address/mask, store them, and set the pixel on.
; -----------------------------------------------------------------------------
place_pixel:
                call    calc_pixel_ptr  ; HL = addr, A = bit mask for current X/Y
                ld      c,a             ; C = mask
                ld      a,(hl)          ; A = current byte
                or      c               ; Set the pixel bit
                ld      (hl),a          ; Store updated byte
                ret                     ; Return

; -----------------------------------------------------------------------------
; erase_at_bc: erase pixel at X in B, Y in C
; -----------------------------------------------------------------------------
erase_at_bc:
                push    bc              ; Save caller BC
                call    calc_pixel_ptr_bc ; HL, A = mask for B,C
                ld      c,a             ; C = mask
                cpl                     ; Invert mask bits
                ld      b,a             ; B = inverted mask
                ld      a,(hl)          ; Read current byte
                and     b               ; Clear the pixel bit
                ld      (hl),a          ; Store updated byte
                pop     bc              ; Restore caller BC
                ret                     ; Return

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
                and     7                ; A = X mod 8
                ld      e,a              ; E = index into mask table
                ld      d,0              ; D = 0 for 16-bit add
                ld      hl,mask_table    ; HL = table start
                add     hl,de            ; HL = table + (X mod 8)
                ld      a,(hl)           ; A = bit mask for this pixel within byte
                ld      (pixel_mask),a   ; stash mask safely

                ld      a,c              ; A = Y
                and     7                ; Low 3 bits: line within 8-row block
                ld      h,a              ; H = (y&7)
                ld      l,0              ; HL = (y&7)<<8 (row offset)

                ld      a,c              ; A = Y again
                and     $38              ; Middle 3 bits: character row within band
                add     a,a              ; *2
                add     a,a              ; *4
                ld      d,0
                ld      e,a              ; DE = (y&0x38)*4
                add     hl,de            ; Add to line offset

                ld      a,c              ; A = Y again
                and     $C0              ; Top 2 bits: band (0,64,128)
                ld      d,0
                ld      e,a              ; DE = band*64
                rl      e                ; shift left 5 times = *32
                rl      d
                rl      e
                rl      d
                rl      e
                rl      d
                rl      e
                rl      d
                rl      e
                rl      d
                add     hl,de            ; Add band offset

                ld      a,b              ; A = X again
                srl     a                ; X >> 1
                srl     a                ; X >> 2
                srl     a                ; X >> 3
                ld      d,0
                ld      e,a              ; DE = byte offset for columns
                add     hl,de            ; Add column offset

                ld      de,SCREEN_BASE   ; DE = bitmap base
                add     hl,de            ; HL = final pixel byte address

                ld      a,(pixel_mask)   ; Restore mask to A for caller
                ret                      ; Return with HL/A set

; -----------------------------------------------------------------------------
; read_inputs: returns mask in A
; bit0 left (O), bit1 right (P), bit2 up (Q), bit3 down (A), bit7 exit (SPACE)
; -----------------------------------------------------------------------------
read_inputs:
                xor     a                ; Clear mask result in A

                ; Row P,O,I,U,Y (A13 low -> $DFFE)
                ld      bc,$DFFE        ; Select keyboard row
                in      l,(c)           ; Read columns into L
                bit     1,l              ; O = left
                jr      nz,no_o
                set     0,a
no_o:
                bit     0,l              ; P = right
                jr      nz,no_p
                set     1,a
no_p:

                ; Row Q,W,E,R,T (A10 low -> $FBFE)
                ld      bc,$FBFE        ; Select row
                in      l,(c)           ; Read columns
                bit     0,l              ; Q = up
                jr      nz,no_q
                set     2,a
no_q:

                ; Row A,S,D,F,G (A9 low -> $FDFE)
                ld      bc,$FDFE        ; Select row
                in      l,(c)           ; Read columns
                bit     0,l              ; A = down
                jr      nz,no_a
                set     3,a
no_a:

                ; Row SPACE,SYM,M,N,B (A15 low -> $7FFE)
                ld      bc,$7FFE        ; Select row
                in      l,(c)           ; Read columns
                bit     0,l              ; SPACE to exit
                jr      nz,no_space
                set     7,a
no_space:

                ret

; -----------------------------------------------------------------------------
; clear_screen: zero pixel memory
; -----------------------------------------------------------------------------
clear_screen:
                ld      hl,SCREEN_BASE  ; HL = start of screen
                ld      de,SCREEN_BASE+1 ; DE = HL+1 for LDIR
                ld      bc,SCREEN_BYTES-1 ; BC = byte count for LDIR
                xor     a               ; A = 0
                ld      (hl),a          ; Zero first byte
                ldir                    ; Fill the rest with zero
                ret                     ; Return

; -----------------------------------------------------------------------------
; clear_attrs: fill attribute area with background colour
; -----------------------------------------------------------------------------
clear_attrs:
                ld      hl,ATTR_BASE    ; HL = start of attributes
                ld      de,ATTR_BASE+1  ; DE = HL+1 for LDIR
                ld      bc,ATTR_BYTES-1 ; BC = byte count
                ld      a,BG_ATTR       ; A = default attribute
                ld      (hl),a          ; Write first attribute
                ldir                    ; Fill remaining attributes
                ret                     ; Return

; -----------------------------------------------------------------------------
; Data
; -----------------------------------------------------------------------------

pixel_x:        defb    0               ; Current X position
pixel_y:        defb    0               ; Current Y position
pixel_ptr:      defw    0               ; (Unused now) kept for compatibility
pixel_mask:     defb    0               ; Temporary mask storage

mask_table:                             ; Bit masks for X mod 8 (bit 7..0)
                defb    %10000000,%01000000,%00100000,%00010000
                defb    %00001000,%00000100,%00000010,%00000001

                end     ENTRYPOINT      ; Mark end and entry address
