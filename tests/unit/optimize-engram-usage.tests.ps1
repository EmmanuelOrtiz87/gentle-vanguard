Describe 'Optimize Engram Usage Timestamp Parsing' {
    BeforeAll {
        $script:root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $script:targetScript = Join-Path $script:root 'scripts/utilities/PERFORMANCE-OPTIMIZATION/optimize-engram-usage.ps1'
        $script:content = Get-Content $script:targetScript -Raw
        $script:functionStart = $script:content.IndexOf('function Parse-CacheTimestamp {')
        $script:functionEnd = $script:content.IndexOf('function Get-EngramMemory {')
        $script:bootstrap = $script:content.Substring($script:functionStart, $script:functionEnd - $script:functionStart)
    }

    It 'parses ISO 8601 cache timestamps' {
        $result = & ([scriptblock]::Create($script:bootstrap + @"

`$parsed = Parse-CacheTimestamp -Timestamp '2026-05-15T18:53:04.7388085-03:00'
if (`$null -ne `$parsed) {
    `$parsed.ToString('o')
}
"@))

        $result | Should Be '2026-05-15T18:53:04.7388085-03:00'
    }

    It 'parses legacy local cache timestamps' {
        $result = & ([scriptblock]::Create($script:bootstrap + @"

`$parsed = Parse-CacheTimestamp -Timestamp '05/15/2026 15:05:28'
if (`$null -ne `$parsed) {
    `$parsed.ToString('yyyy-MM-dd HH:mm:ss')
}
"@))

        $result | Should Be '2026-05-15 15:05:28'
    }

    It 'returns null for unsupported timestamp values' {
        $result = & ([scriptblock]::Create($script:bootstrap + @"

`$parsed = Parse-CacheTimestamp -Timestamp 'not-a-date'
if (`$null -eq `$parsed) {
    'null'
}
"@))

        $result | Should Be 'null'
    }
}