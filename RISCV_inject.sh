#!/bin/bash
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
gdb=$1
shift
QEMU=$1
shift
ramdir=$1
shift
Rin=$1
shift
inst=$1
shift
lastdir=$1
shift
RGtest=$1
shift
high_dir=$1
shift
Excep=$1
shift
size=$1
shift
Mod=$1
shift

let qemu_port=2159+$Rin
commands=commands${Rin}.gdb
stopqemu=stopqemu${Rin}.gdb
regsmain=regsmain${Rin}.txt
regs=regs${Rin}.txt
regsh=regsh${Rin}.txt
regst=regst${Rin}.txt
mem_result=mem${Rin}.txt

echo "Injection in Reg $Rin"

#Function to change a bit in a double-precision number
#-----------------------------------------------------------------------------------------------------------------------------------------------------------
function bitflip {
in="$1" mas=$2 python - <<END
import os
import sys
import math 
inp = os.environ['in']
m = os.environ['mas']
res = int(inp, 16) ^ int(m)
print(res)
END
}


#Function to convert  IEEE754 format to decimal
#-----------------------------------------------------------------------------------------------------------------------------------------------------------
function fptodec {
in="$1" python - <<END
import os
import sys
import math 
inp = int(os.environ['in'])
#inp=32
res = "{0:032b}".format(int(inp))
#res=bin(int(inp)).replace("0b", "")
#print(res)
ieee_32=str(res)
sign_bit = int(ieee_32[0]) 
exponent_bias = int(ieee_32[1 : 9], 2) 
#print("exponent_bias:", exponent_bias)
if (exponent_bias==0):
	exponent_unbias=-126
else:
	exponent_unbias = exponent_bias - 127
mantissa_str = ieee_32[9 : ] 
power_count = -1
mantissa_int = 0
for i in mantissa_str: 
	mantissa_int += (int(i) * pow(2, power_count)) 
	power_count -= 1
	if (exponent_bias==0):
		mantissa=mantissa_int
	else:
		mantissa=mantissa_int+1
	#print("mantissa:", mantissa_int)
real_no = pow(-1, sign_bit) * mantissa * pow(2, exponent_unbias) 
print(" %200.150f"%  real_no)
END
}

#Function to convert  IEEE754 64bits format to decimal
#-----------------------------------------------------------------------------------------------------------------------------------------------------------
function fp64todec {
in="$1" python - <<END
import os
import sys
import math 
inp = int(os.environ['in'])
res = "{0:064b}".format(int(inp))
#res=bin(int(inp)).replace("0b", "")
#print(res)
ieee_64=str(res)
#ieee_64=ieee_64[32 : ] + ieee_64[0:32] #Due to a gdb bug
sign_bit = int(ieee_64[0]) 
exponent_bias = int(ieee_64[1 : 12], 2) 
#print("exponent_bias:", exponent_bias)
if (exponent_bias==2047): #if inf
    print("1e309")
else:
    if (exponent_bias==0):
        exponent_unbias=-1022
    else:
        exponent_unbias = exponent_bias - 1023
    mantissa_str = ieee_64[12 : ] 
    power_count = -1
    mantissa_int = 0
    for i in mantissa_str: 
        mantissa_int += (int(i) * pow(2, power_count)) 
        power_count -= 1
    if (exponent_bias==0):
        mantissa=mantissa_int
    else:
        mantissa=mantissa_int+1
        #print("mantissa:", mantissa_int)
    real_no = pow(-1, sign_bit) * mantissa * pow(2, exponent_unbias) 
    print(" %200.350f"%  real_no) 

END
}

