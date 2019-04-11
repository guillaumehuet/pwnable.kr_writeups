#!/bin/sh
sshpass -p guest scp -P2222 random@pwnable.kr:* .
cp ../fake_flag flag
