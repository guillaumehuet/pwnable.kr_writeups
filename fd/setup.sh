#!/bin/sh
sshpass -p guest scp -P2222 fd@pwnable.kr:fd{,.c} .
cp ../fake_flag flag