#Function to inject in a register
#-----------------------------------------------------------------------------------------------------------------------------------------------------------
function injec_func () {

rm $ramdir/${regs} > /dev/null 2>&1
rm $ramdir/${mem_result} > /dev/null 2>&1

#Create a gdb commands batch file to read the RISCV registers
#echo "target remote localhost:${qemu_port}" > $ramdir/${commands}
echo "target remote |" $QEMU " -gdb stdio -S -M "$mach "-m" $mem "-no-reboot -display none -kernel" $bin  > $ramdir/${commands}
echo "set logging file $ramdir/${regs}" >> $ramdir/${commands}
echo set logging redirect on >> $ramdir/${commands}
echo set logging off >> $ramdir/${commands}
echo set height 0 >> $ramdir/${commands} 
echo set width 0 >> $ramdir/${commands}
echo b \*$dir_inst >> $ramdir/${commands} #Breakpoint at injection address
echo c >> $ramdir/${commands}
if [ $rep_inst -gt 1 ]; then  #Skip breakpoints to reach the injection instruction
let ign_bp=rep_inst-1
echo c $ign_bp >> $ramdir/${commands}
fi
echo "set logging on" >> $ramdir/${commands}
echo "i all-r" >> $ramdir/${commands}              #Obtain info register
echo "set logging off" >> $ramdir/${commands}
echo d 1 >> $ramdir/${commands}   #delete bp
echo b \*$lastdir >> $ramdir/${commands}  #Set lastdir bp
echo c >> $ramdir/${commands}
if [ $size -ne 0 ]; then
    echo "set logging file $ramdir/${mem_result}" >> $ramdir/${commands}
    echo "set logging on" >> $ramdir/${commands}
    echo "x/"$size"xb $"x$reg_resul   >> $ramdir/${commands}
    echo "set logging off" >> $ramdir/${commands}
 fi
echo "kill" >> $ramdir/${commands}
echo "q" >> $ramdir/${commands}

            #echo "launch qemu to get the register value"
            #nohup $QEMU -S -M $mach -m $mem -no-reboot -nographic -gdb tcp::${qemu_port} -kernel $bin  > /dev/null 2>&1 &

#echo "launch gdb"
Tini_inj=$(date +%s%N) 
$gdb -x $ramdir/${commands} > /dev/null 2>&1
Tend_inj=$(date +%s%N) 
   # echo "-------------------------------------------------------------------------------------------------"
    #echo "gdb to get the register value done"

Tinj_s=$(echo "scale=3; (${Tend_inj}-${Tini_inj})/500000000"|bc) #Max execution time in seg (2x)



cat $ramdir/${regs}|head -n 65 > $ramdir/${regsmain}
cat $ramdir/${regs}|head -n 33 > $ramdir/${regsh}
cat $ramdir/${regsmain}|tail -n 32|awk '{print $1, $NF}'|sed 's/.$//' > $ramdir/${regst}
cat $ramdir/${regsh} > $ramdir/${regs}
cat $ramdir/${regst} >> $ramdir/${regs}


let R=Rin+1 #Register to inject
val_reg_nin="$(cat $ramdir/${regs} |awk '{print $2}'|head -n $R|tail -n 1)" #Get register value
#echo $val_reg_nin
   

if ( [ $Rin -gt 32 ] &&  [ $Mod -gt 2 ] ); then
    val_reg_in=$( bitflip $val_reg_nin $masc )  #Change register value for double-precision registers
                                    #                echo $Reg_to_inject "    val_reg:" $val_reg_nin "  val_reg_changed:" $val_reg_in "  masc:"$masc >> $ramdir/flips.txt
else
    val_reg_nin=$(( val_reg_nin&0x00000000ffffffff))
    val_reg_in=$(( val_reg_nin^$masc )) # Change register value
fi   

if [ $Rin -gt 32 ]; then
    if [ $Mod -lt 3 ]; then
        val_reg_in=$(  fptodec $val_reg_in )
    else
       val_reg_in=$(  fp64todec $val_reg_in ) #For double-precision    
    fi
   # echo $Reg_to_inject "    val_reg:" $val_reg_nin "  val_reg_changed:" $val_reg_in "  masc:"$masc >> $ramdir/flips2.txt
fi

rm $ramdir/${regs} > /dev/null 2>&1
rm $ramdir/${mem_result} > /dev/null 2>&1
#Create a gdb commands batch file to change the RISCV register to inject the falut
#echo "target remote localhost:${qemu_port}" > $ramdir/${commands}
echo "target remote |" $QEMU " -gdb stdio -S -M "$mach "-m" $mem "-no-reboot -display none -kernel" $bin  > $ramdir/${commands}
echo "set logging file $ramdir/${regs}" >> $ramdir/${commands}
echo set logging redirect on >> $ramdir/${commands}
echo set logging off >> $ramdir/${commands}
echo set height 0 >> $ramdir/${commands} 
echo b \*$dir_inst >> $ramdir/${commands}  #Breakpoint at injection address
echo c >> $ramdir/${commands}
if [ $rep_inst -gt 1 ]; then  #Skip breakpoints to reach the injection instruction
let ign_bp=rep_inst-1
echo c $ign_bp >> $ramdir/${commands}
fi
if [ $Rin -eq 32 ]; then  #For pc register
    Reg_to_inject=pc
elif [ $Rin -gt 32 ]; then #For FPU registers
    let sreg=Rin-33
    Reg_to_inject=f$sreg
    
else 
    Reg_to_inject=x$Rin
fi

#If fault cause ra or PC to point an out-of-range addres change to Undef inst vector
#if [ $val_reg_in -gt $high_dir ]; then
   # if [ $Rin -eq 1 ] || [ $Rin -eq 32 ]; then
      #  val_reg_in=$Excep
    #fi
#fi

echo set \$$Reg_to_inject=$val_reg_in >> $ramdir/${commands} #inject fault
 
echo d 1 >> $ramdir/${commands}   #delete bp
echo b \*$lastdir >> $ramdir/${commands}  #Set lastdir bp
echo b \*$Excep >> $ramdir/${commands}
echo c >> $ramdir/${commands}
echo "set logging on" >> $ramdir/${commands}
echo "i all-r" >> $ramdir/${commands}
echo "set logging off" >> $ramdir/${commands}
if [ $size -ne 0 ]; then
    echo "set logging file $ramdir/${mem_result}" >> $ramdir/${commands}
    echo "set logging on" >> $ramdir/${commands}
    echo "x/"$size"xb $"x$reg_resul   >> $ramdir/${commands}
    echo "set logging off" >> $ramdir/${commands}
 fi
echo "kill" >> $ramdir/${commands}
echo "q" >> $ramdir/${commands}



#cp $ramdir/${commands} commands
 #   echo "launch qemu to inject"
#nohup $QEMU -S -M $mach -m $mem -no-reboot -nographic -gdb tcp::${qemu_port} -kernel $bin  > /dev/null 2>&1 &
    #echo "launch gdb to inject"
timeout_stat=0
    timeout -k$Tinj_s $Tinj_s $gdb -x $ramdir/${commands} > /dev/null 2>&1  
    timeout_stat=$?
#    $gdb -x $ramdir/${commands} > /dev/null 2>&1
    #echo "gdb to inject done"
    #cp $ramdir/${mem_result} $mem_result

if [ $timeout_stat = 0 ];
then    
        #echo "------- gdb normal finish-----------------------------------------------------------------------------------------------------------------"
    hg=0
else
       # echo "-------gdb killed-----------------------------------------------------------------------------------------------------------------"
    hg=1
   # If gdb was killed by timeout  kill qemu process  
   # pid=$( ps --ppid 1|grep qemu-system-ris|awk '{print $1}' )
    pid=$( ps -edf|grep qemu|awk '$3 == 1'|awk '{print $2}' )
    if [ -n "$pid" ]; then
        kill -9 $pid
    fi
    pid=$( ps -edf|grep qemu|awk '$3 == 1'|awk '{print $2}' )
    if [ -n "$pid" ]; then
        kill -9 $pid
    fi
fi


}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------


