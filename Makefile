SRCDIR := src

crt0:
	startup-gen -P target.gpr -l src\link.ld -s src\crt0.s

tgt: crt0
	gprbuild -p  --target=arm-eabi --RTS=C:\AdaCore\gnu-arm-elf-25.1\arm-eabi\lib\gnat\light-cortex-m7f -P target.gpr