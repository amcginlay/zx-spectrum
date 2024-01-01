                                ; compile with "pasmo --name scratch --tapbas scratch.asm scratch.tap"
                org  $FF58      ; address where you load the program (65368 as per machine-code-loader)

waitkey    LD   HL,23560        ; lastk                                        
           LD   A,255                                           
           LD   (HL),A                                          
wkey       CP   (HL)                                            
           JR   Z,wkey       ; 255 means no key pressed                                   
           LD   BC,(23560)   ; read IN port and value                                  
           CALL #7BD ; translate IN port and value to key                                           
           RET        

                ;end  $FF58      ; determines if RAND USR added to BASIC stub