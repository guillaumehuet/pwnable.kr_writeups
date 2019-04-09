#!/bin/sh
sshpass -p guest scp -P2222 asm@pwnable.kr:{asm{,.c},this*,readme} .

