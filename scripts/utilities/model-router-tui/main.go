package main

import (
	"flag"
	"fmt"
	"os"
	"strconv"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type state int

const (
	stateLoading state = iota
	stateOverview
	stateAllSamePrompt
	stateChangeDefaults
	statePerAgentList
	stateEditAgent
	stateModelPicker
	stateTemperatureEdit
	stateAdminAuth
	stateAdminPassword
	stateSaving
	stateDone
)

var (
	titleStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("#00FFFF")).
			Padding(0, 1)

	headerStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("#FFFFFF")).
			Background(lipgloss.Color("#333333")).
			Padding(0, 1)

	selectedStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("#00FF00")).
			Padding(0, 1)

	defaultStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#AAAAAA")).
			Padding(0, 1)

	overrideStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#FFFF00")).
			Padding(0, 1)

	errorStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#FF4444")).
			Bold(true)

	successStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#00FF00")).
			Bold(true)

	helpStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#888888"))

	subtleStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#666666"))

	labelStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("#00FFFF"))

	valueStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#FFFFFF"))
)

type screenMsg struct{}

type configLoadedMsg struct {
	config *RouterConfig
	cloud  *CloudAgentsConfig
	err    error
}

type savedMsg struct {
	err error
}

type model struct {
	state         state
	config        *RouterConfig
	cloud         *CloudAgentsConfig
	configPath    string
	repoRoot      string
	providers     []ProviderEntry
	agentRows     []AgentRow
	cursor        int
	tempCursor    int
	editAgentCode string
	currentModel  string
	currentProv   string
	currentTemp   float64
	defaultModel  string
	defaultProv   string
	defaultTemp   float64
	adminPassword string
	adminAuthed   bool
	statusMsg     string
	err           error
	width         int
	height        int
	ready         bool
	quit          bool
	tempInput     string
	showTempInput bool
	lastKey       string
}

func initialModel(configPath string) model {
	return model{
		state:      stateLoading,
		configPath: configPath,
		repoRoot:   FindRepoRoot(),
	}
}

func (m model) Init() tea.Cmd {
	return func() tea.Msg {
		cfg, err := LoadRouterConfig(m.configPath)
		if err != nil {
			return configLoadedMsg{err: err}
		}
		cloudPath := m.repoRoot + string(os.PathSeparator) + "config" + string(os.PathSeparator) + "cloud-agents.json"
		cloud, cErr := LoadCloudAgents(cloudPath)
		if cErr != nil {
			cloud = &CloudAgentsConfig{Providers: make(map[string]CloudProvider)}
			cloud.Providers["anthropic"] = CloudProvider{
				Enabled:     true,
				Description: "Anthropic Claude",
				Model:       "claude-3-5-sonnet-20241022",
			}
			cloud.Providers["openai"] = CloudProvider{
				Enabled:     true,
				Description: "OpenAI GPT",
				Model:       "gpt-4o",
			}
		}
		return configLoadedMsg{config: cfg, cloud: cloud}
	}
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		if !m.ready {
			m.ready = true
		}
		return m, nil

	case tea.KeyMsg:
		m.lastKey = msg.String()
		return m.handleKey(msg)

	case configLoadedMsg:
		if msg.err != nil {
			m.err = msg.err
			m.state = stateDone
			return m, tea.Quit
		}
		m.config = msg.config
		m.cloud = msg.cloud
		m.agentRows = m.config.AllBindings()
		m.providers = m.cloud.ProviderList(m.config.Priority.Order)
		m.defaultModel = m.config.Defaults.Model
		m.defaultProv = m.config.Defaults.Provider
		m.defaultTemp = m.config.Defaults.Temperature
		m.adminAuthed = IsTrustedPC(&m.config.Admin)

		if m.config.HasCustomBindings() {
			m.state = stateOverview
		} else {
			m.state = stateAllSamePrompt
		}
		return m, nil

	case savedMsg:
		if msg.err != nil {
			m.err = msg.err
			m.statusMsg = "Error saving: " + msg.err.Error()
		} else {
			m.statusMsg = "Configuration saved successfully"
		}
		m.state = stateDone
		return m, tea.Quit
	}

	return m, nil
}

