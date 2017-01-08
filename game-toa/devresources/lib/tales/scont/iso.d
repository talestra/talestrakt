module tales.scont.iso;

import tales.scont.generic, tales.common;
private import std.file, std.string, std.stdio, std.path, std.regexp, std.stream, std.intrinsic;

// ISO 9660

align(1) struct IsoDate {
	ubyte info[17]; // 8.4.26.1
}

static ulong s733(uint v) {
	return cast(ulong)v | ((cast(ulong)bswap(v)) << 32);
}

align(1) struct IsoDirectoryRecord {
	ubyte   Length;
    ubyte   ExtAttrLength;
	ulong   Extent;
	ulong   Size;
	ubyte   Date[7];
	ubyte   Flags;
	ubyte   FileUnitSize;
	ubyte   Interleave;
	uint    VolumeSequenceNumber;
	ubyte   NameLength;
	//ubyte   _Unused;
	//char    Name[0x100];
}

struct IsoVolumeDescriptor {
	ubyte Type;
	char Id[5];
	ubyte Version;
	ubyte Data[2041];
};


// 0x800 bytes (1 sector)
align(1) struct IsoPrimaryDescriptor {
	ubyte Type;
	char  Id[5];
	ubyte Version;
	ubyte _Unused1;
	char  SystemId[0x20];
	char  VolumeId[0x20];
	ulong _Unused2;
	ulong VolumeSpaceSize;
	ulong _Unused3[4];
	uint  VolumeSetSize;
	uint  VolumeSequenceNumber;
	uint  LogicalBlockSize;
	ulong PathTableSize;
	uint  Type1PathTable;
	uint  OptType1PathTable;
	uint  TypeMPathTable;
	uint  OptTypeMPathTable;
	IsoDirectoryRecord RootDirectoryRecord;
	ubyte _Unused3b;
	char  VolumeSetId[128];
	char  PublisherId[128];
	char  PreparerId[128];
	char  ApplicationId[128];
	char  CopyrightFileId[37];
	char  AbstractFileId[37];
	char  BibliographicFileId[37];
	IsoDate CreationDate;
	IsoDate ModificationDate;
	IsoDate ExpirationDate;
	IsoDate EffectiveDate;
	ubyte FileStructureVersion;
	ubyte _Unused4;
	ubyte ApplicationData[512];
	ubyte _Unused5[653];
};

void Dump(IsoDirectoryRecord idr) {
	writefln("IsoDirectoryRecord {");
	writefln("  Length:               %02X", idr.Length);
	writefln("  ExtAttrLength:        %02X", idr.ExtAttrLength);
	writefln("  Extent:               %08X", idr.Extent & 0xFFFFFFFF);
	writefln("  Size:                 %08X", idr.Size & 0xFFFFFFFF);
	writefln("  Date:                 [...]");
	writefln("  Flags:                %02X", idr.Flags);
	writefln("  FileUnitSize:         %02X", idr.FileUnitSize);
	writefln("  Interleave:           %02X", idr.Interleave);
	writefln("  VolumeSequenceNumber: %08X", idr.VolumeSequenceNumber);
	writefln("  NameLength:           %08X", idr.NameLength);
	writefln("}");
	writefln();
}

