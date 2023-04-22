CROSS_COMPILE := riscv64-linux-gnu-
COMMON_FLAGS  := -fno-pic -march=rv64ifd -mcmodel=medany
CFLAGS        += $(COMMON_FLAGS) -static
ASFLAGS       += $(COMMON_FLAGS) -O0
LDFLAGS       += -melf64lriscv

AM_SRCS := mycpu/start.S \
           mycpu/libgcc/muldi3.S \
           mycpu/libgcc/div.S \
           mycpu/trm.c \
           mycpu/ioe.c \
           mycpu/timer.c \
           mycpu/input.c \
           mycpu/cte.c \
           mycpu/trap.S \
           mycpu/vme.c \
           mycpu/mpe.c \
           mycpu/uart.c

CFLAGS    += -fdata-sections -ffunction-sections
LDFLAGS   += -T $(AM_HOME)/scripts/platform/core_flash.ld --defsym=_pmem_start=0x30000000 --defsym=_entry_offset=0x0
LDFLAGS   += --gc-sections -e _start
CFLAGS += -DMAINARGS=\"$(mainargs)\"
.PHONY: $(AM_HOME)/am/src/mycpu/trm.c

image: $(IMAGE).elf
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@$(OBJDUMP) -d $(IMAGE).elf --disassembler-options=no-aliases > $(IMAGE)-no-aliases.txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin
	riscv64-linux-gnu-objcopy -I binary -O verilog $(IMAGE).bin $(IMAGE).flash
	sed -e '/@/d' -e 's/ //g' -e 's/\(.\{16\}\)/& /' $(IMAGE).flash | sed -e 's/\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\) /\8\7\6\5\4\3\2\1 /g' \
		| sed -e 's/\(.\{17\}\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)/\1\9\8\7\6\5\4\3\2/g' > $(IMAGE).ram
	sed -e '/@/d' -e 's/ //g' -e 's/\(.\{28\}\)/& /' -e 's/\(.\{24\}\)/& /' -e 's/\(.\{20\}\)/& /' \
		  -e 's/\(.\{16\}\)/& /' -e 's/\(.\{12\}\)/& /' -e 's/\(.\{8\}\)/& /' -e 's/\(.\{4\}\)/& /'  \
			$(IMAGE).flash | sed -e 's/\(..\)\(..\) \(..\)\(..\) \(..\)\(..\) \(..\)\(..\)/\2\1 \4\3 \6\5 \8\7/g' > $(IMAGE).sdram
