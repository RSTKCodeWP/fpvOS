#####temp enable#######
#PERI_CRG4560
#devmem 0x11014740 32 0x11

#TSENSOR_CTRL0



#let tmp=`devmem 0x0a108038`
#<6:4> = 111
#let mask=0x70
#let val=$(($tmp|$mask))
#devmem 0x0a108038 32 $val

#while true
#do
#	let temp0=`devmem 0x1102a008`
#	let mask=0x3ff
#	let temp1=$(($temp0&$mask))
#	let temp=$temp1-127
#	let temp2=$temp*165
#	let temp3=$(expr temp2/784)
#	let val=$temp3-40
	#let val=$(($temp3*165-40))
	
#	echo `date` raw:$temp1 temp3:$val

#	sleep 1

#done

get_cpu_temp() {
    temp0=$(devmem 0x1102a008)
    mask=0x3ff
    temp1=$((temp0 & mask))
    temp=$((temp1 - 127))
    temp2=$((temp * 165))
    temp3=$(expr $temp2 / 784)
    val=$((temp3 - 40))
    echo $temp1
}

if [ "$1" == "1" ]; then
    get_cpu_temp
else
    while true
    do
        get_cpu_temp
        sleep 1
    done
fi
