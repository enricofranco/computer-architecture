mov ah, 1h ; keyboard input subprogram
int 21h ; character input
; character is stored in al
mov c, al ; copy character from al to c