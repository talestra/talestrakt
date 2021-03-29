import imports;
import dfl.all;
import dfl.internal.utf;

import test, test_psearch;
import check, npc, btl, skits, script, exe, misc, movie, field, lzma;
import btl_enm, pfs;
import http;

import form_progress, form_secret;

char[] patcher_path;

char[] fromAnsiS(char[] s) {
	return fromAnsi(s.ptr, s.length);
}

version (Windows) {
	import std.c.windows.windows;
	extern (Windows) HINSTANCE ShellExecuteA(HWND hwnd, LPCSTR lpOperation, LPCSTR lpFile, LPCSTR lpParameters, LPCSTR lpDirectory, INT nShowCmd);
	alias ShellExecuteA ShellExecute;
}

bool patchRunning = false;

import std.c.windows.windows;

void PlaySound(ubyte[] data, bool async = true) {
	PlaySoundA(cast(char*)data.ptr, null, SND_MEMORY | (async ? SND_ASYNC : 0)); 
}

Image appBG;
ubyte[] sndHover, sndClick, sndExit;

ubyte[] readStream(Stream s) {
	ubyte[] d; d.length = s.size;
	s.read(d);
	s.close();
	return d;
}

class ButtonSound : Button {
	void onMouseEnter(MouseEventArgs mea) {
		PlaySound(sndHover);
	}

	void onClick(EventArgs mea) {
		PlaySound(sndClick);
		super.onClick(mea);
	}
}

bool firstPainted = false;

class TransparentLabel : Label {
	this() {
		//foreColor = Color.fromRgb(0xFFFFFF);
		super();
	}
	override void onPaintBackground(PaintEventArgs pea) {
		//if (!firstPainted) return;
		auto g = pea.graphics;
		appBG.draw(g, Point(-left, -top));
	}
	
	override void onPaint(PaintEventArgs pea) {
		super.onPaint(pea);
	}
}

class TransparentLabelSound : TransparentLabel {
	void onMouseEnter(MouseEventArgs mea) {
		//PlaySound(sndHover);
	}

	void onClick(EventArgs mea) {
		PlaySound(sndClick);
		super.onClick(mea);
	}	
}

class MyForm : dfl.form.Form {
	// Do not modify or move this block of variables.
	//~Entice Designer variables begin here.
	dfl.textbox.TextBox textBox1;
	ButtonSound button1;
	dfl.textbox.TextBox textBox2;
	ButtonSound button2;
	ButtonSound button3;
	TransparentLabelSound label1;
	TransparentLabelSound label2;
	TransparentLabel label3;
	TransparentLabel slowLabel;
	TransparentLabel label7;
	TransparentLabel label8;
	dfl.label.Label label9;
	dfl.label.Label label10;
	//~Entice Designer variables end here.
	
	bool isClosed = false;
	
	static MyForm self;
	
	FormProgress formProgress;
	
	void closeFormProgress() {
		if (!formProgress) return;
		formProgress.close();
		formProgress = null;
	}
	
	override protected void onClosing(CancelEventArgs cea) {
		scope (exit) {
			if (!cea.cancel) {
				PlaySound(sndExit);
				Sleep(300);
				closeFormProgress();
			}
		}
		if (!patchRunning) {
			return;
		}
		switch (msgBox(this, "¿Cancelar el parcheo a mitad?", "Advertencia", MsgBoxButtons.YES_NO, MsgBoxIcon.ASTERISK, MsgBoxDefaultButton.BUTTON2)) {
			case DialogResult.YES: cea.cancel = false; break;
			case DialogResult.NO: cea.cancel = true; break;
		}	
		if (cea.cancel) return;
		patch_stop();
		int count = 5000;
		while (!patch_stopped) {
			Sleep(1);
			if (count-- <= 0) break;
		}
		isClosed = true;
	}
	
	void onKeyUpOriginal(Control c, KeyEventArgs kea)  {
		fenable();
	}
	
