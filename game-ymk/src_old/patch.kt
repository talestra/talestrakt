import com.talestra.rhcommon.io.SliceStream2
import com.talestra.rhcommon.lang.noImpl
import com.talestra.rhcommon.lang.notMigrated
import java.io.File

fun backup(ori: File, back: File) {
	if (back.exists()) return
	if (!ori.exists()) throw RuntimeException("No existe '$ori'")
	ori.copyTo(back)
}

fun backup(ori: String, back: String) = backup(File(ori), File(back))

fun Chip_regenerate(file_new: File, file_old: File) {
	val arc = ARC(file_old);
	//writefln(arc.list);

	ARC.create(file_new, arc.list) { name: String, bname: String, ext: String ->
		notMigrated
		//try {
		//	return archive["images/$name"].open;
		//} catch(e: Throwable) {
		//}
		//return arc[name];
	}
}

fun msgBox(msg: String) {
	notMigrated
}

fun do_patch() {
	notMigrated

	//backup("Rio.arc", "Rio.en.arc");
	//backup("Chip.arc", "Chip.en.arc");
	//backup("yumemiru.exe", "yumemiru.en.exe");
//
	//File("yumemiru_loader.exe").writeBytes(archive["loader/yumemiru_loader.exe"].read)
	//File("yumemiru_loader.dll").writeBytes(archive["loader/yumemiru_loader.dll"].read)
//
	//val s = File("yumemiru.exe").open2();
	//val sw = SliceStream2(s, 0x793C8, 0x793C8 + 0x30);
	//sw.writeString("YUME MIRU KUSURI :: Una droga que te har\xE1 so\xF1ar\0");
	//s.close();
//
	//Chip_regenerate("Chip.arc", "Chip.en.arc");
	//Script.regenerate();
//
	//msgBox("listo");
}