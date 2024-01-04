; compile with "pasmo --name connect4 --tapbas connect4.asm connect4.tap"

; CONNECT 4 by Darryl Sloan, 3 July 2017

                org  50000

last_k          equ  23560

                ld   hl, udgs   ; UDGs
                ld   (23675), hl ; set up UDG system variable

                ld   a, 2       ; upper screen
                call 5633       ; open channel

; draw game title
                ld   de, banner ; address of string
                ld   bc, eobanr-banner ; length of string to print
                call 8252       ; print our string

; draw board
bdraw           ld   de, board  ; address of string
                ld   bc, eoboard-board ; length of string to print
                call 8252       ; print our string
                ld   hl, board+1
                ld   a, (hl)
                inc  a
                ld   (hl), a
                cp   16         ; finish looping when lines 12 to 16 are drawn
                jr   nz, bdraw

; draw player line
                ld   de, player       
                ld   bc, eoplyr-player
                call 8252

; show player
ploop           ld   hl, 22816
                ld   bc, (ppos)
                add  hl, bc
                ld   a, (pcol)
                ld   (hl), a

; invite player input
                ld   hl, last   ; LAST K system variable
                ld   a, (hl)    ; put last keyboard press into A
                cp   112        ; was "p" pressed?
                jr   z, pright  ; jump to PRIGHT
                cp   111        ; was "o" pressed?
                jr   z, pleft   ; jump to PLEFT
                cp   32         ; was " " pressed?
                jr   z, pfire   ; jump to PFIRE
                cp   114        ; was "r" pressed?
                jr   z, newgame ; jump to NEWGAME
                jr   ploop      ; maintain player input loop

; restart game
newgame         ld   hl, drop   ; reset available drops for all 7 columns
                ld   b, 7
rstdrp          ld   (hl), 6    ; 6 means empty column (i.e. 6 drops remaining)
                inc  hl         ; move forward 1 byte within DROP until all 7 are reset
                djnz rstdrp

; clear board 
                ld   a, 6      ; A keeps track of rows
                ld   b, 7      ; B keeps track of columns
                ld   hl, 22860 ; addr 22860 is top-left attribute of board
                ld   de, 25    ; 25 is the number of spaces from the end of one row to the beginning of the next
empty           ld   (hl), 15  ; 15 is paper blue, ink white, i.e. an empty slot
                inc  hl        ; move forward one attribute
                djnz empty     ; repeat until a row of seven slots is cleared
                ld   b, 7      ; reset B in readiness for next row
                add  hl, de    ; skip to start of next row
                dec  a         ; subtract 1 from remaining rows
                cp   0         ; if all 6 rows are complete, end
                jp   z, clrkey
                jr   empty     ; if not, repeat

; player moves right
pright          ld   a, (ppos) ; prevent player from moving too far right
                cp   18
                jr   z, ploop
                ld   hl, 22816 ; erase player from screen
                ld   bc, (ppos)
                add  hl,bc
                ld   (hl), 63
                ld   a, (ppos) ; move player 1 square right
                inc  a
                ld   (ppos), a
                jp   clrkey

; player moves left
pleft           ld   a, (ppos)  ; prevent player from moving too far left
                cp   12
                jr   z, ploop
                ld   hl, 22816  ; erase player from screen
                ld   bc, (ppos)
                add  hl, bc
                ld   (hl), 63
                ld   a, (ppos)  ; move player 1 square left
                dec  a
                ld   (ppos), a
                jp   clrkey


; player fires
pfire           ld   a, (ppos)  ; get mathematical x position of player (i.e. x=12 is 1)
                sub  11
                ld   hl, drop-1 ; point at mem loc prior to first column (because the loop incs)
                ld   b, a       ; use b to loop until correct column is reached
cntr            inc  hl         ; increase HL to scan across drop vars
                djnz cntr
                ld   a, (hl)    ; load number of rows to descend into a
                ld   (tdrop), a ; store A in TDROP (temporary drop)
                cp   0          ; if no spaces remain in column, jump back to player input loop
                jp   z, clrkey
                ld   hl, 22816  ; erase player from screen
                ld   bc, (ppos)
                add  hl, bc
                ld   (hl), 63

; counter drops
                ld   a, (tdrop)
desnd           ld   bc, 32     ; redraw player 1 row lower
                add  hl, bc
                ld   d, a       ; remember A temporarily in D
                ld   a, (pcol+1)
                ld   (hl), a
                ld   a, d       ; put D back into A
                ld   b, 5       ; create a brief delay between counter movements
stall           halt            ; wait for an interrupt
                djnz stall      ; loop
                ld   (hl), 15   ; draw counter
                dec  a          ; A controls iterations of loop
                jr   nz, desnd  ; loop until descent finished
                ld   a, (pcol+1) ; redraw counter in resting position
                ld   (hl), a

; decrement remaining slots by 1
                ld   a, (ppos)  ; get mathematical x position of player (i.e. x=12 is 1)
                sub  11
                ld   hl, drop-1 ; point at mem loc prior to first column (because the loop incs)
                ld   b, a       ; use b to loop until correct column is reached
cntr2           inc  hl         ; increase HL to scan across drop vars
                djnz cntr2
                ld   a, (tdrop) ; subtract one from slots remaining in selected column
                dec  a
                ld   (tdrop), a
                ld   (hl), a

; change colour for other player
                ld   hl, ppos   ; set player position back to centre
                ld   (hl), 15
                ld   a, (pcol)  ; add 4 to colour (changing red to yellow), for above board
                add  a, 4
                ld   (pcol), a
                ld   a, (pcol+1) ; add 4 to colour (changing red to yellow), for within board
                add  a, 4
                ld   (pcol+1), a
                cp   18         ; if colour is invalid, jump to BADCOL
                jr   z, badcol
                jr   clrkey     ; clear keyboard
badcol          ld   a, 58      ; change invalid colour to red
                ld   (pcol), a
                ld   a, 10
                ld   (pcol+1), a
                jr   clrkey     ; clear keyboard

; clear last keypress and loop back for new input
clrkey          ld   hl, last_k ; clear LAST_K
                ld   (hl), 0
                jp   ploop      ; jump back to keyboard input

; variables
ppos            defb 15, 0      ; player's horiz position, 12 to 18 (0 is added for use in 16-bit register)
pcol            defb 58, 10     ; player's colour (58=red/white, 62=yellow/white; 10=red/blue, 14=yellow/blue)
drop            defb 6, 6, 6, 6, 6, 6, 6 ; the number of rows a counter should drop for each column
tdrop           defb 0          ; temp storage of current drop

banner          defb 22, 3, 11, "CONNECT 4"
eobanr          equ $

; board setup
board           defb 22, 10, 12 ; set print position to y=10, x=12
                defb 16, 7, 17, 1, 144, 144, 144, 144, 144, 144, 144; ink white, paper blue
eoboard         equ $

player          defb 22, 9, 12  ; set print position to y=9, x=12
                defb 16, 7, 17, 7, 144, 144, 144, 144, 144, 144, 144 ; ink & paper white (invisible)
eoplyr          equ $

; graphics setup
udgs            defb 0, 24, 60, 126, 126, 60, 24, 0 ; graphic for counter (and board, inverted)
