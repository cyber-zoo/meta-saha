# The same pinned vendor release explicitly supplies bpu-hw_io_rt. Select it
# only for RT; retain the upstream ordinary-kernel tasks verbatim otherwise.
python () {
    if d.getVar('SAHA_X5_PREEMPT_RT') != '1':
        return
    if d.getVar('SRCREV_drivers') != '9ebc13c76c4dfe14410537b4c1b0761d51d1ab9e':
        bb.fatal('Unreviewed X5 RT BPU object source revision')
    if d.getVar('RDK_X5_KERNEL_VERSION') != '6.1.83':
        bb.fatal('X5 RT BPU integration requires the pinned 6.1.83 BSP')
    for task in ('do_compile', 'do_install'):
        body = d.getVar(task, False)
        if '${S}/bpu-hw_io' not in body:
            bb.fatal('Vendor BPU task changed; review the RT directory selection before building')
        d.setVar(task, body.replace('${S}/bpu-hw_io', '${S}/bpu-hw_io_rt'))
    body = d.getVar('do_rdk_x5_validate_kernel', False)
    if '${RDK_X5_KERNEL_VERSION}' not in body:
        bb.fatal('Vendor BPU ABI validation task changed; manual review required')
    d.setVar('do_rdk_x5_validate_kernel', body.replace('${RDK_X5_KERNEL_VERSION}', '6.1.83-rt28') + '''
        grep -Fxq 'CONFIG_PREEMPT_RT=y' "${STAGING_KERNEL_BUILDDIR}/.config" || bbfatal "RT BPU object requires actual PREEMPT_RT kernel configuration"
        test -s "${S}/bpu-hw_io_rt/bpu_hw_io_x5.o_shipped" || bbfatal "Missing vendor RT BPU object"
    ''')
}
