<?php
	require_once('gen_image.php');

	function processBlock($i, $rx, $ry) {
		$px = $rx * 64; $py = $ry * 64;
		$mx = 0;
		for ($y = 0; $y < 64; $y++) {
			//for ($x = 0; $x < 64; $x++) {
			for ($x = 0; $x < 63; $x++) {
				$a = 1 - ((imagecolorat($i, $x + $px, $y + $py) >> 24) / 0x7F);
				if ($a > 0 && $x > $mx) $mx = $x;
				//echo "$alpha,";
			}
			//echo "\n";
		}
		//echo "$mx\n";
		return $mx + 1;
	}
	
	function getWidths() {
		if (!file_exists('font.widths')) {
			$wds = array();
			$i = Image::fromFile('font/fuente-titulos.png');
			for ($y = 0; $y < 3; $y++) for ($x = 0; $x < 26; $x++) $wds[] = processBlock($i->i, $x, $y);
			file_put_contents('font.widths', json_encode($wds));
		}
		$wds = json_decode(file_get_contents('font.widths'));
		return $wds;
	}
	
	function getTasks() {
		$r = array();
		$f = file('list.txt');
		while (true) {
			if (current($f) === false) break;
			$t = trim(current($f));
			$t1 = trim(next($f));
			$t2 = trim(next($f));
			next($f); next($f);
			$r[$t] = array($t1, $t2);
		}
		return $r;
	}
	
	function drawBorder($i, $f, $x, $y, $text, $c1, $c2) {
		$i->drawText($f, $x - 2, $y + 0, $text, $c2);
		$i->drawText($f, $x + 3, $y + 0, $text, $c2);
		$i->drawText($f, $x + 0, $y - 2, $text, $c2);
		$i->drawText($f, $x + 0, $y + 2, $text, $c2);
		$i->drawText($f, $x + 1, $y - 2, $text, $c2);
		$i->drawText($f, $x + 1, $y + 2, $text, $c2);
		
		$i->drawText($f, $x - 1, $y + 1, $text, $c2);
		$i->drawText($f, $x - 1, $y - 1, $text, $c2);
		$i->drawText($f, $x + 2, $y + 1, $text, $c2);
		$i->drawText($f, $x + 2, $y - 1, $text, $c2);

		$i->drawText($f, $x + 0, $y + 0, $text, $c1);
		$i->drawText($f, $x + 1, $y + 0, $text, $c1);
	}
	
	function prepare() {
		global $tsk, $wss, $ws, $fis, $fs, $red_widths, $adjust;
	
		$tsk = getTasks();
		$wss = getWidths();
		
		$fs = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.,1234567890ñáéíóú          ';
		$fi = Image::fromFile('font/fuente-titulos.png');
		$ws = $fis = array();
		for ($y = 0, $n = 0; $y < 3; $y++) for ($x = 0; $x < 26; $x++, $n++) {
			$fis[$fs[$n]] = $fi->slice($x * 64, $y * 64, $wss[$n], 64);
			$ws[$fs[$n]] = $wss[$n];
		}
		
		$red_widths = array(
			'V' => -5,
			'T' => -3,
			'P' => -3,
			'Y' => -5,
		);
		
		$adjust = array();
		foreach (file('adjust.txt') as $l) { $l = trim($l);
			list($name, $params) = explode(' ', $l, 2);
			$name = trim($name);
			$params = trim(preg_replace('/\\s+/', ' ', strtr($params, '(),', '   ')));
			$params = explode(' ', $params);
			//echo "$name, $params\n";
			if (!isset($params[2])) $params[2] = 0;
			//print_r($params);
			$adjust[$name] = $params;
		}
	}
	
	function getSmall($text, $p, $path2, $t_name) {
		if ($text == '-') $text = '';

		$io = Image::fromFile($path2);
		$i = new Image($io->w, $io->h);
		$w = $i->w;
		
		$mw = $w;
		if ($mw > 320) $mw = 320;
		
		switch ($t_name) {
			case 'TV_NAM': $mw = 140; break;
			case 'TV_YUR': $mw = 216; break;
		}
		
		$fsize = 19;
		$scale = 1;
		
		while (true) {
			$f = new Font('optima.TTF', $fsize);
			$size = $f->getBox($text);
			
			if ($size[0] < $mw - 4) break;
			$fsize--;
			if ($fsize < 1) break;
		}
		
		$scale = $fsize / 19;
		
		if ($scale) {
			$f = new Font('optima.TTF', 19);
			$i2 = new Image((int)($i->w / $scale), (int)($i->h / $scale));
			drawBorder($i2, $f, 2, 4 + 19 * (1 - $scale), $text, $i->color('#3e2a20'), $i->color('#cbcaa6'));
			//drawBorder($i2, $f, 2, 4, $text, $i->color('#3e2a20'), $i->color('#cbcaa6'));
			//drawBorder($i2, $f, 2, 9, $text, $i->color('#3e2a20'), $i->color('#cbcaa6'));
			$i2->putResampled($i);
			
			//$i2 = new Image($i->w, $i->h);
			//$i->put(0, 0, $i2);
			//$i = $i2;
		} else {
			$size[0] = 0;
		}

		/*$chunk = sprintf("ACHUNK: %3d, (%3d, %3d, %3d, %3d), (%3d, %3d)\n",
			$p['time'],
			0, 0,
			$w, 32,
			$p['x'], $p['y']
		);*/
		
		$chunk = array($p['time'], 0, 0, $w, 32, $p['x'], $p['y']);

		return array($i, $chunk, ceil($size[0]));
	}
	
	function getBig($s, $p, $path2, $small_size, $achunk_count, $t_name) {
		global $ws, $fis, $red_widths;
		$io = Image::fromFile($path2);
		$i = new Image($io->w, $io->h);
		$w = $i->w;
		$x = $y = 0;
		
		$big_x = $p['x'];
		$big_y = $p['y'];
		$time = $p['time'];
		$time_inc = $p['time_s'];
		
		$chunks = array();
		
		for ($n = 0, $l = strlen($s); $n < $l; $n++) { $c = $s{$n};
			if ($c == ' ') {
				$big_x += 10;
				$time += $time_inc;
				continue;
			}

			//$x += $ws[$c] + 2;
			//$big_x += $ws[$c] + 2;
			$x += $ws[$c];
			$big_x += $ws[$c];
			$time += $time_inc;
			//echo "$c";
		}
		
		$scale = 1.0;
		
		$rw = $w;
		
		if ($rw > 480) $rw = 480;
		
		if ($small_size + $rw >= 480) {
			$rw = 480 - $small_size;
		}
		
		if ($x > $rw) {
			$scale = $rw / $x;
			//echo "$scale\n";
		}
		
		//echo "{$big_x}\n";

		$big_x = $p['x'];
		$big_y = $p['y'];
		$time = $p['time'];
		$time_inc = $p['time_s'];
		$x = $y = 0;
		
		$schunks = get_chunks($s, $achunk_count);
		
		//print_r($schunks); exit;
		
		foreach ($schunks as $sc) {
			if ($sc == ' ') {
				$big_x += 10 * $scale;
				$time += $time_inc;
				continue;
			}
			
			$x1 = $x;
			
			//echo "$big_x\n";
			
			$big_x2 = $big_x;
			
			for ($n = 0; $n < strlen($sc); $n++) { $c = $sc[$n];
				$dx = $fis[$c]->w * $scale;
			
				// Generate resampled glyph
				$ci = new Image($fis[$c]->w * $scale, $fis[$c]->h * $scale); $fis[$c]->putResampled($ci);
				
				$i->put($x, $y + $fis[$c]->h * (1 - $scale), $ci);
				//$i->put($x, $y, $ci);
				
				$x += $dx;
				$big_x += $dx;
				
				if (isset($red_widths[$c])) {
					if ($n < strlen($sc) - 1) $x += $red_widths[$c] * $scale;
					$big_x += $red_widths[$c] * $scale;
				}
				//echo "$n";
			}
			//echo ";";

			$time += $time_inc;

			$chunks[] = array($time, $x1, 0, $x, 64, $big_x2, $big_y);
		}
		echo "\n";
	
		return array($i, $chunks, $x);
	}
	
	function parseAChunk($l) {
		preg_match_all('(\d+)', $l, $r);
		return $r[0];
	}
	
	function getAttribs($name) {
		$l = file("zANI/{$name}.txt");
		$count = trim($l[11]); preg_match('/\\d+/', $count, $r); $count = $r[0];

		$small = parseAChunk(trim($l[8]));
		$big   = parseAChunk(trim($l[12]));
		$big2  = parseAChunk(trim($l[13]));
		
		$chunks = array();
		for ($n = 0; $n < $count; $n++) {
			$chunks[] = parseAChunk(trim($l[$n + 12]));
		}
		
		//print_r($big);
		
		return array(
			'small' => array(
				'time' => $small[0],
				'x'    => $small[5],
				'y'    => $small[6],
			),
			'big' => array(
				'time'   => $big[0],
				'time_s' => $big2[0] - $big[0],
				'count'  => $count,
				'x'      => $big[5],
				'y'      => $big[6],
				'chunks' => $chunks,
			),
			'lines' => $l,
		);
	}
	
	function perform() {
		global $tsk, $adjust;
		// Slice
		//$tsk = array_slice($tsk, 1, 1);
		
		foreach ($tsk as $t_name => $t_data) {
			//if ($t_name != 'TV_SNP') continue;
			
			switch ($t_name) {
				//default: continue 2;
				case 'TV_AJI':
				case 'TV_DIS':
			}

			echo "{$t_name}\n";
			
			if (isset($adjust[$t_name])) {
				$cadjust = $adjust[$t_name];
			} else {
				$cadjust = array(0, 0, 0);
			}
			
			//print_r($cadjust);
			
			@mkdir($path1 = "TM2/{$t_name}.TM2");
			
			$at = getAttribs($t_name);
			
			//print_r($at);

			sscanf($at['lines'][0], 'POS: %d', $align);
			sscanf($at['lines'][11], "# GLYPH ACHUNKS (%d)", $achunk_count);
			
			//echo $achunk_count; exit;
			
			switch ($align) {
				case 0: $align_x = -1; $align_y = -1; break;
				case 1: $align_x = +1; $align_y = -1; break;
				case 2: $align_x = -1; $align_y = +1; break;
				case 3: $align_x = +1; $align_y = +1; break;
			}
			
			list($i, $ac_small, $small_size) = getSmall($t_data[0], $at['small'], "_{$path1}/000.png", $t_name);
			$i->save("{$path1}/000.png");
			
			list($i, $ac_big, $big_size) = getBig($t_data[1], $at['big'], "_{$path1}/001.png", $small_size, $achunk_count, $t_name);
			$i->save("{$path1}/001.png");
			
			
			$margin = 120;

			$ac_big_o = $ac_big;
			
			// Alineado a la izquierda
			if ($align_x == -1) {
				$xx = $margin;
				$ac_small[5] = $xx;
				if ($small_size) $xx += $small_size + 16;
				$base_x = $ac_big_o[0][5];
				foreach ($ac_big as $k => $a) {
					$ac_big[$k][5] -= $base_x;
					$ac_big[$k][5] += $xx;
				}
			}
			// Alineado al a derecha
			else {
				$xx = $margin;
				$last = $ac_big[sizeof($ac_big) - 1];
				$base_x = 640 - ($last[5] + ($last[3] - $last[1]));
				//$base_x = $ac_big_o[0][5];
				//echo "$base_x";
				$last_x = 640;
				foreach ($ac_big as $k => $a) {
					$ac_big[$k][5] += $base_x;
					$ac_big[$k][5] -= $xx;
				}

				$last_x = $ac_big[0][5];
				
				$ac_small[5] = $last_x - $small_size - 16;
			}
			
			$ac_fonic = parseAChunk(trim($at['lines'][9]));
			
			$ac_fonic[5] += $cadjust[2];
			
			$at['lines'][8] = vsprintf("ACHUNK: %3d, (%3d, %3d, %3d, %3d), (%3d, %3d)\n", $ac_small);
			$at['lines'][9] = vsprintf("ACHUNK: %3d, (%3d, %3d, %3d, %3d), (%3d, %3d)\n", $ac_fonic);

			//array_splice($at['lines'], 12, $at['big']['count'], $ac_big);
			
			//reduce_chunks($ac_big, $achunk_count);
			
			foreach ($ac_big as $k => $a) {
				$a[0] = $at['big']['chunks'][$k][0];

				$a[5] += $cadjust[0];
				$a[6] += $cadjust[1];

				//print_r($a);
				$at['lines'][12 + $k] = vsprintf("ACHUNK: %3d, (%3d, %3d, %3d, %3d), (%3d, %3d)\n", $a);
			}
			
			//$at['lines'] = 
			
			//$at['lines'][11] = "# GLYPH ACHUNKS (" . sizeof($ac_big) . ")\n";
			
			file_put_contents("ANI/{$t_name}.txt", implode('', $at['lines']));
			copy("_{$path1}/002.png", "{$path1}/002.png");
			copy("_{$path1}/003.png", "{$path1}/003.png");
			
			@mkdir("out/{$t_name}/", true);
			//copy("{$path1}/000.png", "out/{$t_name}/0.png");
			//copy("{$path1}/001.png", "out/{$t_name}/1.png");

			if (true) {
				copy("R_tm2/{$t_name}.TM2", "out/{$t_name}/tm2");
				$tm2 = process_tm2("out/{$t_name}/tm2");
				update_tm2_image($tm2[0], Image::fromFile("{$path1}/000.png"));
				update_tm2_image($tm2[1], Image::fromFile("{$path1}/001.png"));
				update_tm2("out/{$t_name}/tm2", $tm2);
				copy("out/{$t_name}/tm2", "ntm2/{$t_name}.tm2");
			}
			
			//exit;
			
			file_put_contents("out/{$t_name}/animation", compile_script(file_get_contents("ANI/{$t_name}.txt")));

			//exit;
			
			//print_r($at['lines']);
		}
	}
	
	function compile_script($data) {
		$out = '';
		foreach (explode("\n", $data) as $l) { $l = trim($l);
			if (!strlen($l)) continue;
			
			if ($l[0] == '#') {
				if (sscanf($l, '# GLYPH ACHUNKS (%d)', $count)) {
					$out .= pack('V', $count);
				}
				continue;
			}
			
			list($type, $params) = explode(':', $l, 2);
			$type = strtoupper(trim($type));
			$p = explode(',', strtr($params, array('(' => '', ')' => '', ' ' => '')));
			switch ($type) {
				case 'POS': case 'UN1': case 'UN2':
					$out .= pack('V', $p[0]);
				break;
				case 'COLOR0': case 'COLOR1':
					$c = explode("\n", chunk_split(substr($p[0], 1), 2, "\n"));
					$out .= pack('VVV', hexdec($c[0]), hexdec($c[1]), hexdec($c[2]));
				break;
				case 'ACHUNK':
					//print_r($p); exit;
					$out .= pack('VVVVVVV', $p[0], $p[1], $p[2], $p[3], $p[4], $p[5], $p[6]);
				break;
				default:
					echo "Unknown {$type}\n";
				break;
			}
			//echo "$type:"; print_r($params);
		}
		return $out;
	}
	
	function get_chunks($s, $count) {
		$cs = explode(' ', $s);
		$cc = array();
		foreach ($cs as $c) {
			$cc[] = $c;
			$cc[] = ' ';
			$count++;
		}
		array_pop($cc); $count--;
		
		echo "get_chunks('$s', $count);\n";
		
		while (sizeof($cc) < $count) {
			$i = -1;
			$s = 1;
			foreach ($cc as $ci => $c) {
				if ($c == ' ') continue;
				if (strlen($c) > $s) {
					$s = strlen($c);
					$i = $ci;
				}
			}
			if ($i == -1) {
				$cc[] = '';
				//print_r($cc);
				//throw(new Exception("Can't subdivide"));
				continue;
			}
			
			$div = 2;

			if ($count - sizeof($cc) >= 2) {
				if (strlen($c) > 6) {
					$div = 3;
				}
			}
			
			switch ($div) {
				case 2:
					$mid = round($s / 2);
					$c1 = substr($cc[$i], 0, $mid);
					$c2 = substr($cc[$i], $mid);
					array_splice($cc, $i, 1, array($c1, $c2));
				break;
				case 3:
					$mid = $s / 3;
					$s1 = floor($mid);
					$s2 = $s - ($s1 * 2);
					$c1 = substr($cc[$i], 0, $s1);
					$c2 = substr($cc[$i], $s1, $s2);
					$c3 = substr($cc[$i], $s1 + $s2, $s2);
					array_splice($cc, $i, 1, array($c1, $c2, $c3));
				break;
			}
				//echo "$c1\n$c2";
				//exit;
		}
		
		return $cc;
	}
	
	//print_r(get_chunks('La fábrica abandonada', 6)); exit;
	
	//file_put_contents('test.anm', compile_script(file_get_contents('ANI/TV_AJI.txt'))); exit;
	
	prepare();
	perform();
	
	system('tm2png ntm2');
?>