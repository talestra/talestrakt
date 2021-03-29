<?php
	function lzma($data) {
		file_put_contents('in', $data);
		system("lzma.exe e in out");
		$data = @file_get_contents('out');
		@unlink('in');
		@unlink('out');
		return $data;
	}
	
	$tree = array();
	$size = array();
	
	function tree($path, $base = '') {
		global $tree, $size;
		foreach (scandir($path) as $file) { $rfile = "{$path}/{$file}"; $bfile = ltrim("{$base}/{$file}", '/');
			if (substr($file, 0, 1) == ".") continue;
			if (is_dir($rfile)) {
				$tree[] = $bfile;
				tree($rfile, $bfile);
			} else {
				$tree[] = $bfile;
				$size[$bfile] = filesize($rfile);
				//echo "$bfile\n";
			}
		}
	}
	
	tree($root = '../../patch');
	
	$patches = array();
	
	$f = fopen('../../patch.bin', 'wb');
	fwrite($f, 'Tales Translations - soywiz - 2008 :3');
	fwrite($f, pack('V', sizeof($tree)));
	foreach ($tree as $fn) {
		$patches[$fn] = ftell($f);
		fwrite($f, pack('V', 0));
		fwrite($f, pack('V', 0));
		fwrite($f, chr(0));
		fwrite($f, pack('V', strlen($fn)));
		fwrite($f, $fn);
	}
	
	foreach ($tree as $fn) { $rfile = "{$root}/{$fn}";
		$at = 0;
		$data = '';
	
		echo "$fn\n";
		if (is_dir($rfile)) {
			$at |= 1;
		} else {
			$data = file_get_contents($rfile);
		}
		
		//if ($comp) $data = lzma($data);
		
		$dpos = ftell($f);
		fseek($f, $patches[$fn]);
		fwrite($f, pack('V', $dpos));
		fwrite($f, pack('V', strlen($data)));
		fwrite($f, chr($at));
		
		fseek($f, $dpos);
		if (!($at & 1)) {
			fwrite($f, $data);
		}
		
		fflush($f);
	}
	
	$mask = array(0xF3,0x76,0x39,0x03,0x32,0x92,0x11,);
	
	file_put_contents('../../patch.bin.lzma', lzma(file_get_contents("../../patch.bin")));
	
	$data = file_get_contents("../../patch.bin.lzma");
	$ml = sizeof($mask);
	for ($n = 0, $l = strlen($data); $n < $l; $n++) {
		$data{$n} = chr((ord($data[$n]) ^ $mask[$n % $ml]) - $n);
	}
	file_put_contents("../../patch.bin.lzma.enc", $data);
?>