#!/bin/sh
sshpass -p guest scp -P2222 lotto@pwnable.kr:* .
cp ../fake_flag flag