func (m *model) handleKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch m.state {
	case stateOverview:
		return m.handleOverviewKey(msg)
	case stateAllSamePrompt:
		return m.handleAllSameKey(msg)
	case stateChangeDefaults:
		return m.handleChangeDefaultsKey(msg)
	case statePerAgentList:
		return m.handlePerAgentKey(msg)
	case stateEditAgent:
		return m.handleEditAgentKey(msg)
	case stateModelPicker:
		return m.handleModelPickerKey(msg)
	case stateTemperatureEdit:
		return m.handleTemperatureKey(msg)
	case stateAdminAuth:
		return m.handleAdminAuthKey(msg)
	case stateAdminPassword:
		return m.handleAdminPasswordKey(msg)
	}
	return m, nil
}

// --- Overview ---

func (m *model) handleOverviewKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "q", "ctrl+c":
		m.quit = true
		m.state = stateDone
		return m, tea.Quit
	case "enter", " ":
		if m.cursor == 0 {
			m.state = stateAllSamePrompt
		} else if m.cursor == 1 {
			m.state = statePerAgentList
		} else if m.cursor == 2 {
			if !m.adminAuthed {
				m.state = stateAdminAuth
			} else {
				m.state = stateOverview
				m.showAdminOptions()
			}
		} else if m.cursor == 3 {
			m.state = stateSaving
			return m, m.saveConfig()
		}
	case "up", "k":
		if m.cursor > 0 {
			m.cursor--
		}
	case "down", "j":
		if m.cursor < 3 {
			m.cursor++
		}
	case "a":
		m.state = stateAdminAuth
	}
	return m, nil
}

func (m *model) showAdminOptions() {
	m.statusMsg = "Admin: " + m.config.Admin.AuthMode + " mode | " +
		strconv.Itoa(len(m.config.Admin.TrustedPcs)) + " trusted PC(s)"
}

// --- All Same Prompt ---

func (m *model) handleAllSameKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "y", "Y":
		m.statusMsg = "All agents will use defaults: " + m.defaultModel
		m.state = stateDone
		return m, tea.Quit
	case "n", "N":
		m.state = statePerAgentList
	case "c", "C":
		m.state = stateChangeDefaults
	case "q", "esc":
		m.state = stateDone
		return m, tea.Quit
	}
	return m, nil
}

// --- Change Defaults ---

func (m *model) handleChangeDefaultsKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "enter":
		if m.cursor == 0 {
			providers := m.cloud.ProviderList(m.config.Priority.Order)
			if len(providers) > 0 {
				for i, p := range providers {
					if p.Code == m.defaultProv {
						nextIdx := (i + 1) % len(providers)
						m.defaultProv = providers[nextIdx].Code
						m.defaultModel = providers[nextIdx].DefaultModel
						break
					}
				}
				if m.defaultProv == "" {
					m.defaultProv = providers[0].Code
					m.defaultModel = providers[0].DefaultModel
				}
			}
		} else if m.cursor == 1 {
			m.showTempInput = !m.showTempInput
			if m.showTempInput {
				m.tempInput = fmt.Sprintf("%.2f", m.defaultTemp)
			}
		} else if m.cursor == 2 {
			m.config.Defaults.Model = m.defaultModel
			m.config.Defaults.Provider = m.defaultProv
			m.config.Defaults.Temperature = m.defaultTemp
			m.state = stateAllSamePrompt
			m.cursor = 0
		}
	case "up", "k":
		if m.cursor > 0 {
			m.cursor--
		}
	case "down", "j":
		if m.cursor < 2 {
			m.cursor++
		}
	case "esc":
		m.state = stateAllSamePrompt
		m.cursor = 0
	case "backspace":
		if m.showTempInput && len(m.tempInput) > 0 {
			m.tempInput = m.tempInput[:len(m.tempInput)-1]
		}
	default:
		if m.showTempInput {
			ch := msg.String()
			if ch >= "0" && ch <= "9" || ch == "." {
				m.tempInput += ch
			}
			if val, err := strconv.ParseFloat(m.tempInput, 64); err == nil {
				if val >= 0 && val <= 2 {
					m.defaultTemp = val
				}
			}
		}
	}
	return m, nil
}

// --- Per-Agent List ---

func (m *model) handlePerAgentKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "enter", " ":
		if m.cursor >= 0 && m.cursor < len(m.agentRows) {
			row := m.agentRows[m.cursor]
			m.editAgentCode = row.Code
			m.currentModel = row.Model
			m.currentProv = row.Provider
			m.currentTemp = row.Temperature
			m.state = stateEditAgent
			m.cursor = 0
			m.showTempInput = false
		}
	case "up", "k":
		if m.cursor > 0 {
			m.cursor--
		}
	case "down", "j":
		if m.cursor < len(m.agentRows)-1 {
			m.cursor++
		}
	case "esc":
		if m.config.HasCustomBindings() {
			m.state = stateOverview
		} else {
			m.state = stateAllSamePrompt
		}
		m.cursor = 0
	case "s":
		m.state = stateSaving
		return m, m.saveConfig()
	}
	return m, nil
}

