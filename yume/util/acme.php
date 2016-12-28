<?php
	function fwrite_s($f, $s) { fwrite($f, pack('V', strlen($s))); fwrite($f, $s); }
	function fwrite4($f, $v) { fwrite($f, pack('V', $v)); }
	
	$list = array();

	foreach (scandir($path = '../acme') as $file) {
		if (substr($file, 0, 1) == '.') continue;
		$rfile = "{$path}/{$file}";
		list($kind) = explode('.', $file);
		list($name, $_id) = explode('$', $kind);
		$data = file_get_contents($rfile);
		foreach (array_slice(explode("## POINTER ", $data), 1) as $row) {
			list($line, $text) = explode("\n", $row, 2);
			$id = (int)$line; $text = trim($text);
			$list[$name][$id] = $text;
			//echo "$id: $text\n";
		}
	}
	
	$f = fopen('../res/data/text/es.bin', 'wb');
	foreach ($list as $name => &$items) {
		fwrite_s($f, $name);
		fwrite4($f, sizeof($items));
		foreach ($items as $k => $item) {
			fwrite4($f, $k);
			fwrite_s($f, $item);
		}
	}
	
	//print_r($list);
?>