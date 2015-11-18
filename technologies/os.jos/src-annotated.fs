inc/fd.h:
16      struct Dev {
17              int dev_id;
18              char *dev_name;
19              ssize_t (*dev_read)(struct Fd *fd, void *buf, size_t len, off_t offset);
20              ssize_t (*dev_write)(struct Fd *fd, const void *buf, size_t len, off_t offset);
21              int (*dev_close)(struct Fd *fd);
22              int (*dev_stat)(struct Fd *fd, struct Stat *stat);
23              int (*dev_seek)(struct Fd *fd, off_t pos);
24              int (*dev_trunc)(struct Fd *fd, off_t length);
25      };
26      
27      struct FdFile {
28              int id;
29              struct File file;
30      };
31      
32      struct Fd {
33              int fd_dev_id;
34              off_t fd_offset;
35              int fd_omode;
36              union { // different types of objects are for different devices
37                      // File server files; may be we could also have fd_tape, etc.
38                      struct FdFile fd_file;
39              };
40      };

inc/fs.h:
28      struct File {
29              char f_name[MAXNAMELEN];        // filename
30              off_t f_size;                   // file size in bytes
31              uint32_t f_type;                // file type
32      
33              // Block pointers.
34              // A block is allocated iff its value is != 0.
35              uint32_t f_direct[NDIRECT];     // direct blocks
36              uint32_t f_indirect;            // indirect block
37      
38              // Points to the directory in which this file lives.
39              // Meaningful only in memory; the value on disk can be garbage.
40              // dir_lookup() sets the value when required.
41              struct File *f_dir;
42      
43              // Pad out to 256 bytes; must do arithmetic in case we're compiling
44              // fsformat on a 64-bit machine.
45              uint8_t f_pad[256 - MAXNAMELEN - 8 - 4*NDIRECT - 4 - sizeof(struct File*)];
46      } __attribute__((packed));      // required only on some 64-bit machines

fs/serv.c:
14      struct OpenFile {
15              uint32_t o_fileid;      // file id
16              struct File *o_file;    // mapped descriptor for open file
17              int o_mode;             // open mode
18              struct Fd *o_fd;        // Fd page
19      };
NOTE:
0. struct File is on-disk data structure maintained by directory.
1. struct OpenFile::o_fd is page-aligned and mapped to caller of open().
2. struct OpenFile::struct Fd *o_fd->struct FdFile fd_file.struct File file is a
   copy of *(struct OpenFile::struct File *o_file). This copying ensures that
   the server always keep a intact and private copy of struct File, while caller
   processes are free to modify the File passed to them.
3. sizeof(struct File) is 256 bytes with padding and sizeof(struct Fd) is mildly
   larger.
4. struct OpenFile::o_fileid (= struct OpenFile::o_fd->struct FdFile fd_file.id)
   is constructed based on this element in the array.
5. The struct OpenFile is the top structure for all that are relevant.
6. For every service calls, fs operates on the o_file (allocated by calling
   file_open()) and reflects the revelant changes to the copy mapped to callee:
   struct OpenFile::struct Fd *o_fd->struct FdFile fd_file.struct File file.

