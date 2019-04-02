#!/bin/sh
sshpass -p guest scp -P2222 mistake@pwnable.kr:mistake{,.c} .
cp ../fake_flag flag
