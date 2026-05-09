package main

import (
	"encoding/json"
	"fmt"
	"os"
	"sort"
	"strings"
)

type RouterConfig struct {
	Version     string                  `json:"version"`
	Enabled     bool                    `json:"enabled"`
	Description string                  `json:"description"`
	LastModified string                 `json:"lastModified"`
	ModifiedBy  string                  `json:"modifiedBy"`
	Defaults    DefaultBinding          `json:"defaults"`
	Bindings    map[string]*AgentBinding `json:"agentBindings"`
	TempPolicy  TemperaturePolicy       `json:"temperaturePolicy"`
	Admin       AdminConfig             `json:"admin"`
	Priority    ProviderPriority        `json:"providerPriority"`
	Audit       AuditConfig             `json:"audit"`
}

type DefaultBinding struct {
	Model             string `json:"model"`
	Provider          string `json:"provider"`
	Temperature       float64 `json:"temperature"`
	HallucinationGuard string `json:"hallucinationGuard"`
	Notes             string `json:"notes"`
}

type AgentBinding struct {
	Model             string   `json:"model"`
	Provider          string   `json:"provider"`
	Temperature       *float64 `json:"temperature"`
	HallucinationGuard string   `json:"hallucinationGuard"`
}

type TemperaturePolicy struct {
	Description            string  `json:"description"`
	AllowCommandOverride   bool    `json:"allowCommandOverride"`
	AllowTUIModification   bool    `json:"allowTUIModification"`
	AllowScriptModification bool   `json:"allowScriptModification"`
	LockedByDefault        bool    `json:"lockedByDefault"`
	UnlockRequiresAdmin    bool    `json:"unlockRequiresAdmin"`
	AuditChanges           bool    `json:"auditChanges"`
	ValidationRange        Range   `json:"validationRange"`
}

type Range struct {
	Min float64 `json:"min"`
	Max float64 `json:"max"`
}

type AdminConfig struct {
	Enabled              bool       `json:"enabled"`
	CredentialSource     string     `json:"credentialSource"`
	PasswordHash         string     `json:"passwordHash"`
	PCIdentitySource     []string   `json:"pcIdentitySource"`
	CurrentPcFingerprint string     `json:"currentPcFingerprint"`
	TrustedPcs           []TrustedPC `json:"trustedPcs"`
	AuthMode             string     `json:"authMode"`
	SessionTimeoutMinutes int       `json:"sessionTimeoutMinutes"`
	AuditLog             string     `json:"auditLog"`
	MaxAuthAttempts      int        `json:"maxAuthAttempts"`
	LockoutDurationMinutes int      `json:"lockoutDurationMinutes"`
}

type TrustedPC struct {
	Fingerprint string `json:"fingerprint"`
	Label       string `json:"label"`
	AutoGrant   bool   `json:"autoGrant"`
	GrantedAt   string `json:"grantedAt"`
}

type ProviderPriority struct {
	Order []string `json:"order"`
}

type AuditConfig struct {
	Enabled          bool   `json:"enabled"`
	LogRetentionDays int    `json:"logRetentionDays"`
	LogToJSON        bool   `json:"logToJson"`
}

type CloudAgentsConfig struct {
	Providers map[string]CloudProvider `json:"providers"`
}

type CloudProvider struct {
	Enabled     bool   `json:"enabled"`
	Description string `json:"description"`
	Model       string `json:"model"`
	Local       bool   `json:"local,omitempty"`
}

type AgentRow struct {
	Code        string
	Model       string
	Provider    string
	Temperature float64
	Source      string
	Selected    bool
}

func LoadRouterConfig(path string) (*RouterConfig, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("cannot read %s: %w", path, err)
	}
	var cfg RouterConfig
	if err := json.Unmarshal(data, &cfg); err != nil {
		return nil, fmt.Errorf("invalid JSON in %s: %w", path, err)
	}
	return &cfg, nil
}

func SaveRouterConfig(path string, cfg *RouterConfig) error {
	data, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return fmt.Errorf("cannot marshal config: %w", err)
	}
	if err := os.WriteFile(path, data, 0644); err != nil {
		return fmt.Errorf("cannot write %s: %w", path, err)
	}
	return nil
}

