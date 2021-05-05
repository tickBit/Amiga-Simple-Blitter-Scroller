
; This can be compiled at least with PhxAss assembler
; I hope, it can be still found in the Aminet

; Written by a random person 5/5/2021

; The code isn't state of the art assembly, but perhaps easier to understand...

        MACHINE  68040

        incdir  "ADCD_2.1:NDK/NDK_3.5/Include/include_i"

        include "exec/types.i"
        include "libraries/dosextens.i"
        include "graphics/gfxbase.i"
        include "exec/libraries.i"
        include "exec/execbase.i"

; Amiga Developer CD v1.1 can be freely downloaded from the internet
; Use this instead, if you don't have ADCD_2.1

        ;incdir   "Amiga_Dev_CD_v1.1:NDK_3.1/includes&libs/include_i"
        ;include "exec/types.i"
        ;include "libraries/dosextens.i"
        ;include "graphics/gfxbase.i"
        ;include "exec/libraries.i"
        ;include "exec/execbase.i"

;------------------------------------------------------------------------------
; Macros
;------------------------------------------------------------------------------
WaitForBlitter: MACRO
W\@:    btst.w  #14,$dff002
        bne.s   W\@
        ENDM

;------------------------------------------------------------------------------
; Constants
;------------------------------------------------------------------------------
Forbid         equ     -$0084
Permit         equ     -$008a
Disable        equ     -$0078
Enable         equ     -$007e
Write          equ     -$0030
Output         equ     -$003c
OpenLibrary    equ     -$0228
CloseLibrary   equ     -$019e

Execbase       equ      4

NOCHIPREV      equ      0

;------------------------------------------------------------------------------
; Startup code, works with AGA machnies. I found this back in the day somewhere
;------------------------------------------------------------------------------

        SECTION CODE,code

startup:
        movem.l d0/a0,-(sp)             ; 
        move.l  4,a6                    ; SysBase
        move.l  #0,a1
        jsr     -$0126(a6)              ; 
        move.l  d0,a4
        move.l  d0,process
        tst.l   pr_CLI(a4)              ; CLI?
                                        ; 
        bne.s   check_aga               ; check_aga
wb:
        lea     pr_MsgPort(a4),a0       ; 
                                        ; 
        jsr     -$0180(a6)              ; 
        lea     pr_MsgPort(a4),a0
        jsr     -$0174(a6)              ; 
                                        ; GetMsg()
        move.l  d0,wbenchmsg            ; 
                                        ; 
check_aga:                              ; 
        moveq   #0,d0                   ; 
        lea     gfxname,a1
        jsr     -$0228(a6)              ; OpenLibrary()
        move.l  d0,gfxbase
        beq.w   reply_to_wb             ; 
        move.l  d0,a4

        moveq   #0,d0
        lea     intuiname,a1
        jsr     -$0228(a6)
        move.l  d0,intuibase
        beq     Sulje

        move.l  4,a6
        jsr     -$0078(a6)              ; Disable()
        cmp.w   #39,LIB_VERSION(a4)     ; 
                                        ; cmp.w #39,$14(a4)
        bne.s   no_chiprev

        move.b  gb_ChipRevBits0(a4),chiprev
                                        ; move.b $ec(a4),chiprev
        bra.s   check_proc
no_chiprev:
        move.b  #NOCHIPREV,chiprev      ; 
check_proc:
        move.w  AttnFlags(a6),processor ; CPU and FPU
                                        ; move.w $128(a6),processor
clear_view:
        move.l  gfxbase,a6
        move.l  gb_ActiView(a6),oldview ; 
                                        ; 
        move.l  #0,a1                   ; 
        jsr     -$00de(a6)              ; 

        jsr     -$010e(a6)
        jsr     -$010e(a6)              ; WaitTOF()

        move.l  4,a6                    ; 
        movem.l (sp)+,d0/a0             ; 
        bsr.s   _start                  ;
        move.l  d0,-(sp)                ; 
old_view:
        move.l  gfxbase,a0
        move.l  $26(a0),$dff080         ; Copperlistan palautus

        move.l  gfxbase,a6
        move.l  oldview,a1              ; old View
        jsr     -$00de(a6)              ; LoadView()
                                                                                                         
        move.l  4,a6
        jsr     -$007e(a6)              ; Enable()
                                                                                                        
        move.l  intuibase,a6
        jsr     -$0186(a6)              ; RethinkDisplay()

        move.l  4,a6
        move.l  intuibase,a1
        jsr     -$019e(a6)              ; CloseLibrary()

