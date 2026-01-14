typedef struct {
    unsigned char FileID;
    unsigned char Version;
    unsigned short Reserved;
    unsigned int Flags;
} CLT;

// instantiate a CLT struct
CLT clut;

// set the FileID to 0x01
clut.FileID = 0x01;

// set the Version to 0x01
clut.Version = 0x01;

// set the Reserved to 0x0000
clut.Reserved = 0x0000;

// set the Flags to 0x00000000
clut.Flags = 0x00000000;
