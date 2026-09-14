# Backlog

Add only work that is known but not actively planned; keep current work in
`active/` and existing implementation quality gaps in `tech-debt-tracker.md`.

## IQ-9075 follow-up hardware coverage

- Direct software EDL: upstream `mode-edl = <0 1>` hangs with the pinned
  Saha kernel/firmware, while Ubuntu's previous combination worked. Compare
  PSCI/firmware behavior with the retained UART evidence; do not repeat the
  disproven DT cell swap. ADB-to-Fastboot and Alpaca-to-EDL are verified
  alternatives. Acceptance: 05c6:9008 plus the exact QDL serial, then return
  to Saha without unplanned partition writes.
- Ethernet: QCA8081 binding is verified, but no physical carrier was present.
  Test cable/link negotiation, DHCP, and throughput before claiming support
  beyond driver bring-up.
- PMIC thermal/audio: resolve disabled ADC5 GEN3 and remaining codec
  suppliers; inspect kernel warnings and temperatures before stress testing.
- Validate camera, GPU/NPU workloads, and the optional Home Assistant image
  separately. Current smoke coverage is the HA-disabled ROS 2 base image.

Evidence and completed base bring-up:
[IQ-9075 flash plan](completed/iq9075-flash-bringup.md).
