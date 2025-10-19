.data

newline: .string "\n"
space:   .string " + i*"

N:      .word   8
x:      .float  1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0
X_real: .space  32  
X_imag: .space  32  
cos_label: .string "cos = "  
sin_label: .string "sin = "  

.LC0:
        .word   1086918619##2pi
.LC1:
        .word   -1068953637##pi
.LC2:
        .word   1078530011#pi tbm?
.LC3:
        .word   869711765##10-7
.LC4:
        .word   1070141403##pi/2
.LC5:
        .word   1065353216## primeiro termo dos somatorios
.LC6:
        .word   -1060565029 ## -2pi


.text

main:  
    addi    sp, sp, -32
    sw      ra, 28(sp)
    sw      s0, 24(sp)  
    sw      s1, 20(sp) 
    sw      s2, 16(sp)  
    sw      s3, 12(sp)  
    csrr    s0, 3073        
    la      a0, x           
    la      a1, X_real    
    la      a2, X_imag      
    lw      a3, N           
    jal     DFT
    csrr    t0, 3073        
    sub     s0, t0, s0    
    mv      a1, s0
    li      a7, 1     
    ecall
    la      a1, newline
    li      a7, 4
    ecall
    li      s1, 0         
    la      s2, X_real
    la      s3, X_imag
    lw      a5, N          
print_loop_start:
    bge     s1, a5, print_loop_end  
    slli    t0, s1, 2

    add     t1, s2, t0      
    flw     fa0, 0(t1)
    li      a7, 2          
    ecall

    
    la      a0, space
    li      a7, 4          
    ecall
    add     t2, s3, t0      
    flw     fa0, 0(t2)
    li      a7, 2           
    ecall
    la      a0, newline
    li      a7, 4           
    ecall
    addi    s1, s1, 1      
    j       print_loop_start

print_loop_end:
    li      a0, 0           
    lw      s3, 12(sp)
    lw      s2, 16(sp)
    lw      s1, 20(sp)
    lw      s0, 24(sp)
    lw      ra, 28(sp)
    li      a7, 10          
    ecall
    addi    sp, sp, 32
    jr      ra
normalize_angle:
        addi    sp,sp,-48
        sw      ra,44(sp)
        sw      s0,40(sp)
        addi    s0,sp,48
        fsw     fa0,-36(s0)
        lui     a5,%hi(.LC0)
        flw     fa5,%lo(.LC0)(a5)
        fsw     fa5,-20(s0)
        flw     fa4,-36(s0)
        flw     fa5,-20(s0)
        fdiv.s  fa5,fa4,fa5
        fcvt.w.s a5,fa5,rtz
        sw      a5,-24(s0)
        lw      a5,-24(s0)
        fcvt.s.w        fa4,a5
        flw     fa5,-20(s0)
        fmul.s  fa5,fa4,fa5
        flw     fa4,-36(s0)
        fsub.s  fa5,fa4,fa5
        fsw     fa5,-36(s0)
        flw     fa4,-36(s0)
        lui     a5,%hi(.LC1)
        flw     fa5,%lo(.LC1)(a5)
        fle.s   a5,fa4,fa5
        bne     a5,zero,.L13
        j       .L8
.L13:
        flw     fa4,-36(s0)
        flw     fa5,-20(s0)
        fadd.s  fa5,fa4,fa5
        fsw     fa5,-36(s0)
.L8:
        flw     fa4,-36(s0)
        lui     a5,%hi(.LC2)
        flw     fa5,%lo(.LC2)(a5)
        fgt.s   a5,fa4,fa5
        bne     a5,zero,.L14
        j       .L10
.L14:
        flw     fa4,-36(s0)
        flw     fa5,-20(s0)
        fsub.s  fa5,fa4,fa5
        fsw     fa5,-36(s0)
.L10:
        flw     fa5,-36(s0)
        fmv.s   fa0,fa5
        lw      ra,44(sp)
        lw      s0,40(sp)
        addi    sp,sp,48
        jr      ra
calccosseno:
        addi    sp,sp,-64
        sw      ra,60(sp)
        sw      s0,56(sp)
        addi    s0,sp,64
        fsw     fa0,-52(s0)
        sw      a0,-56(s0)
        lui     a5,%hi(.LC3)
        flw     fa5,%lo(.LC3)(a5)
        fsw     fa5,-40(s0)
        flw     fa0,-52(s0)
        jal    normalize_angle
        fsw     fa0,-20(s0)
        flw     fa5,-20(s0)
        fmv.s.x fa4,zero
        flt.s   a5,fa5,fa4
        bne     a5,zero,.L28
        j       .L16
.L28:
        flw     fa5,-20(s0)
        fneg.s  fa5,fa5
        fsw     fa5,-20(s0)
.L16:
        li      a5,1
        sw      a5,-24(s0)
        flw     fa4,-20(s0)
        lui     a5,%hi(.LC4)
        flw     fa5,%lo(.LC4)(a5)
        fgt.s   a5,fa4,fa5
        bne     a5,zero,.L29
        j       .L18
