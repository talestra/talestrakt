<?php
	for ($n = 0; $n < 538; $n++) {
		$name = sprintf('skits/CHT_%03d.SKT', $n);
		echo "$name...";
		if (!file_exists("{$name}.u")) {
			system("comptoe.exe -s -d {$name} {$name}.u");
		}
		echo "\n";
	}
?>