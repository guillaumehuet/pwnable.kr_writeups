#!/bin/sh
sshpass -p guest scp -P2222 passcode@pwnable.kr:passcode{,.c} .
cp ../fake_flag flag