Sulje   move.l  4,a6
        move.l  gfxbase,a1              ;
        jsr     -$019e(a6)              ; CloseLibrary()
                                                                                                         
reply_to_wb:
        tst.l   wbenchmsg               ; workbench?
        beq.s   exit                    ; 
        jsr     -$0084(a6)              ; 
                                        ; Forbid()
        move.l  wbenchmsg,a1
        jsr     -$017a(a6)              ; ReplyMsg()
exit:
        move.l  (sp)+,d0
        rts                             ; 


_start

;------------------------------------------------------------------------------
; The program starts..
;------------------------------------------------------------------------------

        movem.l d0-d7/a0-a6,-(sp)

        move.l  4,a6
        jsr     Forbid(a6)

        move.l  4,a6
        move.l  #12288,d0              ; 384 x 256 ; 1 bitplane
        move.l  #65538,d1
        jsr     -$00c6(a6)
        move.l  d0,bitplane1
        beq     Exit


        move.l  #Copperlist,$dff080
        tst.w   $dff088                ; Own Copperlist on..

        move.w  #$87f0,$dff096         ; DMACON

        bsr     Show
MainProgram:
 
	    bsr     Scroll
        bsr     WaitForBeam

        move.l  #fontw,a0       ; Font width
        subq.l  #1,(a0)
        cmp.l   #0,(a0)         ; is it time to draw next letter?
        bne.s   mousebutton
        bsr     drawLetter
 
mousebutton
        btst    #6,$bfe001      ; Left mousebutton to exit the app
        bne.s   MainProgram

CleanUp
Freebitplane1
        move.l  4,a6
        move.l  #12288,d0
        move.l  bitplane1,a1
        jsr     -$00d2(a6)

Exit:   
        move.l  4,a6
        jsr     Permit(a6)
        movem.l (sp)+,d0-d7/a0-a6
        moveq   #0,d0
        rts

drawLetter
        move.l  #fontw,a0
        move.l  #32,(a0)


        move.l  #t_pointer,a2
        move.l  (a2),d0
        move.l  #scrolltext,a4
        add.l   d0,a4
        moveq   #0,d2
        move.b  (a4),d2
        cmp.b   #0,(a4)         ; end of text?
        bne.s   space_
        move.l  #0,t_pointer
        move.l  #t_pointer,a2
        move.l  #scrolltext,a4
        move.b  (a4),d2
space_:
        cmp.b   #32,d2          ; space
        beq.s   space

subtract_A_ascii
      
        sub.l   #65,d2          ; the ASCII code of 'A'
        lsl.l   #7,d2           ; multiply by 128

        addq.l  #1,(a2)         ; next drawLetter

        WaitForBlitter
        
        move.w  #0000,$dff042   ; BLTCON1
        move.w  #$09f0,$dff040  ; BLTCON0

        move.l  #Font,a1
        add.l   d2,a1
        move.l  a1,$dff050      ; BLTAPTR source
        move.l  bitplane1,a0
        add.l   #40,a0
        move.l  a0,$dff054      ; BLTDPTH dest

        move.w  #$ffff,$dff044
        move.w  #$ffff,$dff046

        move.w  #0000,$dff064   ; BLTAMOD (source modulo)
        move.w  #0044,$dff066   ; BLTDMOD (dest modulo)

        moveq   #0,d0
        move.w  #32,d0          ; height
        lsl.w   #6,d0           ; height to appropriate bits
        or.w    #2,d0           ; width / 16
        move.w  d0,$dff058      ; BLTSIZE       
        rts

WaitForBeam:
        cmp.b   #$ff,$dff006
        bne.s   WaitForBeam
WFBeam:
        cmp.b   #$2c,$dff006
        bne.s   WFBeam
        rts

space:
        addq.l  #1,(a2)
        move.w  #0000,$dff042   ; BLTCON1
        move.w  #$09f0,$dff040  ; BLTCON0

        move.l  #spaceg,a1
        move.l  a1,$dff050      ; BLTAPTH source
        move.l  bitplane1,a0
        add.l   #40,a0
        move.l  a0,$dff054      ; BLTDPTH dest

        move.w  #$ffff,$dff044
        move.w  #$ffff,$dff046

        move.w  #0000,$dff064   ; BLTAMOD (source modulo)
        move.w  #0044,$dff066   ; BLTDMOD (dest modulo)

        moveq   #0,d0
        move.w  #32,d0          ; height
        lsl.w   #6,d0           ; height to approriate bits
        or.w    #2,d0           ; width / 16
        move.w  d0,$dff058      ; BLTSIZE       
        rts

