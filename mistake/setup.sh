#!/bin/sh
sshpass -p guest scp -P2222 mistake@pwnable.kr:* .
cp ../fake_flag flag
