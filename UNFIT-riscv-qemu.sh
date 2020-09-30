#!/bin/bash
WHERE=$(dirname "$0")
if [ $# -lt 8 ]; then
	echo Usage: $(basename "$0") '<filename.elf> <Qemu machine> <Qemu memory> <num of injections> <reg to eval > <Bytes to evaluate (0 to result in register)> <Mod: 0-One Reg, 1-All reg, 2-All reg (including FPU reg)> <Num of proces> [Reg to inject (1 to 32 (32=PC))]' >&2
	exit 1
fi

bin="$1" 
shift
mach="$1"
shift
mem="$1"
shift
inj="$1"
shift
reg_resul="$1"
shift
size="$1"
shift
Mod="$1"
shift
NUM_PROC=$1
shift
if [ -n "$1" ]; then
	Reg="$1"
	shift	
	
else
    Reg=0
fi

#gdb path
gdb=/opt/riscv32/bin/riscv32-unknown-elf-gdb
#Qemu path
QEMU=/opt/qemu/bin/qemu-system-riscv32
#QEMU=/home/alex/Descargas/qemu/qemu/riscv32-softmmu/qemu-system-riscv32

#NUM_PROC=4

#Trace file check
if [ -f trace.txt ];
then
    lastdir=$( tail -n1 trace.txt )
    Reset=$( head -n1 trace.txt ) #Reset vector
    Iniprog=$( head -n 3 trace.txt| tail -n 1 ) #Ini program directio
    inst=$( cat trace.txt|wc -l) #Num of instructions
    let inst=inst-11
    #echo $inst
    high_dir=$( sort -nr trace.txt |head -n1 ) #Hihgest dir instruction
else
    echo "trace.txt not found"
    exit 1
fi

#RISCV Exceptions vector 

Excep=$(( "$Iniprog" + 4 )) 

#Create directory in RAM
ramdir=/dev/shm/$RANDOM
mkdir $ramdir

Tini=$(date +%s) 
#Prepare Golden execution
#echo "target remote localhost:2159" > $ramdir/commands.gdb
echo "target remote |" $QEMU " -gdb stdio -S -M "$mach "-m" $mem "-no-reboot -display none -kernel" $bin  > $ramdir/commands.gdb
echo "set logging file $ramdir/golden.txt" >> $ramdir/commands.gdb
echo set logging redirect on >> $ramdir/commands.gdb
echo set logging off >> $ramdir/commands.gdb
echo set height 0 >> $ramdir/commands.gdb 
echo b \*$lastdir >> $ramdir/commands.gdb
echo c >> $ramdir/commands.gdb
echo "set logging on" >> $ramdir/commands.gdb
echo "i all-r" >> $ramdir/commands.gdb
echo "set logging off" >> $ramdir/commands.gdb
 if [ $size -ne 0 ]; then
    echo "set logging file $ramdir/mem_golden.txt" >> $ramdir/commands.gdb
    echo "set logging on" >> $ramdir/commands.gdb
    echo "x/"$size"xb $"x$reg_resul   >> $ramdir/commands.gdb
    echo "set logging off" >> $ramdir/commands.gdb
 fi
echo "kill" >> $ramdir/commands.gdb
echo "q" >> $ramdir/commands.gdb

cp $ramdir/commands.gdb commands.gdb
#Golden execution
echo Golden!!!!!
#nohup $QEMU -S -M $mach -m $mem -no-reboot -nographic -gdb tcp::2159 -monitor telnet:127.0.0.1:1234,server,nowait -kernel $bin  > /dev/null 2>&1 &
$gdb -x $ramdir/commands.gdb > /dev/null 2>&1

 if [ $size -ne 0 ]; then
    cp $ramdir/mem_golden.txt mem_golden.txt
 fi

let R=reg_resul+1
RGtest=$(cat $ramdir/golden.txt |awk '{print $2}'|head -n $R|tail -n 1) #Get golden value of register to evaluate

# echo $RGtest
# echo $Und_inst
# echo $Pref_abort
# echo $Data_abort
 
 F0=unACE F1=SDC F2=Hang
  let Ft0=0
  let Ft1=0
  let Ft2=0
  
  j=0
  while [ $j -lt 3 ]; do
    i=0
    while [ $i -le 64 ]; do    
       let 'R'$i'_F'$j=0
       let i=i+1  
     done     
     let j=j+1
     let Ft${j}=0
 done
    
 echo "Start of injections"
 echo "Injections in progress..."
 
 if [ $Mod -eq 1 ]; then
     echo "All Reg campaign"
      Rin=1
      while [ $Rin -le 32 ]; do
         echo $bin $mach $mem $inj $reg_resul $gdb $QEMU $ramdir $Rin $inst $lastdir $RGtest $high_dir $Excep $size $Mod >> $ramdir/inj_arg.txt
         let Rin=Rin+1        
      done
    cat $ramdir/inj_arg.txt | xargs -P $NUM_PROC -n 16 bash $WHERE/RISCV_inject.sh
     Rin=1
     while [ $Rin -le 32 ]; do
        let R${Rin}_F0=$( cat $ramdir/R${Rin}_F0 )
        let R${Rin}_F1=$( cat $ramdir/R${Rin}_F1 )
        let R${Rin}_F2=$( cat $ramdir/R${Rin}_F2 )
        let Ft0=R${Rin}_F0+Ft0
        let Ft1=R${Rin}_F1+Ft1
        let Ft2=R${Rin}_F2+Ft2
        let 'Perc_R'$Rin'_F0'='R'$Reg'_F0'*100/$inj
        let 'Perc_R'$Rin'_F1'='R'$Reg'_F1'*100/$inj
        let 'Perc_R'$Rin'_F2'='R'$Reg'_F2'*100/$inj
        let Rin=Rin+1        
     done
elif [ $Mod -gt 1 ]; then
     echo "All Reg campaign with FPU registers"
     Rin=1
      while [ $Rin -le 64 ]; do
          echo $bin $mach $mem $inj $reg_resul $gdb $QEMU $ramdir $Rin $inst $lastdir $RGtest $high_dir $Excep $size $Mod >> $ramdir/inj_arg.txt
          let Rin=Rin+1        
       done
      cat $ramdir/inj_arg.txt | xargs -P $NUM_PROC -n 16 bash $WHERE/RISCV_inject.sh
      Rin=1
      
      while [ $Rin -le 64 ]; do
        let R${Rin}_F0=$( cat $ramdir/R${Rin}_F0 )
        let R${Rin}_F1=$( cat $ramdir/R${Rin}_F1 )
        let R${Rin}_F2=$( cat $ramdir/R${Rin}_F2 )
        let Ft0=R${Rin}_F0+Ft0
        let Ft1=R${Rin}_F1+Ft1
        let Ft2=R${Rin}_F2+Ft2
        let 'Perc_R'$Rin'_F0'='R'$Reg'_F0'*100/$inj
        let 'Perc_R'$Rin'_F1'='R'$Reg'_F1'*100/$inj
        let 'Perc_R'$Rin'_F2'='R'$Reg'_F2'*100/$inj
        let Rin=Rin+1        
     done
  else
     Rin=$Reg
     echo "Injection in Reg $Rin"
       
     bash $WHERE/RISCV_inject.sh $bin $mach $mem $inj $reg_resul $gdb $QEMU $ramdir $Rin $inst $lastdir $RGtest $high_dir $Excep $size $Mod
     let R${Rin}_F0=$( cat $ramdir/R${Rin}_F0 )
       let R${Rin}_F1=$( cat $ramdir/R${Rin}_F1 )
       let R${Rin}_F2=$( cat $ramdir/R${Rin}_F2 )
       
       let Ft0=R${Rin}_F0+Ft0
       let Ft1=R${Rin}_F1+Ft1
       let Ft2=R${Rin}_F2+Ft2
     let 'Perc_R'$Reg'_F0'='R'$Reg'_F0'*100/$inj
     let 'Perc_R'$Reg'_F1'='R'$Reg'_F1'*100/$inj
     let 'Perc_R'$Reg'_F2'='R'$Reg'_F2'*100/$inj
  fi

Tend=$(date +%s)
let Ttot=$Tend-$Tini
echo "Time in seg:"
echo $Ttot
echo $Ttot > $ramdir/time.txt


  printf "Reg\t|unACE\t\tSDC\t\tHang\t\t|Tot\n" > "$ramdir/Result.txt"
     echo "---------------------------------------------------------------" >> "$ramdir/Result.txt"
     i=1
     if [ $Mod -gt 1 ]; then
        totreg=64
     else
        totreg=32
     fi
     
     while [ $i -le $totreg ]; do
        let un='R'$i'_F0'
        let sd='R'$i'_F1'
        let ha='R'$i'_F2'
        let tot=un+sd+ha
        if [ $i -eq 32 ]; then
            Regnum="PC"
        elif [ $i -gt 32 ]; then
           let sreg=i-33
            Regnum='f'$sreg
        else
            Regnum='x'$i
        fi
        printf "%s \t|%d\t\t%d\t\t%d\t\t|%d\n" "$Regnum" "$un" "$sd" "$ha" "$tot">> "$ramdir/Result.txt"
     
        let i=i+1
       
     done
     
     echo "---------------------------------------------------------------" >> "$ramdir/Result.txt"
     let tot=Ft0+Ft1+Ft2
     printf "Tot\t|%d\t\t%d\t\t%d\t\t|%d\n" "$Ft0" "$Ft1" "$Ft2" "$tot">> "$ramdir/Result.txt"
     cat $ramdir/Result.txt
     
     printf "Reg\tunACE\t\tSDC\t\tHang\t\tTot\n" > "$ramdir/Result.dat"
     printf "Reg,unACE,SDC,Hang,Tot\n" > "$ramdir/Result.csv"
     let i=1
     if [ $Mod -gt 1 ]; then
        totreg=64
     else
        totreg=32
     fi
     while [ $i -le $totreg ]; do
        let un='R'$i'_F0'
        let sd='R'$i'_F1'
        let ha='R'$i'_F2'
        let tot=un+sd+ha
         if [ $i -eq 32 ]; then
            Regnum="PC"
        elif [ $i -gt 32 ]; then
            let sreg=i-33
            Regnum='f'$sreg
       
       else
            Regnum='x'$i
        fi
        printf "%s \t%d\t\t%d\t\t%d\t\t%d\n" "$Regnum" "$un" "$sd" "$ha" "$tot">> "$ramdir/Result.dat"     
        printf "%s,%d,%d,%d,%d\n" "$Regnum" "$un" "$sd" "$ha" "$tot">> "$ramdir/Result.csv" 
        let i=i+1
     done
     cp $ramdir/Result.dat .
     cp $ramdir/Result.txt .
     cp $ramdir/Result.csv .
        cp $ramdir/Hangs.txt .
        cp $ramdir/SDCs.txt .
        #cp $ramdir/flips.txt .
        #cp $ramdir/flips2.txt .
      #      cp $ramdir/SDCs_results.txt .
       # cp $ramdir/UnAce.txt .
    cp $ramdir/time.txt .
        
    rm -r $ramdir
    rm trace-* > /dev/null 2>&1
    echo " "
     
  
