KERNEL_DEVICETREE = "rockchip/rk3566-radxa-zero-3w-microduck.dtb"

# UART2 belongs to the motor bus; neither printk nor a getty may use it.
SERIAL_CONSOLES = ""
UBOOT_EXTLINUX_CONSOLE = "console=tty1"
MACHINE_EXTRA_RRECOMMENDS += "saha-radxa-microduck"
