; -----------------------------------------------------------------------------
; scratch.asm — ZX Spectrum machine code routine
; -----------------------------------------------------------------------------
; Assemble with:
;     pasmo --name scratch --tapbas scratch.asm scratch.tap
;
; Purpose:
;     Waits until a key is pressed on the ZX Spectrum keyboard,
;     then returns the key code from the system variable LAST_K.
;
;     Returns to the caller (e.g., BASIC via RAND USR).
; -----------------------------------------------------------------------------

ENTRYPOINT      equ     $8000          ; 32768 - user memory starts here
                org     ENTRYPOINT

; System variable constants (ROM-defined)
LAST_K          equ     $5C08          ; Holds code of last key pressed
FLAGS           equ     $5C3B          ; Keyboard flags, bit 5 = "new key"
DF_CC           equ     $5C4D          ; Display file cursor (2 bytes, little-endian)
S_POSN          equ     $5C58          ; Cursor column/row (2 bytes: col,row)
SCR_BASE        equ     $4000          ; Start of display file

; ROM routines / control codes
CLS             equ     $0DAF          ; Clear screen
AT_CODE         equ     22             ; AT y,x positioning control code
RST_CH_OUT      equ     $10            ; Character output routine (RST $10)

; -----------------------------------------------------------------------------
; waitkey_and_print
; -----------------------------------------------------------------------------
; Step 1: Clear "new key" flag in FLAGS (bit 5).
; Step 2: Wait until ROM sets bit 5 (a key has been recognised).
; Step 3: Read the keycode from LAST_K, print it at (0,0), and
;         keep looping until SPACE is pressed, then return to BASIC.
; -----------------------------------------------------------------------------

waitkey:
        call    CLS                     ; Clear the screen once at start

main_loop:
        ; Clear bit 5 of FLAGS to say "no pending key"
        ld      a,(FLAGS)
        res     5,a
        ld      (FLAGS),a

; Busy-wait until bit 5 of FLAGS is set by the ROM.
wkey:
        ld      a,(FLAGS)
        bit     5,a                     ; Test bit 5 of FLAGS
        jr      z,wkey                  ; Loop while no new key

; A new key has been recognised — retrieve keycode.
        ld      a,(LAST_K)              ; A = keycode from LAST_K

        cp      ' '                     ; Exit if SPACE pressed
        ret     z

        ; Force cursor to (0,0) via control codes, then print character.
        push    af                      ; Save keycode
        ld      a,AT_CODE               ; AT control code
        rst     RST_CH_OUT
        xor     a                       ; y = 0
        rst     RST_CH_OUT
        rst     RST_CH_OUT              ; x = 0
        pop     af                      ; Restore keycode
        rst     RST_CH_OUT              ; Print the key at (0,0)

        jr      main_loop               ; Loop for next key

        end    ENTRYPOINT        ; Entry marker for BASIC RAND USR
