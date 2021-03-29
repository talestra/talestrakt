<?php

foreach (glob(__DIR__ . '/texts/*.txt') as $file2) {
	$fileBase = basename($file2);
	$file1 = __DIR__ . '/../' . $fileBase;

	if (!is_file($file1)) {
		echo "missing {$file1}\n";
		continue;
	}
	
	$text1 = file_get_contents($file1);
	$text2 = file_get_contents($file2);
	
	foreach (array(
		'/^@\d+/msi',
		'/^<en>.*$/Umsi',
	) as $pattern) {
		preg_match_all($pattern, $text1, $matches1);
		preg_match_all($pattern, $text2, $matches2);

		$matches1_count = count($matches1[0]);
		$matches2_count = count($matches2[0]);
		
		//echo "$file1\n";
		//print_r($matches1);
		//print_r($matches2);

		if ($matches1_count != $matches2_count) {
			echo "Text count mismatch {$matches1_count} != {$matches2_count} on '{$fileBase}'\n";
			continue;
		}
		
		$pos = 0;
		$text1 = preg_replace_callback($pattern, function($match) {
			global $matches1, $matches2, $pos;
			return $matches2[0][$pos++];
			//return $match[0];
		}, $text1);
	}
	
	file_put_contents($file1, $text1);
	
	//die("end\n");
}