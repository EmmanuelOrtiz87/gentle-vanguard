### 2. Conflict Resolution

#### Newest-Wins Strategy

```powershell
function Resolve-Conflict-NewestWins {
    param([object]$FileA, [object]$FileB)

    $newerFile = if ($FileA.LastWriteTime -gt $FileB.LastWriteTime) {
        $FileA
    } else {
        $FileB
    }

    return @{
        Winner = $newerFile.FullName
        WinnerModified = $newerFile.LastWriteTime
        Strategy = "Newest-Wins"
    }
}
```

#### Manual Resolution

```powershell
function Resolve-Conflict-Manual {
    param([object]$FileA, [object]$FileB)

    Write-Host "Conflict detected:"
    Write-Host "File A: $($FileA.FullName) (Modified: $($FileA.LastWriteTime))"
    Write-Host "File B: $($FileB.FullName) (Modified: $($FileB.LastWriteTime))"
    Write-Host "Choose: [A]File A, [B]File B, [K]Keep both, [S]Skip"

    $choice = Read-Host "Your choice"

    return @{
        Choice = $choice
        Manual = $true
        Timestamp = Get-Date
    }
}
```

---

## References

See `references/patterns.md` for detailed patterns and code examples.
