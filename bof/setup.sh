#!/bin/sh
wget -N http://pwnable.kr/bin/bof
wget -N http://pwnable.kr/bin/bof.c
cp ../fake_flag flag
chmod +x ./bof
