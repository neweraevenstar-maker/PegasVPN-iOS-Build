from pathlib import Path
import re

root = Path("PegasVPN/PegasVPN")

checks = {
    "VPNAPI.swift": [
        "https",
        "Authorization",
    ],
    "VPNKeychain.swift": [
        "SecItemUpdate",
        "kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly",
    ],
    "VPNConfigurationValidator.swift": [
        "PrivateKey",
        "PublicKey",
    ],
}

for filename, markers in checks.items():
    path = root / filename
    assert path.is_file(), f"Missing: {path}"

    content = path.read_text()

    for marker in markers:
        assert marker in content, (
            f"Missing security marker {marker} in {filename}"
        )

# Ищем PEM private keys в исходниках.
for path in root.rglob("*.swift"):
    content = path.read_text()

    assert not re.search(
        r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----",
        content
    ), f"Possible embedded private key: {path}"

print("Security checks passed")