	this() {
		initializeMyForm();
		
		//@  Other MyForm initialization code here.

		appBG = dfl.drawing.Picture.fromStream(FS.patch["patcher/bg.jpg"].open);
		
		self = this;
		
		(new CheckVersion).start();
		
		textBox1.text = expandTilde(replace(iso_paths[0], "/", "\\"));
		textBox2.text = expandTilde(replace(iso_paths[1], "/", "\\"));
		
		textBox1.keyUp ~= &onKeyUpOriginal;
		button1.click ~= &onSelectOriginal;
		button2.click ~= &onSelectPatched;
		button3.click ~= &onPatch;
		this.acceptButton = button3;
		
		icon = new Icon(LoadIconA(GetModuleHandleA(null), cast(char*)101));
		
		text = "Tales of the Abyss (en español) :: Tales Translations :: Versión :: " ~ (cast(char[])(FS.patch["version.patch"].read) ~ " :: " ~ __TIMESTAMP__ ~ "");
		
		setClientSizeCore(640, 480);
		
		sndHover = readStream(FS.patch["patcher/cursor1.wav"].open);
		sndClick = readStream(FS.patch["patcher/cursor2.wav"].open);
		sndExit  = readStream(FS.patch["patcher/cursor3.wav"].open);
		
		fenable();
		
		button1.focus();
		
		label1.cursor = Cursors.hand;
		label2.cursor = Cursors.hand;
		label1.click ~= delegate void(Control c, EventArgs ea) {
			ShellExecuteA(null, "open", "http://tales-tra.com/", null, null, SW_SHOWNORMAL);			
		};
		label2.click ~= delegate void(Control c, EventArgs ea) {
			ShellExecuteA(null, "open", "http://toa.tales-tra.com/", null, null, SW_SHOWNORMAL);			
		};
		label3.click ~= delegate void(Control c, EventArgs ea) {
			auto f = new FormSecret();
			f.showDialog();
		};
		
		slowLabel.click ~= delegate void(Control c, EventArgs ea) {
			writefln("sloooooooow (%d)", modal);
		};
		
		writefln(7);
		
		label3.visible = false;
		
		writefln(8);
		
		//this.refresh();
	}
	
	void onSelectOriginal(Control c, EventArgs ea) {
		OpenFileDialog fd = new OpenFileDialog();
		fd.filter = "Imagen de CD (*.iso)|*.iso|Todos los Archivos (*.*)|*.*";
		fd.title = "Selecciona ISO";
		//fd.initialDirectory = getDirName(textBox1.text);
		fd.fileName = textBox1.text;
		if (fd.showDialog(this) == DialogResult.OK) {
			textBox1.text = fd.fileName;
			PlaySound(sndClick);
		} else {
			PlaySound(sndExit);
		}
		fenable();
	}		

	void onSelectPatched(Control c, EventArgs ea) {
		SaveFileDialog fd = new SaveFileDialog();
		fd.filter = "Imagen de CD (*.iso)|*.iso|Todos los Archivos (*.*)|*.*";
		fd.title = "Selecciona ISO";
		fd.defaultExt = "iso";
		fd.fileName = textBox2.text;
		if (fd.showDialog(this) == DialogResult.OK) {
			textBox2.text = fd.fileName;
			PlaySound(sndClick);
		} else {
			PlaySound(sndExit);
		}
	}
	
	override void onPaintBackground(PaintEventArgs pea) {
	}
	
	override void onPaint(PaintEventArgs pea) {
		auto g = pea.graphics;
		appBG.draw(g, Point(0, 0));
		firstPainted = true;
		label3.visible = true;
	}	
	
	void fenable() {
		fenable(textBox1.enabled);
	}
	
	void fenable(bool v) {
		bool v2 = v;
		if (!std.file.exists(textBox1.text) || !std.file.isfile(textBox1.text)) v2 = false;
		textBox1.enabled = v;
		textBox2.enabled = v;
		button1.enabled = v;
		button2.enabled = v;
		button3.enabled = v2;
	}
	
	void onPatch(Control c, EventArgs ea) {
		std.gc.fullCollect();
		iso_paths[0] = textBox1.text;
		iso_paths[1] = textBox2.text;
		(new PatchThread(this)).start();
		
		chdir(patcher_path);
		formProgress = new FormProgress();
		formProgress.showDialog();		
	}
	
