#!/bin/sh
sshpass -p guest scp -P2222 lotto@pwnable.kr:lotto{,.c} .
cp ../fake_flag flag