// --- Edit Agent ---

func (m *model) handleEditAgentKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "enter", " ":
		if m.cursor == 0 {
			m.state = stateModelPicker
		} else if m.cursor == 1 {
			m.state = stateTemperatureEdit
		} else if m.cursor == 2 {
			m.saveCurrentAgent()
			m.state = statePerAgentList
			m.agentRows = m.config.AllBindings()
			m.cursor = 0
		} else if m.cursor == 3 {
			binding, exists := m.config.Bindings[m.editAgentCode]
			if exists {
				binding.Model = ""
				binding.Provider = ""
				binding.Temperature = nil
			}
			m.state = statePerAgentList
			m.agentRows = m.config.AllBindings()
			m.cursor = 0
		}
	case "up", "k":
		if m.cursor > 0 {
			m.cursor--
		}
	case "down", "j":
		if m.cursor < 3 {
			m.cursor++
		}
	case "esc":
		m.state = statePerAgentList
		m.cursor = 0
	case "r":
		binding, exists := m.config.Bindings[m.editAgentCode]
		if exists {
			binding.Model = ""
			binding.Provider = ""
			binding.Temperature = nil
		}
		m.state = statePerAgentList
		m.agentRows = m.config.AllBindings()
		m.cursor = 0
	}
	return m, nil
}

func (m *model) saveCurrentAgent() {
	if _, exists := m.config.Bindings[m.editAgentCode]; !exists {
		m.config.Bindings[m.editAgentCode] = &AgentBinding{}
	}
	binding := m.config.Bindings[m.editAgentCode]
	binding.Model = m.currentModel
	binding.Provider = m.currentProv
	temp := NormalizeFloat64(m.currentTemp)
	binding.Temperature = &temp
}

// --- Model Picker ---

func (m *model) handleModelPickerKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	providers := m.cloud.ProviderList(m.config.Priority.Order)
	switch msg.String() {
	case "enter", " ":
		if m.cursor >= 0 && m.cursor < len(providers) {
			p := providers[m.cursor]
			m.currentProv = p.Code
			m.currentModel = p.DefaultModel
			m.state = stateEditAgent
			m.cursor = 0
		}
	case "up", "k":
		if m.cursor > 0 {
			m.cursor--
		}
	case "down", "j":
		if m.cursor < len(providers)-1 {
			m.cursor++
		}
	case "esc":
		m.state = stateEditAgent
		m.cursor = 0
	}
	return m, nil
}

// --- Temperature Edit ---

func (m *model) handleTemperatureKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "enter":
		m.state = stateEditAgent
		m.cursor = 0
		m.showTempInput = false
	case "up", "right":
		m.currentTemp = NormalizeFloat64(m.currentTemp + 0.05)
		if m.currentTemp > 2.0 {
			m.currentTemp = 2.0
		}
		m.tempInput = fmt.Sprintf("%.2f", m.currentTemp)
	case "down", "left":
		m.currentTemp = NormalizeFloat64(m.currentTemp - 0.05)
		if m.currentTemp < 0.0 {
			m.currentTemp = 0.0
		}
		m.tempInput = fmt.Sprintf("%.2f", m.currentTemp)
	case "esc":
		m.state = stateEditAgent
		m.cursor = 0
		m.showTempInput = false
	case "backspace":
		if len(m.tempInput) > 0 {
			m.tempInput = m.tempInput[:len(m.tempInput)-1]
		}
	default:
		ch := msg.String()
		if ch >= "0" && ch <= "9" || ch == "." {
			m.tempInput += ch
		}
		if val, err := strconv.ParseFloat(m.tempInput, 64); err == nil {
			if val >= 0 && val <= 2 {
				m.currentTemp = val
			}
		}
	}
	return m, nil
}

// --- Admin Auth ---

func (m *model) handleAdminAuthKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "enter", " ":
		if m.cursor == 0 {
			m.state = stateAdminPassword
			m.adminPassword = ""
			m.cursor = 0
		} else if m.cursor == 1 {
			m.state = stateOverview
			m.cursor = 0
		}
	case "up", "k":
		if m.cursor > 0 {
			m.cursor--
		}
	case "down", "j":
		if m.cursor < 1 {
			m.cursor++
		}
	case "esc":
		m.state = stateOverview
		m.cursor = 0
	}
	return m, nil
}

