<?php
	$zip = new ZipArchive;
	$res = $zip->open('yume.zip');
	$data = array();
	for ($n = 0; $i = $zip->statIndex($n); $n++) {
		$name = $i['name'];
		if (substr($name, 0, 4) != 'SRC/') continue;
		$zipentry = $zip->getFromIndex($n);
		list($block) = explode('$', substr($name, 4));
		foreach (array_slice(explode("## POINTER", $zipentry), 1) as $row) {
			$text = '';
			list($id, $text) = explode("\n", $row, 2);
			list($id) = explode(' ', trim($id));
			$text = trim($text);
			$data[$block][$id] = $text;
		}
		ksort($data[$block], SORT_NUMERIC);
	}
	ksort($data);
	
	function fwriteString4($f, $s) { fwrite($f, pack('V', strlen($s)) . $s); }
	function fwrite4($f, $v) { fwrite($f, pack('V', $v)); }
	
	@mkdir('res/data/text', 0777);
    @mkdir('res/data/script', 0777);
	if ($f = fopen('res/data/text/es.bin', 'wb')) {
		foreach ($data as $k => &$v) {
			fwriteString4($f, $k);
			fwrite4($f, sizeof($v));
			foreach ($v as $vk => $vv) {
				$vv = rtrim($vv);
				fwrite4($f, $vk);
				fwriteString4($f, $vv);
			}
		}
	}
    system("copy ..\\WS res\\data\\script");
?>