Scroll:           
        WaitForBlitter
        move.w  #0002,$dff064  ; BLTAMOD (source modulo)
        move.w  #0002,$dff066  ; BLTDMOD (dest modulo)

        
        move.w  #0000,$dff0042 ; BLTCON1
        clr.l   d0
        clr.l   d2
        move.w  #$09f0,d0
        move.w  #15,d2
        mulu    #$1000,d2
        or.w    d2,d0
        move.w  d0,$dff040     ; BLTCON0
        move.l  bitplane1,a1
        add.l   #2,a1
        move.l  a1,$dff050     ; BLTAPTH source
        move.l  bitplane1,a0
        add.l   #0,a0
        move.l  a0,$dff054     ; BLTDPTH dest
        moveq   #0,d0
        move.w  #32,d0         ; height
        lsl.w   #6,d0          ; height to appropriate bits
        or.w    #23,d0         ; width / 16
        move.w  d0,$dff058     ; BLTSIZE
        rts
      
         

Show:   move.l  bitplane1,d1
        move.w  d1,low1
        swap    d1
        move.w  d1,high1
        rts

gfxname         dc.b    "graphics.library",0
intuiname       dc.b    "intuition.library",0
dosname		    dc.b    "dos.library",0

scrolltext      dc.b    "THOSE WERE THE DAYS   THE AMIGA DAYS   BACK IN THE DAY                                       ",0
        even


        section variables,DATA

wbenchmsg       dc.l    0
oldview         dc.l    0
process         dc.l    0
processor       dc.w    0
chiprev         dc.b    0
                even

intuibase       dc.l    0
gfxbase         dc.l    0
dosbase		    dc.l    0

fontw           dc.l    32
t_pointer       dc.l    0

bitplane1       dc.l    0

        section ChipData,DATA,CHIP


Copperlist:
        dc.w    $00e0
high1:  dc.w    $0000
        dc.w    $00e2
low1:   dc.w    $0000

        dc.w    $0100,$1200 ; BPLCON0 one bitplane...
        dc.w    $0102,$0000 ; BPLCON1
        dc.w    $0108,$0008 ; BPL1MOD
        dc.w    $0092,$0038 ; DDFSTRT
        dc.w    $0094,$00d0 ; DDFSTOP
        dc.w    $008e,$2c81 ; DIWSTRT
        dc.w    $0090,$2cc1 ; DIWSTOP 

Colours
        dc.w    $0180,$0000
        dc.w	$3101,$ff00,$0182,$0138
	    dc.w	$3301,$ff00,$0182,$0238
	    dc.w    $3501,$ff00,$0182,$0338
	    dc.w    $3701,$ff00,$0182,$0438
	    dc.w	$3901,$ff00,$0182,$0538
        dc.w	$3101,$ff00,$0182,$0638
	    dc.w	$3301,$ff00,$0182,$0738
	    dc.w    $3501,$ff00,$0182,$0838
	    dc.w    $3701,$ff00,$0182,$0938
	    dc.w	$3901,$ff00,$0182,$0a38
        dc.w	$3a01,$ff00,$0182,$0b38
	    dc.w	$3b01,$ff00,$0182,$0c38
	    dc.w    $3c01,$ff00,$0182,$0d38
	    dc.w    $3d01,$ff00,$0182,$0e38
	    dc.w	$3e01,$ff00,$0182,$0f38
        dc.w	$3f01,$ff00,$0182,$0f38
	    dc.w	$4001,$ff00,$0182,$0e38
	    dc.w    $4101,$ff00,$0182,$0d38
	    dc.w    $4201,$ff00,$0182,$0c38
	    dc.w	$4301,$ff00,$0182,$0b38
        dc.w	$4401,$ff00,$0182,$0a38
	    dc.w	$4501,$ff00,$0182,$0938
	    dc.w    $4601,$ff00,$0182,$0838
	    dc.w    $4701,$ff00,$0182,$0738
	    dc.w	$4801,$ff00,$0182,$0638
        dc.w	$4901,$ff00,$0182,$0538
	    dc.w	$4a01,$ff00,$0182,$0438
	    dc.w    $4b01,$ff00,$0182,$0338
	    dc.w    $4c01,$ff00,$0182,$02f8
	    dc.w	$4d01,$ff00,$0182,$0138
        dc.w    $4e01,$ff00,$0182,$0138
	    dc.w	$4d01,$ff00,$0182,$0138       

        dc.w    $ffff,$fffe
        
        ; change this to where you have the font
Font    incbin  "Work:MyProjects/Scroller/gfx/gradbubble-32x32-wip.raw"
spaceg  ds.b    (32/8)*32   ; empty space, there isn't space in the font
        end
