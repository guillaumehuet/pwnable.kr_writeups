#!/bin/sh
sshpass -p guest scp -P2222 unlink@pwnable.kr:* .
cp ../fake_flag flag
