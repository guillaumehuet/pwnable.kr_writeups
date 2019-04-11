#!/bin/sh
sshpass -p guest scp -P2222 shellshock@pwnable.kr:* .
cp ../fake_flag flag
