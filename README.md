# Assembling and Uploading .asm Files to m2560
## Dependencies
The following tools must be installed on the system:
1. **AVRA** :  An assembler for AVR microcontrollers.
	run:
	```avra <filename>.asm```
	
2. **AVRDude** : A utility to download/upload/manipulate the firmaware in AVR microcontrollers.
	run:
	```/usr/bin/avrdude -C /etc/avrdude.conf -v -p atmega2560 -c wiring -P /dev/ttyACM0 -b 115200 -D -U flash:w:<filename>.hex:i```
	
3. **AVR Toochain** : This includes the necessary tools for compiling and uplading code to MCU
