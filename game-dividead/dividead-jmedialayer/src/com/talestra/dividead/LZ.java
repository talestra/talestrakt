package com.talestra.dividead;


import com.jtransc.annotation.JTranscInline;
import com.jtransc.io.ra.RAByteArray;
import jmedialayer.util.FastMemByte;

import java.util.Arrays;
import java.util.Objects;

public class LZ {
    static public boolean isCompressed(byte[] data) {
        return Objects.equals(RAStreamExKt.readStringz(new RAByteArray(data), 2), "LZ");
    }

    static public int getUncompressedSize(byte[] data) {
        return new RAByteArray(data).sliceAvailable(6).readS32_LE();
    }

    static public byte[] uncompress(byte[] data) {
        if (data == null || data.length == 0) return new byte[0];
        RAByteArray sdata = new RAByteArray(data);
        String magic = RAStreamExKt.readStringz(sdata, 2);
        int compressedSize = sdata.readS32_LE();
        int uncompressedSize = sdata.readS32_LE();
        if (!Objects.equals(magic, "LZ")) throw new RuntimeException("Invalid LZ stream");
        return _decodeFast(sdata.readBytes((long) compressedSize), uncompressedSize);
    }

    static private byte[] _decodeFast(byte[] input, int uncompressedSize) {
        int ip = 0;
        int il = input.length;


        byte[] o2 = new byte[uncompressedSize + 0x1000];
        int op = 0x1000;
        int ringStart = 0xFEE;

        FastMemByte.selectSRC(input);
        FastMemByte.selectDST(o2);

        while (ip < il) {
            int code = FastMemByte.getSRC_u(ip++) | 0x100;

            while (code != 1) {
                // Uncompressed
                if ((code & 1) != 0) {
                    FastMemByte.setDST(op++, FastMemByte.getSRC_u(ip++));
                }
                // Compressed
                else {
                    if (ip >= il) break;
                    int paramL = FastMemByte.getSRC_u(ip++);
                    int paramH = FastMemByte.getSRC_u(ip++);
                    int param = paramL | (paramH << 8);
                    int ringOffset = extractPosition(param);
                    int ringLength = extractCount(param);
                    int convertedP2 = ((ringStart + op) & 0xFFF) - ringOffset;
                    int convertedP = (convertedP2 < 0) ? convertedP2 + 0x1000 : convertedP2;
                    int outputReadOffset = op - convertedP;

                    for (int n = 0; n < ringLength; n++) {
                        FastMemByte.setDST(op + n, FastMemByte.getDST_u(outputReadOffset + n));
                    }
                    op += ringLength;
                }

                code = code >>> 1;
            }
        }

        return Arrays.copyOfRange(o2, 0x1000, 0x1000 + uncompressedSize);
    }

    @JTranscInline
    static private int extractPosition(int param) {
        return (param & 0xFF) | ((param >>> 4) & 0xF00);
    }

    @JTranscInline
    static private int extractCount(int param) {
        return ((param >>> 8) & 0xF) + 3;
    }
}
