<?php
	function imagecreatefromtga($filename) {
		// http://www.gamers.org/dEngine/quake3/TGA.txt
		if (!$f = fopen($filename, 'rb')) return false;

		$info = unpack('Cnid/Cctype/Citype/vcori/vclen/Cesize/vx/vy/vw/vh/Cbpp/Cflags', fread($f, 18));
		$id   = ($info['nid'] > 0) ? fread($f, $info['nid']) : '';

		$bypp = ($info['bpp'] >> 3);
		$cbypp = ($info['esize'] >> 3);

		list($w, $h) = array($info['w'], $info['h']);

		switch ($info['itype']) {
			case 1: // color-mapped
				$cc = $info['clen'];
				$i = imagecreatetruecolor($w, $h);
				imagefill($i, 0, 0, imagecolorallocatealpha($i, 0xFF, 0xFF, 0xFF, 0x7F));
				$pal = array();
				switch ($info['esize']) {
					case 16:
						imagecreatetrue('Unimplemented 16bit palette tga.', E_USER_WARNING);
						return false;
					break;
					case 24:
						for ($n = 0; $n < $cc; $n++) {
							$c = unpack('C3', fread($f, 3));
							$pal[$n] = imagecolorallocate($i, $c[1], $c[2], $c[3]);
						}
					break;
					case 32:
						for ($n = 0; $n < $cc; $n++) {
							$c = unpack('C4', fread($f, 4));
							$pal[$n] = imagecolorallocatealpha($i, $c[1], $c[2], $c[3], 0x7F - ($c[4] >> 1));
						}
					break;
				}

				for ($y = 0; $y < $h; $y++) {
					for ($x = 0; $x < $w; $x++) {
						$c = ord(fgetc($f));
						imagesetpixel($i, $x, $y, $pal[$c]);
					}
				}
			break;
			case 2: // RGB
				$i = imagecreatetruecolor($w, $h);
				$pd = 'c' . $bypp . 'b';
				for ($y = 0; $y < $h; $y++) {
					for ($x = 0; $x < $w; $x++) {
						$c = unpack($pd, fread($f, $bypp));
						print_r($c);
						//imagesetpixel($i, $x, $y);
						//imagecolorallocatealpha($i, int red, int green, int blue, int alpha )
					}
				}
			break;
			default:
				trigger_error('Image Type Code ' . $info['itype'] . ' unimplemented.', E_USER_WARNING);
				return false;
			break;
		}

	    fclose($f);

	    return $i;
	}
?>