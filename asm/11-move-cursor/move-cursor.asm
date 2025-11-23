; -----------------------------------------------------------------------------
; move-cursor.asm — move a single attribute square with O P Q A, SPACE to exit
; -----------------------------------------------------------------------------
; Assemble with:
;   pasmo --name move-cursor --tapbas move-cursor.asm move-cursor.tap
; Gameplay:
;   O = left, P = right, Q = up, A = down. Hold diagonals for combined moves.
;   SPACE leaves the loop. No ROM calls are used in the main loop.
; -----------------------------------------------------------------------------

ENTRYPOINT      equ     $8000          ; 32768 - load address
ATTR_BASE       equ     $5800          ; Start of attribute area
SCREEN_BASE     equ     $4000          ; Start of pixel area
ATTR_BYTES      equ     768
SCREEN_BYTES    equ     6912

BG_ATTR         equ     %00001000      ; Paper blue, ink black
PLAYER_ATTR     equ     %01111000      ; Bright paper white for the square

INIT_X          equ     15             ; Starting column (0-31)
INIT_Y          equ     11             ; Starting row (0-23)

                org     ENTRYPOINT

start:
                ei                      ; Ensure interrupts are on for HALT pacing
                call    clear_screen
                call    clear_attrs

                ld      a,INIT_X
                ld      (player_x),a
                ld      a,INIT_Y
                ld      (player_y),a
                call    place_player

main_loop:
                halt                    ; Sync to 50 Hz interrupt
                call    read_inputs     ; A = direction mask, bit7 = exit
                bit     7,a
                jr      nz,exit_game
                call    update_position ; Uses mask in A
                jr      main_loop

exit_game:
                ret

; -----------------------------------------------------------------------------
; update_position
; A = direction mask (bit0 left, bit1 right, bit2 up, bit3 down)
; Moves one cell per frame; allows simultaneous horizontal + vertical.
; -----------------------------------------------------------------------------
update_position:
                ld      b,a             ; Save mask

                ld      a,(player_x)
                ld      h,a             ; Remember original X
                ld      c,a             ; Working X
                ld      a,(player_y)
                ld      l,a             ; Original Y
                ld      d,a             ; Working Y

                ; Horizontal delta
                ld      e,0
                bit     1,b             ; Right
                jr      z,no_right
                inc     e
no_right:
                bit     0,b             ; Left
                jr      z,no_left
                dec     e
no_left:
                ld      a,e
                cp      1
                jr      nz,maybe_left_move
                ld      a,c
                cp      31
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

                ; Vertical delta
                ld      e,0
                bit     3,b             ; Down
                jr      z,no_down
                inc     e
no_down:
                bit     2,b             ; Up
                jr      z,no_up
                dec     e
no_up:
                ld      a,e
                cp      1
                jr      nz,maybe_up_move
                ld      a,d
                cp      23
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

                ; Did position change?
                ld      a,c
                cp      h
                jr      nz,do_move
                ld      a,d
                cp      l
                ret     z               ; No movement this frame

do_move:
                ld      hl,(player_ptr)
                ld      a,BG_ATTR
                ld      (hl),a          ; Erase old square

                ld      a,c
                ld      (player_x),a
                ld      a,d
                ld      (player_y),a
                call    place_player
                ret

; -----------------------------------------------------------------------------
; place_player: compute attribute address from (player_x, player_y),
; store it, and draw the square attribute.
; -----------------------------------------------------------------------------
place_player:
                call    calc_player_ptr ; HL = attribute address
                ld      (player_ptr),hl
                ld      a,PLAYER_ATTR
                ld      (hl),a
                ret

; -----------------------------------------------------------------------------
; calc_player_ptr: HL = ATTR_BASE + (Y * 32) + X
; -----------------------------------------------------------------------------
calc_player_ptr:
                ld      a,(player_y)
                add     a,a             ; index = y * 2 (word table)
                ld      e,a
                ld      d,0
                ld      hl,attr_row_table
                add     hl,de
                ld      e,(hl)
                inc     hl
                ld      d,(hl)          ; DE = row base
                ex      de,hl           ; HL = row base
                ld      a,(player_x)
                ld      e,a
                ld      d,0
                add     hl,de
                ret

; -----------------------------------------------------------------------------
; read_inputs: returns mask in A
; bit0 left (O), bit1 right (P), bit2 up (Q), bit3 down (A), bit7 exit (SPACE)
; -----------------------------------------------------------------------------
read_inputs:
                xor     a

                ; Row with P,O,I,U,Y (A13 low -> port $DFFE)
                ld      bc,$DFFE
                in      l,(c)
                bit     1,l             ; O (left)
                jr      nz,no_o
                set     0,a
no_o:
                bit     0,l             ; P (right)
                jr      nz,no_p
                set     1,a
no_p:

                ; Row with Q,W,E,R,T (A10 low -> port $FBFE)
                ld      bc,$FBFE
                in      l,(c)
                bit     0,l             ; Q (up)
                jr      nz,no_q
                set     2,a
no_q:

                ; Row with A,S,D,F,G (A9 low -> port $FDFE)
                ld      bc,$FDFE
                in      l,(c)
                bit     0,l             ; A (down)
                jr      nz,no_a
                set     3,a
no_a:

                ; Row with SPACE,SYM,M,N,B (A15 low -> port $7FFE)
                ld      bc,$7FFE
                in      l,(c)
                bit     0,l             ; SPACE to exit
                jr      nz,no_space
                set     7,a
no_space:
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

player_x:       defb    0
player_y:       defb    0
player_ptr:     defw    0

; Row bases for the 24 attribute rows (ATTR_BASE + y*32)
attr_row_table:
                defw    $5800,$5820,$5840,$5860,$5880,$58A0,$58C0,$58E0
                defw    $5900,$5920,$5940,$5960,$5980,$59A0,$59C0,$59E0
                defw    $5A00,$5A20,$5A40,$5A60,$5A80,$5AA0,$5AC0,$5AE0

                end     ENTRYPOINT
