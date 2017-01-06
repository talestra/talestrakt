<?php

// MGD
// 0x00 - DWORD - 'MGD '
// 0x0C - WORD  - Width
// 0x0E - WORD  - Height
// 0x14 - DWORD - Size
// 0x5C - DWORD - FileSize

$opcodes = array(
	0 => 'VALUE',
	1 => 'FUNC_START',
	2 => 'SCRIPT',
	3 => 'FUNC_END',
	4 => 'SWITCH',
	5 => 'SET_GLOBAL',
	6 => 'JUMP_IF',

	100 => 'BUFFER_SET',
	101 => 'IMAGE_UNSET',
	102 => 'IMAGE_SET',
	103 => 'IMAGE_POSITION',
	106 => 'IMAGE_SET_FROM_BUFFER',
	107 => 'IMAGE_DRAW',
	110 => 'ANIMATE',

	201 => 'MUSIC_PLAY',
	211 => 'SOUND_EFFECT',

	1001 => 'SAVE_POINT',
	1005 => 'SAVE_TITLE',

	2001 => 'TEXT_COLOR',
	2007 => 'CHARA_ID',
	2008 => 'VOICE',
	2009 => 'WAIT_CLICK',
	2010 => 'TEXT',

	2020 => 'COLOR_UNK',

	10000 => 'END',
);

function decrypt_msd($data) {
	$base = "\x82\xBB\x82\xCC\x89\xD4\x82\xD1\x82\xE7\x82\xC9\x82\xAD\x82\xBF\x82\xC3\x82\xAF\x82\xF0";

	for ($n = 0, $num = 0; $n < strlen($data); $n += 0x20, $num++) {
		$md5 = md5(sprintf('%s%d', $base, $num));
		//echo "$md5\n";
		$blen = min(0x20, strlen($data) - $n);
		for ($m = 0; $m < $blen; $m++) {
			@$data[$n + $m] = chr(ord($data[$n + $m]) ^ ord($md5[$m]));
		}
		//exit;
	}

	return $data;
}

class ParamVariableReference {
	public $id;

	public function __construct($id) {
		$this->id = $id;
	}

	public function __toString() {
		return '$' . $this->id;
	}
}

// CSnrBuffer::NextParam
function ExtractParameters($data) {
	$params = array();
	$pos = 0;
	$len = strlen($data);
	while ($pos < $len) {
		switch ($type = ord($data[$pos])) {
			case 3:
				$spos = ++$pos;
				while ($pos < $len && $data[$pos] != "\0") $pos++;
				//$params[] = $type . ':"' . substr($data, $spos, $pos - $spos) . '"';
				$params[] = substr($data, $spos, $pos - $spos);
				$pos++;
				//print_r($params);
			break;
			case 4:
				//exit;
				$pos++;
				$params2 = array();
				while ($pos < $len) {
					list(,$k, $v) = unpack('V2', substr($data, $pos, 8)); $pos += 8;
					//if ($k == 0xFFFFFFFF) break;
					if ($k == -1) break;
					//printf("%08X, %08X\n", $k, $v);
					$params2[] = sprintf('%d:%d', $k, $v);
				}
				//file_put_contents('_TEMP', $data);
				$params[] = '[' . implode(', ', $params2) . ']';
			break;
			case 1:
			case 2:
			case 5:
				$pos++;
				list(,$v) = unpack('V', substr($data, $pos, 4));
				$pos += 4;
				switch ($type) {
					case 1: $params[] = $v; break;
					case 2: $params[] = new ParamVariableReference($v); break;
					case 5: $params[] = "???$v"; break;
				}
			break;
			default: throw(new Exception("Unknown parameter type {$type}"));
		}
	}
	return $params;
}

function EncodeParams($params) {
	$params2 = array();
	foreach ($params as $param) {
		if (is_string($param)) {
			$params2[] = '"' . addslashes($param) . '"';
		} else {
			$params2[] = (string)$param;
		}
	}
	return implode(', ', $params2);
}

function ProcessFile($file) {
	global $opcodes;
	$f = fopen($file, 'rb');
	fseek($f, 0x14);
	list($count1, $count2) = array_values(unpack('V2', fread($f, 8)));
	//echo "$count1, $count2\n";
	fseek($f, 0x458);

	$chara_ids = array(
		-1 => '-',
		0 => 'NANA',
		1 => 'YUUNA',
		2 => 'GIRL_A',
		3 => 'GIRL_B',
		4 => 'GIRL_C',
		5 => 'TEACHER',
		6 => 'CHILD_A',
		7 => 'CHILD_B',
		8 => '???',
	);

	$labels = array();
	for ($n = 0; $n < $count1; $n++) {
		list(,$v) = unpack('V', fread($f, 4));
		$labels[$v] = $n;
		//printf("LABEL($n):(%08X)\n", $v);
	}

	$functions = array();
	for ($n = 0; $n < $count2; $n++) {
		list(,$v) = unpack('V', fread($f, 4));
		$functions[$v] = $n;
		//printf("FUNC($n):(%08X)\n", $v);
	}

	$dialogs = array();
	$chara_id = -1;
	$pos_start = ftell($f);
	while (!feof($f)) {
		$pos = ftell($f);
		$opdata = fread($f, 4);
		if (strlen($opdata) < 4) break;
		list($opcode, $len) = array_values(unpack('v2', $opdata));
		$data = ($len > 0) ? fread($f, $len) : '';
		$params = ExtractParameters($data);
		$ins_pos = $pos - $pos_start;
		if (isset($functions[$ins_pos])) {
			printf("FUNCTION(%d):\n", $functions[$ins_pos]);
		}
		if (isset($labels[$ins_pos])) {
			printf("LABEL(%d):\n", $labels[$ins_pos]);
		}
		printf("[%08X]:", $ins_pos);
		//echo "{$opcode}({$len}): (" . implode(", ", $params) . ")\n";
		$opcode_name = &$opcodes[$opcode];
		if (!isset($opcode_name)) $opcode_name = $opcode;
		echo "{$opcode_name}(" . EncodeParams($params) . ")\n";
		if ($opcode_name == 'CHARA_ID') {
			$chara_id = $params[0];
		}
		if ($opcode_name == 'TEXT') {
			$text_id = $params[0];
			$text_text = $params[3];
			$dialogs[$text_id] = array($chara_ids[$chara_id], trim(preg_replace('#\s*\x81@\x81@#', "\n", $text_text)));
			//echo "$chara_id\n";
		}
		//print_r($params);
		//exit;
	}

	//print_r($dialogs);
	return $dialogs;
}

