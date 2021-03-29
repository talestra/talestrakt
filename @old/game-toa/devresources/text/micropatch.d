import tales.scont.generic, tales.scont.iso, tales.scont.fps3, tales.scont.fps2, tales.util.patches;

import std.stdio, std.stream, std.file, std.string, std.date, std.conv;
import tales.util.gameformat, tales.common;
import tales.scont.generic, tales.scont.iso, tales.scont.fps2;
import tales.isopath, tales.comp, tales.sb7;
import tales.util.rangelist;

version(alignfake2) {
	alias StreamWriteStringR2Fake2 StreamWriteStringR2Final;
} else {
	version(alignfake) {
		alias StreamWriteStringR2Fake StreamWriteStringR2Final;
	} else {
		alias StreamWriteStringR2 StreamWriteStringR2Final;
	}
}

Iso m_iso, m_isomap, m_isoroot, m_isoev, m_isose, m_isobtl, m_isonpc;

void AbyssInitIsoPathMod() {
	char[] m_iso_name = std.string.strip(cast(char[])read("../isopath.mod.txt"));

	if (!exists(m_iso_name)) {
		throw(new Exception(std.string.format("No existe '%s'", m_iso_name)));
	}

	m_iso     = new Iso(m_iso_name);
	m_isomap  = new Iso(m_iso["TO7MAP.CVM"].open);
	m_isoroot = new Iso(m_iso["TO7ROOT.CVM"].open);
	m_isoev	  = new Iso(m_iso["TO7EV.CVM"].open);
	m_isose	  = new Iso(m_iso["TO7SE.CVM"].open);
	m_isobtl  = new Iso(m_iso["TO7BTL.CVM"].open);
	m_isonpc  = new Iso(m_iso["TO7NPC.CVM"].open);
}

int main(char[][] args) {
	//AbyssInitIsoPath();
	AbyssInitIsoPathMod();
	
	//m_isomap[""]
	
	m_isomap.swap("TESTMAP.PKB", "CAP_I06_05.PKB");

	/*
	
	patchBtl();
	patchExe();
	*/
	
	//File f = new File("temp", FileMode.OutNew);
	//f.copyFrom(m_iso["SLUS_213.86"].open);
	//f.close();
	/*
	m_iso["SLUS_213.86"].saveto("temp");
	
	File f = new File("temp", FileMode.Out | FileMode.In);	
	Create_TITLES_Stream(f, new File("exe/titles.es.txt"));
	f.close();
	
	//m_iso["SLUS_213.86"].replace("temp");
	m_iso["SLUS_213.86"].replace("TO7/SLUS_213.86");
	*/
	
	//m_isomap.swap("TESTMAP.PKB", "CAP_I06_05.PKB");
	//m_isomap.swap("ani_t00e.PKB", "CAP_I06_05.PKB");	
	//test1();

	return 0;

	/*
	
	if (true) {
		//if (true) {
		if (false) {
			m_isonpc.swap("TV_HEV.NPC", "TV_MEP.NPC");	
		}
		
		//if (true) {
		if (false) {
			auto fps = new Fps3Archive(m_isonpc["TV_MEP.NPC"].open);	
			fps["tm2"].replace("TV_MEP.NPC.tm2");
		}

		//if (true) {
		if (false) {
			m_isomap.swap("CAP_I06_05.PKB", "YUR_I00_00.PKB");
		}
	}
	*/

	//m_isomap["CAP_I06_05.PKB"].replace("SCR/CAP_I06_05.MOD.PKB");
	
	//m_isomap["CAP_I06_05.PKB"].replace("SCR/CAP_I06_05.MOD.PKB");
	
	//m_isoroot["TOAEND_US.TXT"].replace("END/TOAEND_ES.TXT", false);
	//m_isoroot["ENDROLL.TM2"].replace("END/ENDROLL.TM2", false);
	
	//m_isomap.swap("");
	
	//m_isomap.swap("TESTMAP.PKB", "CAP_I06_05.PKB");	
	//m_isose.swap("CHT_000.SKT", "CHT_001.SKT");
	
	/*
	m_iso["SLUS_213.86"].replace("TO7/SLUS_213.86");
	
	return 0;
	
	//m_isoev	  = new Iso(m_iso["TO7EV.CVM"].open);	
	
	//if (true) {
	if (false) {
		//m_isomap.swap("TESTMAP.PKB", "CAP_I06_05.PKB");
		
		//m_isomap["CAP_I06_05.PKB"].replace("scr/PKB/TESTMAP.PKB", false);
		m_isomap["CAP_I06_05.PKB"].replace("scr/PKB/CAP_I06_05.PKB", false);
		
		m_isomap["CAP_I06_06.PKB"].replace("scr/PKB/CAP_I06_06.PKB", false);	
		//m_isomap["CAP_I06_05.PKB"].replace("scr/PKB/CAP_I06_05.PKB", false);	
	}
	
	//if (true) {
	if (false) {
		m_isoroot["_S_MENU.TM2"].replace("../images/_S_MENU/_S_MENU.TM2");
		m_isoroot["S_NAMCOLOGO.TM2"].replace("../images/S_NAMCOLOGO/S_NAMCOLOGO.TM2");
		m_isoroot["S_TOA_LOGO.TM2"].replace("../images/S_TOA_LOGO/S_TOA_LOGO.TM2");
		m_isoev["S_DB_TITLE.TM2"].replace("../images/S_DB_TITLE/S_DB_TITLE.TM2");
	}
	
	if (true) {
	//if (false) {
		m_isoroot["TOAEND_US.TXT"].replace("../text/end/TOAEND_ES.TXT", false);
		m_isoroot["_SLTSKL_.DAT"].replace("../text/dat/_SLTSKL_.DAT", false);
		m_isoroot["_ACS_.DAT"].replace("../text/dat/_ACS_.DAT", false);
		m_isoroot["_SP_.DAT"].replace("../text/dat/_SP_.DAT", false);
		m_isoroot["_I_.DAT"].replace("../text/dat/_I_.es.DAT", false);
	}
	
	//if (true) {
	if (false) {
		m_isose["CHT_000.SKT"].replace("skt/mod/CHT_001.SKT", false);
	}

	//if (true) {
	if (false) {
		m_isobtl["BTL_USU.BIN"].replace("../BTL_USU.BIN");
	}

	//if (true) {
	if (false) {
		m_isoroot["_FONTB.TM2"].replace("../font/_FONTB.TM2", false);
		m_iso["SLUS_213.86"].replace("../SLUS_213.86");
	}
	*/
	
	return 0;
}
