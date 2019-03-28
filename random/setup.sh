#!/bin/sh
sshpass -p guest scp -P2222 random@pwnable.kr:random{,.c} .
cp ../fake_flag flag
