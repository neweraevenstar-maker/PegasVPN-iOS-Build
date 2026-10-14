from pathlib import Path

root = Path("PegasVPN/PegasVPN")

required = {
    "VPNRemoteServer.swift": [
        "struct VPNRemoteServer",
        "endpointURL"
    ],
    "VPNRemoteServerSelection.swift": [
        "VPNRemoteServerSelection",
        "selectedID"
    ],
    "VPNConfigurationExpiry.swift": [
        "isExpired",
        "shouldRefresh"
    ],
    "VPNRetryPolicy.swift": [
        "maximumAttempts",
        "shouldRetry"
    ],
    "VPNRequestExecutor.swift": [
        "Task.checkCancellation",
        "allowRetry"
    ],
    "VPNAPIHealth.swift": [
        "VPNAPIHealthStatus"
    ],
    "VPNAPIHealthChecker.swift": [
        "URLSessionConfiguration.ephemeral",
        "httpMethod = \"HEAD\""
    ],
    "VPNConnectionDiagnostics.swift": [
        "NWPathMonitor"
    ],
    "VPNProvisioningState.swift": [
        "VPNProvisioningState"
    ],
    "VPNConfigurationRefreshPolicy.swift": [
        "minimumRefreshInterval"
    ],
    "VPNProvisioningValidation.swift": [
        "maximumConfigurationBytes",
        "VPNConfigurationValidator.validate"
    ],
    "VPNRemoteServerValidator.swift": [
        "identifiers.insert"
    ]
}

for filename, markers in required.items():
    path = root / filename
    assert path.exists(), f"Missing: {filename}"
    content = path.read_text()

    for marker in markers:
        assert marker in content, f"{filename}: missing {marker}"

    print("PASS:", filename)

api = (root / "VPNAPIClient.swift").read_text()
assert "VPNProvisioningError" in api
assert "VPNAPIError" not in api

print("PASS: no duplicate VPNAPIError")
print("Platform static checks passed")