	private void initializeMyForm()
	{
		// Do not manually modify this function.
		//~Entice Designer 0.8.5.02 code begins here.
		//~DFL Form
		formBorderStyle = dfl.all.FormBorderStyle.FIXED_SINGLE;
		maximizeBox = false;
		startPosition = dfl.all.FormStartPosition.CENTER_SCREEN;
		text = "title";
		clientSize = dfl.all.Size(640, 480);
		//~DFL dfl.textbox.TextBox=textBox1
		textBox1 = new dfl.textbox.TextBox();
		textBox1.name = "textBox1";
		textBox1.backColor = dfl.all.Color(0, 0, 0);
		textBox1.font = new dfl.all.Font("Lucida", 10f, dfl.all.FontStyle.REGULAR);
		textBox1.foreColor = dfl.all.Color(255, 255, 255);
		textBox1.borderStyle = dfl.all.BorderStyle.NONE;
		textBox1.bounds = dfl.all.Rect(120, 250, 280, 18);
		textBox1.parent = this;
		//~DFL ButtonSound:dfl.button.Button=button1
		button1 = new ButtonSound();
		button1.name = "button1";
		button1.font = new dfl.all.Font("Lucida", 8f, dfl.all.FontStyle.REGULAR);
		button1.text = "Seleccionar...";
		button1.bounds = dfl.all.Rect(416, 245, 104, 26);
		button1.parent = this;
		//~DFL dfl.textbox.TextBox=textBox2
		textBox2 = new dfl.textbox.TextBox();
		textBox2.name = "textBox2";
		textBox2.backColor = dfl.all.Color(0, 0, 0);
		textBox2.font = new dfl.all.Font("Lucida", 10f, dfl.all.FontStyle.REGULAR);
		textBox2.foreColor = dfl.all.Color(255, 255, 255);
		textBox2.borderStyle = dfl.all.BorderStyle.NONE;
		textBox2.bounds = dfl.all.Rect(120, 298, 280, 18);
		textBox2.parent = this;
		//~DFL ButtonSound:dfl.button.Button=button2
		button2 = new ButtonSound();
		button2.name = "button2";
		button2.font = new dfl.all.Font("Lucida", 8f, dfl.all.FontStyle.REGULAR);
		button2.text = "Seleccionar...";
		button2.bounds = dfl.all.Rect(416, 292, 104, 26);
		button2.parent = this;
		//~DFL ButtonSound:dfl.button.Button=button3
		button3 = new ButtonSound();
		button3.name = "button3";
		button3.font = new dfl.all.Font("Georgia", 14f, dfl.all.FontStyle.REGULAR);
		button3.text = "Parchear";
		button3.bounds = dfl.all.Rect(176, 360, 288, 40);
		button3.parent = this;
		//~DFL TransparentLabelSound:dfl.label.Label=label1
		label1 = new TransparentLabelSound();
		label1.name = "label1";
		label1.backColor = dfl.all.Color(0, 0, 0);
		label1.bounds = dfl.all.Rect(224, 432, 192, 40);
		label1.parent = this;
		//~DFL TransparentLabelSound:dfl.label.Label=label2
		label2 = new TransparentLabelSound();
		label2.name = "label2";
		label2.backColor = dfl.all.Color(0, 0, 0);
		label2.bounds = dfl.all.Rect(200, 24, 232, 128);
		label2.parent = this;
		//~DFL TransparentLabel:dfl.label.Label=label3
		label3 = new TransparentLabel();
		label3.name = "label3";
		label3.backColor = dfl.all.Color(255, 0, 0);
		label3.bounds = dfl.all.Rect(600, 120, 24, 24);
		label3.parent = this;
		//~DFL TransparentLabel:dfl.label.Label=slowLabel
		slowLabel = new TransparentLabel();
		slowLabel.name = "slowLabel";
		slowLabel.backColor = dfl.all.Color(255, 0, 0);
		slowLabel.bounds = dfl.all.Rect(120, 16, 24, 24);
		slowLabel.parent = this;
		//~DFL TransparentLabel:dfl.label.Label=label7
		label7 = new TransparentLabel();
		label7.name = "label7";
		label7.backColor = dfl.all.Color(255, 0, 0);
		label7.foreColor = dfl.all.Color(255, 255, 255);
		label7.text = "Selecciona la ISO original en inglés:";
		label7.bounds = dfl.all.Rect(120, 230, 280, 16);
		label7.parent = this;
		//~DFL TransparentLabel:dfl.label.Label=label8
		label8 = new TransparentLabel();
		label8.name = "label8";
		label8.backColor = dfl.all.Color(255, 0, 0);
		label8.foreColor = dfl.all.Color(255, 255, 255);
		label8.text = "Escoge el nombre de la ISO a crear en castellano:";
		label8.bounds = dfl.all.Rect(120, 274, 280, 16);
		label8.parent = this;
		//~DFL dfl.label.Label=label9
		label9 = new dfl.label.Label();
		label9.name = "label9";
		label9.backColor = dfl.all.Color(0, 0, 0);
		label9.bounds = dfl.all.Rect(120, 292, 280, 26);
		label9.parent = this;
		//~DFL dfl.label.Label=label10
		label10 = new dfl.label.Label();
		label10.name = "label10";
		label10.backColor = dfl.all.Color(0, 0, 0);
		label10.bounds = dfl.all.Rect(120, 244, 280, 26);
		label10.parent = this;
		//~Entice Designer 0.8.5.02 code ends here.
	}
}


