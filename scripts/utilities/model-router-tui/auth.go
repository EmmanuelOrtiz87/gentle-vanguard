package main

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"net"
	"os"
	"os/exec"
	"strings"
)

func GetPcFingerprint() string {
	parts := []string{
		getMachineGUID(),
		getMacAddress(),
		getHostname(),
	}
	combined := strings.Join(parts, "|")
	hash := sha256.Sum256([]byte(combined))
	return hex.EncodeToString(hash[:])
}

func VerifyAdminPassword(passwordHash string, keyFilePath string) bool {
	data, err := os.ReadFile(keyFilePath)
	if err != nil {
		return false
	}
	hash := sha256.Sum256(data)
	return hex.EncodeToString(hash[:]) == passwordHash
}

func IsTrustedPC(cfg *AdminConfig) bool {
	fp := GetPcFingerprint()
	for _, pc := range cfg.TrustedPcs {
		if pc.Fingerprint == fp && pc.AutoGrant {
			return true
		}
	}
	return false
}

func getMachineGUID() string {
	cmd := exec.Command("powershell", "-NoProfile", "-Command",
		"(Get-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\Cryptography' -Name MachineGuid).MachineGuid")
	out, err := cmd.Output()
	if err != nil {
		return "no-guid"
	}
	return strings.TrimSpace(string(out))
}

func getMacAddress() string {
	ifaces, err := net.Interfaces()
	if err != nil {
		return "no-mac"
	}
	for _, iface := range ifaces {
		if iface.Flags&net.FlagUp != 0 && len(iface.HardwareAddr) > 0 {
			return iface.HardwareAddr.String()
		}
	}
	return "no-mac"
}

func getHostname() string {
	h, err := os.Hostname()
	if err != nil {
		return "no-hostname"
	}
	return h
}

func WriteAuditEntry(action, detail, status string) {
	repoRoot := FindRepoRoot()
	logDir := repoRoot + string(os.PathSeparator) + ".logs"
	os.MkdirAll(logDir, 0755)
	logFile := logDir + string(os.PathSeparator) + "model-router-audit.jsonl"

	entry := fmt.Sprintf(`{"timestamp":"%s","action":"%s","detail":"%s","status":"%s","fingerprint":"%s","hostname":"%s"}`,
		strings.ReplaceAll(os.Getenv("DATE"), "\"", ""),
		action,
		detail,
		status,
		GetPcFingerprint(),
		getHostname(),
	)

	f, err := os.OpenFile(logFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return
	}
	defer f.Close()
	f.WriteString(entry + "\n")
}
