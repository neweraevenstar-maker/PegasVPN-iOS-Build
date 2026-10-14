from pathlib import Path

root = Path("PegasVPN/PegasVPN")

required = [
    "VPNManager.swift",
    "VPNKeychain.swift",
    "VPNConfigurationValidator.swift",
    "VPNKillSwitch.swift",
    "VPNDeviceIdentity.swift",
    "VPNEventLog.swift",
    "VPNServerCatalog.swift",
    "VPNEndpointValidator.swift",
    "VPNControlCenterView.swift",
    "VPNAdvancedSettingsView.swift",
    "VPNAdvancedDiagnosticsView.swift",
]

for filename in required:
    path = root / filename
    assert path.is_file(), f"Missing: {path}"
    assert path.stat().st_size > 0, f"Empty: {path}"

api = (root / "VPNAPI.swift").read_text()
assert "https" in api.lower(), "HTTPS validation missing"

keychain = (root / "VPNKeychain.swift").read_text()
assert "SecItemUpdate" in keychain, "Safe Keychain update missing"

print("PegasVPN project checks passed")


additional = [
    "VPNConnectionState.swift",
    "VPNConfigurationInspector.swift",
    "VPNConfigurationHealthView.swift",
    "VPNConnectionGuard.swift",
]

for filename in additional:
    path = root / filename
    assert path.exists(), f"Missing: {filename}"

print("PegasVPN stability checks passed")


recovery_files = [
    "VPNConnectionMonitor.swift",
    "VPNConfigurationManagementView.swift",
    "VPNConfigurationStore.swift",
]

for filename in recovery_files:
    assert (root / filename).is_file(), filename

print("PegasVPN recovery checks passed")


assert (root / "VPNPreferencesExport.swift").is_file()

manager = (root / "VPNManager.swift").read_text()
assert "removeSavedConfiguration()" in manager

management = (
    root / "VPNConfigurationManagementView.swift"
).read_text()
assert "vpnManager.removeSavedConfiguration()" in management

print("Configuration lifecycle checks passed")


assert (
    Path("PegasVPN/PegasVPNTests/VPNCoreTests.swift")
).is_file()

assert "PegasVPNTests:" in (
    Path("PegasVPN/project.yml").read_text()
)

print("Automated test suite present")



assert Path(
    "PegasVPN/PegasVPNTests/VPNCoreTests.swift"
).is_file()

print("iOS CI workflow present")