char[][] iso_paths;

//version = console_test;

int doMain(char[][] args) {
	if (args.length <= 1) return 0;
	
	patch_start();
	chdir(patcher_path);	

	FS.setAbyssIsos(iso_paths[0], iso_paths[1]);
	FS.setAbyssIsos1(iso_paths[0], iso_paths[0]);
	//check.process();   patch_stopPoint(); Progress.set(1);
	FS.setAbyssIsos2(iso_paths[0], iso_paths[1]);
	//check.process2();   patch_stopPoint(); Progress.set(1);	
	
	switch (args[1]) {
		case "test": test.process(); break;
		case "btl_restore":
			FS.gout["btl/BTL_USU.BIN"].replace(FS.gin["btl/BTL_USU.BIN"], false);
			FS.gout["btl/BTL_ENM.BIN"].replace(FS.gin["btl/BTL_ENM.BIN"], false);
		break;
		case "test_search_btem": btl_enm.test_search_btem(); break;
		case "check": check.process(); break;
		case "field": field.process(); break;
		case "btl": btl.process(); break;
		case "npc": npc.process(); break;
		case "misc": misc.process(true); break;
		case "skits": skits.process(); break;
		case "script": script.process(); break;
		case "exe": exe.process(true); break;
		case "movie": movie.process(); break;
		case "psearch": test_psearch.process(); break;
		case "testmap": test.process_swap_testmap(); break;
		case "regenroot": misc.regen_root(); break;
		case "all":
			check.process();
			exe.process();
			btl.process();
			npc.process();
			skits.process();
			misc.process(true);
			script.process();
			movie.process();
			field.process();
		break;
		default: writefln("Unknown options '%s'", args[1]);
	}
	return 1;
}

class PatchThread : Thread {
	MyForm form;
	
	this(MyForm form) {
		this.form = form;
	}

	void process() { scope(exit)Progress.pop; Progress.push("Parcheando juego", 10);
		patch_start();
	
		chdir(patcher_path);
	
		FS.setAbyssIsos(iso_paths[0], iso_paths[1]);
		FS.setAbyssIsos1(iso_paths[0], iso_paths[0]);
		check.process();   patch_stopPoint(); Progress.set(1);
		FS.setAbyssIsos2(iso_paths[0], iso_paths[1]);
		check.process2();   patch_stopPoint(); Progress.set(1);
		
		exe.process();     patch_stopPoint(); Progress.set(2);
		btl.process();     patch_stopPoint(); Progress.set(3);
		npc.process();     patch_stopPoint(); Progress.set(4);
		skits.process();   patch_stopPoint(); Progress.set(5);
		misc.process();    patch_stopPoint(); Progress.set(6);
		script.process();  patch_stopPoint(); Progress.set(7);
		movie.process();   patch_stopPoint(); Progress.set(8);
		field.process();   patch_stopPoint(); Progress.set(9);
		misc.regen_root(); patch_stopPoint(); Progress.set(10);
	}