void Dump(IsoPrimaryDescriptor ipd) {
	writefln("IsoPrimaryDescriptor {");
	writefln("  Type:                 %02X",   ipd.Type);
	writefln("  ID:                   '%s'",   ipd.Id);
	writefln("  Version:              %02X",   ipd.Version);
	writefln("  SystemId:             '%s'",   ipd.SystemId);
	writefln("  VolumeId:             '%s'",   ipd.VolumeId);
	writefln("  VolumeSpaceSize:      %016X",  ipd.VolumeSpaceSize);
	writefln("  VolumeSetSize:        %08X",   ipd.VolumeSetSize);
	writefln("  VolumeSequenceNumber: %08X",   ipd.VolumeSequenceNumber);
	writefln("  LogicalBlockSize:     %08X",   ipd.LogicalBlockSize);
	writefln("  PathTableSize:        %016X",  ipd.PathTableSize);
	writefln("  Type1PathTable:       %08X",   ipd.Type1PathTable);
	writefln("  OptType1PathTable:    %08X",   ipd.OptType1PathTable);
	writefln("  TypeMPathTable:       %08X",   ipd.TypeMPathTable);
	writefln("  OptTypeMPathTable:    %08X",   ipd.OptTypeMPathTable);
	writefln("  RootDirectoryRecord:  [...]");
	Dump(ipd.RootDirectoryRecord);
	writefln("  VolumeSetId:          '%s'",   ipd.VolumeSetId);
	writefln("  PublisherId:          '%s'",   ipd.PublisherId);
	writefln("  PreparerId:           '%s'",   ipd.PreparerId);
	writefln("  ApplicationId:        '%s'",   ipd.ApplicationId);
	writefln("  CopyrightFileId:      '%s'",   ipd.CopyrightFileId);
	writefln("  AbstractFileId:       '%s'",   ipd.AbstractFileId);
	writefln("  BibliographicFileId:  '%s'",   ipd.BibliographicFileId);
	writefln("  CreationDate:         [...]");
	writefln("  ModificationDate:     [...]");
	writefln("  ExpirationDate:       [...]");
	writefln("  EffectiveDate:        [...]");
	writefln("  FileStructureVersion: %02X",   ipd.FileStructureVersion);
	writefln("}");
	writefln();
}

class IsoEntry : ContainerEntryWithStream {
	Stream drstream;
	IsoDirectoryRecord dr;
	Iso iso;
	uint udf_extent;
	
	char[] fullname;

	override void print() {
		writefln(this.toString);
		Dump(dr);
	}

	// Escribimos el DirectoryRecord
	void writedr() {
		drstream.position = 0;
		drstream.write(TSerialize(&dr));
		
		// Actualizamos tambien el udf
		if (udf_extent) {
			//writefln("UDF: %08X", udf_extent);
			Stream udfs = new SliceStream(iso.stream, 0x800 * udf_extent, 0x800 * (udf_extent + 1));
			udfs.position = 0x38;
			udfs.write(cast(uint)(dr.Size & 0xFFFFFFFF));
			udfs.position = 0x134;
			//writefln("%08X", dr.Size & 0xFFFFFFFF);
			udfs.write(cast(uint)(dr.Size & 0xFFFFFFFF));
			udfs.write(cast(uint)((dr.Extent & 0xFFFFFFFF) - 262));
			//writefln("patching udf");
		}
	}

	// Cantidad de sectores necesarios para almacenar
	uint Sectors() {
		return iso.sectors(dr.Size);
	}

	override int replace(Stream from, bool limited = true) {
		Stream op = iso.openDirectoryRecord(dr, limited);
		ulong start = op.position;
		//op.copyFrom(from);
		copyStream(from, op);
		uint length = op.position - start;
		op.close();
		dr.Size = s733(length);
		writedr();
		return length;
	}

	override int replaceAt(Stream from, int skip = 0) {
		Stream op = iso.openDirectoryRecord(dr, false);
		ulong start = op.position;
		op.position = start + skip;
		//op.copyFrom(from);
		copyStream(from, op);
		uint length = op.position - start;
		op.close();
		dr.Size = s733(length);
		writedr();
		return length;
	}

	void swap(IsoEntry ie) {
		if (ie.iso != this.iso) throw(new Exception("Only can swap entries in same iso file"));

		int TempExtent, TempSize;

		TempExtent = ie.dr.Extent;
		TempSize   = ie.dr.Size;

		ie.dr.Extent = this.dr.Extent;
		ie.dr.Size   = this.dr.Size;

		this.dr.Extent = TempExtent;
		this.dr.Size   = TempSize;

		this.writedr();
		ie.writedr();
	}

	void use(IsoEntry ie) {
		if (ie.iso != this.iso) throw(new Exception("Only can swap entries in same iso file"));

		this.dr.Extent = ie.dr.Extent;
		this.dr.Size   = ie.dr.Size;

		this.writedr();
	}

	/*override protected Stream realopen(bool limited = true) {
		throw(new Exception(""));
	}*/
}

class IsoDirectory : IsoEntry {
	Stream open() {
		throw(new Exception(""));
	}
	
