<?php
	define('WIDTH_ADD', 2);
	define('WIDTH_SPACE', 6);

	function colorat(&$i, $x, $y) {
		return array_sum(imagecolorsforindex($i, imageColorAt($i, $x + 0, $y))) * 3 / 765;
	}

	function dumpImage($i, $f) {
		list($w, $h) = array(imageSX($i), imageSY($i));
		//echo "$w, $h\n";
		for ($y = 0; $y < $h; $y++) {
			for ($x = 0; $x < $w; $x += 2) {
				$c  = colorat($i, $x + 0, $y) << 0;
				$c |= colorat($i, $x + 1, $y) << 4;
				fwrite($f, chr($c));
				//printf("%02X", $c);
			}
			//echo "\n";
		}
	}

	function prepareImage($page) {
		global $fi;
		$c_from = $page * 100;
		$c_to = $c_from + 99;
		$i = imagecreate(256, 256);
		for ($n = 0, $c = $c_from; $c <= $c_to; $c++, $n++) {
			list($xs, $ys) = array((int)($c % 16), (int)($c / 16));
			list($xd, $yd) = array((int)($n % 10), (int)($n / 10));
			imagecopy($i, $fi, $xd * 24, $yd * 24, $xs * 24, $ys * 24, 24, 24);
		}
		return $i;
	}

	$fi = imageCreateFromGif('font.gif');

	if (true) {
	//if (false) {
		printf("Updating tim2...");
		$f = fopen('_FONTB.TM2', 'r+b');
		fseek($f, 0x10);

		for ($n = 0; $n < 3; $n++) {
			$cpos = ftell($f);
			//print_r(array_values(unpack('V3a/vb', fread($f, 4 * 3 + 2))));
			list($s_total, $s_clut, $s_image, $s_header) = array_values(unpack('V3a/vb', fread($f, 4 * 3 + 2)));
			//exit;
			//fseek($f, $cpos + $s_total - $s_image);
			fseek($f, $cpos + $s_header);

			$ci = prepareImage($n);

			//imageGif($ci, "page.$n.gif");

			dumpImage($ci, $f);

			fseek($f, $cpos + $s_total);
		}

		fclose($f);
		printf("Ok\n");
	}

	if (true) {
	//if (false) {
		printf("Determining characters width...");
		$f = fopen("_FONTB.WIDTH", 'wb');

		for ($y = 0, $cc = 0; $y < 16; $y++) {
		for ($x = 0; $x < 16; $x++, $cc++) {
			$w = 0;
			for ($y2 = 0; $y2 < 24; $y2++) {
			for ($x2 = 0; $x2 < 24; $x2++) {
				$c = imagecolorsforindex($fi, imagecolorat($fi, $x * 24 + $x2, $y * 24 + $y2));
				if ($c['red'] != 255 || $c['blue'] != 255 || $c['green'] != 255) continue;
				if ($x2 > $w) $w = $x2;
			} }
			if ($w > 0) {
				switch ($cc) {
					case 95: $w += 0; break;
					case 0x7F: $w += 16; break;
					//case 95: $w += -3; break;
					//case 45: $w += -4; break;
					default: $w += WIDTH_ADD;
				}				
			}
			if ($cc == 0x7F) $w += 16;
			if ($cc == 0x20) $w = WIDTH_SPACE;
			fwrite($f, chr($w));
		} }

		fclose($f);

		printf("Ok\n");
	}

	if (true) {
	//if (false) {
		$patches = array(
			0x00339B14 => "\x64\x00\x11\x34\x1a\x00\x11\x02\x10\x88\x00\x00\x2D\x20\x80\x02\xbc\x9f\x0d\x0c\x12\x28\x00\x00\x0a\x00\x12\x34\x1a\x00\x32\x02\x12\x88\x00\x00\x10\x90\x00\x00\x38\x00\x01\x04\x00\x00\x00\x00",
			0x00380FA0 => "\x5b\x00\x01\x3c\x70\xb1\x24\x34\x20\x20\x85\x00\x00\x00\x84\x80\x00\x00\x84\x44\x20\x00\x80\x46\xa0\x3f\x02\x3c\x00\x08\x82\x44\x08\x00\xe0\x03\x02\x00\x01\x46",
			0x005BB170 => '',
		);

		printf("Patching executable...");
		$f = fopen('../SLUS_213.86', 'r+b');

		foreach ($patches as $addr => &$data) {
			fseek($f, $addr - 0x00100000 + 0x100);
			if (strlen($data)) {
				fwrite($f, $data);
			} else {
				fwrite($f, file_get_contents("_FONTB.WIDTH"));
			}
		}

		fclose($f);
		printf("Ok\n");
	}
?>