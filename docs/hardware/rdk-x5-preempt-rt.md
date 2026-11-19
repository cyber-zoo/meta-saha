# RDK X5 optional PREEMPT_RT

[RDK X5 guide](rdk-x5.md) · [Project README](../../README.md)

This profile applies only to the pinned RDKOS 3.5.0 / SDK 1.1.1 Linux 6.1.83
BSP. Ordinary builds remain unchanged. It adds no service that runs benchmarks
automatically and makes no persistent CPU-isolation, governor or IRQ-affinity
changes. No NAND firmware, eFuse, Secure Boot, OTA or partition changes are
part of this profile.

## Build

Use the normal Docker + kas entry point, adding the explicit RT option:

```bash
SAHA_META_D_ROBOTICS_DIR=/path/to/meta-d-robotics \
SAHA_X5_PREEMPT_RT=1 \
  ./scripts/saha-build rdk-x5
```

For the RT kernel with the separately optional BPU/camera runtime:

```bash
SAHA_META_D_ROBOTICS_DIR=/path/to/meta-d-robotics \
SAHA_X5_PREEMPT_RT=1 SAHA_X5_ACCELERATORS=1 \
  ./scripts/saha-build rdk-x5
```

The same options apply to `saha-shell` and `saha-validate`. Unset or `0` keeps
RT disabled. Empty strings and values other than literal `0` or `1` fail
before Docker starts. Enabling RT on any other target is rejected.
The wrapper composes `kas/include/rdk-x5-preempt-rt.yml` after the base graph
and optional accelerator include; the normal and RT profiles have
[separate default build directories](rdk-x5.md#optional-preempt_rt).

Check the graph or build individual packages without flashing:

```bash
SAHA_META_D_ROBOTICS_DIR=/path/to/meta-d-robotics \
SAHA_X5_PREEMPT_RT=1 ./scripts/saha-validate rdk-x5

SAHA_META_D_ROBOTICS_DIR=/path/to/meta-d-robotics \
SAHA_X5_PREEMPT_RT=1 ./scripts/saha-shell rdk-x5 \
  -c 'bitbake virtual/kernel saha-rt-tests'
```

Select the resulting timestamped image under
`build/rdk-x5-preempt-rt/tmp/deploy/images/rdk-x5/`, or
`build/rdk-x5-preempt-rt-accelerators/tmp/deploy/images/rdk-x5/` with BPU enabled.
Flashing remains a separate operation using the existing guarded helper.

## Kernel and BPU contract

The kernel append refuses RT on an unreviewed `SRCREV_kernel`; it requires
`c642eabfd7aacc4f44f2300e69d27ef1691a47d7` from
[D-Robotics/x5-kernel](https://github.com/D-Robotics/x5-kernel/tree/c642eabfd7aacc4f44f2300e69d27ef1691a47d7).
The fragment is merged explicitly because the vendor recipe inherits
`kernel`, rather than `kernel-yocto`. A post-configure guard requires actual
`CONFIG_PREEMPT_RT=y`, expert/high-resolution timers and readable kernel
configuration, and rejects dynamic preemption and RT group scheduling.
The latter otherwise denies FIFO scheduling to ordinary v2 SSH session
cgroups on this BSP. The global RT bandwidth limit remains intact.

With accelerators selected, the BPU append requires driver source revision
`9ebc13c76c4dfe14410537b4c1b0761d51d1ab9e`, the original 6.1.83 BSP contract,
and the expected vendor task bodies. It selects the supplied `bpu-hw_io_rt`
directory, checks the actual RT kernel configuration, and validates release
`6.1.83-rt28`. Unexpected BSP task changes stop parsing for manual review.
It never changes vermagic strings or forces a module load. With RT disabled,
the ordinary vendor tasks are retained.

The vendor BPU contains a proprietary precompiled object. On this BSP
`CONFIG_MODVERSIONS=n`; matching release strings, symbols and successful smoke
tests do not prove a complete structure-level ABI contract. The module also
taints the kernel (`P|O`), and kernel lock debugging is disabled after loading
it. Do not interpret a quiet BPU run as complete lockdep verification.

## Patch provenance

The 13 patches integrate Linux PREEMPT_RT and selected public Linux fixes
with the pinned vendor kernel. Patch headers retain their public source
references and upstream authorship; two manifests record backport commits
and hashes. The layer and public option are scoped to X5. The manual helper
depends explicitly on `util-linux-dmesg` and refuses a complete result when
either kernel-log capture fails.

| Patches | Purpose |
| --- | --- |
| `0001` | Official Linux 6.1.83-rt28, rebased onto the vendor UART DMA context |
| `0002`–`0003` | PPS uses IRQ-core RT scheduling; retain built-in PPS without a NULL IRQ-action dereference |
| `0004`–`0011` | Upstream cacheinfo/topology backports preallocate on the primary CPU, avoiding sleeping allocation during secondary-CPU bring-up |
| `0012` | Remove the redundant outer IRQ mask from the vendor ACA crypto PM callbacks while retaining native locking and request quiescing |
| `0013` | Complete CTI/ETM4 device-lock conversion to raw locks for atomic callbacks and CPU hotplug, preserving existing plain/irqsave boundaries |

The original [RT patch archive](https://cdn.kernel.org/pub/linux/kernel/projects/rt/6.1/older/patch-6.1.83-rt28.patch.xz)
has SHA-256
`b078326a17069cedb8bebc0d9174646de266cbcd5b35eed14467147bda1f9b1f`.
Patch headers retain upstream source references. The
[cacheinfo manifest](../../saha-layers/meta-rdk-x5-saha/recipes-kernel/linux/files/cacheinfo-backports.json)
records the eight backport commits and patch hashes; the
[CoreSight manifest](../../saha-layers/meta-rdk-x5-saha/recipes-kernel/linux/files/coresight-backports.json)
records upstream commits, file hashes and the vendor adaptation. See
[third-party notices](../../NOTICE.md) for licensing boundaries.

**CoreSight perf with configuration IDs (`configid`) remains unsupported by
this RT profile.** Its framework lock path requires a separate backport of
[26f060c106f6](https://github.com/torvalds/linux/commit/26f060c106f630e34876c096c1c8997a9e68c371)
and targeted functional/locking tests. Patch `0013` fixes the observed hotplug
path; it does not cover that framework path.

## Manual measurements after a separately authorized flash

The RT image installs `saha-rt-tests`, `rt-tests` and `stress-ng`. As root on
the board, use a new output directory for each case:

```bash
uname -r
cat /sys/kernel/realtime
zcat /proc/config.gz | grep '^CONFIG_PREEMPT_RT='
saha-rt-tests --duration 60 --output /var/tmp/rt-idle
saha-rt-tests --duration 180 --load --output /var/tmp/rt-load
```

The helper refuses a non-RT kernel. It runs 1 kHz `cyclictest` with FIFO80,
locked memory, SMP threads and a 10,000 us histogram, collecting JSON, kernel
configuration, command line, governors, interrupts and before/after dmesg.
`--load` adds bounded CPU, 128 MiB memory and a 64 MiB scratch-file load.
The storage exercised is the filesystem containing the output directory;
do not describe a tmpfs run as TF-card I/O. Cyclictest's default PM QoS request
affects the measurement; record it when comparing results. An interrupted or
failed run is invalid; confirm its processes have exited before repeating.

`measurement_complete` means the commands completed, not that a real-time
deadline passed. Inspect every CPU's sample count, maximum, histogram
overflow, late samples, load coverage and kernel diagnostics. Declare an
allowable jitter before assigning a pass/fail threshold. This helper measures
scheduler wakeups; it does not exercise motor commands or prove physical
bus/actuator deadlines. The accelerator image's existing
`saha-rdk-x5-bpu-smoke` provides a separate offline BPU functional check.

## Validation and remaining qualification

[Port validation record](../validation/rdk-x5-preempt-rt-port-20261113.md)
records the checks performed on the Saha integration and its remaining build
and hardware gates.

For this Saha profile, complete normal/RT builds both with and without BPU, then
perform boot, module, crypto PM, CPU hotplug and latency checks on the actual
image before deployment. Still pending are long-duration/thermal campaigns,
matched ordinary-vs-RT comparisons, suspend/resume and cold-boot crypto PM,
peripheral combinations, RT policy/IRQ tuning, firmware/ABI upgrades, fault
handling and actual control-bus/motor end-to-end deadlines. These hardware
campaigns have not been executed for this Saha profile.
