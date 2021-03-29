<?php
	class Font {
		public $file, $size, $angle;

		function __construct($file, $size, $angle = 0) {
			$this->file  = $file;
			$this->size  = $size;
			$this->angle = $angle;
		}

		function getBoxExtended($text) {
			return imagettfbbox($this->size, $this->angle, $this->file, $text);
		}
		
		function getBox($text) {
			list(,,$x2,$y2,,,$x1,$y1) = $this->getBoxExtended($text);
			//echo "($x1,$y1)-($x2,$y2)\n";
			return array(abs($x2 - $x1), abs($y2 - $y1));
		}
		
		function getBaseLine($text) {
			$b = $this->getBoxExtended($text);
			return -$b[7];
		}
	}

	class Image {
		const PNG  = IMAGETYPE_PNG;
		const JPEG = IMAGETYPE_JPEG;
		const GIF  = IMAGETYPE_GIF;
		const AUTO = -1;
		
		private static $map = array(self::GIF => 'gif', self::PNG => 'png', self::JPEG => 'jpeg');
		private static $map_r = array('gif' => self::GIF, 'png' => self::PNG, 'jpeg' => self::JPEG, 'jpg' => self::JPEG);
	
		public $i;
		public $x, $y;
		public $w, $h;
		
		function __construct($w = null, $h = null, $bpp = 32) {
			if (empty($w) && empty($h)) return;
			$this->w = $w; $this->h = $h;
			switch ($bpp) {
				case 32: case 24: default:
					$i = $this->i = ImageCreateTrueColor($w, $h);
					if ($bpp == 32) {
						ImageSaveAlpha($i, true);
						ImageAlphaBlending($i, false);
						//cacaa5
						//Imagefilledrectangle($i, 0, 0, $w, $h, imagecolorallocatealpha($i, 0xca, 0xca, 0xa5, 0x7f));
						Imagefilledrectangle($i, 0, 0, $w, $h, imagecolorallocatealpha($i, 0x00, 0x00, 0x00, 0x7f));
						ImageAlphaBlending($i, true);
					}
				break;
				case 8:
					$i = $this->i = imagecreate($w, $h);
				break;
			}
		}
		
		static function fromFile($url) {
			$i = new Image();
			list($i->w, $i->h, $type) = getimagesize($url);
			if (!isset(self::$map[$type])) throw(new Exception('Invalid file format'));
			$call = 'imagecreatefrom' . self::$map[$type];
			$i->i = $call($url);
			ImageSaveAlpha($i->i, true);
			return $i;
		}
		
		function getPos($x, $y) {
			if ($x < 0 || $y > 0)
			return array(-1, -1);
		}
		
		function checkBounds($x, $y) {
			return ($x < 0 || $y < 0 || $x >= $this->w || $y >= $this->h);
		}
		
		function isSlice() {
			return ($this->x != 0 || $this->y != 0 || $this->w != imageSX($this->i) || $this->h != imageSY($this->i));
		}
		
		function get($x, $y) {
			if ($this->checkBounds($x, $y)) return -1;
			return imageColorAt($i, $x + $this->x, $y + $this->y);
		}
		
		function color($r = 0x00, $g = 0x00, $b = 0x00, $a = 0xFF) {
			if (is_string($r)) sscanf($r, '#%02X%02X%02X%02X', $r, $g, $b, $a);
			return imagecolorallocatealpha($this->i, $r, $g, $b, round(0x7F - (($a * 0x7F) / 0xFF)));
		}
		
		function put($x, $y, $i) {
			if ($i instanceof Image) {
				imagecopy($this->i, $i->i, $x, $y, $i->x, $i->y, $i->w, $i->h);
			} else {
				imagesetpixel($this->i, $x, $y, $i);
			}
		}
		
		function putResampled($i) {
			imagecopyresampled($i->i, $this->i, $i->x, $i->y, $this->x, $this->y, $i->w, $i->h, $this->w, $this->h);
		}
		
		function drawText($f, $x, $y, $text, $color = 0xFFFFFF, $anchorX = -1, $anchorY = -1, $baseLine = false) {
			if ($this->isSlice()) {
				throw(new Exception("Drawing in slices not implemented"));
			} else {
				$b = $f->getBox($text);
				$rx = $x - ((($anchorX + 1) * $b[0]) / 2);
				$ry = $y - ((($anchorY + 1) * $b[1]) / 2);
				if (!$baseLine) $ry += $f->getBaseLine($text);
				//echo "";
				imagettftext($this->i, $f->size, $f->angle, $rx, $ry, $color, $f->file, $text);
			}
		}
		
		function drawTextBorder($f, $px, $py, $text, $color1, $color2, $border, $boldX = 0) {
			for ($y = -$border; $y <= $border; $y++) {
				for ($x = -$border - $boldX / 2; $x <= $border + $boldX / 2; $x++) {
					if ($x == 0 && $y == 0) continue;
					if ($x < 0) {
						if (hypot($x + $boldX, $y) > $border) continue;
					} else {
						if (hypot($x - $boldX, $y) > $border) continue;
					}
					$this->drawText($f, $px + $x, $py + $y, $text, $color2);
				}
			}
			for ($n = 0; $n <= $boldX; $n++) {
				$this->drawText($f, $px - $boldX / 2 + $n, $py, $text, $color1);
			}
		}
		
		function slice($x, $y, $w, $h) {
			if ($this->isSlice()) {
				throw(new Exception("Not implemented yet slices of slices"));
			}
			$i = new Image();
			$i->i = $this->i;
			list($i->x, $i->y, $i->w, $i->h) = array($x, $y, $w, $h);
			return $i;
		}
		
		function save($name, $f = self::AUTO) {
			$i = $this;
		
			if ($f == self::AUTO) {
				$f = self::PNG;
				$f = @self::$map_r[substr(strtolower(strrchr($name, '.')), 1)];
			}
			
			if ($i->isSlice()) {
				$i2 = $i;
				$i = new Image($i->w, $i->h);
				$i->put(0, 0, $i2);
			}
			
			$p = array($i->i, $name);
			call_user_func_array('image' . self::$map[$f], $p);
		}
	}
	
	function swap(&$a, &$b) {
		$c = $b;
		$b = $a;
		$a = $c;
	}
	
	function process_tm2($tm2) {
		if (!($f = fopen($tm2, 'rb'))) throw(new Exception("Can't open tm2"));
		fseek($f, 6, SEEK_SET);
		list(,$count) = unpack('v', fread($f, 2));
		//echo "$count\n";
		fseek($f, 0x10, SEEK_SET);
		
		$ii = array();

		for ($n = 0; $n < $count; $n++) {
			$ci = &$ii[$n];
			$ci['offet'] = ftell($f);
			$ci['info']  = $ff = unpack('Vtotal_size/Vclut_size/Vimage_size/vheader_size/vclut_colors/Cpict_format/Cmipmap_texts/Cclut_type/Cimage_type/vwidth/vheight', fread($f, 48));
			$ci['image_offset'] = ftell($f);
			$ci['image'] = fread($f, $ff['image_size']);
			$ci['clut_offset'] = ftell($f);
			$ci['clut']  = fread($f, $ff['clut_size']);
			$ci['clut_p'] = array();
			$cll = $ci['info']['clut_colors'];

			/*if ($n >= 0 && $n <= 1) {
				$data = pack('N*', 0xCACAA500, 0xCACAA522, 0xCACAA542, 0xCACAA562, 0xCACAA57F, 0xCBCAA6A4, 0xCBCAA6BE, 0xCBCAA6E2, 0x3E2A1FFF, 0x564436FF, 0x655646FF, 0x847862FF, 0xA29C7FFF, 0xB2AE8EFF, 0xC1BF9DFF, 0xCBCAA6FF);
				$ci['clut'] = $data . substr($ci['clut'], strlen($data));
				$cll = 16;
				
				//echo "{$tm2}-{$ff['clut_size']}\n";
			}*/
			
			//if ($cll > 24) $cll = 24;
			//echo "$n\n";
			for ($m = 0; $m < $cll; $m++) {
				list(,$c) = unpack('N', substr($ci['clut'], $m * 4, 4));
				$ci['clut_p'][] = sprintf('#%08X', $c);
				//printf("%02d: %08X\n", $m, $c);
			}
			
			if ($ci['info']['image_type'] == 5) {
				// Unswizzle
				for ($_n = 8; $_n < 256; $_n += 4 * 8) for ($_m = 0; $_m < 8; $_m++) {
					swap(
						$ci['clut_p'][$_n + $_m],
						$ci['clut_p'][$_n + $_m + 8]
					);
				}
			}
			

			/*if ($n == 0 || $n == 1) {
				print_r($ci['clut_p']);
				exit;
			}*/

			//$ci['image'] = $ci['clut'] = '';
		}
		
		//$d = $ii[0]; $d['image'] = ''; $d['clut'] = ''; print_r($d);
		
		fclose($f);
		
		return $ii;
	}

	function color_alpha_comp($a, $b) {
		return (
			((0xFF - abs($a[0] - $b[0])) *  1) +
			((0xFF - abs($a[1] - $b[1])) *  1) +
			((0xFF - abs($a[2] - $b[2])) *  1) +
			((0xFF - abs($a[3] - $b[3])) * 10) +
		0);
	}
	
	function color_alpha_check($cc, $c) {
		$r = 0;
		$mw = null;
		foreach ($cc as $k => $c1) {
			$w = color_alpha_comp($c1, $c);
			if (!isset($mw) || ($w > $mw)) {
				$mw = $w;
				$r = $k;
			}
		}
		return $r;
	}
	
	function update_tm2_image(&$ti, $i) {
		list($w, $h) = array($ti['info']['width'], $ti['info']['height']);
		$ci = new Image(1, 1, 8); // clut image
		
		$tii = $ti['info'];
		
		// $tii['image_type'] 4 -> 16 colores | 5 -> 256 colores
		
		//image_type
		
		$colors = array();
		
		foreach ($ti['clut_p'] as $c) {
			$ci->color($c);
			$colors[] = array(hexdec(substr($c, 1, 2)), hexdec(substr($c, 3, 2)), hexdec(substr($c, 5, 2)), (int)(0x7F - ((hexdec(substr($c, 7, 2)) * 0x7F) / 0xFF)));
		}
		
		//print_r($colors); exit;
		
		//$cs = array(); foreach ($ti['clut_p'] as $c) $cs[] = $ci->color($c);
		
		if (($w != $i->w) || ($h != $i->h)) throw(new Exception("Size mismatch"));
		
		//print_r($cs); exit;
		
		//echo "$w, $h\n";
		//echo strlen($ti['image']);
		
		$ctrans = array();
		
		switch ($tii['image_type']) {
			case 4:
				for ($y = 0, $n = 0; $y < $h; $y++) {
					for ($x = 0; $x < $w; $x += 2, $n++) {
						$c = ord($ti['image'][$n]);
						$_c1 = $c1 = ($c >> 0) & 0x0F;
						$_c2 = $c2 = ($c >> 4) & 0x0F;
						
						$cc = imagecolorat($i->i, $x + 0, $y);
						if (!isset($ctrans[$cc])) {
							$b = (($cc >>  0) & 0xFF); $g = (($cc >>  8) & 0xFF); $r = (($cc >> 16) & 0xFF); $a = (($cc >> 24) & 0xFF);
							$ctrans[$cc] = color_alpha_check($colors, array($r, $g, $b, $a));
						}
						
						$c1 = $ctrans[$cc];
						
						$cc = imagecolorat($i->i, $x + 1, $y);
						if (!isset($ctrans[$cc])) {
							$b = (($cc >>  0) & 0xFF); $g = (($cc >>  8) & 0xFF); $r = (($cc >> 16) & 0xFF); $a = (($cc >> 24) & 0xFF);
							$ctrans[$cc] = color_alpha_check($colors, array($r, $g, $b, $a));
						}
						$c2 = $ctrans[$cc];
						
						$ti['image']{$n} = chr((($c1 & 0x0F) << 0) | (($c2 & 0x0F) << 4));
					}
				}
			break;
			case 5:
				for ($y = 0, $n = 0; $y < $h; $y++) {
					for ($x = 0; $x < $w; $x++, $n++) {
						$c = ord($ti['image'][$n]);
						$_c1 = $c1 = ($c >> 0) & 0x0F;
						$_c2 = $c2 = ($c >> 4) & 0x0F;
						
						$cc = imagecolorat($i->i, $x + 0, $y);
						
						if (!isset($ctrans[$cc])) {
							$b = (($cc >>  0) & 0xFF); $g = (($cc >>  8) & 0xFF); $r = (($cc >> 16) & 0xFF); $a = (($cc >> 24) & 0xFF);
							$ctrans[$cc] = color_alpha_check($colors, array($r, $g, $b, $a));
						}
						
						$c1 = $ctrans[$cc];
						
						$ti['image']{$n} = chr($c1);
					}
				}				
			break;
			default: throw(new Exception("Unknown image_type:{$tii['image_type']}"));
		}
	}
	
	function update_tm2($name, $tm2) {
		if (!($f = fopen($name, 'r+b'))) throw(new Exception("Can't open tm2"));
		foreach ($tm2 as $i) {
			fseek($f, $i['image_offset']);
			fwrite($f, $i['image']);
			fseek($f, $i['clut_offset']);
			fwrite($f, $i['clut']);
		}
	}	
?>