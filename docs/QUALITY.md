# Quality

## Definition of done

A change is complete only when it has a clear, reversible scope, documents its
user-visible behavior, passes the applicable focused checks, and is recorded
in a Conventional Commit. A claimed full image build must have completed; a
parse, dry run, or package build must be described at its actual level.

## Required review checks

- Confirm the change touches the correct BSP layer and does not leak
  board-specific metadata into another vendor graph.
- Verify the public target alias, `MACHINE`, kas target, wrapper behavior, and
  README stay consistent.
- Verify packages shared between platforms are available in every selected
  graph; otherwise keep them platform-specific or optional.
- Preserve cache mounts, non-root Docker behavior, input validation, and proxy
  redaction.
- Review any image-size, rootfs, network, security, firmware, or flash impact.
- Run `git diff --check` before committing.

## Baseline commands

Run the relevant commands from the repository root:

```bash
bash tests/test-build-framework.sh
bash tests/test-flash-rdk-x5.sh
bash -n scripts/saha-build scripts/saha-shell scripts/saha-targets \
  scripts/saha-validate scripts/saha-flash-rdk-x5
git diff --check
```

For a new or changed target, also test valid and invalid wrapper input using
`SAHA_DRY_RUN=1`, then validate kas expansion or BitBake parsing in the Docker
builder. A full build is the final packaging proof when time, storage, network,
and source access permit it.

## Hardware and flash boundary

No hardware test is implied by a build. Record exact artifact paths and the
validation level, then ask for hardware connection before attempting boot,
peripheral, accelerator, or flash verification. Never use a physical write as
a routine test.

## Test expectations by change type

| Change | Minimum checks |
| --- | --- |
| Shell wrapper or target map | Shell syntax, focused wrapper test, valid/invalid dry-run behavior. |
| kas or layer configuration | YAML/config expansion and BitBake parse; full build when practical. |
| Image/packagegroup | Parse or package build, manifest/rootfs inspection when available. |
| Flash helper | Existing flash safety test, syntax check, static safety contract review; no device write. |
| Documentation only | Link/path review and `git diff --check`. |
