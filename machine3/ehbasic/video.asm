;

VRAM = $9000
CHRRAM = $a800
TPTR = $E2
TCOLOR = $e4
ITMP = $e5
CURSORON = $e6

init_chr:
    ldx #0
copy_chr:
    lda chrset,x
    sta CHRRAM,x
    lda chrset+$100,x
    sta CHRRAM+$100,x
    lda chrset+$200,x
    sta CHRRAM+$200,x
    lda chrset+$300,x
    sta CHRRAM+$300,x
    lda chrset+$400,x
    sta CHRRAM+$400,x
    lda chrset+$500,x
    sta CHRRAM+$500,x
    lda chrset+$600,x
    sta CHRRAM+$600,x
    lda chrset+$700,x
    sta CHRRAM+$700,x
    inx
    bne copy_chr
    
CURSORHOME:
    lda #$0
    sta TPTR
    lda #$90
    sta TPTR+1
    lda #$0f
    sta TCOLOR
    rts

CLRSCR:
    lda #$0f
    ldx #$0
CLRSCR_COLOR:
    pha
    jsr CURSORHOME
    txa
    ldx #0
    jsr clr_loop
    pla
    ldx #1

clr_loop:
    sta VRAM+0,x
    sta VRAM+240,x
    sta VRAM+480,x
    sta VRAM+720,x
    sta VRAM+960,x
    sta VRAM+1200,x
    sta VRAM+1440,x
    sta VRAM+1680,x
    inx
    inx
    cpx 240
    bcc clr_loop
    rts
    
SCROLLUP:
    stx ITMP
    ldx #0
scroll_loop0:
    lda VRAM+$040,x
    sta VRAM+$000,x
    inx
    bne scroll_loop0
scroll_loop1:
    lda VRAM+$140,x
    sta VRAM+$100,x
    inx
    bne scroll_loop1
scroll_loop2:
    lda VRAM+$240,x
    sta VRAM+$200,x
    inx
    bne scroll_loop2
scroll_loop3:
    lda VRAM+$340,x
    sta VRAM+$300,x
    inx
    bne scroll_loop3
scroll_loop4:
    lda VRAM+$440,x
    sta VRAM+$400,x
    inx
    bne scroll_loop4
scroll_loop5:
    lda VRAM+$540,x
    sta VRAM+$500,x
    inx
    bne scroll_loop5
scroll_loop6:
    lda VRAM+$640,x
    sta VRAM+$600,x
    inx
    bne scroll_loop6
scroll_loop7:
    lda VRAM+$740,x
    sta VRAM+$700,x
    inx
    cpx #$40
    bne scroll_loop7
scroll_loop8:
    lda #0
    sta VRAM+$700,x
    inx
    lda TCOLOR
    sta VRAM+$700,x
    inx
    cpx #$80
    bne scroll_loop8
    ldx ITMP
    rts


SCREENOUT:
    sty ITMP
    ldy #0
;    ldy CURSORON
;    beq checkchar
;    pha
;    lda #0
;    tay
;    sta (TPTR),y
;    pla
checkchar:
    cmp #13
    beq txtcr
    cmp #10
    beq txtlf
    cmp #08
    beq txtbs
    sta (TPTR),y
    lda TCOLOR
    inc TPTR
    sta (TPTR),y
    inc TPTR
    bne txtend
txtinc:
    inc TPTR+1
txtend:
check_scroll:
    lda TPTR+1
    cmp #$97
    bcc check_done
    lda TPTR
    cmp #$80
    bcc check_done
    jsr SCROLLUP
    lda #$40
    sta TPTR
check_done:
;    lda CURSORON
;    beq cursor_done
;    lda #9
;    sta (TPTR),y
cursor_done:
    ldy ITMP
    rts

txtcr:
    lda TPTR
    and #$c0
    sta TPTR
    ldy ITMP
    rts
txtlf:
    lda TPTR
    clc
    adc #$40
    sta TPTR
    bcs txtinc
    bcc txtend

txtbs:
    lda TPTR
    bne txtbs1
    dec TPTR+1
txtbs1:
    dec TPTR
    dec TPTR
    lda #0
    sta (TPTR),y
    beq txtend        
