ARM_TOOLCHAIN_DIR = /opt/gcc-arm-none-eabi-9-2020-q2-update/bin
ARM_INCLUDES = -I/opt/gcc-arm-none-eabi-9-2020-q2-update/arm-none-eabi/include/ 



MCPU = -mcpu=cortex-a15
# Compiler to use
CC= arm-none-eabi-gcc
AS=arm-none-eabi-as
LD=arm-none-eabi-ld
OBJCOP=arm-none-eabi-objcopy
OBJDUMP=arm-none-eabi-objdump


# Compilation flags
CFLAGS= -mfloat-abi=softfp -mfpu=vfpv2
LDFLAGS  = -lm -lc --specs=nosys.specs -nostartfiles -fno-math-errno



# Source file
COD=ln2.c
# Asemb file
ASM=ln2.s
# Objet file
OBJS=ln2.o
# elf binary file
ELF=ln2.elf
# binary file
BIN=ln2.bin
# 
DIS=ln2_dis.s
DIS_PRE=ln2_p.s





# Compilation rules
all: comp assem link
#	$(ARM_TOOLCHAIN_DIR)/$(CC) --specs=nosys.specs $(MCPU) $(CFLAGS) $(ARM_INCLUDES) -o $(ELF) $(OBJS) #startup.o
link:
	$(ARM_TOOLCHAIN_DIR)/$(CC) -T link.ld $(OBJS) startup.o -o $(ELF) $(LDFLAGS)
	$(ARM_TOOLCHAIN_DIR)/$(OBJCOP)  -O binary $(ELF) $(BIN)
	$(ARM_TOOLCHAIN_DIR)/$(OBJDUMP) -d $(ELF) > $(DIS)

assem: 
	$(ARM_TOOLCHAIN_DIR)/$(AS) $(MCPU) -o $(OBJS) $(ASM) 
	$(ARM_TOOLCHAIN_DIR)/$(AS) $(MCPU) $(CFLAGS) -g startup.s -o startup.o
	
comp: 
	$(ARM_TOOLCHAIN_DIR)/$(CC) $(ARM_INCLUDES) -Wall $(CFLAGS) $(MCPU) -S $(COD)
	
# clean files ∗.o and ∗.elf
clean:
	rm  $(ELF) $(OBJS)  startup.o $(ASM) $(BIN)
	
#Genera el archivo asm completo para obtener funciones (como division)
asm_gen:
	$(ARM_TOOLCHAIN_DIR)/$(CC) $(ARM_INCLUDES) $(CFLAGS) --specs=nosys.specs $(COD) -o $(ELF)
	$(ARM_TOOLCHAIN_DIR)/$(OBJDUMP) -d $(ELF) > $(DIS_PRE)
