#!/usr/bin/env python3
"""Install the App Store certificate and profiles on a GitHub macOS runner.

Reads secrets from the environment and writes ios/signing_profiles.json plus
ios/ExportOptions.plist for the iOS Fastlane lane. Does not print secret values.
"""

import base64
import json
import os
import plistlib
import subprocess
import sys
from pathlib import Path

APP_BUNDLE_ID = "tinyminyapps.upsc.wars"
EXTENSION_BUNDLE_ID = "tinyminyapps.upsc.wars.MakePulse"
TEAM_ID = "PJFA69Q3GT"
ROOT = Path(__file__).resolve().parents[1]


def require(name: str) -> str:
    value = os.environ.get(name, "")
    if not value:
        print(f"Missing secret: {name}", file=sys.stderr)
        sys.exit(1)
    return value


def decode(value: str, path: Path) -> None:
    path.write_bytes(base64.b64decode(value))


def install_profile(encoded: str, expected_bundle_id: str) -> str:
    runner_temp = Path(os.environ["RUNNER_TEMP"])
    source = runner_temp / f"{expected_bundle_id}.mobileprovision"
    decode(encoded, source)
    plist_xml = subprocess.check_output(["security", "cms", "-D", "-i", str(source)])
    profile = plistlib.loads(plist_xml)
    app_id = profile["Entitlements"]["application-identifier"]
    prefix = f"{TEAM_ID}."
    if not app_id.startswith(prefix):
        print(f"Profile {profile.get('Name')} is not for team {TEAM_ID}.", file=sys.stderr)
        sys.exit(1)
    bundle_id = app_id[len(prefix) :]
    if bundle_id != expected_bundle_id:
        print(
            f"Expected a profile for {expected_bundle_id}, got {bundle_id}.",
            file=sys.stderr,
        )
        sys.exit(1)
    destination_dir = Path.home() / "Library/MobileDevice/Provisioning Profiles"
    destination_dir.mkdir(parents=True, exist_ok=True)
    source.replace(destination_dir / f"{profile['UUID']}.mobileprovision")
    return profile["Name"]


def main() -> None:
    certificate = require("IOS_DIST_CERTIFICATE_BASE64")
    certificate_password = require("IOS_DIST_CERTIFICATE_PASSWORD")
    app_profile = require("IOS_PROVISION_PROFILE_BASE64")
    extension_profile = require("IOS_EXTENSION_PROVISION_PROFILE_BASE64")

    runner_temp = Path(os.environ["RUNNER_TEMP"])
    certificate_path = runner_temp / "distribution.p12"
    keychain_path = runner_temp / "app-signing.keychain-db"
    keychain_password = subprocess.check_output(["openssl", "rand", "-base64", "24"], text=True).strip()
    decode(certificate, certificate_path)

    subprocess.run(["security", "create-keychain", "-p", keychain_password, str(keychain_path)], check=True)
    subprocess.run(["security", "set-keychain-settings", "-lut", "21600", str(keychain_path)], check=True)
    subprocess.run(["security", "unlock-keychain", "-p", keychain_password, str(keychain_path)], check=True)
    subprocess.run(
        [
            "security",
            "import",
            str(certificate_path),
            "-P",
            certificate_password,
            "-A",
            "-t",
            "cert",
            "-f",
            "pkcs12",
            "-k",
            str(keychain_path),
        ],
        check=True,
    )
    subprocess.run(
        [
            "security",
            "set-key-partition-list",
            "-S",
            "apple-tool:,apple:,codesign:",
            "-s",
            "-k",
            keychain_password,
            str(keychain_path),
        ],
        check=True,
    )
    existing = subprocess.check_output(["security", "list-keychains", "-d", "user"], text=True)
    keychains = [str(keychain_path)] + [item.strip().strip('"') for item in existing.splitlines() if item.strip()]
    subprocess.run(["security", "list-keychains", "-d", "user", "-s", *keychains], check=True)

    profiles = {
        APP_BUNDLE_ID: install_profile(app_profile, APP_BUNDLE_ID),
        EXTENSION_BUNDLE_ID: install_profile(extension_profile, EXTENSION_BUNDLE_ID),
    }
    (ROOT / "ios/signing_profiles.json").write_text(json.dumps(profiles) + "\n")

    export_options = {
        "method": "app-store-connect",
        "signingStyle": "manual",
        "teamID": TEAM_ID,
        "signingCertificate": "Apple Distribution",
        "uploadSymbols": True,
        "provisioningProfiles": profiles,
    }
    with (ROOT / "ios/ExportOptions.plist").open("wb") as handle:
        plistlib.dump(export_options, handle)
    print("Installed the distribution certificate and both provisioning profiles.")


if __name__ == "__main__":
    main()