	void clearFiles() {
		foreach (ce; this) {
			IsoEntry ie = cast(IsoEntry)ce;
			if (ie.classinfo.name == IsoFile.classinfo.name) {
				ie.dr.Extent = s733(0);
				ie.dr.Size   = s733(0);
				ie.writedr();
			} else if (ie.classinfo.name == IsoDirectory.classinfo.name) {
				if (ie != this) (cast(IsoDirectory)ie).clearFiles();
			}
		}
	}
}

class IsoFile : IsoEntry {
	uint size;
	
	override bool isFile() {
		return true;
	}

	//override protected Stream realopen(bool limited = true) {
	override Stream realopen(bool limited = true) {		
		//writefln("%s", name);
		//writefln("%08X", (dr.Size >> 32) & 0x_FFFFFFFF);
		return iso.openDirectoryRecord(dr);
	}
}

class SliceStreamNoClose : SliceStream {
	this(Stream s, ulong pos, ulong len) { super(s, pos, len); }
	this(Stream s, ulong pos) { super(s, pos); }

	override void close() { Stream.close(); }
}

class Iso : IsoDirectory {
	IsoPrimaryDescriptor ipd;
	Stream stream;
	uint position = 0;
	uint datastart = 0xFFFFFFFF;
	uint firstDatasector = 0xFFFFFFFF;
	uint lastDatasector = 0x00000000;
	uint writeDatasector = 0x00000000;
		
	Iso copyIsoStructure(Stream s) {
		Iso iso;
		//writefln(firstDatasector);
		
		if (firstDatasector > 3000) throw(new Exception("ERROR!"));
		
		//s.copyFrom(new SliceStream(stream, 0, (cast(ulong)firstDatasector) * 0x800));
		//writefln(firstDatasector);
		copyStream(new SliceStream(stream, 0, (cast(ulong)firstDatasector) * 0x800), s);
		s.position = 0;
		
		iso = new Iso(s);
		iso.writeDatasector = iso.firstDatasector;
		
		iso.clearFiles();
		
		return iso;
	}
	
	void copyUnrecreatedFiles(Iso iso, bool show = true) {
		//writefln("copyUnrecreatedFiles()");
		foreach (ce; this) {			
			IsoEntry ie = cast(IsoEntry)ce;			
			if (ie.dr.Extent) continue;
				
			if (show) printf("%s...", toStringz(ce.name));
				
			recreateFile(ie, iso[ie.name].open, 5);	iso[ie.name].close();
			
			if (show) printf("Ok\n");
		}
		stream.flush();
	}
	
	void recreateFile(ContainerEntry ce) {
		IsoEntry e  = cast(IsoEntry)ce;
		e.dr.Extent = s733(1);
		e.dr.Size   = s733(0);
		e.writedr();
	}
	
	void recreateFile(ContainerEntry ce, char[] n, int addVoidSectors = 0) {
		Stream s = new File(n, FileMode.In);
		recreateFile(ce, s, addVoidSectors);
		s.close();
	}
	
	void recreateFile(ContainerEntry ce, Stream s, int addVoidSectors = 0) {
		s.position = 0;		
		//printf("Available: %d\n", cast(int)(s.available & 0xFFFFFFFF));
		Stream w = startFileCreate(ce);
		uint pos = w.position;		

		uint available = s.available;
		
		copyStream(s, w);
		//w.copyFrom(s);
		w.position = pos + available;
		
		//printf("Z: %d | (%d)\n", cast(int)(w.position - pos), s.available);
		endFileCreate(addVoidSectors);
	}
	
	ContainerEntry oce; // OpenedContainerEntry
	Stream writing;
	Stream startFileCreate(ContainerEntry ce) {
		oce = ce;
		if ((cast(IsoEntry)ce).iso != this) throw(new Exception("Only can update entries in same iso file"));
		//printf("{START: %08X}\n", writeDatasector);
		uint spos = (cast(ulong)writeDatasector) * 0x800;
		{
			stream.seek(0, SeekPos.End);
			ubyte[] temp; temp.length = 0x800 * 0x100;
			while (stream.position < spos) {
				if (spos - stream.position > temp.length) {
					stream.write(temp);
				} else {
					stream.write(temp[0..spos - stream.position]);
					//stream.position - spos
				}
			}
		}
		writing = new SliceStream(stream, spos);
		return writing;
	}
	
