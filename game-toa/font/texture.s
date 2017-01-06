# -----------------------------------------
#  Tales of the Abyss - glyph texture hack
#  soywiz | Tales Translations 2007-2008
# -----------------------------------------

	.text 0x00439B14
	.globl __start
__start:

# original glyph decoding has a very complex decodification
# this is a simpler one

# font.gif (384x384) is an image with 256 glyphs; 16 glyphs per row.
# _FONTB.TM2 (256x256) is a set of 3 images with 100 glyphs per image. Each image has 10 rows and each row has 10 glyphs.
# each glyph is a slice of (24x24)

	#li $s0, 123
	
# First of all, we select font page
# $s1 = c % 100 # POSITION IN PAGE
# $a1 = c / 100 # PAGE

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
	
# With the position in page, we will get row and column
# $s1 = pos / 10 # row
# $s2 = pos % 10 # column
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
