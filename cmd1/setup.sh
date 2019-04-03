#!/bin/sh
sshpass -p guest scp -P2222 cmd1@pwnable.kr:cmd1{,.c} .
cp ../fake_flag flag
