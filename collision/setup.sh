#!/bin/sh
sshpass -p guest scp -P2222 col@pwnable.kr:* .
cp ../fake_flag flag
