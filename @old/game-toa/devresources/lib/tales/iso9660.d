module iso9660;

import std.string, std.stream, std.file, std.intrinsic;


// ISO9660

align(1) struct IsoDate {
	ubyte info[17]; // 8.4.26.1
	
	static void set(Date date) {		
		info[0..17] = std.string.format("%4.4d%2.2d%2.2d%2.2d%2.2d%2.2d00", date.year, date.month, date.day, date.hour, date.minute, date.second)[0..17];
	}	
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
}

// UDF

align(1) struct EntityID { /* ISO 13346 1/7.4 */
	ubyte Flags;
	char  Identifier[23];
	char  IdentifierSuffix[8];
}

align(1) struct Timestamp { /* ISO 13346 1/7.3 */
	ushort TypeAndTimezone;
	ushort Year;
	ubyte  Month;
	ubyte  Day;
	ubyte  Hour;
	ubyte  Minute;
	ubyte  Second;
	ubyte  Centiseconds;
	ubyte  HundredsofMicroseconds;
	ubyte  Microseconds;
}

align(1) struct Charspec {
	ubyte CharacterSetType;
	char  CharacterSetInfo[63];
}

align(1) struct Tag { /* ISO 13346 3/7.2 */
	ushort TagIdentifier;
	ushort DescriptorVersion;
	ubyte  TagChecksum;
	ubyte  Reserved;
	ushort TagSerialNumber;
	ushort DescriptorCRC;
	ushort DescriptorCRCLength;
	uint   TagLocation;
}

align(1) struct Extent_ad {
}

align(1) struct UdfPrimaryVolumeDescriptor { /* ISO 13346 3/10.1 */
	Tag       DescriptorTag;
	uint      VolumeDescriptorSequenceNumber;
	uint      PrimaryVolumeDescrip torNumber;
	char      VolumeIdentifier[32];
	ushort    VolumeSequenceNumber;
	ushort    MaximumVolumeSequenceNumber;
	ushort    InterchangeLevel;
	ushort    MaximumInterchangeLevel;
	uint      CharacterSetList;
	uint      MaximumCharacterSetList;
	char      VolumeSetIdentifier[128];
	Charspec  DescriptorCharacterSet;
	Charspec  ExplanatoryCharacterSet;
	Extent_ad VolumeAbstract;
	Extent_ad VolumeCopyrightNotice;
	EntityID  ApplicationIdentifier;
	Timestamp RecordingDateandTime;
	EntityID  ImplementationIdentifier;
	byte      ImplementationUse[64];
	uint      PredecessorVolumeDescriptorSequenceLocation;
	ushort    Flags;
	byte      Reserved[22];
}

class ISO9660 {
	Stream os;
	char[] SystemId;
	char[] VolumeId;
	
	char[] VolumeSetId;
	char[] PublisherId;
	char[] PreparerId;
	char[] ApplicationId;
	char[] CopyrightFileId;
	char[] AbstractFileId;
	char[] BibliographicFileId;
			
	ubyte ApplicationData[512];
	
	int sectors;
	int sectors_table;
	int path_table_addr;
	int path_table_addr_opt;
	int path_table_addr_m;
	int path_table_addr_opt_m;
	
	/*
"%4.4d%2.2d%2.2d%2.2d%2.2d%2.2d00",
		1900 + local.tm_year,
		local.tm_mon + 1, local.tm_mday,
		local.tm_hour, local.tm_min, local.tm_sec);
		*/
	static char[] s84261(char[] s, Date date) {		
		return std.string.format("%4.4d%2.2d%2.2d%2.2d%2.2d%2.2d00", date.year, date.month, date.day, date.hour, date.minute, date.second);
	}	
	
	static void setText(char[] s, char[] r) {
		if (r.length > s.length) { s[0..s.length] = r[0..s.length]; return; }		
		s[0..r.length] = r[0..r.length];
		for (int n = r.length; n < s.length; n++) s[n] = 0x20;
	}
	
	static ulong s733(uint v) {
		return cast(ulong)v | ((cast(ulong)bswap(v)) << 32);
	}
		
	void SystemAreaStream(Stream s) {
		os.position = 0;
		os.copyFrom(s);
	}
	
	void WritePrimaryVolumeDescriptor() {
		IsoPrimaryDescriptor ipd;
		ipd.Type    = 0x01;
		ipd.Id      = "CD001";
		ipd.Version = 0x01;
		
		setText(ipd.SystemId, SystemId);
		setText(ipd.VolumeId, VolumeId);
		
		ipd.VolumeSpaceSize      = s733(sectors);
		ipd.VolumeSetSize        = 0x1000001;
		ipd.VolumeSequenceNumber = 0x1000001;
		ipd.LogicalBlockSize     = 0x0080800;
		ipd.PathTableSize        = s733(sectors_table);
		
		ipd.Type1PathTable       = path_table_addr;
		ipd.OptType1PathTable    = path_table_addr_opt;
		ipd.TypeMPathTable       = bswap(path_table_addr);
		ipd.OptTypeMPathTable    = bswap(path_table_addr_opt);
		
		setText(ipd.VolumeSetId, VolumeSetId);
		setText(ipd.PublisherId, PublisherId);
		setText(ipd.PreparerId, PreparerId);
		setText(ipd.ApplicationId, ApplicationId);
		setText(ipd.CopyrightFileId, CopyrightFileId);
		setText(ipd.AbstractFileId, AbstractFileId);
		setText(ipd.BibliographicFileId, BibliographicFileId);
		
		Date d;
		
		ipd.CreationDate.set(d);
		ipd.ModificationDate.set(d);
		ipd.ExpirationDate.set(d);
		ipd.EffectiveDate.set(d);
		
		ipd.FileStructureVersion = 0x01;
		ipd.ApplicationData = ApplicationData;
		
		os.write(TSerialize(&ipd));
	}
	
	void WriteVolumeDescriptorSetTerminator() {
		IsoPrimaryDescriptor ipd;
		ipd.Type    = 0xFF;
		ipd.Id      = "CD001";
		ipd.Version = 0x01;		
		os.write(TSerialize(&ipd));		
	}

	void WriteBegginingExtendedAreaDescriptor() {
		IsoPrimaryDescriptor ipd;
		ipd.Type    = 0x00;
		ipd.Id      = "BEA01";
		ipd.Version = 0x01;		
		os.write(TSerialize(&ipd));		
	}

	void WriteNSRDescriptor() {
		IsoPrimaryDescriptor ipd;
		ipd.Type    = 0x00;
		ipd.Id      = "NSR02";
		ipd.Version = 0x01;		
		os.write(TSerialize(&ipd));		
	}

	void WriteTerminatingExtendedAreaDescriptor() {
		IsoPrimaryDescriptor ipd;
		ipd.Type    = 0x00;
		ipd.Id      = "TEA01";
		ipd.Version = 0x01;		
		os.write(TSerialize(&ipd));		
	}
	
	void WriteUdfPrimaryVolumeDescriptor() {
		
	}
}