func (m *model) handleAdminPasswordKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "enter":
		keyPath := m.adminPassword
		if keyPath == "" {
			keyPath = m.repoRoot + string(os.PathSeparator) + "keys" + string(os.PathSeparator) + "master.key"
		}
		if VerifyAdminPassword(m.config.Admin.PasswordHash, keyPath) {
			m.adminAuthed = true
			WriteAuditEntry("admin.auth.tui", "Admin authenticated via TUI", "success")
			m.state = stateOverview
			m.statusMsg = "Admin authenticated"
			m.cursor = 0
		} else {
			m.statusMsg = "Invalid admin credentials"
			m.state = stateAdminAuth
			m.cursor = 0
		}
	case "esc":
		m.state = stateAdminAuth
		m.cursor = 0
	case "backspace":
		if len(m.adminPassword) > 0 {
			m.adminPassword = m.adminPassword[:len(m.adminPassword)-1]
		}
	default:
		if len(msg.String()) == 1 {
			m.adminPassword += msg.String()
		}
	}
	return m, nil
}

// --- Save ---

func (m *model) saveConfig() tea.Cmd {
	return func() tea.Msg {
		err := SaveRouterConfig(m.configPath, m.config)
		if err == nil {
			WriteAuditEntry("config.saved.tui", "Config saved via TUI", "success")
		}
		return savedMsg{err: err}
	}
}

// ============================================================================
// VIEWS
// ============================================================================

func (m model) View() string {
	if !m.ready {
		return "Loading..."
	}
	switch m.state {
	case stateLoading:
		return m.viewLoading()
	case stateOverview:
		return m.viewOverview()
	case stateAllSamePrompt:
		return m.viewAllSamePrompt()
	case stateChangeDefaults:
		return m.viewChangeDefaults()
	case statePerAgentList:
		return m.viewPerAgentList()
	case stateEditAgent:
		return m.viewEditAgent()
	case stateModelPicker:
		return m.viewModelPicker()
	case stateTemperatureEdit:
		return m.viewTemperatureEdit()
	case stateAdminAuth:
		return m.viewAdminAuth()
	case stateAdminPassword:
		return m.viewAdminPassword()
	case stateSaving:
		return m.viewSaving()
	case stateDone:
		return m.viewDone()
	}
	return "Unknown state"
}

func (m model) viewLoading() string {
	return lipgloss.JoinVertical(lipgloss.Center,
		titleStyle.Render("Model Router v2.0"),
		"",
		"Loading configuration...",
	)
}

func (m model) viewOverview() string {
	title := titleStyle.Render("Model Router — Agent Routing Overview")
	header := headerStyle.Render(fmt.Sprintf("%-6s %-22s %-14s %-10s %s", "AGENT", "MODEL", "PROVIDER", "TEMP", "SOURCE"))
	sep := strings.Repeat("─", m.width-2)
	if sep == "" || sep == "─" {
		sep = strings.Repeat("─", 60)
	}

	var rows []string
	for _, row := range m.agentRows {
		sty := defaultStyle
		if row.Source == "override" {
			sty = overrideStyle
		}
		line := sty.Render(fmt.Sprintf("%-6s %-22s %-14s %-10.2f %s",
			row.Code, row.Model, row.Provider, row.Temperature, row.Source))
		rows = append(rows, "  "+line)
	}

	actions := []string{
		"Change Default Model for All Agents",
		"Configure Per-Agent",
		"Admin Settings",
		"Save & Exit",
	}

	var actionLines []string
	for i, a := range actions {
		prefix := "  "
		if m.cursor == i {
			prefix = "> "
			actionLines = append(actionLines, selectedStyle.Render(prefix+a))
		} else {
			actionLines = append(actionLines, defaultStyle.Render(prefix+a))
		}
	}

	statusLine := ""
	if m.statusMsg != "" {
		statusLine = "\n" + subtleStyle.Render(m.statusMsg)
	}

	helpLine := helpStyle.Render("\n↑/↓ navigate • Enter select • a admin • q quit")

	return lipgloss.JoinVertical(lipgloss.Left,
		title,
		"",
		header,
		sep,
		lipgloss.JoinVertical(lipgloss.Left, rows...),
		"",
		sep,
		lipgloss.JoinVertical(lipgloss.Left, actionLines...),
		statusLine,
		helpLine,
	)
}

