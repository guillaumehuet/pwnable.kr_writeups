#!/bin/sh
sshpass -p guest scp -P2222 shellshock@pwnable.kr:{shellshock{,.c},bash} .
cp ../fake_flag flag
