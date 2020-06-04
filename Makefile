# Makefile for avr-gcc by Franco Sauvisky
MCU_TARGET = attiny2313
PGR = main
CCFLAGS = -g -Wall -Wextra -Os --short-enums -flto
PROGRAMM = usbasp

.PHONY: all full prog_lfuse prog_hfuse prog_full prog_verify pon poff clean tar size sim test

all: build build/$(PGR).hex build/$(PGR)_eeprom.hex build/$(PGR).lst

full: all prog pon

build:
	mkdir -p build

build/$(PGR).hex: ./build/$(PGR).elf
	avr-objcopy -j .text -j .data -O ihex build/$(PGR).elf build/$(PGR).hex

build/$(PGR)_eeprom.hex: ./build/$(PGR).elf
	avr-objcopy -j .eeprom --change-section-lma .eeprom=0 -O ihex \
	build/$(PGR).elf build/$(PGR)_eeprom.hex

build/$(PGR).lst: ./build/$(PGR).elf
	avr-objdump -h -S ./build/$(PGR).elf > build/$(PGR).lst

build/$(PGR).elf ./build/$(PGR).map: ./build/$(PGR).o $(MODCF)
	avr-gcc -g $(CCFLAGS) -mmcu=$(MCU_TARGET) -Wl,-Map,build/$(PGR).map -o \
	build/$(PGR).elf build/$(PGR).o $(MODOF)

build/$(PGR).o: $(PGR).c $(MODCF)
	avr-gcc -g $(CCFLAGS) -mmcu=$(MCU_TARGET) -c $(PGR).c -o build/$(PGR).o

prog: build/$(PGR).hex
	avrdude -c $(PROGRAMM) -p $(MCU_TARGET) -U flash:w:'build/$(PGR).hex':a

prog_full: build/$(PGR).hex build/$(PGR)_eeprom.hex ./build/$(PGR).elf
	avr-objcopy -O binary --only-section=.fuse build/main.elf build/$(PGR)_fuses.bin
	split -b 1 build/$(PGR)_fuses.bin 'build/fuse'
	avrdude -c $(PROGRAMM) -p $(MCU_TARGET) -e -U flash:w:'build/$(PGR).hex':a -U eeprom:w:'build/$(PGR)_eeprom.hex':a -U hfuse:w:'build/fuseab':r -U lfuse:w:'build/fuseaa':r
	rm build/fusea* build/$(PGR)_fuses.bin

prog_eeprom: build/$(PGR)_eeprom.hex
	avrdude -c $(PROGRAMM) -p $(MCU_TARGET) -U eeprom:w:'build/$(PGR)_eeprom.hex':a

prog_lfuse: ./build/$(PGR).elf
	avr-objcopy -O binary --only-section=.fuse build/main.elf build/$(PGR)_fuses.bin
	split -b 1 build/$(PGR)_fuses.bin 'build/fuse'
	avrdude -c $(PROGRAMM) -p $(MCU_TARGET) -U lfuse:w:'build/fuseaa':r
	rm build/fusea* build/$(PGR)_fuses.bin

prog_hfuse: ./build/$(PGR).elf
	avr-objcopy -O binary --only-section=.fuse build/main.elf build/$(PGR)_fuses.bin
	split -b 1 build/$(PGR)_fuses.bin 'build/fuse'
	avrdude -c $(PROGRAMM) -p $(MCU_TARGET) -U hfuse:w:'build/fuseab':r
	rm build/fusea* build/$(PGR)_fuses.bin

prog_verify: ./build/$(PGR).elf
	avr-objcopy -O binary --only-section=.fuse build/main.elf build/$(PGR)_fuses.bin
	split -b 1 build/$(PGR)_fuses.bin 'build/fuse'
	avrdude -c $(PROGRAMM) -p $(MCU_TARGET) -U flash:v:'build/$(PGR).hex':a -U eeprom:v:'build/$(PGR)_eeprom.hex':a -U hfuse:v:'build/fuseab':r -U lfuse:v:'build/fuseaa':r
	rm build/fusea* build/$(PGR)_fuses.bin

pon:
	pk2cmd -P PIC16F630 -T -R

poff:
	pk2cmd -P PIC16F630

clean:
	find . -maxdepth 2 -regextype awk -regex \
	".*\.(lst|hex|o|map|elf|tar.gz|zip)" -delete

tar: build/$(PGR).hex Makefile
	tar --create --file $(PGR).tar.gz --gzip Makefile \
	$$(find -maxdepth 2 -regextype awk -regex ".*\.(c|h|hex)" -printf "%P ")

zip: build/$(PGR).hex Makefile
	7z a $(PGR).zip Makefile \
	$$(find -maxdepth 2 -regextype awk -regex ".*\.(c|h|hex)" -printf "%P ")

size: build/$(PGR).elf
	avr-size --mcu=$(MCU_TARGET) -B ./build/main.hex
	avr-size --mcu=$(MCU_TARGET) -A ./build/main.elf
	avr-size --mcu=$(MCU_TARGET) -C ./build/main.elf

test: testrand.c
	gcc -O3 -lm $< -o build/test.out && ./build/test.out
