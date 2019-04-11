# collision Writeup

## Challenge infos

```text
Daddy told me about cool MD5 hash collision today.
I wanna do something like that too!

ssh col@pwnable.kr -p2222 (pw:guest)
```

## Server content

```text
$ sshpass -p guest ssh col@pwnable.kr -p2222
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
Last login: Wed Apr 10 23:44:42 2019 from 61.138.251.22
col@ubuntu:~$ ls -la
total 36
drwxr-x---  5 root    col     4096 Oct 23  2016 .
drwxr-xr-x 93 root    root    4096 Oct 10 22:56 ..
d---------  2 root    root    4096 Jun 12  2014 .bash_history
-r-sr-x---  1 col_pwn col     7341 Jun 11  2014 col
-rw-r--r--  1 root    root     555 Jun 12  2014 col.c
-r--r-----  1 col_pwn col_pwn   52 Jun 11  2014 flag
dr-xr-xr-x  2 root    root    4096 Aug 20  2014 .irssi
drwxr-xr-x  2 root    root    4096 Oct 23  2016 .pwntools-cache
col@ubuntu:~$ id
uid=1005(col) gid=1005(col) groups=1005(col)
col@ubuntu:~$ file col
col: setuid ELF 32-bit LSB executable, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-, for GNU/Linux 2.6.24, BuildID[sha1]=05a10e253161f02d8e6553d95018bc82c7b531fe, not stripped
col@ubuntu:~$ cat col.c
#include <stdio.h>
#include <string.h>
unsigned long hashcode = 0x21DD09EC;
unsigned long check_password(const char* p){
        int* ip = (int*)p;
        int i;
        int res=0;
        for(i=0; i<5; i++){
                res += ip[i];
        }
        return res;
}

int main(int argc, char* argv[]){
        if(argc<2){
                printf("usage : %s [passcode]\n", argv[0]);
                return 0;
        }
        if(strlen(argv[1]) != 20){
                printf("passcode length should be 20 bytes\n");
                return 0;
        }

        if(hashcode == check_password( argv[1] )){
                system("/bin/cat flag");
                return 0;
        }
        else
                printf("wrong passcode.\n");
        return 0;
}
col@ubuntu:~$
```
## Exploitation objective
* The ssh user is ```col```, group ```col```
* The ```flag``` file is readable only by the user ```col_pwn``` or the group ```col_pwn```
* The ```col``` binary is a 32bit ELF executable by the ```col_pwn``` user or members of the ```col``` group and is ```suid``` meaning that it executes with the rights of its user even if called by a member of its group

This means that if we pwn the ```col``` executable we can gain read access to the ```flag``` file via suid user ```col_pwn```.

The ```col``` executable is certainly compiled from the ```col.c``` source code, let's have a look.

## C code analysis
```c
unsigned long hashcode = 0x21DD09EC;
```

* The target hash is hardcoded in the source file to be ```0x21DD09EC```


```c
unsigned long check_password(const char* p){
        int* ip = (int*)p;
        int i;
        int res=0;
        for(i=0; i<5; i++){
                res += ip[i];
        }
        return res;
}
```

* The hashing algorithm consists of rounds on blocks of 4 characters of the password (sizeof(int) = 4 and sizeof(char) = 1 on 32bit systems), the first five blocks (4*5 = 20 characters) are simply added together to produce the hash

```c
        if(argc<2){
                printf("usage : %s [passcode]\n", argv[0]);
                return 0;
        }
```

* We need to supply the ```passcode``` as the first command line argument : ```./col [passcode]```

```c
        if(strlen(argv[1]) != 20){
                printf("passcode length should be 20 bytes\n");
                return 0;
```

* The ```passcode``` should be 20 characters long, this is consistent with the hashing algorithm

```c
        if(hashcode == check_password( argv[1] )){
                system("/bin/cat flag");
                return 0;
        }
```

* If the hash of the passcode correspond to the hardcoded hash, the executable calls ```system()``` to output the content of ```flag``` with ```cat```, this is our target

## Hashing algorithm reversing

The hashing is a simple addition, the simplest way to get a matching hash would be to set the first 5 characters of the ```passcode``` to ```0x21DD09EC``` and then the remaining 15 characters to all ```0x00```, but ```strlen()``` expects ```NULL``` (```0x00```) terminated strings and the calculated length of the ```passcode``` would be only 4.

* In order to compute the correct length we need to get a passcode with no ```NULL``` (```0x00```) bytes, let's define each of the remaining characters to be ```0x01```
* The resulting ```passcode``` would be (separated by hashing blocks) : ```0xnnnnnnnn 0x01010101 0x01010101 0x01010101 0x01010101```
* We need to comply to the rule ```0xnnnnnnnn + 0x01010101 + 0x01010101 + 0x01010101 + 0x01010101 == 0x21DD09EC <=> 0xnnnnnnnn == 0x21DD09EC - 0x4\*0x01010101 <=> 0xnnnnnnnn == 0x21DD09EC - 0x04040404 <=> 0xnnnnnnnn == 0x1DD905E8```
* The resulting passcode would be (separated by hashing blocks) : ```0x1DD905E8 0x01010101 0x01010101 0x01010101 0x01010101``` or in python string (NB : Be carefull, blocks are [Little Endian](https://fr.wikipedia.org/wiki/Endianness)) ```'\xE8\x05\xD9\x1D\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01'```

## Exploitation

* We simply need to pass the computed ```passcode``` as the first argument to the ```./col``` call

* We can use python on the command line to pass non printable characters as arguments : ```./col $(python -c "print('\xE8\x05\xD9\x1D\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01')")```

* The check is then passed and the ```flag``` is output

* ```PWN```

## Exploitation script

```python
#!/usr/bin/env python

from pwn import *
```
* Use [pwntools](https://github.com/Gallopsled/pwntools) for automatic exploitation
```python
target_hash = 0x21DD09EC
last_ints = 0x01010101
first_int = target_hash - 4*(last_ints)

argv_1 = p32(first_int) + 4*p32(last_ints)
```
* Compute the ```argv_1``` variable from the hardcoded hash value with the algorithm described above.
* ```p32()``` is used to pack 32bits values to strings with correct padding and endianness
```python
#io = process(['./col', argv_1])

server = ssh('col', 'pwnable.kr', 2222, 'guest')

io = server.process(['./col', argv_1])
```
* During testing the ```io``` is set to the local ```./col``` executable downloaded by the setup script
* After the exploit is working we can use it on the server by ssh-ing to it before setting ```io``` to the remote ```.\col``` executable
* In both cases, pass the ```argv_1``` argument
```python
result = io.recvall()

io.close()
server.close()

print(result)
```
* Print the ```result``` which is the ```flag```
* ```PWN```
