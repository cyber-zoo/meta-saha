#!/usr/bin/env python3
"""Run published ARM64 image software in an isolated, disposable chroot.

Run through the Docker command in docs/microduck.md. Robot execution always
uses --fake; this check must never be used to measure board timing or gait.
"""
import argparse
import json
import os
from pathlib import Path
import signal
import socket
import stat
import subprocess
import time
import tomllib
import urllib.request


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


class RuntimeCheck:
    def __init__(self, root, output):
        self.root = root
        self.output = output
        self.output.mkdir(parents=True, exist_ok=True)
        self.environment = ["ORT_DYLIB_PATH=/usr/lib/libonnxruntime.so.1",
                            "GST_PLUGIN_PATH=/usr/lib/gstreamer-1.0",
                            "GST_REGISTRY_FORK=no"]
        self.processes = []

    def command(self, args):
        return ["chroot", str(self.root), "/usr/bin/env", *self.environment, *args]

    def run(self, name, args, timeout=30):
        result = subprocess.run(self.command(args), stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, text=True, timeout=timeout)
        (self.output / f"{name}.log").write_text(result.stdout)
        require(result.returncode == 0, f"{name} exited {result.returncode}; inspect its log")
        print(f"PASS {name}", flush=True)
        return result.stdout

    def launch(self, name, args):
        log = (self.output / f"{name}.log").open("w")
        process = subprocess.Popen(self.command(args), stdout=log, stderr=subprocess.STDOUT,
                                   start_new_session=True)
        self.processes.append((process, log))
        return process

    def stop(self, process):
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=8)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait(timeout=8)

    def cleanup(self):
        for process, log in reversed(self.processes):
            self.stop(process)
            log.close()

    def rpc(self, target, method, params=None):
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
            client.settimeout(5)
            client.connect(str(self.root / target.lstrip("/")))
            request = {"jsonrpc": "2.0", "id": 1, "method": method}
            if params is not None:
                request["params"] = params
            client.sendall(json.dumps(request).encode() + b"\n")
            response = json.loads(client.makefile("rb").readline())
        require("error" not in response, f"{method}: {response}")
        return response["result"]

    def wait(self, process, probe, name, timeout=90):
        deadline = time.monotonic() + timeout
        last = None
        while time.monotonic() < deadline:
            require(process.poll() is None, f"{name} exited; inspect its log")
            try:
                result = probe()
                if result:
                    return result
            except (OSError, KeyError, ValueError) as error:
                last = str(error)
            time.sleep(0.2)
        raise RuntimeError(f"{name} did not become ready: {last}")

    def robot(self, name, policy, duration):
        original = (self.root / "etc/robot/robotd.toml").read_text()
        # All changes live in the container's disposable copy, never in the image.
        bench = original.replace("[audio]\nenabled = true", "[audio]\nenabled = false")
        if policy:
            bench = bench.replace("[policy]\nenabled = false", "[policy]\nenabled = true\n" + policy)
        config = f"/run/saha-{name}.toml"
        target = f"/run/saha-{name}.sock"
        (self.root / config.lstrip("/")).write_text(bench)
        process = self.launch(name, ["/opt/robot/daemon/current/bin/robotd", "--fake",
                                     "--params", config, "--socket", target])
        try:
            def ready():
                health = self.rpc(target, "robot.health")
                loop = health.get("control_loop")
                return health if loop and loop["ticks"] > 0 else None

            initial = self.wait(process, ready, name)
            policies = self.rpc(target, "robot.policies")
            require(policies["enabled"] == bool(policy), f"{name}: unexpected policy state")
            require(not any(slot.get("error") for slot in policies["slots"]),
                    f"{name}: policy fallback/error: {policies}")
            if policy:
                require("policy loaded" in (self.output / f"{name}.log").read_text(),
                        f"{name}: policy warmup was not completed")
            samples = []
            deadline = time.monotonic() + duration
            ticks = initial["control_loop"]["ticks"]
            while time.monotonic() < deadline:
                time.sleep(1)
                require(process.poll() is None, f"{name}: daemon stopped")
                health = self.rpc(target, "robot.health")
                loop = health["control_loop"]
                require(loop["ticks"] > ticks and loop["last_tick_age_ms"] < 2000,
                        f"{name}: control loop stalled: {health}")
                ticks = loop["ticks"]
                samples.append(health)
            # Exercise a mutation only against FakeIo, then return it to disabled.
            if policy:
                require(self.rpc(target, "robot.enable", {"on": True, "toggle": False})["accepted"],
                        f"{name}: fake enable refused")
                require(self.rpc(target, "robot.init")["accepted"], f"{name}: fake initialization refused")
                time.sleep(3)
                require(process.poll() is None, f"{name}: fake initialization stopped daemon")
                self.rpc(target, "robot.enable", {"on": False, "toggle": False})
                self.rpc(target, "robot.stop")
            report = {"policies": policies, "initial_health": initial, "samples": samples,
                      "seconds": duration, "backend": "FakeIo under ARM64 emulation"}
            (self.output / f"{name}.json").write_text(json.dumps(report, indent=2))
            print(f"PASS {name}: {duration}s, {ticks} ticks", flush=True)
            return {Path(slot["path"]).name for slot in policies["slots"] if slot.get("path")}
        finally:
            self.stop(process)

    def check(self, seconds):
        for directory in ("run", "tmp", "dev", "root"):
            (self.root / directory).mkdir(exist_ok=True)
        for name, minor in (("null", 3), ("zero", 5), ("urandom", 9)):
            device = self.root / "dev" / name
            if not device.exists():
                os.mknod(device, stat.S_IFCHR | 0o666, os.makedev(1, minor))
        version = tomllib.loads((self.root / "opt/robot/daemon/current/version.toml").read_text())
        for binary in version["binaries"]:
            self.run(f"version-{binary}", [f"/opt/robot/daemon/current/bin/{binary}", "--version"])
        for element in ("webrtcsink", "errorignore", "h264parse", "x264enc", "opusenc", "rtpopuspay"):
            self.run(f"gst-{element}", ["/usr/bin/gst-inspect-1.0", element])
        self.run("gst-video", ["/usr/bin/gst-launch-1.0", "-q", "videotestsrc", "num-buffers=30",
                              "!", "video/x-raw,width=320,height=240,framerate=10/1", "!",
                              "videoconvert", "!", "x264enc", "speed-preset=ultrafast",
                              "tune=zerolatency", "!", "h264parse", "!", "fakesink"])
        self.run("gst-audio", ["/usr/bin/gst-launch-1.0", "-q", "audiotestsrc", "num-buffers=30",
                              "!", "audioconvert", "!", "audioresample", "!", "opusenc", "!",
                              "rtpopuspay", "!", "fakesink"])
        units = [f"{name}.service" for name in ("robotd", "configd", "btd", "padd", "mediad",
                                               "updaterd", "tofd", "microduck-audio-init",
                                               "microduck-bluetooth-uart")]
        self.run("systemd-units", ["/usr/bin/systemd-analyze", "--man=no", "verify", *units])
        self.run("updater-self-test", ["/opt/robot/daemon/current/bin/updaterd", "--self-test"])

        self.robot("commissioning", "", 5)
        models = self.robot("walk-v5", 'mode = "walk"', seconds)
        models |= self.robot("walk-alpha", 'mode = "walk"\n'
                             'walk = "/opt/robot/policies/current/alpha_walking.onnx"\n'
                             'stand = "/opt/robot/policies/current/alpha_stand.onnx"', 5)
        models |= self.robot("roller", 'mode = "roller"', 5)
        expected = {path.name for path in (self.root / "opt/robot/policies/current").glob("*.onnx")}
        require(models == expected and len(models) == 10,
                f"model warmup coverage: loaded={sorted(models)}, expected={sorted(expected)}")

        config = self.launch("configd", ["/opt/robot/daemon/current/bin/configd", "--fake-net",
                                         "--fake-pads", "--socket", "/run/saha-configd.sock"])
        config_status = self.wait(config, lambda: self.rpc("/run/saha-configd.sock", "system.info"),
                                  "configd")
        self.rpc("/run/saha-configd.sock", "net.status")
        self.rpc("/run/saha-configd.sock", "pad.status")
        (self.output / "configd.json").write_text(json.dumps(config_status, indent=2))

        media_config = (self.root / "etc/robot/robotd.toml").read_text().replace(
            "[audio]\nenabled = true", "[audio]\nenabled = false")
        (self.root / "run/saha-media.toml").write_text(media_config)
        media = self.launch("mediad", ["/opt/robot/daemon/current/bin/mediad", "--no-remote",
                                       "--config", "/run/saha-media.toml", "--host", "127.0.0.1",
                                       "--config-socket", "/run/saha-configd.sock",
                                       "--web-port", "18080", "--port", "18443"])

        def console():
            with urllib.request.urlopen("http://127.0.0.1:18080/", timeout=2) as response:
                return response.status == 200 and bool(response.read())

        self.wait(media, console, "mediad")
        time.sleep(5)
        require(media.poll() is None, "mediad stopped after serving console")
        media_log = (self.output / "mediad.log").read_text()
        require("signalling server listening" in media_log and "capture rate" in media_log,
                "mediad did not start the actual test-source pipeline")
        require(not any(error in media_log for error in ("pipeline error", "Error running discovery",
                                                        "Codec discovery pipeline failed")),
                "mediad codec discovery/pipeline failed; inspect its log")
        print("PASS configd IPC and mediad console/test-source startup", flush=True)
        return {"version": version["version"], "model_warmups": sorted(models),
                "walk_seconds": seconds,
                "scope": "isolated ARM64 software execution; no board, radio, audio or timing proof"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rootfs", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--seconds", type=int, default=60)
    args = parser.parse_args()
    root = args.rootfs.resolve(strict=True)
    require(os.geteuid() == 0 and root != Path("/"), "use a disposable Docker chroot as root")
    require(os.environ.get("SAHA_MICRODUCK_EMULATION") == "1", "use the documented isolated invocation")
    require(args.seconds >= 5, "at least five seconds are required")
    check = RuntimeCheck(root, args.output)
    try:
        report = check.check(args.seconds)
        (args.output / "runtime.json").write_text(json.dumps(report, indent=2))
        print(json.dumps(report, indent=2), flush=True)
    finally:
        check.cleanup()


if __name__ == "__main__":
    main()
