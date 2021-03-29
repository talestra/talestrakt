	#.text 0x00380FA0
	.text
	.globl __start
__start:

	#li $a0, 79
	li $a0,0x005BB170
	add $a0, $a0, $a1
	lb $a0, 0($a0)
	mtc1 $a0, $f0
	cvt.s.w $f0, $f0
	lui $v0, 0x3FA0
	mtc1 $v0, $f1
	jr $ra
	mul.s $f0, $f0, $f1
