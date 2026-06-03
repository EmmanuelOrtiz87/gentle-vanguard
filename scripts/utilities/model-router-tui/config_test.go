package main

import (
	"encoding/json"
	"os"
	"sort"
	"testing"
)

func TestNormalizeFloat64(t *testing.T) {
	tests := []struct {
		input    float64
		expected float64
	}{
		{0.15678, 0.15},
		{0.999, 0.99},
		{1.2345, 1.23},
		{0.0, 0.0},
		{-0.5, -0.5},
	}
	for _, tt := range tests {
		got := NormalizeFloat64(tt.input)
		if got != tt.expected {
			t.Errorf("NormalizeFloat64(%f) = %f, want %f", tt.input, got, tt.expected)
		}
	}
}

func TestAgentCodesSorted(t *testing.T) {
	if !sort.StringsAreSorted(AgentCodes) {
		t.Error("AgentCodes must be sorted")
	}
}

func TestAgentNamesCoverage(t *testing.T) {
	for _, code := range AgentCodes {
		if _, ok := AgentNames[code]; !ok {
			t.Errorf("AgentNames missing entry for code %q", code)
		}
	}
}

func TestLoadRouterConfig(t *testing.T) {
	tmp := t.TempDir()
	path := tmp + "/router.json"
	validJSON := `{
		"version": "1.0",
		"enabled": true,
		"description": "test",
		"lastModified": "2026-06-01",
		"modifiedBy": "test",
		"defaults": {
			"model": "qwen-3.6-plus",
			"provider": "openrouter",
			"temperature": 0.3,
			"hallucinationGuard": "low",
			"notes": ""
		},
		"agentBindings": {},
		"temperaturePolicy": {
			"description": "",
			"allowCommandOverride": false,
			"allowTUIModification": false,
			"allowScriptModification": false,
			"lockedByDefault": true,
			"unlockRequiresAdmin": true,
			"auditChanges": true,
			"validationRange": { "min": 0, "max": 2 }
		},
		"admin": {
			"enabled": false,
			"credentialSource": "",
			"passwordHash": "",
			"pcIdentitySource": [],
			"currentPcFingerprint": "",
			"trustedPcs": [],
			"authMode": "none",
			"sessionTimeoutMinutes": 60,
			"auditLog": "",
			"maxAuthAttempts": 3,
			"lockoutDurationMinutes": 15
		},
		"providerPriority": { "order": ["ollama", "openrouter"] },
		"audit": { "enabled": false, "logRetentionDays": 90, "logToJson": true }
	}`
	if err := os.WriteFile(path, []byte(validJSON), 0644); err != nil {
		t.Fatal(err)
	}
	cfg, err := LoadRouterConfig(path)
	if err != nil {
		t.Fatalf("LoadRouterConfig failed: %v", err)
	}
	if cfg.Version != "1.0" {
		t.Errorf("Version = %q, want %q", cfg.Version, "1.0")
	}
	if !cfg.Enabled {
		t.Error("Expected Enabled = true")
	}
}

func TestLoadRouterConfig_InvalidJSON(t *testing.T) {
	tmp := t.TempDir()
	path := tmp + "/bad.json"
	if err := os.WriteFile(path, []byte("{invalid}"), 0644); err != nil {
		t.Fatal(err)
	}
	_, err := LoadRouterConfig(path)
	if err == nil {
		t.Error("Expected error for invalid JSON")
	}
}

func TestLoadRouterConfig_MissingFile(t *testing.T) {
	_, err := LoadRouterConfig("/nonexistent/path.json")
	if err == nil {
		t.Error("Expected error for missing file")
	}
}

func TestSaveRouterConfig(t *testing.T) {
	cfg := &RouterConfig{
		Version: "2.0",
		Enabled: true,
		Defaults: DefaultBinding{
			Model:    "kimi-k2.6",
			Provider: "openrouter",
		},
	}
	tmp := t.TempDir()
	path := tmp + "/saved.json"
	if err := SaveRouterConfig(path, cfg); err != nil {
		t.Fatalf("SaveRouterConfig failed: %v", err)
	}
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	var loaded RouterConfig
	if err := json.Unmarshal(data, &loaded); err != nil {
		t.Fatalf("Saved file is not valid JSON: %v", err)
	}
	if loaded.Version != "2.0" {
		t.Errorf("Version = %q, want %q", loaded.Version, "2.0")
	}
}

