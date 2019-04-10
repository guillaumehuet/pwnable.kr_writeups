#!/bin/sh
sshpass -p guest scp -P2222 unlink@pwnable.kr:unlink{,.c} .
cp ../fake_flag flag
