#!/bin/sh
sshpass -p guest scp -P2222 cmd1@pwnable.kr:* .
cp ../fake_flag flag
