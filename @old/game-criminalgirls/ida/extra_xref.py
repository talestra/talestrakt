# LOAD:810E3DAC imy_related5

def parseInt(str):
    if (str[0] == '#'):
        return parseInt(str[1:])

    if (str[0:2] == '0x'):
        return int(str[2:], 16)
    else:
        return int(str[0:], 10)

def hasInt(str):
    r = re.search('#((0x)?[\da-fA-F]+)', str)
    if r:
        return 1
    else:
        return 0

def extractInt(str):
    r = re.search('#((0x)?[\da-fA-F]+)', str)
    if r:
        return parseInt(r.group(1))
    else:
        print 'extractInt:' + str
        return 0

def extractInsn(str):
    r = re.search('^(\w+)', str)
    if r:
        return r.group(1)
    else:
        print str
        return ''

def extractFirstReg(str):
    r = re.search('^(\w+)\s+(\w+)', str)
    if r:
        return r.group(2)
    else:
        return ''

def createCodeToDataRef(codePtr, dataPtr):
    add_dref(codePtr, dataPtr, dr_R)
    add_dref(dataPtr, codePtr, dr_R)

def extractMOVT(addr1):
    i1 = GetDisasm(addr1)
    if (extractInsn(i1) != 'MOVT'):
        #raise ValueError("Not a MOVT")
        return
    reg1 = extractFirstReg(i1)
    highValue = extractInt(i1)
    for n in range(0, 10):
        addr2 = addr1 - n * 4
        i2 = GetDisasm(addr2)
        if (extractInsn(i2) == 'MOV'):
            reg2 = extractFirstReg(i2)
            if ((reg1 == reg2) and hasInt(i2)):
                lowValue = extractInt(i2)
                value = (highValue << 16) | lowValue
                createCodeToDataRef(addr1, value)
                #print hex(value)
                return
    return

start = 0x810000C0
#end = 0x810000F0
end = 0x8112DF0C

for n in range(start, end, 4):
    #print n
    extractMOVT(n)

#print range(start, end, 4)
#