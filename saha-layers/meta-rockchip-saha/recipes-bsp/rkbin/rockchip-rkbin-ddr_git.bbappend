require rk3566-pinned-inputs.inc
SRC_URI[firmware.sha256sum] = "20e4bb076847bd019fcdeb7bdc15bd249890f07ecc76e9937101f22e50950982"

python __anonymous() {
    if d.getVar("MACHINE") == "radxa-zero-3w" and d.getVar("RKBIN_DDR_RECONFIGURE") != "0":
        bb.fatal("Saha ZERO 3W uses the unmodified pinned DDR blob; DDR reconfiguration requires the upstream Git/tool recipe.")
}
