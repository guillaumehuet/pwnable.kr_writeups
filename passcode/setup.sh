#!/bin/sh
sshpass -p guest scp -P2222 passcode@pwnable.kr:* .
cp ../fake_flag flag