#Function to make i injections
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
function injections () {

   unace=0
   sdc=0
   hang=0

     i=0
     
     while [ $i -lt $inj ]; do #Make inj number of injections
 #echo "start-------------------------"    
 echo "Regsiter:" $Rin "injection number:" $i
#   Get a random instruction
      inst_inj=$(( $RANDOM % $inst ))
            #echo $inst_inj
      let inst_inj=inst_inj+10 #Discard initialization
            #echo $inst_inj
      dir_inst=$(cat trace.txt |head -n $inst_inj|tail -n 1) # inst addres
      rep_inst=$( cat trace.txt|head -n $inst_inj|grep "^"$dir_inst"$"| wc -l )  #Times of instr is repeated before addres    
       # echo $inst_inj
        #echo $dir_inst
       # echo $rep_inst
       
      if [ $Mod -lt 3 ]; then 
        nb=$(( $RANDOM % 31)) # Get a random bit 
      else
        nb=$(( $RANDOM % 63)) # Get a random bit for double-precision registers
      fi 
      masc=$((1 << $nb))
      injec_func  #injection function
           # cp $ramdir/${regs} .
      let R=reg_resul+1
      
      if [ "$hg" != 1 ]; then
        Last_PC="$(cat $ramdir/${regs} |awk '{print $2}'|head -n 33|tail -n 1)"
        let Last_PC=Last_PC+0
        Rtest="$(cat $ramdir/${regs} |awk '{print $2}'|head -n $R|tail -n 1)"
      else
        Last_PC=x
        Rtest=x
      fi  
                
        #Classify fault
       if [ "$Last_PC" != "$lastdir" ]; then
            let hang=hang+1
                echo $Reg_to_inject "     inst:" $inst_inj "     dir:"  $dir_inst "     rep:" $rep_inst "    val_reg:" $val_reg_nin "  val_reg_changed:" $val_reg_in "  masc:"$masc "     time:" $Tinj_s"    Las_pc: " $Last_PC>> $ramdir/Hangs.txt
           echo "hang---- reg=" $Rin
        elif [ "$Rtest" != "$RGtest" ]; then
                let sdc=sdc+1
                    echo $Reg_to_inject "     inst:" $inst_inj "     dir:"  $dir_inst "     rep:" $rep_inst "    val_reg:" $val_reg_nin "  val_reg_changed:" $val_reg_in  >> $ramdir/SDCs.txt
                            echo $Rtest >> $ramdir/SDCs_results.txt
               echo "SDC---- reg=" $Rin    
        elif [ $size -ne 0 ]; then
            if cmp --silent $ramdir/mem_golden.txt $ramdir/$mem_result; then
                let unace=unace+1                
                echo $inst_masc >> $ramdir/UnAce.txt
            else
                let sdc=sdc+1
                echo $Reg_to_inject "     inst:" $inst_inj "     dir:"  $dir_inst "     rep:" $rep_inst "    val_reg:" $val_reg_nin "  val_reg_changed:" $val_reg_in  >> $ramdir/SDCs.txt
                echo $Rtest >> $ramdir/SDCs_results.txt
                echo "SDC_MEM---- reg=" $Rin
                #cp $ramdir/${mem_result} SDC$mem_result
            fi
        else
                let unace=unace+1                
                echo $inst_masc >> $ramdir/UnAce.txt
        fi      
        let i=i+1
      done
           
      echo $unace >> $ramdir/R${Rin}_F0
      echo $sdc >> $ramdir/'R'$Rin'_F1'
      echo $hang >> $ramdir/'R'$Rin'_F2'
}

injections
echo Finish injection in Reg $Rin 
echo ----------------------
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
