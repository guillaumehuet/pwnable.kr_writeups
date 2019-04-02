#!/usr/bin/env python

from pwn import *

def numbers_from_to(a = 0, b = None):
	if b == None:
		b = a
	return ''.join(str(n) + " " for n in range(a, b + 1))

def binary_search(io, c, nmax, nmin = 0):
	if nmin == nmax:
		for _ in range(c):
			io.sendline(str(nmin))
			io.recvline()
		io.sendline(str(nmin))
		return
	middle = (nmin + nmax) // 2
	payload = numbers_from_to(nmin, middle)
	io.sendline(payload)
	weight = int(io.recvline())
	if weight % 10:
		binary_search(io, c - 1, middle, nmin)
	else:
		binary_search(io, c - 1, nmax, middle + 1)
	return

io = remote('localhost', 9007)

io.recvuntil('... -')


for _ in range(100):
	io.recvuntil('=')
	n = int(io.recvuntil(' '))
	io.recvuntil('=')
	c = int(io.recvuntil('\n'))
	binary_search(io, c, n - 1)
	print(io.recvline(False))

io.recvline()
print(io.recvline())
io.close()
