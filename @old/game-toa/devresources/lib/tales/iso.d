import std.stdio, std.c.stdio, std.c.stdlib, std.c.string, std.string;

const int SECTOR_SIZE = 2048;

const int ISO_FLAG_FILE        = 0x00;
const int ISO_FLAG_EXISTENCE   = 0x01;
const int ISO_FLAG_DIRECTORY   = 0x02;
const int ISO_FLAG_ASSOCIATED  = 0x04;
const int ISO_FLAG_RECORD      = 0x08;
const int ISO_FLAG_PROTECTION  = 0x10;
const int ISO_FLAG_MULTIEXTENT = 0x80;

align(1) struct DirectoryRecord {
	byte	DirectoryLength;
    byte    XARlength;
	uint	ExtentLocation;
	uint	ExtentLocationBE;
	uint	DataLength;
	uint	DataLengthBE;
	byte	DateTime[7];
	byte	FileFlags;
	byte    FileUnitSize;
	byte	InterleaveGapSize;
	uint	VolumeSequenceNum;
	byte	FileNameLength;
	char	FileName[256];
}

struct DirectoryRecordInfo {
	char[] name;
	uint pos;
	uint size;
}

DirectoryRecordInfo[] IsoGetStruct(FILE *isofile) {
	DirectoryRecord dr;
	DirectoryRecordInfo[] ret;
	fseek(isofile, 16 * SECTOR_SIZE + 156, SEEK_SET);
	fread(&dr, 1, DirectoryRecord.sizeof, isofile);
	fseek(isofile, dr.ExtentLocation * SECTOR_SIZE, SEEK_SET);
	IsoGetStruct(isofile, &dr, "", ret);
	return ret;
}

void IsoGetStruct(FILE *isofile, DirectoryRecord *output, char[] add, inout DirectoryRecordInfo[] ret) {
	DirectoryRecord dr;
	int fpointer;
	int oldDirLen = 0;

	fpointer = ftell(isofile);

	void AddEntry(char[] name, uint pos, uint size) {
		DirectoryRecordInfo rete;
		rete.name = name;
		rete.size = size;
		rete.pos  = pos;
		ret ~= rete;
		//writefln("%08X - %s", rete.pos, rete.name);
	}

	while (1) {
		memset(&dr, 0, DirectoryRecord.sizeof);
		fread(&dr, 1, DirectoryRecord.sizeof, isofile);

		if (dr.DirectoryLength == 0) {
			if (SECTOR_SIZE - (fpointer % SECTOR_SIZE) > oldDirLen) break;
			fpointer += (SECTOR_SIZE - (fpointer % SECTOR_SIZE));
			fseek(isofile, fpointer, SEEK_SET);
			fread(&dr, 1, DirectoryRecord.sizeof, isofile);
			if (dr.DirectoryLength == 0) break;
		}

		if (dr.FileName[0] != 0 && dr.FileName[0] != 1) {
			char[] name; if (add.length) name ~= add ~ "/";
			name ~= toString(dr.FileName.ptr);

			if (dr.FileFlags) {
				fseek(isofile, dr.ExtentLocation * SECTOR_SIZE, SEEK_SET);
				IsoGetStruct(isofile, &dr, name, ret);
			} else {
				AddEntry(name, dr.ExtentLocation * SECTOR_SIZE, dr.DataLength);
			}
		}

		fpointer += dr.DirectoryLength;
		oldDirLen = dr.DirectoryLength;
		fseek(isofile, fpointer, SEEK_SET);
	}
}

/*
int main() {
	FILE *f = fopen("\\toe\\bin\\TOE-ESP-PSP.iso", "rb");

	auto retl = IsoGetStruct(f);

	foreach (cret; retl) {
		writefln("%s - %08X, %08X", cret.name, cret.pos, cret.size);
	}

	fclose(f);

	return 0;
}
*/
