#!/bin/sh
sshpass -p guest scp -P2222 fd@pwnable.kr:* .
cp ../fake_flag flag
