# flag Writeup

## Challenge infos

```text
Papa brought me a packed present! let's open it.

Download : http://pwnable.kr/bin/flag

This is reversing task. all you need is binary
```

## Server content

```text
$ wget http://pwnable.kr/bin/flag
--2019-04-11 20:19:09--  http://pwnable.kr/bin/flag
Resolving pwnable.kr (pwnable.kr)... 143.248.249.64
Connecting to pwnable.kr (pwnable.kr)|143.248.249.64|:80... connected.
HTTP request sent, awaiting response... 301 Moved Permanently
Location: https://pwnable.kr/bin/flag [following]
--2019-04-11 20:19:09--  https://pwnable.kr/bin/flag
Connecting to pwnable.kr (pwnable.kr)|143.248.249.64|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 335288 (327K)
Saving to: ‘flag’

flag                     100%[===============================>] 327.43K   231KB/s    in 1.4s

2019-04-11 20:19:12 (231 KB/s) - ‘flag’ saved [335288/335288]

$ file flag
flag: ELF 64-bit LSB executable, x86-64, version 1 (GNU/Linux), statically linked, stripped
$ chmod +x flag
$
```
## Exploitation objective
As the hint suggest, we "just" need to reverse the binary provided to get the flag

## Exploitation
* We try different binary information tools that are basically silent, even-though the executable seems to run fine.
* One of the tools tried is ```strings``` (to get all the data from the executable that look like an ASCII string of a minimum length) which is on the contrary very verbose with the default length of 4 but mostly gibberish.
* Let's try strings with a larger minimum length, for example 15.
```text
$ strings -n 15 flag
'''' (0h''''HPX`
np!f@(Q[uIB(0Tc
FFFF|vpjFFFFd^XR
^0HMdZp)->? & 0+03
?../:deps/x86_64
?_OUTPU1YNAMIC_WEAK
_~SO/IEC 14652 i18n FDC
*+,-./0>3x6789:;<=>?
@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_
`abcdefghijklmnopqrstuvwxyz{|}~
ANSI_X3.4&968//T
 "9999$%&/999956799999:<DG9999HI_`
#6''''<dej''''k
 ''''!#$`''''abcd''''efgh''''ijkl''''mnop''''qrst''''uvwx''''yz{|''''}~
Q2R''''STUV''''WXYZ''''[\]^''''_
MNONNNNPRTUNNNNVWYZNNNN[\_`NNNNabcdNNNNefhi
 rrrr!"#$rrrr%&'(rrrr)*+,rrrr-./0rrrr1234rrrr5678rrrr9;<=rrrr>@ABrrrrCDFJrrrrKLMNrrrrOPRSrrrrTUVWrrrrXYZ[rrrr\]^_rrrr`abcrrrrdefgrrrrhijkrrrrlmnorrrrpqrsrrrrtuvwrrrrxyz{rrrr|}~
 !"9999#$%&9999'()*9999+,-.9999/012999934569999789:9999;<=>9999?@AB9999CDEF9999GHIJ9999KLMN9999OPQR9999STUV9999WXYZ9999[\]^9999_`ab9999cdef9999ghij9999klmn9999opqr9999stuv9999wxyz9999{|}~9999
'12Wr%W345%Wr%67x!Wr892
b'cdr%WrefgWr%Whij%Wr%klr%WrmnoWr%Wpqr%Wr%str%WruvwWr%Wxyz%Wr%ABr%WrCDEWr%WFGH%Wr%IJr%WrKLMWr%WNOP%Wr%QRr%WrSTUWr%WVWX%Wr%YZ
_r%W;k'MGEp%WTu
pchuilqesyuustuw
 $9999(/6>9999HQXa9999eimq9999uy}
&9223372036854775807L`
PROT_EXEC|PROT_WRITE failed.
$Info: This file is packed with the UPX executable packer http://upx.sf.net $
$Id: UPX 3.08 Copyright (C) 1996-2011 the UPX Team. All Rights Reserved. $
GCC: (Ubuntu/Linaro 4.6.3-1u)#
ild-id$rela.plt
call_gmon_start
DEH_FRAME_BEGINf
_PRETTY_FUNCT0Na
C_>YPE/NUMERIC?
$
```
* Still a lot of gibberish values but two of them are very interesting :
```text
$Info: This file is packed with the UPX executable packer http://upx.sf.net $
$Id: UPX 3.08 Copyright (C) 1996-2011 the UPX Team. All Rights Reserved. $
```
* There's even a convenient link to download the appropriate tool!
* Let's follow the link, which advise us to download the latest release at https://github.com/upx/upx/releases/latest
```text
$ wget https://github.com/upx/upx/releases/download/v3.95/upx-3.95-i386_linux.tar.xz
--2019-04-11 20:41:33--  https://github.com/upx/upx/releases/download/v3.95/upx-3.95-i386_linux.tar.xz
Resolving github.com (github.com)... 192.30.253.113, 192.30.253.112
Connecting to github.com (github.com)|192.30.253.113|:443... connected.
HTTP request sent, awaiting response... 302 Found
Location: https://github-production-release-asset-2e65be.s3.amazonaws.com/67031040/ea39ab00-a8f2-11e8-8901-377620ed6594?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20190411%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20190411T204133Z&X-Amz-Expires=300&X-Amz-Signature=e1cfa082b2f7afd55e8bc4d995882488d84c4c3270d29f182f2b5f6db58bfc12&X-Amz-SignedHeaders=host&actor_id=0&response-content-disposition=attachment%3B%20filename%3Dupx-3.95-i386_linux.tar.xz&response-content-type=application%2Foctet-stream [following]
--2019-04-11 20:41:33--  https://github-production-release-asset-2e65be.s3.amazonaws.com/67031040/ea39ab00-a8f2-11e8-8901-377620ed6594?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20190411%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20190411T204133Z&X-Amz-Expires=300&X-Amz-Signature=e1cfa082b2f7afd55e8bc4d995882488d84c4c3270d29f182f2b5f6db58bfc12&X-Amz-SignedHeaders=host&actor_id=0&response-content-disposition=attachment%3B%20filename%3Dupx-3.95-i386_linux.tar.xz&response-content-type=application%2Foctet-stream
Resolving github-production-release-asset-2e65be.s3.amazonaws.com (github-production-release-asset-2e65be.s3.amazonaws.com)... 52.216.224.168
Connecting to github-production-release-asset-2e65be.s3.amazonaws.com (github-production-release-asset-2e65be.s3.amazonaws.com)|52.216.224.168|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 477560 (466K) [application/octet-stream]
Saving to: ‘upx-3.95-i386_linux.tar.xz’

upx-3.95-i386_linux.tar. 100%[===============================>] 466.37K  --.-KB/s    in 0.05s

2019-04-11 20:41:34 (9.88 MB/s) - ‘upx-3.95-i386_linux.tar.xz’ saved [477560/477560]

$ tar Jxf upx-3.95-i386_linux.tar.xz
$ cd upx-3.95-i386_linux/
$ ls
BUGS  COPYING  LICENSE  NEWS  README  README.1ST  THANKS  upx  upx.1  upx.doc  upx.html
$ ./upx
                       Ultimate Packer for eXecutables
                          Copyright (C) 1996 - 2018
UPX 3.95        Markus Oberhumer, Laszlo Molnar & John Reiser   Aug 26th 2018

Usage: upx [-123456789dlthVL] [-qvfk] [-o file] file..

Commands:
  -1     compress faster                   -9    compress better
  -d     decompress                        -l    list compressed file
  -t     test compressed file              -V    display version number
  -h     give more help                    -L    display software license
Options:
  -q     be quiet                          -v    be verbose
  -oFILE write output to 'FILE'
  -f     force compression of suspicious files
  -k     keep backup files
file..   executables to (de)compress

Type 'upx --help' for more detailed help.

UPX comes with ABSOLUTELY NO WARRANTY; for details visit https://upx.github.io
$
```
* It seems that executables compressed by UPX can be decompressed with the ```-d``` command line option, let's try it:
```text
$ ./upx -d ../flag
                       Ultimate Packer for eXecutables
                          Copyright (C) 1996 - 2018
UPX 3.95        Markus Oberhumer, Laszlo Molnar & John Reiser   Aug 26th 2018

        File size         Ratio      Format      Name
   --------------------   ------   -----------   -----------
    883745 <-    335288   37.94%   linux/amd64   flag

Unpacked 1 file.
$ cd ..
$ file flag
flag: ELF 64-bit LSB executable, x86-64, version 1 (GNU/Linux), statically linked, for GNU/Linux 2.6.24, BuildID[sha1]=96ec4cc272aeb383bd9ed26c0d4ac0eb5db41b16, not stripped
```
* That's good news, the ```flag``` executable that was stripped and hard to examine is actually not stripped after unpacking, we can try ```gdb``` on it :
```text
$ gdb ./flag
GNU gdb (Ubuntu 7.11.1-0ubuntu1~16.5) 7.11.1
Copyright (C) 2016 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
and "show warranty" for details.
This GDB was configured as "x86_64-linux-gnu".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<http://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
<http://www.gnu.org/software/gdb/documentation/>.
For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from ./flag...(no debugging symbols found)...done.
(gdb) disas main
Dump of assembler code for function main:
   0x0000000000401164 <+0>:     push   %rbp
   0x0000000000401165 <+1>:     mov    %rsp,%rbp
   0x0000000000401168 <+4>:     sub    $0x10,%rsp
   0x000000000040116c <+8>:     mov    $0x496658,%edi
   0x0000000000401171 <+13>:    callq  0x402080 <puts>
   0x0000000000401176 <+18>:    mov    $0x64,%edi
   0x000000000040117b <+23>:    callq  0x4099d0 <malloc>
   0x0000000000401180 <+28>:    mov    %rax,-0x8(%rbp)
   0x0000000000401184 <+32>:    mov    0x2c0ee5(%rip),%rdx        # 0x6c2070 <flag>
   0x000000000040118b <+39>:    mov    -0x8(%rbp),%rax
   0x000000000040118f <+43>:    mov    %rdx,%rsi
   0x0000000000401192 <+46>:    mov    %rax,%rdi
   0x0000000000401195 <+49>:    callq  0x400320
   0x000000000040119a <+54>:    mov    $0x0,%eax
   0x000000000040119f <+59>:    leaveq
   0x00000000004011a0 <+60>:    retq
End of assembler dump.
(gdb)
```
* Using a ```flag``` symbol right after the ```malloc``` ? That's very suspicious, let's look at what it points to
```text
(gdb) x/s flag
```
* ```PWN```

## Exploitation script
```bash
#!/bin/sh
wget -N https://github.com/upx/upx/releases/download/v3.95/upx-3.95-i386_linux.tar.xz
tar Jxf upx-3.95-i386_linux.tar.xz
```
* Download UPX and untar it
```bash
./upx-3.95-i386_linux/upx -d -o flag_unpacked flag
```
* Use it to unpack the ```flag``` executable
```bash
(echo "x/s flag"; echo "q") | gdb ./flag_unpacked
```
* Send the command to examine the content of the symbol ```flag``` and quit
* ```PWN```
