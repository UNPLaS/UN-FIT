#!/bin/bash
WHERE=$(dirname "$0")
if [ $# -lt 5 ]; then
	echo Usage: $(basename "$0") '<filename.elf> <architecture: 0-ARM, 1-RISCV> <Qemu machine> <Qemu memory> <end direction>' >&2
	exit 1
fi

bin="$1"
shift
arch="$1"
shift
mach="$1"
shift
mem="$1"
shift
dir="$1"
gdbarm=/home/alex/gcc-arm-none-eabi-9-2019-q4-major/bin/arm-none-eabi-gdb
gdbriscv=/opt/riscv32/bin/riscv32-unknown-elf-gdb
#qemu=qemu-system-arm
#qemu_riscv=/home/alex/Descargas/qemu/qemu/riscv32-softmmu/qemu-system-riscv32
qemu_riscv=/opt/qemu/bin/qemu-system-riscv32
qemu_arm=/opt/qemu/bin/qemu-system-arm
Tini=$(date +%s) 
ramdir=/dev/shm/$RANDOM
mkdir $ramdir
echo "target remote localhost:2159" > $ramdir/trace.gdb
echo "set logging file $ramdir/tr.txt" >> $ramdir/trace.gdb
echo set logging redirect on >> $ramdir/trace.gdb
echo set logging off >> $ramdir/trace.gdb
echo set height 0 >> $ramdir/trace.gdb 
echo "b *"$dir >> $ramdir/trace.gdb
echo "c" >> $ramdir/trace.gdb
echo "kill" >> $ramdir/trace.gdb
echo "q" >> $ramdir/trace.gdb


case $arch in
    0)
      nohup $qemu_arm -S -M $mach -m $mem -nographic -singlestep -d nochain,cpu -D $ramdir/logs_qemu.txt -gdb tcp::2159 -kernel $bin &
      $gdbarm -x $ramdir/trace.gdb
      cat $ramdir/logs_qemu.txt |grep R15|cut -f5 -d"=" >> trace_hexa.txt 
      rm $ramdir/logs_qemu.txt
       ;;
    1)
       nohup $qemu_riscv -S -M $mach -m $mem -nographic -singlestep -d nochain,cpu -D $ramdir/logs_qemu.txt -gdb tcp::2159 -kernel $bin &
      $gdbriscv -x $ramdir/trace.gdb
      #cp $ramdir/logs_qemu.txt logs_qemu.txt
      cat $ramdir/logs_qemu.txt |grep " pc"|sed 's/ //g'|sed 's/pc//g' >> trace_hexa.txt 
      ls -lh $ramdir/logs_qemu.txt
      rm $ramdir/logs_qemu.txt
       ;;    
    esac
    #cp $ramdir/trace.txt trace_hexa.txt
    while read number
    do
        echo $(( 16#$number )) >> trace.txt
    done <  trace_hexa.txt
   # cp $ramdir/trace_cpu.txt trace.txt
    echo Done!
    
rm -r $ramdir 
Tend=$(date +%s)
let Ttot=$Tend-$Tini
echo "Time in seg:"
echo $Ttot
