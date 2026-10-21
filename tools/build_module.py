#!/usr/bin/env python3
"""Build an installable ZIP from module/ using only Python's standard library."""

from __future__ import annotations

import hashlib
import json
import re
import stat
import sys
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE = ROOT / "module"
REQUIRED = (
    "README.md",
    "action.sh",
    "audio_tuning.conf",
    "customize.sh",
    "diagnose.sh",
    "module.prop",
    "post-fs-data.sh",
    "selfcheck.sh",
    "service.sh",
    "system.prop",
    "uninstall.sh",
    "system/odm/etc/audio/audio_effects_config.json",
    "system/odm/etc/audio_policy_engine_stream_volumes_mi.xml",
    "system/odm/etc/dolby/dax-default-spatializer.xml",
    "system/odm/etc/dolby/dax-default.xml",
)


def build() -> Path:
    if not MODULE.is_dir() or MODULE.is_symlink():
        raise ValueError("Expected a regular module/ directory")
    for name in REQUIRED:
        if not (MODULE / name).is_file():
            raise ValueError(f"Missing required module file: {name}")

    entries = sorted(MODULE.rglob("*"))
    for path in entries:
        if path.is_symlink():
            raise ValueError(f"Symlinks are not supported: {path}")
        if path.name == ".git":
            raise ValueError("module/ must not contain a nested Git repository")
    files = [path for path in entries if path.is_file()]
    payload = {path.relative_to(MODULE).as_posix(): path.read_bytes() for path in files}

    properties = {}
    for line in payload["module.prop"].decode("utf-8-sig").splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            key, value = line.split("=", 1)
            properties[key.strip()] = value.strip()
    version = properties.get("version", "")
    if not re.fullmatch(r"[0-9]+(?:\.[0-9]+)*", version):
        raise ValueError("module.prop must contain a numeric dotted version")
    if properties.get("id") != "xiaomi17-stock-safe-audio":
        raise ValueError("Unexpected module id")

    for name, content in payload.items():
        if name.endswith(".json"):
            json.loads(content)
        elif name.endswith(".xml"):
            ET.fromstring(content)

    output = ROOT / "dist" / f"xiaomi17-audio-v{version}.zip"
    output.parent.mkdir(exist_ok=True)
    temporary = output.with_suffix(".zip.tmp")
    try:
        with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
            for name, content in payload.items():
                info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
                info.create_system = 3
                mode = 0o755 if name.endswith(".sh") else 0o644
                info.external_attr = (stat.S_IFREG | mode) << 16
                archive.writestr(info, content, compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
        with zipfile.ZipFile(temporary) as archive:
            if archive.testzip() is not None or set(archive.namelist()) != set(payload):
                raise ValueError("ZIP integrity or file list verification failed")
            for name, content in payload.items():
                if archive.read(name) != content:
                    raise ValueError(f"ZIP content mismatch: {name}")
        temporary.replace(output)
    finally:
        temporary.unlink(missing_ok=True)

    print(f"Built: {output}")
    print(f"Files: {len(payload)} (module.prop is at ZIP root)")
    print(f"SHA-256: {hashlib.sha256(output.read_bytes()).hexdigest()}")
    return output


if __name__ == "__main__":
    try:
        build()
    except (OSError, ValueError, zipfile.BadZipFile, ET.ParseError) as exc:
        print(f"Build failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
