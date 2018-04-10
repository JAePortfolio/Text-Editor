
; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt


;JOHN ARENA - COMPUTER ASSEMBLY- PROJECT 2 - 2:00-3:15PM. LAST 4 ID: 9781 - PROJECT 2 DUE 12/19/17 or EARLY 12/20/17 MORNING
org 100h

jmp start

inHandle dw ?
charAmount dw ? 
buff db 4000 dup (?)
startY db 2
startX db 0
newAddr dw ?
newLineCount dw 0
commandString db "F2: Switch Modes(Insert/Overtype) || F3: Encrypt || F5: Save || F10: Font Color"
savedStringOne db "Not Saved: X"  
savedStringTwo db "Saved:      "
fileNameString db "|| Filename: test.txt "
modeOverTypeString db "|| Mode: Overtype "
modeInsertString db "|| Mode: Insert    "
colorString db "COLOR:Black"
fileName db 20 
distIndex dw 2
distArray db 100 dup (0)
distCount db 0
lineLen db 0 
buffLoc dw 0
asciiCode db 0
newX dw ?
newY dw ?
encrX db 0
encrY db 2
colorArray dw 00f0h,00f1h,00f2h,00f3h,00f4h,00f5h,00f6h
colorArrayString db "Black Blue  Green Aqua  Red   PurpleYellow" 
colorIndex dw 6
color dw 0f0h
colIndex db 0
 
start:
    mov ax, @data
    mov ds, ax
    
    mov ax, 0B800h
    mov es, ax 
    
    mov ax, 0003h           ; Size of 80x25(al=03, ah=00)
    int 10h    
    
;    xor di, di              ; vid mem offset 0
;    mov ax, 02f00h + ' '    ; green background, white foreground
;    mov cx, 80*25           ; This amount is stored in cx. Cx counts down for instruction below
;    rep stosw

    xor di, di              ; offset 0
    mov ax, 09f00h + ' '    ; Blue on white 
    mov cx, 80              ;  80
    rep stosw
    
    mov di, 160
    mov ax, 09000h + '-'   ; Blue on white with line
    mov cx, 80
    rep stosw
    
    mov di, 320
    mov ax, 0f000h + ' '   ;Black letters, white background
    mov cx, 80*21
    rep stosw
    
    mov di, 3680
    mov ax, 8F00h + '-'    ; Gray on white, dashes
    mov cx, 80
    rep stosw
    
    mov di, 3840
    mov ax, 8F00h + ' '    ; Gray on white
    mov cx, 80
    rep stosw
;    
    mov bx, 0 
    xor si, si
    commandDraw:                             ; Draws Command Description String
        mov al, commandString[si]
        mov byte ptr es: [bx], al
        add bx, 2
        inc si
        cmp si, 79                           ; Width
        jl commandDraw 
    
    mov bx, 3840
    xor si, si
    drawSave:                                ; Draws Save status at start
        mov al, savedStringOne[si]
        mov byte ptr es: [bx], al
        add bx, 2
        inc si
        cmp si, 12
        jl drawSave
    
    mov bx, 3866
    xor si, si
    drawFileNameString:                      ; Draws file name
        mov al, fileNameString[si]
        mov byte ptr es:[bx], al
        add bx, 2
        inc si
        cmp si, 22
        jl drawFileNameString 
    
    mov bx, 3948
    xor si, si                               ; Draws Color currently used for font
    drawColorString:
        mov al, colorString[si]
        mov byte ptr es:[bx], al
        add bx, 2
        inc si
        cmp si, 11
        jl drawColorString 

;    int 10h        

    ;*******GET COMMAND LINE ARG*****
    xor bx, bx               ; 0
    mov bl, [80h]            ; length string at 80h
    cmp bl, 126              ; check length
    ja exit                
    mov [bx+81h], 0         ; add 0 at end of string
    
    ;********OPEN FILE*********
    mov ah, 3Dh             ; Open existing file
    mov al, 0               ; Read mode
    mov dx, 82h             ; offset of string
    int 21h                 ; Interrupt call
    jc exit                  ; CF set, jmp
    mov inHandle, ax        ; save handler
    mov bx, 186             ; random test
    jmp continue