func LoadCloudAgents(path string) (*CloudAgentsConfig, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("cannot read %s: %w", path, err)
	}
	var cfg CloudAgentsConfig
	if err := json.Unmarshal(data, &cfg); err != nil {
		return nil, fmt.Errorf("invalid JSON in %s: %w", path, err)
	}
	return &cfg, nil
}

func (cfg *RouterConfig) ResolveBinding(code string) AgentRow {
	binding, exists := cfg.Bindings[code]
	model := cfg.Defaults.Model
	provider := cfg.Defaults.Provider
	temp := cfg.Defaults.Temperature
	source := "default"

	if exists && binding.Model != "" {
		model = binding.Model
		source = "override"
	}
	if exists && binding.Provider != "" {
		provider = binding.Provider
		source = "override"
	}
	if exists && binding.Temperature != nil {
		temp = *binding.Temperature
		source = "override"
	}

	return AgentRow{
		Code:        code,
		Model:       model,
		Provider:    provider,
		Temperature: temp,
		Source:      source,
	}
}

func (cfg *RouterConfig) AllBindings() []AgentRow {
	codes := []string{"BA", "SAD", "DEV", "QA", "OPS", "GOV", "DOC"}
	var rows []AgentRow
	for _, c := range codes {
		rows = append(rows, cfg.ResolveBinding(c))
	}
	return rows
}

func (cfg *RouterConfig) HasCustomBindings() bool {
	for _, code := range []string{"BA", "SAD", "DEV", "QA", "OPS", "GOV", "DOC"} {
		b, ok := cfg.Bindings[code]
		if ok && (b.Model != "" || b.Provider != "" || b.Temperature != nil) {
			return true
		}
	}
	return false
}

func (cfg *CloudAgentsConfig) ProviderList(priority []string) []ProviderEntry {
	entries := make(map[string]ProviderEntry)
	for code, p := range cfg.Providers {
		entries[code] = ProviderEntry{
			Code:        code,
			Description: p.Description,
			DefaultModel: p.Model,
			Enabled:     p.Enabled,
			Local:       p.Local,
		}
	}

	var result []ProviderEntry
	seen := make(map[string]bool)
	for _, code := range priority {
		if e, ok := entries[code]; ok {
			result = append(result, e)
			seen[code] = true
		}
	}
	for code, e := range entries {
		if !seen[code] {
			result = append(result, e)
			seen[code] = true
		}
	}
	return result
}

type ProviderEntry struct {
	Code         string
	Description  string
	DefaultModel string
	Enabled      bool
	Local        bool
}

func (p ProviderEntry) Label() string {
	status := ""
	if !p.Enabled {
		status = " (disabled)"
	}
	if p.Local {
		status = " (local)"
	}
	return fmt.Sprintf("%s — %s%s", p.Code, p.Description, status)
}

var AgentCodes = []string{"BA", "SAD", "DEV", "QA", "OPS", "GOV", "DOC"}
var AgentNames = map[string]string{
	"BA":  "Business Analyst",
	"SAD": "Solution Architect",
	"DEV": "Developer",
	"QA":  "Quality Assurance",
	"OPS": "DevOps",
	"GOV": "Governance",
	"DOC": "Documentation",
}

func NormalizeFloat64(v float64) float64 {
	return float64(int(v*100)) / 100
}

func FindRepoRoot() string {
	wd, _ := os.Getwd()
	parts := strings.Split(wd, string(os.PathSeparator))
	for i := len(parts); i > 0; i-- {
		candidate := strings.Join(parts[:i], string(os.PathSeparator))
		if _, err := os.Stat(candidate + string(os.PathSeparator) + "config"); err == nil {
			if _, err := os.Stat(candidate + string(os.PathSeparator) + "config" + string(os.PathSeparator) + "model-router.json"); err == nil {
				return candidate
			}
		}
	}
	return wd
}

func init() {
	sort.Strings(AgentCodes)
}