func TestResolveBinding_Default(t *testing.T) {
	cfg := &RouterConfig{
		Defaults: DefaultBinding{
			Model:    "qwen-3.6-plus",
			Provider: "openrouter",
			Temperature: 0.3,
		},
		Bindings: map[string]*AgentBinding{
			"DEV": {Model: "kimi-k2.6", Provider: "openrouter"},
		},
	}
	row := cfg.ResolveBinding("BA")
	if row.Model != "qwen-3.6-plus" {
		t.Errorf("BA Model = %q, want %q", row.Model, "qwen-3.6-plus")
	}
	if row.Source != "default" {
		t.Errorf("BA Source = %q, want %q", row.Source, "default")
	}
}

func TestResolveBinding_Override(t *testing.T) {
	cfg := &RouterConfig{
		Defaults: DefaultBinding{
			Model:    "qwen-3.6-plus",
			Provider: "openrouter",
			Temperature: 0.3,
		},
		Bindings: map[string]*AgentBinding{
			"DEV": {Model: "kimi-k2.6", Provider: "openrouter"},
		},
	}
	row := cfg.ResolveBinding("DEV")
	if row.Model != "kimi-k2.6" {
		t.Errorf("DEV Model = %q, want %q", row.Model, "kimi-k2.6")
	}
	if row.Source != "override" {
		t.Errorf("DEV Source = %q, want %q", row.Source, "override")
	}
}

func TestHasCustomBindings(t *testing.T) {
	cfg := &RouterConfig{
		Defaults:  DefaultBinding{Model: "default"},
		Bindings:  map[string]*AgentBinding{},
	}
	if cfg.HasCustomBindings() {
		t.Error("Expected no custom bindings when empty")
	}
	cfg.Bindings["DEV"] = &AgentBinding{Model: "custom"}
	if !cfg.HasCustomBindings() {
		t.Error("Expected custom bindings when DEV has model")
	}
}

func TestAllBindingsCount(t *testing.T) {
	cfg := &RouterConfig{
		Defaults:  DefaultBinding{Model: "qwen", Provider: "openrouter"},
		Bindings:  make(map[string]*AgentBinding),
	}
	rows := cfg.AllBindings()
	if len(rows) != len(AgentCodes) {
		t.Errorf("AllBindings returned %d rows, want %d", len(rows), len(AgentCodes))
	}
}

func TestProviderList(t *testing.T) {
	cfg := &CloudAgentsConfig{
		Providers: map[string]CloudProvider{
			"ollama":     {Enabled: true, Description: "Local"},
			"openrouter": {Enabled: true, Description: "Cloud"},
		},
	}
	priority := []string{"ollama", "openrouter"}
	list := cfg.ProviderList(priority)
	if len(list) != 2 {
		t.Errorf("ProviderList returned %d, want 2", len(list))
	}
	if list[0].Code != "ollama" {
		t.Errorf("First provider = %q, want %q", list[0].Code, "ollama")
	}
}

func TestProviderEntryLabel(t *testing.T) {
	e := ProviderEntry{Code: "test", Description: "Test provider", Enabled: true}
	label := e.Label()
	if label != "test — Test provider" {
		t.Errorf("Label = %q, want %q", label, "test — Test provider")
	}
	eDis := ProviderEntry{Code: "x", Description: "X", Enabled: false}
	if eDis.Label() != "x — X (disabled)" {
		t.Errorf("Disabled label = %q", eDis.Label())
	}
	eLoc := ProviderEntry{Code: "y", Description: "Y", Enabled: true, Local: true}
	if eLoc.Label() != "y — Y (local)" {
		t.Errorf("Local label = %q", eLoc.Label())
	}
}

func TestLoadCloudAgents(t *testing.T) {
	tmp := t.TempDir()
	path := tmp + "/cloud.json"
	validJSON := `{"providers":{"test":{"enabled":true,"description":"Test","model":"m1"}}}`
	if err := os.WriteFile(path, []byte(validJSON), 0644); err != nil {
		t.Fatal(err)
	}
	cfg, err := LoadCloudAgents(path)
	if err != nil {
		t.Fatalf("LoadCloudAgents failed: %v", err)
	}
	if _, ok := cfg.Providers["test"]; !ok {
		t.Error("Expected provider 'test'")
	}
}

func TestLoadCloudAgents_Invalid(t *testing.T) {
	_, err := LoadCloudAgents("/nonexistent.json")
	if err == nil {
		t.Error("Expected error for missing file")
	}
}
