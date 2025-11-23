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
REPDEL          equ     $5C09          ; Initial repeat delay (in frames)
REPPER          equ     $5C0A          ; Repeat period (in frames)

; ROM routines / control codes
CLS             equ     $0DAF          ; Clear screen
RST_CH_OUT      equ     $10            ; Character output routine (RST $10)

; -----------------------------------------------------------------------------
; waitkey_and_print
; -----------------------------------------------------------------------------
; Step 1: Clear "new key" flag in FLAGS (bit 5).
; Step 2: Wait until ROM sets bit 5 (a key has been recognised).
; Step 3: Read the keycode from LAST_K. If it's O/P/Q/A, print it; ignore
;         all other keys. Loop until SPACE is pressed, then return to BASIC.
; -----------------------------------------------------------------------------

waitkey:
        call    CLS                     ; Clear the screen once at start
        ld      a,(REPDEL)              ; Save current repeat settings
        ld      (orig_repdel),a
        ld      a,(REPPER)
        ld      (orig_repper),a
        ld      a,1                     ; Minimal non-zero delay
        ld      (REPDEL),a              ; Near-instant repeat delay
        ld      (REPPER),a              ; Fast repeat period (per frame)
        ei                               ; Ensure interrupts are on for HALT/keyboard scan

main_loop:
        ; Clear bit 5 of FLAGS to say "no pending key"
        ld      a,(FLAGS)
        res     5,a
        ld      (FLAGS),a

; Busy-wait until bit 5 of FLAGS is set by the ROM.
wkey:
        halt                            ; Yield until next interrupt
        ld      a,(FLAGS)
        bit     5,a                     ; Test bit 5 of FLAGS
        jr      z,wkey                  ; Loop while no new key

; A new key has been recognised — retrieve keycode.
        ld      a,(LAST_K)              ; A = keycode from LAST_K
        and     $7F                     ; Strip "valid" bit to get ASCII-ish code
        and     $DF                     ; Force to uppercase (handle lowercase mode)

        cp      ' '                     ; Exit if SPACE pressed
        jr      z,restore_and_exit

        ; Only accept O, P, Q, A — ignore other keys
        cp      'O'
        jr      z,print_char
        cp      'P'
        jr      z,print_char
        cp      'Q'
        jr      z,print_char
        cp      'A'
        jr      z,print_char
        jr      main_loop               ; Unhandled key: ignore and wait again

print_char:
        ; Print character at current cursor; cursor advances automatically.
        rst     RST_CH_OUT

        jr      main_loop               ; Loop for next key

restore_and_exit:
        ld      a,(orig_repdel)         ; Restore original repeat settings
        ld      (REPDEL),a
        ld      a,(orig_repper)
        ld      (REPPER),a
        ret

orig_repdel:    defb    0
orig_repper:    defb    0

        end    ENTRYPOINT        ; Entry marker for BASIC RAND USR