	void endFileCreate(int addVoidSectors = 0) {
		writing.position = 0; uint length = writing.available;
		
		IsoEntry e = cast(IsoEntry)oce;
		e.dr.Extent = s733(writeDatasector);
		e.dr.Size = s733(length);
		e.writedr();
		writeDatasector += sectors(length) + addVoidSectors;
		
		//printf("| {END: %08X}\n", writeDatasector);
		
		if (length % 0x800) {
			stream.position = (cast(ulong)writeDatasector) * 0x800 - 1;
			stream.write(cast(ubyte)0);
		}
	}	

	override void print() {
		Dump(ipd);
	}
	
	static uint sectors(ulong size) {
		uint sect = (size / 0x800);
		if ((size % 0x800) != 0) sect++;
		return sect;
	}
	
	void processFileDR(IsoDirectoryRecord dr) {
		uint ssect = (dr.Extent & 0xFFFFFFFF);
		uint size  = (dr.Size   & 0xFFFFFFFF);
		uint sectl = sectors(size);
		uint esect = ssect + sectl;
		
		//writefln("%08X", ssect);
		
		if (ssect < firstDatasector) firstDatasector = ssect;
		if (esect > lastDatasector ) lastDatasector  = esect;
	}
	
	Stream openDirectoryRecord(IsoDirectoryRecord dr, bool limited = true) {
		ulong from = getSectorPos(dr.Extent & 0x_FFFF_FFFF);
		uint size  = (dr.Size & 0x_FFFF_FFFF);
		return limited ? (new SliceStreamNoClose(stream, from, from + size)) : (new SliceStreamNoClose(stream, from));
	}

	ubyte[] readSector(uint sector) {
		ubyte[] ret; ret.length = 0x800;
		stream.position = getSectorPos(sector);
		stream.read(ret);
		return ret;
	}

	private ulong getSectorPos(uint sector) {
		return (cast(ulong)sector) * 0x800;
	}

	private void processDirectory(IsoDirectory id) {
		IsoDirectoryRecord dr;
		IsoDirectoryRecord bdr = id.dr;
		int cp;
		
		stream.position = getSectorPos(bdr.Extent & 0x_FFFF_FFFF);
		uint maxPos = stream.position + (bdr.Size & 0x_FFFF_FFFF);
		
		//Dump(bdr);
		
		while (true) {
			char[] name;
			Stream drstream;

			uint bposition = stream.position;

			drstream = new SliceStream(stream, stream.position, stream.position + dr.sizeof);
			stream.read(TA(dr));

			//writefln("%08X", bposition);
			//Dump(dr);
			//writefln("%08X", dr.Length);
			
			if (!dr.Length) {
				stream.position = getSectorPos(bposition / 0x800 + 1);
				
				drstream = new SliceStream(stream, stream.position, stream.position + dr.sizeof);
				stream.read(TA(dr));
			}
			
			if (stream.position >= maxPos) break;

			name.length = dr.Length - dr.sizeof;
			stream.read(cast(ubyte[])name);
			name.length = dr.NameLength;

			//writefln(":'%s'", name); Dump(dr);
			
			//processDR(dr);

			if (dr.NameLength && name[0] != 0 && name[0] != 1) {
				//writefln("DIRECTORY: '%s'", name);
				// Directorio
				if (dr.Flags & 2) {
					IsoDirectory cid = new IsoDirectory();
					cid.drstream = drstream;
					cid.iso = this;
					cid.dr = dr;
					id.add(cid);
					cid.name = name[0..name.length - 2];

					uint bp = stream.position;
					{
						processDirectory(cid);
					}
					stream.position = bp;
				}
				// Fichero
				else {
					processFileDR(dr);
					if (cast(uint)dr.Extent < datastart) datastart = dr.Extent;
					IsoFile cif = new IsoFile();
					cif.drstream = drstream;
					cif.iso = this;
					cif.dr = dr;
					cif.size = dr.Size;
					cif.name = name[0..name.length - 2];
					id.add(cif);
					//writefln("%08X - %s", cast(uint)dr.Size, cif.name);
				}
			} else {
				IsoEntry ie = new IsoEntry();
				ie.iso = this;
				ie.dr = dr;
				id.add(ie);
				//Dump(dr);
			}
		}
	}