;    mov ptr es: [bx], 14    ; sym for work
;    jmp continue                ; jmp contin
;    err:
;    mov ptr es: [bx], 15  
;    jmp exit
    
    
    ;**********POINTER**********
    continue: nop
    mov ah, 42h             ; Seek, pointer
    mov bx, inHandle        ; Bx takes handler
    mov al, 2               ; End of file 
    mov cx, 0               ; Upper order # bytes to move
    mov dx ,0               ; Lower order # bytes to move
    int 21h                 ; Interrupt
    mov charAmount, ax      ; Store amount of char
    ; AX Now has the size of the string 
    mov ah, 42h              ; Seek pointer
    mov bx, inHandle        ; Bx takes handle
    mov al, 0               ; Move back to beginning
    mov cx, 0               ; Upper order # bytes to move
    mov dx, 0               ; Lower order # bytes to move
    int 21h                 ; Interrupt

    
    ;*******READ FILE**********
    ;read file  *NOTE MAKE CONSISTENCE XOR*
    mov ah, 3Fh             ; Read file
    mov bx, inHandle        ; Takes handle
    xor cx, cx
    mov cx, charAmount 
    mov dx, offset buff
    int 21h
    
    ;***Close File*****
    mov ah, 3Eh             ; Close file
    mov bx, inHandle
    int 21h
    
    mov dh, 2   ;Set cursor position
    mov dl, 0 
    mov bh, 0
    mov ah, 02h
    int 10h     ; Interrupt
    
    ;********************DRAW TEXT TO SCREEN**********************
    ;mov bx, 320                 ; start at OB800h:0320 on video memory
    xor si, si                  ; Zero out si, si, will use as the buffer index 
    loopDraw:                
;        mov ax, 0B800h
;        mov es, ax
        xor ax, ax
        mov al, buff[si]        ; set al to the value at the index in buffer array
        cmp al, 10              ; Compare if there's a new line ascii code 
        je newLine              ; If so, jump to newLine to take care of it
        mov ah, 09h             ; Write character
        mov bh, 0
        mov bl, b.color
        mov cx, 1
        int 10h                 ; Interrupt
        inc si                  ; Increment index
        inc lineLen             ; line length
        inc startX              ; X+1
        mov ah, 02h             ; Move cursor
        mov dl, startX          ; 
        mov bh, 0
        int 10h                 ; Interrupt
        cmp si, charAmount      ; Compare the index to the amount of characters in the array
        jle loopDraw            ; If we haven't gone through all the characters, loop back
        jnle scanForInput       ; Otherwise jump to avoid the newLine function below
    
    
    ;*********************TAKES CARE OF NEW LINE SCENARIO*****************
    newLine:
        ;********The formula for address on screen is address=2*((80*y)+x), 
        ;but x is always 0 since it's the start of a new line, so I neglect
        ;the adding x part since its redundant***************
        
        xor ax, ax              ; Zero out ax so we don't cause unforseen errors
        xor bx, bx              ; Zero out bx so we don't cause unforseen errors
        xor cx, cx
        mov di, distIndex
        inc lineLen
        mov cl, lineLen
        mov distArray[di], cl
        inc distIndex           ; Incremenet
        inc startY              ; Next row on screen (y=rows, x=columns)
        inc newLineCount        ; Increment new line count
        inc si
        mov startX, 0
        mov ah, 02h
        mov dh, startY
        mov dl, startX
        mov bh, 0
        int 10h
        jmp loopDraw            ; Jump back to loopDraw
        
    
    scanForInput:
        ;call getCursorPosition
        mov ah, 00h             ; Keyboard shift flags
        int 16h                 ; Interrupt
        cmp ah, 72              ; Check if keystroke equal to BIOS scan code for UP key-
        je keyUp                ; if equal, jump to keyUp
        cmp ah, 80              ; Check equal to BIOS scan code for DOWN key
        je keyDown              ; equal than jump to keyDown
        cmp ah, 75              ; Check equal to BIOS scan code for LEFT key
        je keyLeft              ; equal than jump to keyLeft
        cmp ah, 77              ; Check equal to BIOS scan code for RIGHT key
        je keyRight             ; equal than jump to keyRight 
        cmp al, 32
        jge overType            
        cmp ah, 83              ; Check equal to BIOS scan code for DEL key
        je delChar              ; equal than jump to delChar
        cmp ah, 60              ; F2 key
        je insertText           ; equal jump to insertTextMode  
        cmp ah, 61              ; F3 Key
        je startEncrypt         ; start encrypt function
        cmp ah, 63              ; F5 Key
        je saveFile             ; save file function   
        cmp ah, 68              ; F10 Key
        je fontColor       ; back ground text function
        jmp scanForInput        ; loop back
    
;    processCtrl:
;        mov ah,00h
;        int 16h
;        cmp ah, 105
;        je testCtrl 
    
