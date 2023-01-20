# meta-saha

## Introduction

`meta-saha` is a [Yocto Project](https://www.yoctoproject.org/) distro layer designed for building robot system. For hardware, it supports Jetson Xavier NX(hardware name: rolling-nx). For software. it supports the version [kirkstone](https://docs.yoctoproject.org/4.0.6/migration-guides/migration-4.0.html)(the latest LTS version of yocto) currently.

This project is modified based on [OE4T/tegra-demo-distro](https://github.com/OE4T/tegra-demo-distro). Thanks for [OE4T](https://github.com/OE4T).

## Prerequisite

Read the documentation [Yocto Project Quick Build](https://docs.yoctoproject.org/4.0.6/brief-yoctoprojectqs/index.html) to setting up building environment for building yocto image. Also, if your OS distro is Arch Linux, read the documentation [Yocto - ArchWiki](https://wiki.archlinux.org/title/Yocto) for more information about how to set up environment in Arch Linux.

Besides, [vcs-tool](https://github.com/dirk-thomas/vcstool) is the other necessary tool. Install it by using `pip`.

```
$ pip install vcstool
```

## Building

Make a empty directory for building saha image. Then get the code.

```
$ mkdir yocto_saha
$ git clone https://github.com/cyber-zoo/meta-saha.git
```

Init the building environment with:

```
$ . meta-saha/scripts/init.sh
```

Then set the hardware board with [`meta-saha/setup-env`](./setup-env). For example, if the board is `rolling-nx`, set the image machine with:

```
$ . meta-saha/setup-env --machine rolling-nx
```

The directory will be changed to a folder called `build`. Make sure there is no error messages during past steps. Then build image with `bitbake`. For example, if you wanna build the image `saha-image-base`, build it with:

```
$ bitbake saha-image-base
```

If there is no error occur, the image built by bitbake will be saved under `build/tmp/deploy/image/rolling-nx`. Just uncompress it and flash it to the board!

## License

This project is open sourced under Apache 2.0 License.

```
Copyright (c) 2022 CyberZoo

Licensed under the Apache License, Version 2.0 (the"License");
you may not use this file except in compliance with theLicense.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to inwriting, software
distributed under the License is distributed on an "ASIS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, eitherexpress or implied.
See the License for the specific language governingpermissions and
limitations under the License.
```

Also, the source code forked from OE4T/tegra-demo-distro is under [MIT License](./docs/licenses/OE4T.license).

```
The MIT License (MIT)

Copyright (c) 2020, Matthew Madison and the OE4T contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Contributing

Welcome to contribute to this project!