	override int run() {
		patchRunning = true;
		form.fenable(false);
		
		//Sleep(3000);
		
		void finish(bool success) {
			patch_stopped = true;
			try { FS.gout.open.close(); } catch { }
			try { FS.gin.open.close(); } catch { }
			Progress.sendUpdate(success ? 1 : -1);
		}
		
		try {
			process();
			int rtime = cast(int)secondsPatcher;
			int seconds = rtime % 60; rtime /= 60;
			int minutes = rtime % 60; rtime /= 60;
			int hours   = rtime % 60; rtime /= 60;
			
			finish(true);
			msgBox(MyForm.self, format("Iso del Tales of the Abyss generada satisfactoriamente en\n\n%d hora(s) %d minuto(s) %d segundo(s)", hours, minutes, seconds), "Ok", MsgBoxButtons.OK, MsgBoxIcon.EXCLAMATION);
		} catch (Exception e) {
			finish(false);
			if (e.toString.length) msgBox(MyForm.self, e.toString, "Error");
		} finally {
			form.fenable(true);
		}
		patchRunning = false;
		MyForm.self.closeFormProgress();
		return 0;
	}
}

class CheckVersion : Thread {
	override int run() {
		writefln("Comprobando última versión en internet...");
		char[] ver2 = cast(char[])HTTP.GET("http://toa.tales-tra.com/version.patch");
		char[] ver1 = cast(char[])FS.patch["version.patch"].read;
		
		writefln("Actual: %s | Online: %s", ver1, ver2);
		
		//ver1 = "dummy";
		
		if (ver1 != ver2) {
			writefln("New version");
			switch (msgBox(MyForm.self,
				format(
					"Hay disponible una nueva versión de la traducción:\n\nEsta versión: %s\nNueva versión: %s\n\n¿Ir a la página web a descargarla?",
					ver1,
					ver2
				), format("Nueva versión %s", ver2), MsgBoxButtons.YES_NO, MsgBoxIcon.EXCLAMATION)
			) {
				case DialogResult.YES:
					ShellExecute(null, "open", "http://toa.tales-tra.com/", null, null, SW_SHOWNORMAL);
				break;
				default:
				break;
			}
		} else {
			writefln("Última versión");
		}
		
		return 0;
	}
}


void checkISOPath() {
	iso_paths = [];
	iso_paths ~= "";
	iso_paths ~= patcher_path ~ "\\toa-spa.iso";

	if (std.file.exists("isopath.txt")) {
		Stream s = new BufferedFile("isopath.txt");
		for (int n = 0; n < 2; n++) {
			iso_paths[n] = s.readLine;
			if (iso_paths[n].find(":") == -1) {
				iso_paths[n] = patcher_path ~ "\\" ~ iso_paths[n];
			}
		}
		s.close();
		writefln("Leído 'isopath.txt':");
	} else {
		writefln("No se pudo encontrar 'isopath.txt':");
	}
	
	writeln("  '" ~ iso_paths[0] ~ "'");
	writeln("  '" ~ iso_paths[1] ~ "'");
}

import std.c.stdio;
	
int main(char[][] args) {
	int result = 0;
	
	version (gui) {
		try { mkdir("logs"); } catch { }
		freopen("logs/stdout.txt", "w", stdout);
		freopen("logs/stderr.txt", "w", stderr);
	}

	patcher_path = fromAnsiS(getDirName(args[0]));
	checkISOPath();
	
	if (doMain(args)) return 0;
	
	try {
		Application.enableVisualStyles();
		Application.run(new MyForm());
	} catch(Object o) {
		msgBox(o.toString(), "Fatal Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);
		result = 1;
	}
	
	return result;
}