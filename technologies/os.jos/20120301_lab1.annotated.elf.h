#ifndef JOS_INC_ELF_H
#define JOS_INC_ELF_H

#define ELF_MAGIC 0x464C457FU	/* "\x7FELF" in little endian */

struct Elf {
	uint32_t e_magic;	// must equal ELF_MAGIC
	uint8_t e_elf[12];	// object class (32-bit or 64-), endianness, header version, padding, etc.
	uint16_t e_type;	// the object file type
	uint16_t e_machine;	// required architecture for this file
	uint32_t e_version;	// object file version
	uint32_t e_entry;	// the virtual address to which the system first transfers control
	uint32_t e_phoff;	// the program header table's file offset in bytes
	uint32_t e_shoff;	// the section header table's file offset in bytes
	uint32_t e_flags;	// process-specific flags associated with the file
	uint16_t e_ehsize;	// ELF header's size in bytes
	uint16_t e_phentsize;	// program header table entry size in bytes
	uint16_t e_phnum;	// # entries in the program header table
	uint16_t e_shentsize;	// section header table entry size in bytes
	uint16_t e_shnum;	// # entries in the section header table
	uint16_t e_shstrndx;	// index for the section name string table in section header table
};

struct Proghdr {
	uint32_t p_type;	// segment type
	uint32_t p_offset;	// offset in bytes of the segment in the file
	uint32_t p_va;		// virtual address this segment to be loaded
	uint32_t p_pa;		// physical address (if applicable)
	uint32_t p_filesz;	// # bytes of the segment in file
	uint32_t p_memsz;	// # bytes of the segment in memory
	uint32_t p_flags;	// flags
	uint32_t p_align;	// value to which the segments are aligned in memory and in file
};

struct Secthdr {
	uint32_t sh_name;	// section name's index into the section header string table
	uint32_t sh_type;	// section type
	uint32_t sh_flags;	// attributes (write, alloc, etc.)
	uint32_t sh_addr;	// the address of the section's first byte in memory (if applicable)
	uint32_t sh_offset;	// offset of the section's first byte from the beginning of the file
	uint32_t sh_size;	// section size
	uint32_t sh_link;	// these two members are
	uint32_t sh_info;	// section type-specific.
	uint32_t sh_addralign;	// address alignment constraints
	uint32_t sh_entsize;	// size in bytes for fixed-size entries such as in symbol table; otherwise 0
};

// Values for Proghdr::p_type
#define ELF_PROG_LOAD		1

// Flag bits for Proghdr::p_flags
#define ELF_PROG_FLAG_EXEC	1
#define ELF_PROG_FLAG_WRITE	2
#define ELF_PROG_FLAG_READ	4

// Values for Secthdr::sh_type
#define ELF_SHT_NULL		0
#define ELF_SHT_PROGBITS	1
#define ELF_SHT_SYMTAB		2
#define ELF_SHT_STRTAB		3

// Values for Secthdr::sh_name
#define ELF_SHN_UNDEF		0

#endif /* !JOS_INC_ELF_H */
