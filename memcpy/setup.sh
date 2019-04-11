#!/bin/sh
wget -N http://pwnable.kr/bin/memcpy.c
gcc -o memcpy memcpy.c -m32 -lm
