<?php
	function getialpha($i, $x, $y) {
		return (int)((array_sum(imagecolorsforindex($i, imagecolorat($i, $x, $y))) * 14) / (255 * 3));
	}

	$i = imagecreatefromgif('logo_endroll.gif');
	$f = fopen('ENDROLL.TM2', 'r+b');
	fseek($f, 0x6200);
	for ($y = 0; $y < imageSY($i); $y++) {
		for ($x = 0; $x < imageSX($i); $x += 2) {
			$c2 = 15 - getialpha($i, $x + 0, $y);
			$c1 = 15 - getialpha($i, $x + 1, $y);
			fwrite($f, chr(($c1 & 0x0F) | (($c1 << 4) & 0xF0)));
		}
	}
?>