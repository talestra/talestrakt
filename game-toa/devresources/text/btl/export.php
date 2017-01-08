<?php
	$db = new PDO('sqlite:btsc.db'); 

	echo '<html><head>';
?>
<style>
h1 {
	background: #f8e3e7;
	padding-left: 10px;	
	font: 30px Arial;
}

h2 {
	background: white;
	color: #605f1a;
	font: 20px Arial;
	padding-left: 6px;
	margin: 0;
}

p {
	font: 12px Arial;
	padding: 2px 10px;
	white-space: pre;
}

p.otext {
	background: #e3edf8;
	margin: 0;
}
p.text {
	background: #e3f8ed;
	margin: 0;
	margin-bottom: 18px;
	color: #c42d4b;
}
</style>
<?php
	echo '</head><body>';
	
	$bs = '';
	
	foreach ($db->query('SELECT * from texts;') as $row) {
		$s = "{$row['file']}_{$row['sid']}";
		if ($bs != $s) {			
			echo '<h1>' . $s . '</h1>';			
			$bs = $s;
		}
		
		echo "<h2>{$row['title']}</h2>";
		echo "<p class=\"otext\">" . htmlspecialchars($row['otext']) . "</p>\n";
		echo "<p class=\"text\">" . htmlspecialchars($row['text']) . "</p>\n";
	}	
	echo '</body></html>';
?>