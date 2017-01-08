module tales.image.tim2;

import tales.image.image;
import std.stream, std.file, std.string, std.stdio, std.string, std.math;
import tales.common;

align(1) struct TIM2Header {
	ubyte[4] FileId = ['T', 'I', 'M', '2']; //  ID of the File (must be 'T', 'I', 'M' and '2')
	ubyte    FormatVersion; // Version number of the format
	ubyte    FormatId;      // ID of the format
	ushort   Pictures;      // Number of picture data
	ubyte[8] pad;           // Padding (must be 0x00)
}

align(1) struct TIM2EntryHeader {
	uint   TotalSize;   // Total size of the picture data in bytes
	uint   ClutSize;    // CLUT data size in bytes
	uint   ImageSize;   // Image data size in bytes
	ushort HeaderSize;  // Header size in bytes
	ushort ClutColors;  // Total color number in CLUT data
	ubyte  PictFormat;  // ID of the picture format (must be 0)
	ubyte  MipMapTexs;  // Number of MIPMAP texture
	ubyte  ClutType;    // Type of the CLUT data
	ubyte  ImageType;   // Type of the Image data
	ushort ImageWidth;  // Width of the picture
	ushort ImageHeight; // Height of the picture

	ubyte GsTex0[8];    // Data for GS TEX0 register
	ubyte GsTex1[8];    // Data for GS TEX1 register
	uint  GsRegs;       // Data for GS TEXA, FBA, PABE register
	uint  GsTexClut;    // Data for GS TEXCLUT register
}

align(1) struct TIM2MipMapHeader{
	ulong GsMiptbp1;
	ulong GsMiptbp2;
	uint  MMImageSize[0];
}

align(1) struct TIM2ExtHeader {
	ubyte[4] ExHeaderId = ['e', 'X', 't', 0];
	uint     UserSpaceSize;
	uint     UserDataSize;
	uint     Reserved;
}

void Dump(TIM2EntryHeader teh) {
	writefln("TIM2EntryHeader (%04X) {", teh.sizeof);
	writefln("  TotalSize:   %08X", teh.TotalSize);
	writefln("  ClutSize:    %08X", teh.ClutSize);
	writefln("  ImageSize:   %08X", teh.ImageSize);
	writefln("  HeaderSize:  %04X", teh.HeaderSize);
	writefln("  ClutColors:  %04X", teh.ClutColors);
	writefln("  PictFormat:  %02X", teh.PictFormat);
	writefln("  MipMapTexs:  %02X", teh.MipMapTexs);
	writefln("  ClutType:    %02X", teh.ClutType);
	writefln("  ImageType:   %02X", teh.ImageType);
	writefln("  ImageWidth:  %04X", teh.ImageWidth);
	writefln("  ImageHeight: %04X", teh.ImageHeight);
	writefln("  GsTex0:      %02X", teh.GsTex0);
	writefln("  GsTex1:      %02X", teh.GsTex1);
	writefln("  GsRegs:      %08X", teh.GsRegs);
	writefln("  GsTexClut:   %08X", teh.GsTexClut);
	writefln("}");
}

class TIM2 {
	Image[] images;

