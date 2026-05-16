param(
    [ValidateSet('send', 'poll', 'ack', 'list-conversations', 'list-mailbox', 'purge', 'status')]
    [string]$Action = 'status',
    [string]$Sender = '',
    [string]$Recipient = '',
    [string]$Subject = '',
    [string]$Payload = '',
    [string]$ConversationId = '',
    [string]$CorrelationId = '',
    [string]$MessageId = '',
    [ValidateSet('request', 'response', 'broadcast', 'event')]
    [string]$MessageType = 'request',
    [ValidateSet('normal', 'high', 'low')]
    [string]$Priority = 'normal',
    [int]$TtlSeconds = 300,
    [int]$Limit = 20,
    [switch]$AsJson,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
$mailboxDir = Join-Path $repoRoot '.event-bus\agent-mailboxes'

function Initialize-MailboxDir {
    if (-not (Test-Path $mailboxDir)) {
        New-Item -ItemType Directory -Path $mailboxDir -Force | Out-Null
    }
}

function Get-MessageId {
    "msg-$(Get-Date -Format 'yyyyMMdd-HHmmssfff')-$([System.IO.Path]::GetRandomFileName().Substring(0,8))"
}

function Get-ConversationId {
    param([string]$Prefix = 'conv')
    "$Prefix-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$([System.IO.Path]::GetRandomFileName().Substring(0,6))"
}

function Get-MailboxPath {
    param([string]$Agent)
    Join-Path $mailboxDir "mailbox-$Agent.json"
}

function Read-Mailbox {
    param([string]$Agent)
    $path = Get-MailboxPath -Agent $Agent
    if (Test-Path $path) {
        try { return Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json } catch { }
    }
    return @{ agent = $Agent; messages = @(); lastPoll = $null }
}

function Write-Mailbox {
    param([string]$Agent, [object]$Data)
    $path = Get-MailboxPath -Agent $Agent
    $Data | ConvertTo-Json -Depth 10 | Set-Content $path -Encoding UTF8 -Force
}

function New-Message {
    param(
        [string]$Type,
        [string]$From,
        [string]$To,
        [string]$ConvId,
        [string]$CorrId,
        [string]$MsgSubject,
        [string]$MsgPayload,
        [string]$MsgPriority,
        [int]$MsgTtl
    )
    $id = Get-MessageId
    $now = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
    $exp = if ($MsgTtl -gt 0) { (Get-Date).AddSeconds($MsgTtl).ToString('yyyy-MM-ddTHH:mm:ssK') } else { $null }
    @{
        id = $id
        type = $Type
        sender = $From
        recipient = $To
        conversation_id = $ConvId
        correlation_id = $CorrId
        subject = $MsgSubject
        payload = if ($MsgPayload) { try { $MsgPayload | ConvertFrom-Json } catch { $MsgPayload } } else { $null }
        timestamp = $now
        expires_at = $exp
        priority = $MsgPriority
        ack = $false
    }
}

function Remove-Expired {
    param([object]$Mailbox)
    $now = Get-Date
    $active = @()
    foreach ($m in $Mailbox.messages) {
        if ($m.expires_at) {
            try { if ([datetime]::Parse($m.expires_at) -lt $now) { continue } } catch { }
        }
        $active += $m
    }
    $Mailbox.messages = $active
    $Mailbox
}

function Log-MessageEvent {
    param([string]$MsgId, [string]$From, [string]$To, [string]$Subject, [string]$Type)
    $logDir = Join-Path $repoRoot '.event-bus'
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $logFile = Join-Path $logDir 'agent-messages.jsonl'
    $entry = @{
        timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
        message_id = $MsgId
        sender = $From
        recipient = $To
        subject = $Subject
        type = $Type
    } | ConvertTo-Json -Compress
    Add-Content -Path $logFile -Value $entry -Encoding UTF8
}

function Write-AMsg {
    param([string]$M, [string]$C = 'White')
    if (-not $Quiet) { Write-Host $M -ForegroundColor $C }
}

Initialize-MailboxDir

switch ($Action) {
    'send' {
        if (-not $Sender -or -not $Recipient) {
            if ($AsJson) { return (@{ error = 'Sender and Recipient required' } | ConvertTo-Json) }
            Write-AMsg '[ERROR] Sender and Recipient required' 'Red'; exit 1
        }
        $convId = if ($ConversationId) { $ConversationId } else { Get-ConversationId }
        $msg = New-Message -Type $MessageType -From $Sender -To $Recipient -ConvId $convId -CorrId $CorrelationId -MsgSubject $Subject -MsgPayload $Payload -MsgPriority $Priority -MsgTtl $TtlSeconds

        $mb = Read-Mailbox -Agent $Recipient
        $mb = Remove-Expired -Mailbox $mb
        $mb.messages = @($mb.messages) + @($msg)
        $mb.lastUpdated = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
        Write-Mailbox -Agent $Recipient -Data $mb

        Log-MessageEvent -MsgId $msg.id -From $Sender -To $Recipient -Subject $Subject -Type $MessageType
        Write-AMsg "[MSG] $($msg.id) $Sender->$Recipient [$MessageType] $Subject" 'Green'

        if ($AsJson) {
            return ($msg | ConvertTo-Json -Depth 5)
        }
    }

    'poll' {
        if (-not $Recipient) {
            if ($AsJson) { return (@{ error = 'Recipient required' } | ConvertTo-Json) }
            Write-AMsg '[ERROR] Recipient required' 'Red'; exit 1
        }
        $mb = Read-Mailbox -Agent $Recipient
        $mb = Remove-Expired -Mailbox $mb
        $mb.lastPoll = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'

        $results = @($mb.messages | Where-Object { -not $_.ack })
        if ($ConversationId) { $results = @($results | Where-Object { $_.conversation_id -eq $ConversationId }) }
        if ($Subject) { $results = @($results | Where-Object { $_.subject -eq $Subject }) }
        if ($Sender) { $results = @($results | Where-Object { $_.sender -eq $Sender }) }

        $results = $results | Sort-Object { @{high=0;normal=1;low=2}[$_.priority] }, timestamp
        if ($results.Count -gt $Limit) { $results = $results[0..($Limit-1)] }

        Write-Mailbox -Agent $Recipient -Data $mb
        Write-AMsg "[POLL] ${Recipient}: $($results.Count) unread messages" 'Cyan'

        if ($AsJson) {
            return (@{ agent = $Recipient; count = $results.Count; messages = $results } | ConvertTo-Json -Depth 5)
        }
        if ($results.Count -eq 0) { return }
        foreach ($m in $results) {
            $color = if ($m.priority -eq 'high') { 'Yellow' } elseif ($m.priority -eq 'low') { 'Gray' } else { 'White' }
            Write-Host "  [$($m.priority)] $($m.id) $($m.sender) [$($m.type)] $($m.subject)" -ForegroundColor $color
        }
    }

    'ack' {
        if (-not $MessageId -or -not $Recipient) {
            if ($AsJson) { return (@{ error = 'MessageId and Recipient required' } | ConvertTo-Json) }
            Write-AMsg '[ERROR] MessageId and Recipient required' 'Red'; exit 1
        }
        $mb = Read-Mailbox -Agent $Recipient
        $mb = Remove-Expired -Mailbox $mb
        $found = $false
        for ($i = 0; $i -lt $mb.messages.Count; $i++) {
            if ($mb.messages[$i].id -eq $MessageId) {
                $mb.messages[$i].ack = $true
                $mb.messages[$i].ackedAt = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
                $found = $true
                break
            }
        }
        if ($found) {
            Write-Mailbox -Agent $Recipient -Data $mb
            Write-AMsg "[ACK] $MessageId acknowledged" 'Green'
            if ($AsJson) { return (@{ status = 'acknowledged'; message_id = $MessageId } | ConvertTo-Json) }
        } else {
            Write-AMsg "[WARN] Message $MessageId not found in $Recipient mailbox" 'Yellow'
            if ($AsJson) { return (@{ status = 'not-found'; message_id = $MessageId } | ConvertTo-Json) }
        }
    }

    'list-conversations' {
        $mailboxes = @(Get-ChildItem -Path $mailboxDir -Filter 'mailbox-*.json' -ErrorAction SilentlyContinue)
        $convs = @{}
        foreach ($f in $mailboxes) {
            $mb = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($m in $mb.messages) {
                if ($m.conversation_id -and (-not $ConversationId -or $m.conversation_id -eq $ConversationId)) {
                    if (-not $convs[$m.conversation_id]) {
                        $convs[$m.conversation_id] = @{ conversation_id = $m.conversation_id; messages = @(); agents = @{} }
                    }
                    $convs[$m.conversation_id].messages += $m
                    $convs[$m.conversation_id].agents[$m.sender] = $true
                    if ($m.recipient) { $convs[$m.conversation_id].agents[$m.recipient] = $true }
                }
            }
        }
        if ($AsJson) {
            return (@{ conversations = @($convs.Values) } | ConvertTo-Json -Depth 5)
        }
        Write-AMsg "=== Conversations ($(@($convs.Keys).Count)) ===" 'Cyan'
        foreach ($cid in ($convs.Keys | Sort-Object)) {
            $c = $convs[$cid]
            $agents = @($c.agents.Keys) -join ','
            $count = $c.messages.Count
            $last = $c.messages[-1].timestamp
            Write-Host "  $cid" -ForegroundColor Green
            Write-Host "    Agents: $agents | Messages: $count | Last: $last" -ForegroundColor Gray
        }
    }

    'list-mailbox' {
        if (-not $Recipient) {
            $mailboxes = @(Get-ChildItem -Path $mailboxDir -Filter 'mailbox-*.json' -ErrorAction SilentlyContinue)
            Write-AMsg "=== Mailboxes ===" 'Cyan'
            foreach ($f in $mailboxes) {
                $mb = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
                $unread = @($mb.messages | Where-Object { -not $_.ack }).Count
                $total = $mb.messages.Count
                Write-Host "  $($mb.agent): $unread unread / $total total" -ForegroundColor $(if ($unread -gt 0) { 'Yellow' } else { 'Green' })
            }
            return
        }
        $mb = Read-Mailbox -Agent $Recipient
        $mb = Remove-Expired -Mailbox $mb
        if ($AsJson) {
            return ($mb | ConvertTo-Json -Depth 5)
        }
        Write-AMsg "=== Mailbox: $Recipient ($(@($mb.messages | Where-Object { -not $_.ack }).Count) unread) ===" 'Cyan'
        foreach ($m in $mb.messages) {
            $mark = if ($m.ack) { '[X]' } else { '[ ]' }
            $color = if ($m.priority -eq 'high') { 'Yellow' } elseif ($m.ack) { 'Gray' } else { 'White' }
            Write-Host "  $mark $($m.id) $($m.sender)->$($m.recipient) [$($m.type)] $($m.subject)" -ForegroundColor $color
        }
        Write-Mailbox -Agent $Recipient -Data $mb
    }

    'purge' {
        $target = if ($Recipient) { @(Get-MailboxPath -Agent $Recipient) } else { @(Get-ChildItem -Path $mailboxDir -Filter 'mailbox-*.json' | ForEach-Object { $_.FullName }) }
        $count = 0
        foreach ($p in $target) {
            if ($Recipient) {
                $mb = Read-Mailbox -Agent $Recipient
                $before = $mb.messages.Count
                if ($MessageId) {
                    $mb.messages = @($mb.messages | Where-Object { $_.id -ne $MessageId })
                } elseif ($ConversationId) {
                    $mb.messages = @($mb.messages | Where-Object { $_.conversation_id -ne $ConversationId })
                } elseif ($Subject) {
                    $mb.messages = @($mb.messages | Where-Object { $_.subject -ne $Subject })
                } else {
                    $mb.messages = @()
                }
                $removed = $before - $mb.messages.Count
                $count += $removed
                Write-Mailbox -Agent $Recipient -Data $mb
            } else {
                Remove-Item -Path $p -Force -ErrorAction SilentlyContinue
                $count++
            }
        }
        Write-AMsg "[PURGE] Removed $count items" 'Green'
        if ($AsJson) { return (@{ removed = $count } | ConvertTo-Json) }
    }

    'status' {
        $mailboxFiles = @(Get-ChildItem -Path $mailboxDir -Filter 'mailbox-*.json' -ErrorAction SilentlyContinue)
        $totalMessages = 0
        $unreadMessages = 0
        $agentMailboxes = @{}
        foreach ($f in $mailboxFiles) {
            $mb = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
            $unread = @($mb.messages | Where-Object { -not $_.ack }).Count
            $totalMessages += $mb.messages.Count
            $unreadMessages += $unread
            $agentMailboxes[$mb.agent] = @{ total = $mb.messages.Count; unread = $unread }
        }
        $logFile = Join-Path $repoRoot '.event-bus\agent-messages.jsonl'
        $totalLogged = if (Test-Path $logFile) { @(Get-Content $logFile -ErrorAction SilentlyContinue).Count } else { 0 }

        if ($AsJson) {
            return (@{
                mailboxes = $agentMailboxes
                agentCount = $mailboxFiles.Count
                totalMessages = $totalMessages
                unreadMessages = $unreadMessages
                totalLogged = $totalLogged
            } | ConvertTo-Json)
        }
        Write-AMsg "=== Agent Message Bus ===" 'Cyan'
        Write-Host "  Mailbox dir: $mailboxDir" -ForegroundColor Gray
        Write-Host "  Agents: $($mailboxFiles.Count)" -ForegroundColor White
        Write-Host "  Messages: $totalMessages total, $unreadMessages unread" -ForegroundColor $(if ($unreadMessages -gt 0) { 'Yellow' } else { 'Green' })
        Write-Host "  Logged: $totalLogged entries" -ForegroundColor Gray
    }
}