function extract_fjsys($fjsys_file) {
	$f = fopen($fjsys_file, 'rb');
	if (rtrim(fread($f, 8), "\0") != "FJSYS") throw(new Exception("FJSYS"));
	fseek($f, 0x0C); $table_strings_size = unpack('V', fread($f, 4))[1];
	fseek($f, 0x10); $count = unpack('V', fread($f, 4))[1];

	$table_strings_start = 0x54 + $count * 0x10;
	$table_files_start   = $table_strings_start + $table_strings_size;

	$table_files_pos = $table_files_start;

	$files = array();
	fseek($f, $table_strings_start); $table_strings = fread($f, $table_strings_size);
	fseek($f, 0x4C);
	for ($n = 0; $n < $count; $n++) {
		list(,$dummy, $dummy, $name_start, $data_size) = unpack('V4', fread($f, 4 * 4));
		list($name) = explode("\0", substr($table_strings, $name_start), 2);
		//echo "$name_start : $name\n";
		$files[] = array('name' => $name, 'offset' => $table_files_pos, 'size' => $data_size);
		$table_files_pos += $data_size;
	}

	foreach ($files as $file) {
		$rfile = "{$fjsys_file}.D/{$file['name']}";
		@mkdir(dirname($rfile), 0777, true);
		echo "{$file['name']}...";
		if (!is_file($rfile)) {
			fseek($f, $file['offset']);
			$data = fread($f, $file['size']);
			file_put_contents($rfile, $data);
			echo "Ok\n";
		} else {
			echo "Exists\n";
		}

		if (substr($rfile, -4) == '.MGD') {
			if (!is_file("{$rfile}.png")) {
				fseek($f, $file['offset']);
				$data = fread($f, $file['size']);
				file_put_contents("{$rfile}.png", substr($data, 0x60));
			}
		}

		if (substr($rfile, -4) == '.MSD') {
			if (!is_file("{$rfile}.decrypt")) {
				fseek($f, $file['offset']);
				$data = fread($f, $file['size']);
				if (substr($data, 0, 0x10) != 'MSCENARIO FILE  ') {
					$data = decrypt_msd($data);
				}
				file_put_contents("{$rfile}.decrypt", $data);
			}
			ob_start();
			$dialogs = ProcessFile("{$rfile}.decrypt");
			$data2 = ob_get_clean();
			file_put_contents("{$rfile}.scr", $data2);
			$acme_file = "{$fjsys_file}.D/src/{$file['name']}.txt";
			@mkdir(dirname($acme_file), 0777, true);
			@unlink($acme_file);
			if (count($dialogs)) {
				$f = fopen($acme_file, 'wb');
				foreach ($dialogs as $dialog_id => $dialog_data) {
					fprintf($f, "## POINTER %d\n", $dialog_id);
					$text = mb_convert_encoding($dialog_data[1], 'utf-8', 'shift_jis');
					fprintf($f, "%s\n%s\n\n", $dialog_data[0], $text);
				}
				fclose($f);
			}
			//file_put_contents($acme_file);
		}
	}
	//print_r($files);
}

//extract_fjsys('C:/juegos/Sono Hanabira ni Kuchizuke wo/BGM');
//extract_fjsys('C:/juegos/Sono Hanabira ni Kuchizuke wo/DATA');
//extract_fjsys('C:/juegos/Sono Hanabira ni Kuchizuke wo/MGD');
//extract_fjsys('C:/juegos/Sono Hanabira ni Kuchizuke wo/MGE');
//extract_fjsys('C:/juegos/Sono Hanabira ni Kuchizuke wo/MSD');
extract_fjsys('C:/juegos/Sono Hanabira ni Kuchizuke wo/MSE');
//extract_fjsys('C:/juegos/Sono Hanabira ni Kuchizuke wo/SE');
//extract_fjsys('C:/juegos/Sono Hanabira ni Kuchizuke wo/VOICE');

//ProcessFile('C:/juegos/Sono Hanabira ni Kuchizuke wo/MSE.d/TITLE.MSD.decrypt');
//ProcessFile('C:/juegos/Sono Hanabira ni Kuchizuke wo/MSE.d/start.MSD.decrypt');
//ProcessFile('C:/juegos/Sono Hanabira ni Kuchizuke wo/MSE.d/com.talestra.criminalgirls.main.MSD.decrypt');
//ProcessFile('C:/juegos/Sono Hanabira ni Kuchizuke wo/MSE.d/S001.MSD.decrypt');