func (m model) viewAllSamePrompt() string {
	title := titleStyle.Render("Model Router — Initial Configuration")
	defaults := fmt.Sprintf("Default model: %s (%s) — Temperature: %.2f",
		m.defaultModel, m.defaultProv, m.defaultTemp)

	return lipgloss.JoinVertical(lipgloss.Left,
		title,
		"",
		defaults,
		"",
		labelStyle.Render("¿Desea que todos los agentes usen el mismo modelo de IA?"),
		"",
		"  [Y] Yes — Use defaults for all agents",
		"  [N] No  — Configure per-agent",
		"  [C]     — Change default model/temperature first",
		"  [Q]     — Quit without saving",
		"",
		helpStyle.Render("Press a key to select"),
	)
}

func (m model) viewChangeDefaults() string {
	title := titleStyle.Render("Model Router — Default Configuration")

	lines := []string{title, ""}

	items := []struct {
		label string
		value string
	}{
		{"Provider", m.defaultProv},
		{"Temperature", fmt.Sprintf("%.2f", m.defaultTemp)},
		{"Apply & Back", ""},
	}

	for i, item := range items {
		prefix := "  "
		if m.cursor == i {
			prefix = "> "
		}
		line := prefix + item.label + ": "
		if m.cursor == i {
			line += selectedStyle.Render(item.value)
		} else {
			line += valueStyle.Render(item.value)
		}
		lines = append(lines, line)
	}

	if m.cursor == 1 && m.showTempInput {
		lines = append(lines, "", subtleStyle.Render("   Type temperature (0-2), then Enter"))
	}

	lines = append(lines, "", helpStyle.Render("↑/↓ navigate • Enter toggle/select • Esc back"))

	return lipgloss.JoinVertical(lipgloss.Left, lines...)
}

func (m model) viewPerAgentList() string {
	title := titleStyle.Render("Model Router — Per-Agent Configuration")
	header := headerStyle.Render(fmt.Sprintf("%-6s %-22s %-14s %-10s %s", "AGENT", "MODEL", "PROVIDER", "TEMP", "SOURCE"))
	sep := strings.Repeat("─", m.width-2)
	if sep == "" || sep == "─" {
		sep = strings.Repeat("─", 60)
	}

	var rows []string
	for i, row := range m.agentRows {
		pfx := "  "
		if m.cursor == i {
			pfx = "> "
		}
		sty := defaultStyle
		if row.Source == "override" {
			sty = overrideStyle
		}
		line := sty.Render(fmt.Sprintf("%-6s %-22s %-14s %-10.2f %s",
			row.Code, row.Model, row.Provider, row.Temperature, row.Source))
		if m.cursor == i {
			rows = append(rows, selectedStyle.Render(pfx+line))
		} else {
			rows = append(rows, defaultStyle.Render(pfx+line))
		}
	}

	helpLine := helpStyle.Render("\n↑/↓ navigate • Enter edit • s save & exit • Esc back")

	return lipgloss.JoinVertical(lipgloss.Left,
		title,
		"",
		header,
		sep,
		lipgloss.JoinVertical(lipgloss.Left, rows...),
		helpLine,
	)
}

func (m model) viewEditAgent() string {
	name := AgentNames[m.editAgentCode]
	if name == "" {
		name = m.editAgentCode
	}
	title := titleStyle.Render(fmt.Sprintf("Editing: %s (%s)", m.editAgentCode, name))
	status := labelStyle.Render("Status: ") + valueStyle.Render(
		fmt.Sprintf("%s (%s) — %.2f°", m.currentModel, m.currentProv, m.currentTemp))

	items := []string{
		fmt.Sprintf("Change Model/Provider     [%s / %s]", m.currentProv, m.currentModel),
		fmt.Sprintf("Temperature               %.2f", m.currentTemp),
		"Apply Changes & Back",
		"Reset to Defaults",
	}

	var lines []string
	lines = append(lines, title, "", status, "")
	for i, item := range items {
		if m.cursor == i {
			lines = append(lines, selectedStyle.Render("> "+item))
		} else {
			lines = append(lines, defaultStyle.Render("  "+item))
		}
	}

	lines = append(lines, "", helpStyle.Render("↑/↓ navigate • Enter select • r reset • Esc back"))

	return lipgloss.JoinVertical(lipgloss.Left, lines...)
}

