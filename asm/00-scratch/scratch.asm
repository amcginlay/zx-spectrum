; -----------------------------------------------------------------------------
; scratch.asm — ZX Spectrum machine code routine
; -----------------------------------------------------------------------------
; Assemble with:
;     pasmo --name scratch --tapbas scratch.asm scratch.tap
;
; Purpose:
;     Waits until a key is pressed on the ZX Spectrum keyboard,
;     then calls a ROM routine to translate the raw keyboard
;     line/bit data (written by the ROM into the system variable
;     LAST_K) into a usable keycode.
;
;     Returns to the caller (e.g., BASIC via RAND USR).
; -----------------------------------------------------------------------------

        org     $FF58                  ; Load address used by the BASIC loader stub.

; System variable constants (ROM-defined)
LAST_K  equ     $5C08                  ; Holds info about last key pressed; $FF = none.
ROM_KEY equ     $07BD                  ; ROM routine to translate key line/value to keycode.

; -----------------------------------------------------------------------------
; waitkey
; -----------------------------------------------------------------------------
; Step 1: Reset LAST_K to "no key" marker.
; Step 2: Wait until the ROM keyboard scanner updates it.
; Step 3: Read the 16-bit (port,value) pair.
; Step 4: Call ROM_KEY to translate into keycode.
; -----------------------------------------------------------------------------

waitkey
        LD      HL,LAST_K              ; Point HL to LAST_K system variable.
        LD      A,$FF                  ; A = "no key pressed" marker.
        LD      (HL),A                 ; Clear previous key state.

; Busy-wait until LAST_K changes from $FF.
wkey
        CP      (HL)                   ; Compare A ($FF) with current LAST_K.
        JR      Z,wkey                 ; Loop while still $FF (no key).

; A key has been pressed — retrieve and translate.
        LD      BC,(LAST_K)            ; BC = (keyboard line, bit pattern).
        CALL    ROM_KEY                ; ROM translates BC → keycode in A.
        RET                            ; Return to caller.

        ;end    $FF58                  ; Optional: entry marker for BASIC RAND USR