;    getCursorPosition:
;        mov ax, 00h                 ; Initialize mouse
;        int 33h                     ; Interrupt
;        mov ax, 01h                 ; Show mouse on screen
;        int 33h                     ; Interrupt
;        mov ax, 03h                 ; Get mouse place and status
;        int 33h                     ; Interrupt
;        cmp bx, 1                   ; Check left click
;        jne scanForInput
;        mov newX, cx
;        mov newY, dx
;        mov ah, 02h                 ; Set cursor
;        mov dh, b.newY                ; New Y
;        mov dl, b.newX                ; New X
;        mov bh, 0                   ; Page number
;        int 10h
;        ret
;    
;    updateMouse:
;        mov ax, 03h                 ; Get mouse position and status of buttons
;        int 33h                     ; Interrupt
;        cmp bx, 1                   ; Check for left click
;        jne scanForInput            ; No left click, ignore and jump back
;        mov newX, cx                ; store the new X
;        mov newY, dx                ; store the new Y
;        mov dh, b.newY
;        mov dl, b.newX
;        mov bh, 0
;        mov ah, 02h
;        int 10h
;        jmp scanForInput
        
    keyUp:                          
        mov ah, 02h                 ; Set cursor position mode  
        mov bh, 0                   ; Page number
        cmp dh, 2                   ; Check if cursor is at the highest it can go on board- 
        je scanForInput             ; to prevent going off screen-If it is, don't move up, jmp back       
        sub dh, 1                   ; Otherwise, mov 1 positions "upward" (currentY-1) 
        int 10h                     ; Interrupt call
        jmp scanForInput            ; Jump back to scanForInput
    keyDown:                          
        mov ah, 02h                 ; Set cursor position mode  
        mov bh, 0                   ; Page number
        cmp dh, 22                  ; Check if cursor is at the lowest it can go on board- 
        je scanForInput             ; to prevent going off screen-If it is, don't move down, jmp back       
        add dh, 1                   ; Otherwise, mov 1 positions "downward" (currentY+1) 
        int 10h                     ; Interrupt call
        jmp scanForInput            ; Jump back to scanForInput
    keyLeft:                       
        mov ah, 02h                 ; Set cursor position mode
        mov bh, 0                   ; Page number
        cmp dl, 0                   ; Check if cursor is at the left most side of the board-
        je scanForInput             ; to prevent going off screen-Ifit is, don't move left, jmp back
        sub dl, 1                   ; Otherwise, mov 1 positions left
        int 10h                     ; Interrupt call
        jmp scanForInput            ; Jump back to scanForInput
    keyRight:
        mov ah, 02h                 ; Set cursor position mode
        mov bh, 0                   ; Page number
        cmp dl, 78                  ; Check if cursor is at the right most side of the board-
        je scanForInput             ; to prevent going off screen-Ifit is, don't move right, jmp back
        add dl, 1                   ; Otherwise, mov 1 positions right
        int 10h                     ; Interrupt call
        jmp scanForInput            ; Jump back to scanForInput        
    
    overType:                        ;
        mov asciiCode, al
        xor bx, bx
        xor si, si
        mov bx, 3840
        call notSavedStatus          ; Print not saved since editing currently
        xor si, si
        mov bx, 3910
        call modeStatusOverType      ; Show mode as overtype
        call buffLocator             ; Gives buffer location
        mov bx, buffLoc
        cmp buff[bx], 10             ; Check if there's a CR start there
        je scanForInput              ; If so DO NOT override, go back
        cmp buff[bx], 13
        je scanForInput              ; Same with new line
        mov ah, 09h                  ; Draw to screen
        mov al, asciiCode
        mov bh, 0
        mov bl, b.color
        mov cx, 1
        int 10h
        ;Update buffer
        mov bx, buffLoc
        mov buff[bx], al             ; Buffer has new character
        jmp keyRight
    
    delChar:
        xor bx, bx
        xor si, si
        mov bx, 3840
        call notSavedStatus          ; Not saved since editing
        xor si, si
        mov bx, 3910
        call modeStatusOverType      ;Display mode
        call buffLocator
        mov bx, buffLoc
        cmp buff[bx], 10             ; Check if CR character
        je scanForInput              ; Do NOT overwrite it, go back
        cmp buff[bx], 13             ; Same with New Line
        je scanForInput
        mov ah, 09h                  ; Draw to screen
        mov al, 0                    ; Draws a blank since delete
        mov bh, 0
        mov bl, b.color
        mov cx, 1
        int 10h                      ; Interrupt 
        mov bx, buffLoc
        mov buff[bx], al             ; Update buffer
        jmp scanForInput           
    
    insertText:
        mov ah, 00h
        int 16h
        mov asciiCode, al       ; Store ascii to use after call
        cmp al, 8
        je backSpaceCase        ; If backspace during insert mode, go there
        xor bx, bx
        xor si, si
        mov bx, 3840        
        call notSavedStatus     ; Display save status
        xor si, si
        mov bx, 3910
        call modeStatusInsert   ; Display mode status
        call buffLocator        ;
        xor ax, ax              ;
        xor cx, cx              ;
        lea si, buff            ; Address buff
        add si, charAmount      ; Offset
        dec si                  ; last letter
        mov cx, charAmount      ; Counter
        mov al, b.buffLoc
        sub cx, ax
        dec cx
        lea di, buff
        add di, charAmount      ; Points to where we want to move string
        mov ax, 00700h
        mov es, ax
        mov ds, ax
        STD                     ; Direction
        rep movsb
        ;mov ah, 00h
        ;int 16h
        xor bx, bx
        xor ax, ax
        mov al, asciiCode
        mov bx, buffLoc
        mov buff[bx+1], al      ; Store in buffer
        xor si, si
        mov ah, 02h
        mov dh, 2   ;Set cursor position
        mov dl, 0 
        mov bh, 0
        int 10h     ; Interrupt
        inc charAmount
        mov lineLen, 0 
        mov startX, 0
        mov startY, 2
        call loopDraw           ; Redraw to screen after resetting lineLen, startX and startY
        jmp scanForInput
        
    backSpaceCase:
        mov asciiCode, al         ; Store ascii
        xor bx, bx
        xor si, si
        mov bx, 3840       
        call notSavedStatus
        xor si, si
        mov bx, 3910
        call modeStatusInsert
        call buffLocator
        xor ax, ax
        xor bx, bx
        xor cx, cx
        lea di, buff              
        add di, buffLoc           ; Points to where we want to move  everything
        lea si, buff
        add si, buffLoc
        inc si                    ; First byte to move
        mov cx, charAmount        
        mov al, b.buffLoc
        sub cx, ax
        dec cx                    ; Amount to move by
        mov ax, 00700h
        mov es, ax
        mov ds, ax
        CLD                       ; Direction
        rep movsb
        xor bx, bx
        xor ax, ax 
        mov bx, charAmount
        mov buff[bx-1], 0
        xor si, si
        mov ah, 02h
        mov dh, 2
        mov dl, 0
        mov bh, 0
        int 10h
        dec charAmount            ; Deleted, so decrease charAmount
        mov startY, 2
        mov startX, 0
        mov lineLen, 0
        call loopDraw             ; Redraw using values after reset for startY,X and lineLen
        jmp scanForInput  
    
    buffLocator:                   
        xor ax, ax              ; Zero out
        xor bx, bx              ; Zero out
        xor di, di              ; Zero out
        mov ah, 03h             ; Get cursor loc
        int 10h                 ; Int
        ;mov bl, 0               ; 0 out lower
        mov bl, dh              ; Dh has Y, move to bl
        mov bh, 0               ; Zero out upper
        mov di, bx              ; Since we have to do indirect addressing, can't use BX, so use DI
        dec di
        mov al, distArray[di]   ;  
        mov ah, 0               ; Extend to 16 bit
        add al, dl              ; Answer in ax
        mov buffLoc, ax
        ret
    
    startEncrypt:
        mov ah, 02h             ; Cursor at start
        mov dh, encrY
        mov dl, encrX
        mov bh, 0
        int 10h
        jmp encrypt
        
    encrypt:
        xor ax, ax
        mov ah, 08h             ; Read character
        mov bh, 0               ; Page num
        int 10h                 ; Interrupt
        cmp al, 13              ; 13 CRET (end of line)
        je updateEncrXY         ; Jump to next line vid mem
