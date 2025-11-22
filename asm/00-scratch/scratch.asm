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

        org     $FF58                  ; Load address used by the BASIC loader stub.
start

; System variable constants (ROM-defined)
LAST_K  equ     $5C08                  ; Holds code of last key pressed; 0 = none.

; -----------------------------------------------------------------------------
; waitkey
; -----------------------------------------------------------------------------
; Step 1: Reset LAST_K to "no key" marker (0).
; Step 2: Wait until the ROM keyboard scanner updates it.
; Step 3: Read the keycode from LAST_K and return it in A.
; -----------------------------------------------------------------------------

waitkey
        LD      HL,LAST_K              ; Point HL to LAST_K system variable.
        XOR     A                      ; A = 0 = "no key pressed" marker.
        LD      (HL),A                 ; Clear previous key state.

; Busy-wait until LAST_K changes from 0.
wkey
        CP      (HL)                   ; Compare A (0) with current LAST_K.
        JR      Z,wkey                 ; Loop while still 0 (no key).

; A key has been pressed — retrieve keycode and return.
        LD      A,(HL)                 ; A = keycode from LAST_K.
        RET                            ; Return to caller.

        end    start                   ; Optional: entry marker for BASIC RAND USR
