import imports;

void process_tv() { scope(exit)Progress.pop;Progress.push("Traduciendo animaciones de zona (tv)");
	const char[][] tvs = ["TV_AJI", "TV_ANI", "TV_CAP", "TV_CAS", "TV_CHD", "TV_CHU", "TV_COK", "TV_CPO", "TV_DIS", "TV_EXE", "TV_FIR", "TV_FON", "TV_FOR", "TV_FPO", "TV_GLE", "TV_GRA", "TV_HEV", "TV_ICE", "TV_KIN", "TV_LAS", "TV_MEI", "TV_MEP", "TV_MIN", "TV_MIR", "TV_MOU", "TV_MYU", "TV_NAM", "TV_NEV", "TV_NOR", "TV_OAS", "TV_ORG", "TV_ORP", "TV_RIV", "TV_SAI", "TV_SAN", "TV_SCO", "TV_SEA", /*"TV_SEB", */"TV_SHI", "TV_SNO", "TV_SNP", "TV_SOU", "TV_SPW", "TV_TUN", "TV_WAT", "TV_WET", "TV_XXX", "TV_YUR"];
	
	uint offset;
	
	foreach (n, tv; tvs) {
		Progress.set(n, tvs.length);
		Stream si = new BufferedStream(FS.gin[format("npc/%s.npc", tv)].open);
		Stream so = FS.gout[format("npc/%s.npc", tv)].open;
		so.copyFrom(si);
		si.close();
		
		so.position = 0x10C; so.read(offset); so.position = offset;
		so.copyFrom(FS.patch[format("tv/%s/tm2", tv)].open);

		so.position = 0x118; so.read(offset); so.position = offset;
		so.copyFrom(FS.patch[format("tv/%s/animation", tv)].open);
		
		so.close();
	}
	
	/*foreach (tv; tvs) {
		FS.gout[format("npc/%s.NPC", tv)].replace(getTempFile(format("tv/%s", tv), FileMode.In), true);
	}*/
}

void process() {
	process_tv();
}