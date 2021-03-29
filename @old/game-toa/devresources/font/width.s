# -----------------------------------------------
#  Tales of the Abyss - variable font width hack
#  soywiz | Tales Translations 2007-2008
# -----------------------------------------------

	#.text 0x00380FA0
	.text
	.globl __start
__start:

# original width function was ruled based
# this is a simpler one, using a table with widths

# 0x005BB170 = Width Table (256 bytes one for each character)
# $a1 = character
# $a0 = table + character

	#li $a0, 79
	li $a0,0x005BB170
	add $a0, $a0, $a1
	lb $a0, 0($a0)
	mtc1 $a0, $f0
	cvt.s.w $f0, $f0
	
# (float)(font_width) * 1.25f
	lui $v0, 0x3FA0 # 1.25f
	mtc1 $v0, $f1
	jr $ra
	mul.s $f0, $f0, $f1
