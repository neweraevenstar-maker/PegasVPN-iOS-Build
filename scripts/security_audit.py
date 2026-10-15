from pathlib import Path
import re
import subprocess

root = Path("PegasVPN/PegasVPN")

checks = {
    "VPNAPI.swift": ["https", "Authorization"],
    "VPNKeychain.swift": [
        "SecItemUpdate",
        "kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly",
    ],
    "VPNConfigurationValidator.swift": ["PrivateKey", "PublicKey"],
}

for filename, markers in checks.items():
    path = root / filename
    assert path.is_file(), f"Missing: {path}"
    content = path.read_text()
    for marker in markers:
        assert marker in content, (
            f"Missing security marker {marker} in {filename}"
        )

# Scan every tracked file, not only the Swift app directory.
tracked = subprocess.check_output(["git", "ls-files", "-z"]).decode().split("\0")
for name in filter(None, tracked):
    path = Path(name)
    lower = path.name.lower()
    forbidden_suffixes = (
        ".p8", ".p12", ".pfx", ".pem", ".key",
        ".mobileprovision", ".sqlite", ".sqlite3", ".db",
    )
    forbidden_names = {
        ".env", "id_rsa", "id_ed25519",
        "credentials.json", "service-account.json",
    }
    assert not (
        lower in forbidden_names
        or lower.startswith(".env.")
        or lower.endswith(forbidden_suffixes)
    ), f"Sensitive file tracked publicly: {name}"

    if path.suffix.lower() not in {
        ".swift", ".yml", ".yaml", ".json", ".plist", ".sh",
    }:
        continue
    if not path.is_file():
        continue
    content = path.read_text(errors="replace")
    assert not re.search(
        r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----",
        content
    ), f"Possible embedded private key: {name}"

print("Public source security checks passed")
