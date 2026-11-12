# SPDX-License-Identifier: MIT
# Each BSP opts its selected provider in; other parsed providers remain intact.
SAHA_X5_KERNEL_RT_ENABLED ?= "0"

saha_x5_rt_assert_config() {
    test -s "${B}/.config" || bbfatal "Missing final kernel configuration"
    for setting in CONFIG_PREEMPT_RT=y CONFIG_EXPERT=y CONFIG_HIGH_RES_TIMERS=y CONFIG_IKCONFIG=y CONFIG_IKCONFIG_PROC=y; do
        grep -Fxq "$setting" "${B}/.config" || bbfatal "PREEMPT_RT request did not survive Kconfig: $setting"
    done
    if grep -Fxq 'CONFIG_PREEMPT_DYNAMIC=y' "${B}/.config"; then
        bbfatal "Unexpected PREEMPT_DYNAMIC in the fixed RT configuration"
    fi
    if grep -Fxq 'CONFIG_RT_GROUP_SCHED=y' "${B}/.config"; then
        bbfatal "RT_GROUP_SCHED blocks FIFO tasks in v2 SSH session cgroups"
    fi
    bbnote "RDK X5 PREEMPT_RT final Kconfig validation passed for ${MACHINE}"
}

do_configure[postfuncs] += "${@' saha_x5_rt_assert_config' if d.getVar('SAHA_X5_KERNEL_RT_ENABLED') == '1' else ''}"
