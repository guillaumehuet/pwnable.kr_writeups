
# pwnable.kr_writeups
Exploits scripts and writeups for the https://pwnable.kr/play.php CTF challenges

## Requirements
Requires pwntools (https://github.com/Gallopsled/pwntools)

## File structure
Each challenge is contained in its own folder

Each folder consists of 4 files :
* setup.sh : Setup script usually for downloading the provided files for the challenge (run before exploit)
* exploit.[py|sh] : Exploit script retrieving the flag from the target
* clean.sh : Cleanup script to revert the folder content to the 4 initial files
* writeup.md : Writeup explaining the exploit script

## Challenges status

### Legend :
* unsolved
* [solved](fd)
* [solved with writeup](fd) ([writeup](fd/writeup.md))

### Toddler's Bottle
* [fd](fd) ([writeup](fd/writeup.md))
* [collision](collision) ([writeup](collision/writeup.md))
* [bof](bof) ([writeup](bof/writeup.md))
* [flag](flag) ([writeup](flag/writeup.md))
* [passcode](passcode) ([writeup](passcode/writeup.md))
* [random](random)
* input
* [leg](leg)
* [mistake](mistake)
* [shellshock](shellshock)
* [coin1](coin1)
* [blackjack](blackjack)
* [lotto](lotto)
* [cmd1](cmd1)
* [cmd2](cmd2)
* uaf
* [memcpy](memcpy)
* [asm](asm)
* [unlink](unlink)
* blukat
* horcruxes

### Rookiss
* brain fuck
* md5 calculator
* simple login
* otp
* ascii_easy
* tiny_easy
* fsb
* dragon
* fix
* syscall
* crypto1
* echo1
* echo2
* rsa calculator
* note
* alloca
* loveletter

### Grotesque
* proxy server
* rootkit
* dos4fun
* ascii
* aeg
* coin2
* maze
* wtf
* sudoku
* starcraft
* cmd3
* elf
* lfh
* lokihardt
* asg
* hunter
* mipstake

### Hacker's Secret
* unexploitable
* tiny
* softmmu
* towelroot
* nuclear
* malware
* exploitable
* tiny_hard
* kcrc
* exynos
* combabo calculator
* pwnsandbox
* crcgen
