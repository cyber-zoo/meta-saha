# Conventions

## Repository organization

- Put per-machine selection in `kas/targets/<target>.yml` and reusable policy
  in `kas/include/`.
- Use a separate local layer for each BSP family. Do not add vendor-specific
  recipes or overrides to an unrelated platform layer.
- Keep the public target alias, `MACHINE`, and description in
  `scripts/saha-lib`; aliases use lowercase kebab case.
- Keep the primary image name `saha-image-robot` unless an approved product
  requirement changes it.

## Yocto metadata

- Use current BitBake override syntax (`:`), consistent with the Wrynose
  metadata already in this repository.
- Name bbappends so they actually match their upstream recipe. For a
  versionless recipe, use a versionless append rather than assuming `_%.bbappend`
  will match.
- Keep packagegroups narrow and compose optional functionality through kas
  overlays instead of duplicating whole images.
- Pin or explicitly document vendor source/revision contracts when a platform
  needs a non-moving BSP graph.

## Shell and Docker

- Shell scripts use Bash with `set -euo pipefail` and source `saha-lib` for
  shared behavior rather than duplicating validation or Docker arguments.
- Public build options are named `SAHA_*`; reject unsupported values before
  launching Docker.
- Docker and kas are the normal build path. Keep cache paths configurable and
  avoid printing secret proxy values in dry-run output.

## Tests and documentation

- Add focused assertions to the existing shell tests for each changed command,
  target map, kas composition, image contract, or flash safety rule.
- Keep README instructions executable and aligned with wrapper behavior.
- Document a hardware action separately from a build action. Never make a test
  perform an actual flash write.
- Use English for executable contracts and technical documentation, matching
  the existing README and layer metadata.

## Git history

- Make small, independently reversible commits after a coherent checked unit
  of work.
- Follow Conventional Commits, for example `docs(harness): add agent knowledge
  base`, `feat(qcom): add iq-9075 kas target`, or `test(qcom): cover target
  validation`.
- Do not amend, reset, or overwrite user work unless explicitly requested.