.L29:
        lui     a5,%hi(.LC2)
        flw     fa4,%lo(.LC2)(a5)
        flw     fa5,-20(s0)
        fsub.s  fa5,fa4,fa5
        fsw     fa5,-20(s0)
        li      a5,-1
        sw      a5,-24(s0)
.L18:
        flw     fa5,-20(s0)
        fmul.s  fa5,fa5,fa5
        fsw     fa5,-44(s0)
        lui     a5,%hi(.LC5)
        flw     fa5,%lo(.LC5)(a5)
        fsw     fa5,-28(s0)
        flw     fa5,-28(s0)
        fsw     fa5,-32(s0)
        li      a5,1
        sw      a5,-36(s0)
        j       .L20
.L26:
        lw      a5,-36(s0)
        fcvt.s.w        fa5,a5
        fadd.s  fa4,fa5,fa5
        lui     a5,%hi(.LC5)
        flw     fa5,%lo(.LC5)(a5)
        fsub.s  fa4,fa4,fa5
        lw      a5,-36(s0)
        fcvt.s.w        fa5,a5
        fadd.s  fa5,fa5,fa5
        fmul.s  fa5,fa4,fa5
        fsw     fa5,-48(s0)
        flw     fa5,-44(s0)
        fneg.s  fa4,fa5
        flw     fa5,-48(s0)
        fdiv.s  fa5,fa4,fa5
        flw     fa4,-28(s0)
        fmul.s  fa5,fa4,fa5
        fsw     fa5,-28(s0)
        flw     fa4,-32(s0)
        flw     fa5,-28(s0)
        fadd.s  fa5,fa4,fa5
        fsw     fa5,-32(s0)
        flw     fa5,-28(s0)
        fmv.s.x fa4,zero
        flt.s   a5,fa5,fa4
        bne     a5,zero,.L30
        j       .L31
.L30:
        flw     fa5,-28(s0)
        fneg.s  fa5,fa5
        flw     fa4,-40(s0)
        fgt.s   a5,fa4,fa5
        andi    a5,a5,0xff
        j       .L23
.L31:
        flw     fa4,-28(s0)
        flw     fa5,-40(s0)
        flt.s   a5,fa4,fa5
        andi    a5,a5,0xff
.L23:
        bne     a5,zero,.L32
        lw      a5,-36(s0)
        addi    a5,a5,1
        sw      a5,-36(s0)
.L20:
        lw      a4,-36(s0)
        lw      a5,-56(s0)
        blt     a4,a5,.L26
        j       .L25
.L32:
        nop
.L25:
        lw      a5,-24(s0)
        fcvt.s.w        fa4,a5
        flw     fa5,-32(s0)
        fmul.s  fa5,fa4,fa5
        fmv.s   fa0,fa5
        lw      ra,60(sp)
        lw      s0,56(sp)
        addi    sp,sp,64
        jr      ra
calcseno:
        addi    sp,sp,-64
        sw      ra,60(sp)
        sw      s0,56(sp)
        addi    s0,sp,64
        fsw     fa0,-52(s0)
        sw      a0,-56(s0)
        lui     a5,%hi(.LC3)
        flw     fa5,%lo(.LC3)(a5)
        fsw     fa5,-40(s0)
        flw     fa0,-52(s0)
        jal    normalize_angle
        fsw     fa0,-20(s0)
        la      a0, newline
        li      a5,1
        sw      a5,-24(s0)
        flw     fa5,-20(s0)
        fmv.s.x fa4,zero
        flt.s   a5,fa5,fa4
        bne     a5,zero,.L46
        j       .L34
.L46:
        flw     fa5,-20(s0)
        fneg.s  fa5,fa5
        fsw     fa5,-20(s0)
        li      a5,-1
        sw      a5,-24(s0)
.L34:
        flw     fa4,-20(s0)
        lui     a5,%hi(.LC4)
        flw     fa5,%lo(.LC4)(a5)
        fgt.s   a5,fa4,fa5
        bne     a5,zero,.L47
        j       .L36
.L47:
        lui     a5,%hi(.LC2)
        flw     fa4,%lo(.LC2)(a5)
        flw     fa5,-20(s0)
        fsub.s  fa5,fa4,fa5
        fsw     fa5,-20(s0)
.L36:
        flw     fa5,-20(s0)
        fmul.s  fa5,fa5,fa5
        fsw     fa5,-44(s0)
        flw     fa5,-20(s0)
        fsw     fa5,-28(s0)
        flw     fa5,-28(s0)
        fsw     fa5,-32(s0)
        li      a5,1
        sw      a5,-36(s0)
        j       .L38
