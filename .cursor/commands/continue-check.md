Run Continue.dev checks from Cursor on the current changes.

1. List available checks: `Get-ChildItem .continue/checks/ -Name`
2. For each check file:
   - Read the check: `Get-Content ".continue/checks/<check>.md" -Raw`
   - Run the check logic: review the diff, use grep/gh as needed
   - Report findings for each check
3. Summarize: pass/fail per check, list any issues found
