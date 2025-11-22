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

ENTRYPOINT      equ  $8000             ; 32768 - user memory starts here
                org  ENTRYPOINT 

; System variable constants (ROM-defined)
LAST_K  equ     $5C08                  ; Holds code of last key pressed
FLAGS   equ     $5C3B                  ; Keyboard flags, bit 5 = "new key"

; -----------------------------------------------------------------------------
; waitkey
; -----------------------------------------------------------------------------
; Step 1: Clear "new key" flag in FLAGS (bit 5).
; Step 2: Wait until ROM sets bit 5 (a key has been recognised).
; Step 3: Read the keycode from LAST_K and return it in A.
; -----------------------------------------------------------------------------

waitkey:
        ; Clear bit 5 of FLAGS to say "no pending key"
        ld      a,(FLAGS)
        res     5,a
        ld      (FLAGS),a

; Busy-wait until bit 5 of FLAGS is set by the ROM.
wkey:
        ld      a,(FLAGS)
        bit     5,a              ; test bit 5 of FLAGS
        jr      z,wkey           ; loop while no new key

; A new key has been recognised — retrieve keycode and return.
        ld      a,(LAST_K)       ; A = keycode from LAST_K
        ret                      ; Return to caller.

        end    ENTRYPOINT        ; Entry marker for BASIC RAND USR