.L44:
        lw      a5,-36(s0)
        fcvt.s.w        fa5,a5
        fadd.s  fa4,fa5,fa5
        lw      a5,-36(s0)
        fcvt.s.w        fa5,a5
        fadd.s  fa3,fa5,fa5
        lui     a5,%hi(.LC5)
        flw     fa5,%lo(.LC5)(a5)
        fadd.s  fa5,fa3,fa5
        fmul.s  fa5,fa4,fa5
        fsw     fa5,-48(s0)
        flw     fa5,-44(s0)
        fneg.s  fa4,fa5
        flw     fa5,-48(s0)
        fdiv.s  fa5,fa4,fa5
        flw     fa4,-28(s0)
        fmul.s  fa5,fa4,fa5
        fsw     fa5,-28(s0)
        flw     fa4,-32(s0)
        flw     fa5,-28(s0)
        fadd.s  fa5,fa4,fa5
        fsw     fa5,-32(s0)
        flw     fa5,-28(s0)
        fmv.s.x fa4,zero
        flt.s   a5,fa5,fa4
        bne     a5,zero,.L48
        j       .L49
.L48:
        flw     fa5,-28(s0)
        fneg.s  fa5,fa5
        flw     fa4,-40(s0)
        fgt.s   a5,fa4,fa5
        andi    a5,a5,0xff
        j       .L41
.L49:
        flw     fa4,-28(s0)
        flw     fa5,-40(s0)
        flt.s   a5,fa4,fa5
        andi    a5,a5,0xff
.L41:
        bne     a5,zero,.L50
        lw      a5,-36(s0)
        addi    a5,a5,1
        sw      a5,-36(s0)
.L38:
        lw      a4,-36(s0)
        lw      a5,-56(s0)
        blt     a4,a5,.L44
        j       .L43
.L50:
        nop
.L43:
        lw      a5,-24(s0)
        fcvt.s.w        fa4,a5
        flw     fa5,-32(s0)
        fmul.s  fa5,fa4,fa5
        fmv.s   fa0,fa5
        lw      ra,60(sp)
        lw      s0,56(sp)
        addi    sp,sp,64
        jr      ra
DFT:
        addi    sp,sp,-64
        sw      ra,60(sp)
        sw      s0,56(sp)
        addi    s0,sp,64
        sw      a0,-52(s0)
        sw      a1,-56(s0)
        sw      a2,-60(s0)
        sw      a3,-64(s0)
        li      a5,12
        sw      a5,-36(s0)
        sw      zero,-20(s0)
        j       .L52
.L55:
        sw      zero,-24(s0)
        sw      zero,-28(s0)
        sw      zero,-32(s0)
        j       .L53
.L54:
        lw      a5,-20(s0)
        fcvt.s.w        fa4,a5
        lui     a5,%hi(.LC6)
        flw     fa5,%lo(.LC6)(a5)
        fmul.s  fa4,fa4,fa5
        lw      a5,-32(s0)
        fcvt.s.w        fa5,a5
        fmul.s  fa4,fa4,fa5
        lw      a5,-64(s0)
        fcvt.s.w        fa5,a5
        fdiv.s  fa5,fa4,fa5
        fsw     fa5,-40(s0)
        lw      a0,-36(s0)
        flw     fa0,-40(s0)
        jal    calccosseno
        fsw     fa0,-44(s0)
        lw      a0,-36(s0)
        flw     fa0,-40(s0)
        jal    calcseno
        fsw     fa0,-48(s0)
        lw      a5,-32(s0)
        slli    a5,a5,2
        lw      a4,-52(s0)
        add     a5,a4,a5
        flw     fa4,0(a5)
        flw     fa5,-44(s0)
        fmul.s  fa5,fa4,fa5
        flw     fa4,-24(s0)
        fadd.s  fa5,fa4,fa5
        fsw     fa5,-24(s0)
        lw      a5,-32(s0)
        slli    a5,a5,2
        lw      a4,-52(s0)
        add     a5,a4,a5
        flw     fa4,0(a5)
        flw     fa5,-48(s0)
        fmul.s  fa5,fa4,fa5
        flw     fa4,-28(s0)
        fadd.s  fa5,fa4,fa5
        fsw     fa5,-28(s0)
        lw      a5,-32(s0)
        addi    a5,a5,1
        sw      a5,-32(s0)
.L53:
        lw      a4,-32(s0)
        lw      a5,-64(s0)
        blt     a4,a5,.L54       
       ## lw      a5,-20(s0)
       ## slli    a5,a5,2
       ## lw      a4,-56(s0)
        ##add     a5,a4,a5
       ## flw     fa5,-24(s0)
        ##fsw     fa5,0(a5)
        #lw      a5,-20(s0)
        #slli    a5,a5,2
        #lw      a4,-60(s0)
        #add     a5,a4,a5
        #flw     fa5,-28(s0)
        #fsw     fa5,0(a5)
        lw      t0, -20(s0)    
        slli    t1, t0, 2       
        lw      a4, -56(s0)     
        add     a5, a4, t1      
        flw     fa5, -24(s0)    
        fsw     fa5, 0(a5)
        lw      a4, -60(s0)     
        add     a5, a4, t1    
        flw     fa5, -28(s0)    
        fsw     fa5, 0(a5)
        lw      a5,-20(s0)
        addi    a5,a5,1
        sw      a5,-20(s0)
.L52:
        lw      a4,-20(s0)
        lw      a5,-64(s0)
        blt     a4,a5,.L55
        nop
        nop
        lw      ra,60(sp)
        lw      s0,56(sp)
        addi    sp,sp,64
        jr      ra