	void load(Stream s) {
		ushort cimages;
		ubyte[] temp;
		temp.length = 4;
		s.read(temp);
		if (cast(char[])temp != "TIM2") throw(new Exception("File isn't a TIM2 one"));
		s.position = 0x6;
		s.read(cimages);
		s.position = 0x10;

		for (int ni = 0; ni < cimages; ni++) {
			Image image;
			ubyte[] palette;
			ubyte[] dimage;

			// Leemos el header
			TIM2EntryHeader teh; s.read(TSerialize(&teh));
			s.seek(teh.HeaderSize - teh.sizeof, SeekPos.Current);

			// Leemos la imagen
			dimage.length = teh.ImageSize; s.read(dimage);

			//Dump(teh);
			
			Dump(teh);

			switch (teh.ImageType) {
				case 0x05: // con paleta (4 bits)
					image = new Image(teh.ImageWidth, teh.ImageHeight, 1);
					
					switch (teh.ClutType) {
						case 0x02:
						case 0x03:
							uint pbpp = (teh.ClutType + 1);
							//writefln("TYPE:", pbpp);
							//s.seek(teh.ClutSize - pbpp * 0x10, SeekPos.Current);

							// Leemos la paleta
							palette.length = teh.ClutSize; s.read(palette);

							image.ncol = teh.ClutColors;
							for (int y = 0, n = 0; y < teh.ImageHeight; y++) {
								for (int x = 0; x < teh.ImageWidth; x++, n++) {
									image.putpixel(x, y, dimage[n]);
								}
							}

							for (int n = 0; n < image.ncol; n++) {
								/*const uint b5 = ((1 << 5) - 1);
								ushort c = (palette[n * 2] << 8) | (palette[n * 2 + 1] << 0);
								image.pal.rgba[n].r = ((c >>  0) & b5) << 3;
								image.pal.rgba[n].g = ((c >>  5) & b5) << 3;
								image.pal.rgba[n].b = ((c >> 10) & b5) << 3;
								image.pal.rgba[n].a = 0xFF;*/
								image.pal.rgba[n].r = palette[n * pbpp + 0];
								image.pal.rgba[n].g = palette[n * pbpp + 1];
								image.pal.rgba[n].b = palette[n * pbpp + 2];
								if (pbpp > 3) image.pal.rgba[n].a = palette[n * pbpp + 3];
								//writefln("#%02X%02X%02X%02X", image.pal.rgba[n].r, image.pal.rgba[n].g, image.pal.rgba[n].b, image.pal.rgba[n].a);
							}
							for (int n = 8; n < 256; n += 4 * 8) {
								for (int m = 0; m < 8; m++) {
									Color ct = image.pal.rgba[n + m];
									image.pal.rgba[n + m] = image.pal.rgba[n + m + 8];
									image.pal.rgba[n + m + 8] = ct;
								}
							}
							//writefln("%d, %d", palette.length, image.ncol * pbpp);
						break;
						default:
							throw(new Exception("Unknown TIM2 Clut Type"));
						break;
					}
					
					//throw(new Exception("Not implemented"));
				break;
				case 0x04: // con paleta (4 bits)
					image = new Image(teh.ImageWidth, teh.ImageHeight, 1);
					//image.data[0..dimage.length] = dimage[0..dimage.length];

					switch (teh.ClutType) {
						case 0x02:
						case 0x03:
							uint pbpp = (teh.ClutType + 1);
							//writefln("TYPE:", pbpp);
							//s.seek(teh.ClutSize - pbpp * 0x10, SeekPos.Current);

							// Leemos la paleta
							palette.length = teh.ClutSize; s.read(palette);

							image.ncol = teh.ClutColors;
							for (int y = 0, n = 0; y < teh.ImageHeight; y++) {
								for (int x = 0; x < teh.ImageWidth; x += 2, n++) {
									image.putpixel(x + 0, y, (dimage[n] & 0x0F) >> 0);
									image.putpixel(x + 1, y, (dimage[n] & 0xF0) >> 4);
								}
							}

							for (int n = 0; n < image.ncol; n++) {
								/*const uint b5 = ((1 << 5) - 1);
								ushort c = (palette[n * 2] << 8) | (palette[n * 2 + 1] << 0);
								image.pal.rgba[n].r = ((c >>  0) & b5) << 3;
								image.pal.rgba[n].g = ((c >>  5) & b5) << 3;
								image.pal.rgba[n].b = ((c >> 10) & b5) << 3;
								image.pal.rgba[n].a = 0xFF;*/
								image.pal.rgba[n].r = palette[n * pbpp + 0];
								image.pal.rgba[n].g = palette[n * pbpp + 1];
								image.pal.rgba[n].b = palette[n * pbpp + 2];
								if (pbpp > 3) image.pal.rgba[n].a = palette[n * pbpp + 3];
								//writefln("#%02X%02X%02X%02X", image.pal.rgba[n].r, image.pal.rgba[n].g, image.pal.rgba[n].b, image.pal.rgba[n].a);
							}
							//writefln("%d, %d", palette.length, image.ncol * pbpp);
						break;
						default:
							throw(new Exception("Unknown TIM2 Clut Type"));
						break;
					}
				break;
				case 0x03: // a 32 bits
					image = new Image(teh.ImageWidth, teh.ImageHeight, 4);
					image.data[0..dimage.length] = dimage[0..dimage.length];
				break;
				default:
					throw(new Exception("Unknown TIM2 Image Type"));
				break;
			}

			//image.savetga(format("%04d.tga", ni));

			images ~= image;

			//break;
		}
	}

	this(Stream s) {
		load(s);
	}

	this(char[] f) {
		File s = new File(f, FileMode.In);
		load(s);
		s.close();
	}
}