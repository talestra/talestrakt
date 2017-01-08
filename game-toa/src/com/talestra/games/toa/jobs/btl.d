import imports;

import btl_usu, btl_enm;

void process() { scope(exit)Progress.pop;Progress.push("Parcheando datos de batalla");
	btl_usu.unpack();
	
		btl_usu.translate();
		btl_enm.process();
		// TODO EP039
	
	btl_usu.repack();
}