func (m model) viewModelPicker() string {
	providers := m.cloud.ProviderList(m.config.Priority.Order)
	title := titleStyle.Render("Select Provider for " + m.editAgentCode)

	var lines []string
	lines = append(lines, title, "")

	for i, p := range providers {
		prefix := "  "
		if m.cursor == i {
			prefix = "> "
		}
		label := p.Label()
		selected := ""
		if p.Code == m.currentProv {
			selected = " [current]"
		}
		if m.cursor == i {
			lines = append(lines, selectedStyle.Render(prefix+label+selected))
		} else {
			lines = append(lines, defaultStyle.Render("  "+label+selected))
		}
	}

	lines = append(lines, "", helpStyle.Render("↑/↓ navigate • Enter select • Esc back"))

	return lipgloss.JoinVertical(lipgloss.Left, lines...)
}

func (m model) viewTemperatureEdit() string {
	title := titleStyle.Render(fmt.Sprintf("Temperature — %s", m.editAgentCode))

	barLen := 30
	filled := int((m.currentTemp / 2.0) * float64(barLen))
	if filled > barLen {
		filled = barLen
	}
	bar := strings.Repeat("█", filled) + strings.Repeat("░", barLen-filled)

	return lipgloss.JoinVertical(lipgloss.Left,
		title,
		"",
		labelStyle.Render(fmt.Sprintf("Temperature: %.2f", m.currentTemp)),
		"",
		"  ["+bar+"]",
		"",
		subtleStyle.Render("  ← → or ↓ ↑ adjust by 0.05"),
		subtleStyle.Render("  Type a number to set precisely"),
		"",
		helpStyle.Render("Enter confirm • Esc back"),
	)
}

func (m model) viewAdminAuth() string {
	title := titleStyle.Render("Admin Authentication")
	fp := GetPcFingerprint()

	return lipgloss.JoinVertical(lipgloss.Left,
		title,
		"",
		subtleStyle.Render("PC Fingerprint: "+fp),
		"",
		labelStyle.Render("This PC is not registered as trusted."),
		labelStyle.Render("Admin authentication is required to modify configuration."),
		"",
		"> "+selectedStyle.Render("Enter Admin Password / Key File Path")+"  ",
		"  Cancel and return",
		"",
		helpStyle.Render("↑/↓ navigate • Enter select • Esc back"),
	)
}

func (m model) viewAdminPassword() string {
	title := titleStyle.Render("Admin Authentication")
	masked := strings.Repeat("*", len(m.adminPassword))
	if masked == "" {
		masked = "(empty — will use keys/master.key)"
	}

	return lipgloss.JoinVertical(lipgloss.Left,
		title,
		"",
		labelStyle.Render("Enter master.key path or admin password:"),
		"",
		"  "+valueStyle.Render(masked),
		"",
		subtleStyle.Render("  Default: <repo>/keys/master.key"),
		subtleStyle.Render("  Type the full path to use a different key file."),
		"",
		helpStyle.Render("Enter to submit • Esc back"),
	)
}

func (m model) viewSaving() string {
	return lipgloss.JoinVertical(lipgloss.Center,
		titleStyle.Render("Model Router"),
		"",
		"Saving configuration...",
	)
}

func (m model) viewDone() string {
	if m.err != nil {
		return lipgloss.JoinVertical(lipgloss.Center,
			errorStyle.Render("Error: "+m.err.Error()),
		)
	}
	if m.statusMsg != "" {
		return lipgloss.JoinVertical(lipgloss.Left,
			successStyle.Render(m.statusMsg),
		)
	}
	return "Model Router — done."
}

// ============================================================================
// MAIN
// ============================================================================

func main() {
	configPath := flag.String("config", "", "Path to model-router.json")
	flag.Parse()

	repoRoot := FindRepoRoot()
	path := *configPath
	if path == "" {
		path = repoRoot + string(os.PathSeparator) + "config" + string(os.PathSeparator) + "model-router.json"
	}

	if _, err := os.Stat(path); os.IsNotExist(err) {
		fmt.Println("Model router config not found. Run 'gv.ps1 route defaults --init' first.")
		fmt.Println("Expected path:", path)
		os.Exit(1)
	}

	p := tea.NewProgram(initialModel(path), tea.WithAltScreen())
	m, err := p.Run()
	if err != nil {
		fmt.Println("Error running TUI:", err)
		os.Exit(1)
	}

	finalModel := m.(model)
	if finalModel.err != nil {
		fmt.Println(finalModel.err)
		os.Exit(1)
	}
	if finalModel.statusMsg != "" {
		fmt.Println(finalModel.statusMsg)
	}
}

