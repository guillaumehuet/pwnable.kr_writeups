#!/bin/sh
sshpass -p guest scp -P2222 col@pwnable.kr:col{,.c} .
cp ../fake_flag flag
