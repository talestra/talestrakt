	.text 0x00439B14
	.globl __start
__start:

	#li $s0, 123
	
	li $s1, 100
	div $s0, $s1
	nop
	nop
	mfhi $s1
	#li $a1, 0
	#mflo $a1	
	#.word 0280202D # daddu   $a0, $s4, $0
	.word 0x0C0D9FBC # JAL font_select_page	
	nop
	nop
	nop
	nop
	li $s2, 10
	div $s1, $s2
	mflo $s1 # filas
	mfhi $s2 # columnas
	b continue
	nop
	nop
	nop
	nop
	nop
	nop
	
.text 0x00439C20
continue:
