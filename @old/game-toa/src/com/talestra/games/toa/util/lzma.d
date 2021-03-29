import std.stdio, std.file, std.string;

alias ushort CProb;

struct CLzmaProperties { int lc, lp, pb; }
struct CLzmaDecoderState { CLzmaProperties Properties; CProb* Probs; }

const uint LZMA_RESULT_OK = 0;
const uint LZMA_RESULT_DATA_ERROR = 1;

const uint LZMA_BASE_SIZE = 1846;
const uint LZMA_LIT_SIZE = 768;
const uint LZMA_PROPERTIES_SIZE = 5;

extern(C) int LzmaDecode(CLzmaDecoderState* vs, ubyte* inStream, uint inSize, uint* inSizeProcessed, ubyte* outStream, uint outSize, uint* outSizeProcessed);
extern(C) int LzmaDecodeProperties(CLzmaProperties* propsRes, ubyte* propsData, int size);
int LzmaGetNumProbs(CLzmaProperties Properties) { return (LZMA_BASE_SIZE + (LZMA_LIT_SIZE << (Properties.lc + Properties.lp))); }


ubyte[] LzmaDecode(ubyte[] d_in) {
	CLzmaDecoderState vs;
	CProb[] cprobs;
	uint outSize;
	uint inSize = d_in.length;
	ubyte[] r;

	try {
		if (LzmaDecodeProperties(&vs.Properties, d_in.ptr, LZMA_PROPERTIES_SIZE) != LZMA_RESULT_OK) throw(new Exception("Invalid LZMA header"));

		cprobs = new CProb[LzmaGetNumProbs(vs.Properties)];
		vs.Probs = cprobs.ptr;
		
		outSize = cast(uint)*(cast(ulong *)(d_in.ptr + LZMA_PROPERTIES_SIZE));
		
		if (outSize > 0x4000000) throw(new Exception(format("Too big output %d", outSize)));
		
		r.length = outSize;
		
		ubyte *inData = (d_in.ptr + LZMA_PROPERTIES_SIZE + 8);
		
		if (LzmaDecode(&vs, inData, inSize, &inSize, r.ptr, outSize, &outSize) != LZMA_RESULT_OK) throw(new Exception("Invalid LZMA stream"));
		if (outSize != r.length) throw(new Exception("Invalid LZMA stream output size"));
	} finally {
		cprobs.length = 0;
	}
	
	return r;
}

alias LzmaDecode decode;