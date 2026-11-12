# Notices for meta-saha

## Copyright
---
meta-saha is released under Apache 2.0 license.

> Copyright (c) Homalozoa
> 
> Licensed under the Apache License, Version 2.0 (the "License");
> you may not use this file except in compliance with the License.
> You may obtain a copy of the License at
> 
>     http://www.apache.org/licenses/LICENSE-2.0
> 
> Unless required by applicable law or agreed to in writing, software
> distributed under the License is distributed on an "AS IS" BASIS,
> WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
> See the License for the specific language governing permissions and
> limitations under the License.

## Source Code & Projects
---
The project maintains the following source code repositories:

- [meta-saha](https://github.com/homalozoa/meta-saha)

## Third-party Dependencies & Reference

tegra-demo-distro (master)
- License: MIT License
- Project: https://github.com/OE4T/tegra-demo-distro
- Source: https://github.com/OE4T/tegra-demo-distro
- Usage: modified

RDK X5 PREEMPT_RT integration
- Public source references: Linux PREEMPT_RT and the pinned D-Robotics kernel;
  patch headers and backport manifests identify the applicable upstream commits.
- Usage: X5-only kernel integration and a manual measurement helper.
- The configuration guard, fragment and measurement helper retain their MIT
  SPDX notices; the MIT text accompanies them in
  `saha-layers/meta-rdk-x5-saha/COPYING.MIT`.
- Linux RT and backport patches retain the applicable Linux/vendor per-file
  licenses, upstream authorship and source references (including GPL-2.0-only
  and GPL-2.0-or-later). The GPLv2 text accompanies them in
  `saha-layers/meta-rdk-x5-saha/COPYING.GPL-2.0`. The repository's Apache-2.0
  license does not relicense these kernel changes. See
  `docs/hardware/rdk-x5-preempt-rt.md` for pinned sources and provenance.
- Vendor BPU binaries are fetched by the existing BSP recipes under their
  own license; no binary is included by this integration.
