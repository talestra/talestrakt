<?php
	$exe = file_get_contents('SLUS_213.86');
	function create($type) {
		echo "$type\n";
		global $exe;
		$f = fopen("{$type}.dump", 'wb');
		fseek($f, 0xFFF00);
		fwrite($f, $exe);
		fseek($f, 0x64B880);
		fwrite($f, file_get_contents("OV_PDVD_{$type}_US.OVL"));
	}
	
	create('BTL');
	create('FIELD');
	create('SKIT');
	create('SFD');
?>