	this(Stream s) {
		ubyte magic[4];
		//stream = new PatchedStream(s);
		stream = s;

		stream.position = 0;

		stream.read(magic);

		if (cast(char[])magic == "CVMH") {
			stream.position = 0;
			stream = new SliceStream(stream, 0x1800);
		}

		stream.position = getSectorPos(0x10);
		stream.read(TA(ipd));

		this.dr = ipd.RootDirectoryRecord;
		this.name = "/";

		processDirectory(this);
		
		writeDatasector = lastDatasector;
		
		//try { _udf_check(); } catch (Exception e) { }
	}

	this(char[] s, bool readonly = false) {
		File f;
		
		try {
			f = new File(s, readonly ? FileMode.In : (FileMode.In | FileMode.Out));
		} catch (Exception e) {
			f = new File(s, FileMode.In);
		}
		
		this(f);
	}

	private this() { }

	void copyIsoInfo(Iso from) {
		ubyte[0x800 * 0x10] data;
		int fromposition = from.stream.position; scope(exit) { from.stream.position = fromposition; }
		from.stream.position = 0;
		from.stream.read(data);
		this.stream.write(data);
		this.ipd = from.ipd;
		this.position = 0x800 * 0x11;
		this.datastart = from.datastart;
	}

	static Iso create(Stream s) {
		Iso iso = new Iso;
		iso.stream = s;
		return iso;
	}

	void swap(char[] a, char[] b) {
		(cast(IsoEntry)this[a]).swap(cast(IsoEntry)this[b]);
	}

	void use(char[] a, char[] b) {
		(cast(IsoEntry)this[a]).use(cast(IsoEntry)this[b]);
	}
	
	//void _udf_test() {
	void _udf_check() {
		char[] decodeDstringUDF(ubyte[] s) {
			char[] r;
			if (s.length) {
				ubyte bits = s[0];
				switch (bits) {
					case 8:
						for (int n = 1; n < s.length; n++) r ~= s[n];
					break;
					case 16:
						for (int n = 2; n < s.length; n += 2) r ~= s[n];
					break;
				}
			}
			return r;
		}
		
		stream.position = 0x800 * 264;
				
		int count = 0;
		
		while (true) {
			uint ICB_length, ICB_extent;
			ubyte FileCharacteristics, LengthofFileIdentifier;
			ushort FileVersionNumber, LengthofImplementationUse;

			// Padding			
			while (stream.position % 4) stream.position = stream.position + 1;

			// Escapamos el tag
			stream.seek(0x10, SeekPos.Current);
			
			stream.read(FileVersionNumber);			
			if (FileVersionNumber != 0x01) {
				//writefln("%08X : %04X", stream.position - 2, FileVersionNumber);
				break;
			}
			
			//writefln("%08X", stream.position - 2);
			
			stream.read(FileCharacteristics);
			stream.read(LengthofFileIdentifier);			
			stream.read(ICB_length);
			stream.read(ICB_extent);
			stream.seek(8, SeekPos.Current);
			
			// Escapamos la implementacion
			stream.read(LengthofImplementationUse);
			stream.seek(LengthofImplementationUse, SeekPos.Current);
			
			ubyte[] name; name.length = LengthofFileIdentifier;
			stream.read(name);			
			
			if (name.length) {
				//writefln("%s : %d", decodeDstringUDF(name), ICB_length);
				(cast(IsoEntry)this[decodeDstringUDF(name)]).udf_extent = ICB_extent + 262;
				//writefln("%s", decodeDstringUDF(name));
				//writefln(this[decodeDstringUDF(name)]);
			}
		}
	}
}

/*int main(char[][] args) {
	ubyte[0x100] temp;
	Iso iso = new Iso(new File("f:\\isos\\ps2\\Tales of Abyss.iso", FileMode.In));
	Iso niso = Iso.create(new File("temp.iso", FileMode.OutNew));

	niso.copyIsoInfo(iso);

	//iso.list;

	//Stream s = iso.childs[0].open();
	//s.read(temp);
	//writefln("%s", cast(char[])temp);

	//Iso iso = new Iso(new File("f:\\isos\\ps2\\Final Fantasy XII.iso", FileMode.In));

	//writefln("%d", IsoDirectoryRecord.sizeof);
	//writefln("%d", IsoPrimaryDescriptor.sizeof);

	return 0;
}*/