;        cmp al, 32
;        jmp cursorFix
        cmp al , 0              ; If null (no more)
        je encrFinish           ; Done with encyrption
        cmp al, 32
        jle cursorFix
        cmp al, 78              ; Lesser half of Capital letters
        jl addEncr              ; Encryption for lesser half of Capital Letters
        cmp al, 90              ; Upper half of CapitaL Letters
        jl subEncr              ; Encryption for upper half of Capital Letters
        cmp al, 110             ; Lesser half of Lowercase Letters
        jl addEncr              ; Encryption for lesser half of Lowercase Letters
        cmp al, 122             ; Upper half of Lowercase Letters
        jl subEncr              ; Encryption for upper half of Lowercase Letters
        jmp encrypt
    
    cursorFix:
        mov ah, 02h             ; Set cursor position
        add dl, 1               ; Move by 1
        mov bh, 0               ; Page number
        int 10h
        jmp encrypt 
        
    addEncr:
        add al, 13              ; Add 13 to encrypt
        mov ah, 0Ah             ; Write char only
        mov bh, 0               ; Page number
        mov cx, 1               ; Once
        int 10h                ; Interrupt 
        call moveCursor         ; call function
        jmp encrypt             ; jump back encrypt
    subEncr:
        sub al, 13              ; Sub 13 to encrypt
        mov ah, 0Ah
        mov bh, 0
        mov cx, 1
        int 10h
        call moveCursor
        jmp encrypt
        
    moveCursor:
        mov ah, 02h             ; Set cursor position
        add dl, 1               ; Move by 1
        mov bh, 0               ; Page number
        int 10h
        ret 
    
    updateEncrXY:
        inc encrY               ; Y+1
        mov encrX, 0            ; X=0
        call startEncrypt
        jmp encrypt
     
    encrFinish:                ; Reset the cursor after encryption
        mov encrY, 2
        mov encrX, 0
        mov ah, 02h
        mov dh, 2
        mov dl, 0
        mov bh, 0
        int 10h
        jmp scanForInput
   
    fontColor:                   ; Function to change colors
        xor bx, bx
        add colIndex, 2          ; Add 2 since word array
        cmp colIndex, 14         ; compare with length
        jg  resetIndex 
        mov bl, colIndex         ; Bl has colIndex for array
        mov bh, 0                ; Extend to 8 bits
        mov ax, colorArray[bx]   ; Color in array
        mov color, ax            ; Set color in ax
        xor cx, cx               ; Setting values for color status 
        mov bx, 3960
        jmp displayColor
        jmp scanForInput 
    
    resetIndex:
        mov colIndex, -2         ; Just resets the index when reached highest number
        jmp fontColor
    
    notSavedStatus:                  ; Prints the not saved status
        mov al, savedStringOne[si]
        mov byte ptr es: [bx], al
        add bx, 2
        inc si
        cmp si, 12
        jl notSavedStatus
        ret    
    
    modeStatusInsert:                ; Prints the Insert mode status
        mov al, modeInsertString[si]
        mov byte ptr es: [bx], al
        add bx, 2
        inc si
        cmp si, 19
        jl modeStatusInsert
        ret
    
    modeStatusOverType:                ; Prints the overtype mode status
        mov al, modeOverTypeString[si]
        mov byte ptr es: [bx], al
        add bx, 2
        inc si
        cmp si, 19
        jl modeStatusOverType
        ret
    
    displayColor:                   ; Attempt to display color mode at bottom of screen
        cmp colorIndex, 42
        je colorIndexReset
        mov si, colorIndex
        mov al, colorArrayString[si]
        mov ptr es: [bx], al 
        add bx, 2
        inc colorIndex
        inc cx
        cmp cx, 6
        jl displayColor
        jmp scanForInput  
    colorIndexReset:               ; Reset value 
        mov colorIndex, 0
        jmp displayColor
           
    saveFile:
    mov ax, @data
    mov ds, ax
     ;********OPEN FILE*********
    mov ah, 3Dh             ; Open existing file
    mov al, 1               ; Read mode
    mov dx, 82h             ; offset of string
    int 21h                 ; Interrupt call
    jc exit                  ; CF set, jmp
    mov inHandle, ax        ; save handler
    
    ;********WRITE TO FILE********
    mov ah, 40h             ; Write to file
    mov bx, inHandle        ; Handler
    xor cx, cx
    mov cx, charAmount      ; Amount to write
    lea dx, buff            ; Give DX address of buffer
    int 21h 
    jc exit                 ; Error jump out
    
    ;***Close File*****
    mov ah, 3Eh             ; Close file
    mov bx, inHandle
    int 21h
    
    mov bx, 3840
    xor si, si
    mov ax, 0B800h
    mov es, ax
    savedStatus:                    ; Displays you saved file
        mov al, savedStringTwo[si]
        mov byte ptr es: [bx], al
        add bx, 2
        inc si
        cmp si, 12
        jl savedStatus
    mov bx, 3856                    ; Check mark for saved
    mov byte ptr es: [bx], 251   
    jmp scanForInput
    
    exit: nop
    
end start




