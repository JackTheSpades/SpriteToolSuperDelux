; Routine that changes the map16 tile of a block from inside of a bounce sprite.
; You'd be better using %InvisibleMap16() and %RevertMap16() instead of this routine.
;
; Input: 
;   A = Map16 to change into ($9C)
;   C = Custom tile flag
;
; Output:
;   N/A

?main:
    rtl