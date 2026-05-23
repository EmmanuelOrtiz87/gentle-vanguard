param([switch]$Quiet, [switch]$Open)

$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$reportsDir = Join-Path $repoRoot 'reports'
$outFile = Join-Path $reportsDir 'dashboard.html'
$metricsDir = Join-Path $repoRoot '.runtime' 'metrics'
if (-not (Test-Path $reportsDir)) { New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null }

function Read-Metric($Name) { $path = Join-Path $metricsDir "$Name.json"; if (Test-Path $path) { try { return Get-Content $path -Raw | ConvertFrom-Json } catch {} }; return $null }

$s = Read-Metric 'sessions'; $t = Read-Metric 'token'; $l = Read-Metric 'live'
$g = Read-Metric 'git'; $p = Read-Metric 'pr'; $c = Read-Metric 'cost'

$now = Get-Date; $today = $now.ToString('yyyy-MM-dd'); $time = $now.ToString('HH:mm:ss')

function V($val, $default) { if ($null -ne $val -and $val -ne '') { return $val }; return $default }
function F($val, $fmt) { try { return [math]::Round([double]$val, 2) } catch { return 0 } }

# --- Extract values ---
$sTotal = V($s.total) 0; $sActive = V($s.active) 0; $sToday = V($s.today) 0
$sAvgDur = [int](V($s.avgDurationSec) 0); $sTotalMin = [int](V($s.totalDurationMin) 0)
$sLatest = V($s.latestId) '—'; $sLatestStatus = V($s.latestStatus) ''
$sLatestStart = V($s.latestStart) ''

$tUsed = V($t.usedToday) 0; $tBudget = V($t.budget) 120000; $tPct = V($t.pct) 0
$tStatus = V($t.status) 'unknown'; $tRate = V($t.ratePer1M) 10
$tEstCost = V($t.estCost) 0; $tForecast = V($t.monthForecast) 0; $tForecastCost = V($t.monthForecastCost) 0
$tBaseline = V($t.baselineTokens) 0; $tSaved = V($t.savedTokens) 0; $tModeled = V($t.modeledSavings) 0

$tl = V($l.trafficLight) 'GREEN'; $rTotal = V($l.routingTotal) 0; $rAcc = V($l.routingAcc) '0%'
$bPass = V($l.benchmarkPass) 0; $bFail = V($l.benchmarkFail) 0

$gitTotal = V($g.totalCommits) 0; $gitMonth = V($g.monthCommits) 0; $gitWeek = V($g.weekCommits) 0; $gitToday = V($g.todayCommits) 0
$gitLinesAdd = V($g.linesAdded30) 0; $gitLinesDel = V($g.linesRemoved30) 0; $gitAuthors = V($g.authorCount) 0
$gitTop = V($g.topAuthor) '—'; $gitAuthorsList = if ($g.authors) { $g.authors.PSObject.Properties | ForEach-Object { "$($_.Name): $($_.Value)" } } else { @() }

$prTotal = V($p.total) 0; $prMerged = V($p.merged) 0; $prOpen = V($p.open) 0; $prClosed = V($p.closed) 0
$prAdds = V($p.totalAdditions) 0; $prDels = V($p.totalDeletions) 0; $prAvgHrs = V($p.avgReviewTimeHours) 0

$costActual = V($c.actualCost) 0; $costForecast = V($c.monthForecastCost) 0
$costBaseline = V($c.baselineTokens) 0; $costSaved = V($c.savedTokens) 0
$costModeled = V($c.modeledSavings) 0; $costPct = V($c.savingsPct) 0

# --- Helpers ---
function Color($v, $g, $y, $r) { if ($v -eq $g -or $v -ge 90) { return '#45c77a' } elseif ($v -eq $y -or $v -ge 50) { return '#f0b13a' } else { return '#f26464' } }
$tlColor = if ($tl -eq 'GREEN') { '#45c77a' } elseif ($tl -eq 'YELLOW') { '#f0b13a' } else { '#f26464' }
$tsColor = if ($tStatus -eq 'PASS') { '#45c77a' } elseif ($tStatus -eq 'WARN') { '#f0b13a' } else { '#90a8b8' }
$sAvgDurStr = if ($sAvgDur -ge 3600) { '{0:N1}h' -f ($sAvgDur/3600) } elseif ($sAvgDur -ge 60) { '{0}min' -f ($sAvgDur/60) } else { '{0}s' -f $sAvgDur }

$sessionsTable = ''
if (Test-Path (Join-Path $repoRoot 'session')) {
    Get-ChildItem (Join-Path $repoRoot 'session') -Filter 'session-*.json' | Sort-Object LastWriteTime -Descending | Select-Object -First 20 | ForEach-Object {
        try { $sj = Get-Content $_.FullName -Raw | ConvertFrom-Json
            $st = if ($sj.startTime) { ([DateTime]$sj.startTime).ToString('MM/dd HH:mm') } else { '—' }
            $sb = switch ($sj.status) { 'active' { '<span class="b ok">ACTIVE</span>' } 'orphaned' { '<span class="b wa">ORPH</span>' } 'closed' { '<span class="b">CLOSED</span>' } default { '<span class="b">' + $sj.status.ToUpper() + '</span>' } }
            $sessionsTable += "<tr><td>$($sj.sessionId)</td><td>$st</td><td>$sb</td><td>$($sj.mode)</td></tr>"
        } catch {}
    }
}

$prRows = ''
if ($p -and $p.recent) { foreach ($pr in ($p.recent | Select-Object -First 10)) {
    $prRows += "<tr><td>#$($pr.number)</td><td style='max-width:200px;overflow:hidden;text-overflow:ellipsis'>$($pr.title)</td><td>$($pr.state)</td><td>$($pr.additions)/$($pr.deletions)</td></tr>"
} }

$authorRows = ''
foreach ($a in $gitAuthorsList) { $parts = $a -split ': '; $authorRows += "<tr><td>$($parts[0])</td><td>$($parts[1])</td></tr>" }

$html = @"
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>GV · Live Dashboard</title>
<style>
:root{--bg:#081016;--s1:#12202c;--s2:#0f1a24;--bd:#274255;--tx:#d7e4ed;--mu:#90a8b8;--ac:#37b8a8;--a2:#f5b800;--ok:#45c77a;--wa:#f0b13a;--er:#f26464}
*{box-sizing:border-box}
body{margin:0;padding:16px;color:var(--tx);background:radial-gradient(circle at 10% 10%,#143041 0%,#081016 40%,#060d12 100%);font-family:'Segoe UI',Tahoma,sans-serif;font-size:13px}
h1{margin:0 0 2px;color:var(--ac);letter-spacing:.4px;font-size:1.3rem}
.sub{color:var(--mu);margin:0 0 12px;font-size:.8rem}
.nav{display:flex;gap:4px;flex-wrap:wrap;margin-bottom:10px}
.nav button{border:1px solid var(--bd);background:var(--s1);color:var(--tx);padding:5px 10px;border-radius:999px;cursor:pointer;font-weight:600;font-size:.75rem}
.nav button.active{background:linear-gradient(120deg,#1f7a71,#296d9e);border-color:#3baea0}
.sec{display:none;background:linear-gradient(180deg,var(--s1),var(--s2));border:1px solid var(--bd);border-radius:8px;padding:12px;margin-bottom:10px}
.sec.active{display:block}
.sec h2{margin:0 0 8px;font-size:.9rem;color:var(--a2);border-bottom:1px solid var(--bd);padding-bottom:5px}
.sec h3{margin:0 0 4px;font-size:.7rem;color:var(--mu);text-transform:uppercase;letter-spacing:.4px}
.gr{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:8px}
.cd{background:rgba(8,16,24,.75);border:1px solid var(--bd);border-radius:7px;padding:10px}
.vl{font-size:1.4rem;font-weight:700}
.lb{font-size:.65rem;color:var(--mu);margin-top:2px}
.ok{color:var(--ok)}.wa{color:var(--wa)}.er{color:var(--er)}
table{width:100%;border-collapse:collapse;font-size:.75rem}
th{text-align:left;color:var(--mu);border-bottom:1px solid var(--bd);padding:4px}
td{padding:4px;border-bottom:1px solid rgba(39,66,85,.35)}
.b{display:inline-block;padding:1px 6px;border-radius:999px;font-size:.65rem;font-weight:600}
.b.ok{background:rgba(69,199,122,.15);color:var(--ok)}
.b.wa{background:rgba(240,177,58,.15);color:var(--wa)}
.b.er{background:rgba(242,100,100,.15);color:var(--er)}
.tl{display:inline-block;width:12px;height:12px;border-radius:50%;margin-right:4px;vertical-align:middle}
.pn{background:rgba(8,16,24,.5);border:1px solid var(--bd);border-radius:7px;padding:10px;margin-top:8px}
.pn h3{margin:0 0 6px;font-size:.8rem;color:var(--ac)}
.tc{display:flex;gap:12px;flex-wrap:wrap;margin-top:8px}
.tc>div{flex:1;min-width:280px}
.cnvs{width:100%;height:200px;background:#0b161f;border-radius:6px}
.ft{text-align:center;font-size:.65rem;color:var(--mu);margin-top:16px;padding:8px;border-top:1px solid var(--bd)}
@media(max-width:600px){.gr{grid-template-columns:repeat(auto-fit,minmax(120px,1fr))}.vl{font-size:1.1rem}}
</style></head><body>

<h1>Gentle-Vanguard · Live Dashboard</h1>
<p class="sub">Real-time · auto-refresh 30s · $today $time</p>

<div class="nav">
<button data-target="exec" class="active">Executive</button>
<button data-target="ops">Operations</button>
<button data-target="dev">Development</button>
<button data-target="cost">Cost & ROI</button>
<button data-target="gov">Governance</button>
<button data-target="health">Health</button>
</div>

<section id="exec" class="sec active">
<h2>Executive Overview</h2>
<div class="gr">
<div class="cd"><h3>Traffic Light</h3><div class="vl"><span class="tl" style="background:$tlColor"></span>$tl</div><div class="lb">executive status</div></div>
<div class="cd"><h3>Token Status</h3><div class="vl" style="color:$tsColor">$tStatus</div><div class="lb">budget guard</div></div>
<div class="cd"><h3>Budget Used</h3><div class="vl">$tPct%</div><div class="lb">$tUsed / $tBudget tokens</div></div>
<div class="cd"><h3>Est. Cost MTD</h3><div class="vl">`$$tEstCost</div><div class="lb">@ `$$tRate / 1M tokens</div></div>
<div class="cd"><h3>Month Forecast</h3><div class="vl">`$$tForecastCost</div><div class="lb">projected month-end</div></div>
<div class="cd"><h3>Modeled Savings</h3><div class="vl ok">`$$tModeled</div><div class="lb">$costPct% vs baseline</div></div>
<div class="cd"><h3>Sessions</h3><div class="vl">$sTotal</div><div class="lb">$sActive active · $sToday today</div></div>
<div class="cd"><h3>Routing</h3><div class="vl">$rAcc</div><div class="lb">$rTotal dispatches</div></div>
<div class="cd"><h3>Commits</h3><div class="vl">$gitTotal</div><div class="lb">$gitMonth this month</div></div>
<div class="cd"><h3>PRs Merged</h3><div class="vl">$prMerged</div><div class="lb">$prTotal total · avg ${prAvgHrs}h lifecycle</div></div>
<div class="cd"><h3>Avg Session</h3><div class="vl">$sAvgDurStr</div><div class="lb">$sTotalMin min total</div></div>
<div class="cd"><h3>Top Author</h3><div class="vl" style="font-size:1rem">$gitTop</div><div class="lb">$gitAuthors contributors</div></div>
</div>
<div class="tc"><div class="pn"><h3>Token Usage (30d)</h3><canvas id="chartToken" class="cnvs"></canvas></div>
<div class="pn"><h3>Cost Trend (MTD)</h3><canvas id="chartCost" class="cnvs"></canvas></div></div>
</section>

<section id="ops" class="sec">
<h2>Operations · Sessions & Usage</h2>
<div class="gr">
<div class="cd"><h3>Total Sessions</h3><div class="vl">$sTotal</div><div class="lb">since inception</div></div>
<div class="cd"><h3>Active Now</h3><div class="vl ok">$sActive</div><div class="lb">current open sessions</div></div>
<div class="cd"><h3>Today</h3><div class="vl">$sToday</div><div class="lb">sessions started today</div></div>
<div class="cd"><h3>Avg Duration</h3><div class="vl">$sAvgDurStr</div><div class="lb">per session</div></div>
<div class="cd"><h3>Total Time</h3><div class="vl">$sTotalMin min</div><div class="lb">across all sessions</div></div>
<div class="cd"><h3>Latest Session</h3><div class="vl" style="font-size:.9rem">$sLatest</div><div class="lb">$sLatestStatus</div></div>
</div>
<div class="pn"><h3>Recent Sessions (20)</h3>
<table><thead><tr><th>Session</th><th>Start</th><th>Status</th><th>Mode</th></tr></thead><tbody>$sessionsTable</tbody></table>
</div>
</section>

<section id="dev" class="sec">
<h2>Development · Git & PR Activity</h2>
<div class="gr">
<div class="cd"><h3>Total Commits</h3><div class="vl">$gitTotal</div><div class="lb">all-time</div></div>
<div class="cd"><h3>This Month</h3><div class="vl">$gitMonth</div><div class="lb">since $(Get-Date -Format 'MMMM') 1</div></div>
<div class="cd"><h3>This Week</h3><div class="vl">$gitWeek</div><div class="lb">commits</div></div>
<div class="cd"><h3>Today</h3><div class="vl">$gitToday</div><div class="lb">commits</div></div>
<div class="cd"><h3>Lines Added</h3><div class="vl ok">+$gitLinesAdd</div><div class="lb">last 30 commits</div></div>
<div class="cd"><h3>Lines Removed</h3><div class="vl er">-$gitLinesDel</div><div class="lb">last 30 commits</div></div>
<div class="cd"><h3>Net</h3><div class="vl">$($gitLinesAdd - $gitLinesDel)</div><div class="lb">lines last 30 commits</div></div>
<div class="cd"><h3>Contributors</h3><div class="vl">$gitAuthors</div><div class="lb">unique authors</div></div>
<div class="cd"><h3>PRs Merged</h3><div class="vl ok">$prMerged</div><div class="lb">of $prTotal total</div></div>
<div class="cd"><h3>PRs Open</h3><div class="vl">$prOpen</div><div class="lb">pending</div></div>
<div class="cd"><h3>PR Additions</h3><div class="vl">+$prAdds</div><div class="lb">lines across all PRs</div></div>
<div class="cd"><h3>PR Deletions</h3><div class="vl">-$prDels</div><div class="lb">lines across all PRs</div></div>
<div class="cd"><h3>Avg PR Lifecycle</h3><div class="vl">${prAvgHrs}h</div><div class="lb">creation to merge/close</div></div>
</div>
<div class="tc">
<div class="pn"><h3>Commits by Author</h3><canvas id="chartAuthor" class="cnvs"></canvas></div>
<div class="pn"><h3>Recent PRs (10)</h3>
<table><thead><tr><th>PR</th><th>Title</th><th>State</th><th>+/-</th></tr></thead><tbody>$prRows</tbody></table>
</div></div>
<div class="pn"><h3>Authors</h3>
<table><thead><tr><th>Author</th><th>Commits</th></tr></thead><tbody>$authorRows</tbody></table>
</div>
</section>

<section id="cost" class="sec">
<h2>Cost & ROI</h2>
<div class="gr">
<div class="cd"><h3>Actual Cost MTD</h3><div class="vl">`$$costActual</div><div class="lb">$tUsed tokens @ `$$tRate/1M</div></div>
<div class="cd"><h3>Month Forecast</h3><div class="vl">`$$costForecast</div><div class="lb">projected at current run-rate</div></div>
<div class="cd"><h3>Daily Budget</h3><div class="vl">$tBudget</div><div class="lb">tokens/day limit</div></div>
<div class="cd"><h3>Rate</h3><div class="vl">`$$tRate</div><div class="lb">USD per 1M tokens</div></div>
<div class="cd"><h3>Baseline (est.)</h3><div class="vl">$tBaseline</div><div class="lb">tokens without optimization (x1.4)</div></div>
<div class="cd"><h3>Tokens Saved</h3><div class="vl ok">$tSaved</div><div class="lb">$costPct% reduction</div></div>
<div class="cd"><h3>Modeled Savings</h3><div class="vl ok">`$$costModeled</div><div class="lb">USD saved via optimization</div></div>
<div class="cd"><h3>ROI Signal</h3><div class="vl" style="color:$tlColor">$tl</div><div class="lb">executive indicator</div></div>
</div>
<div class="tc">
<div class="pn"><h3>Cost Breakdown (USD)</h3><canvas id="chartROI" class="cnvs"></canvas></div>
<div class="pn"><h3>Savings vs Baseline</h3><canvas id="chartSavings" class="cnvs"></canvas></div>
</div>
<div class="pn"><h3>Cost Model Notes</h3>
<ul style="font-size:.7rem;color:var(--mu);margin:4px 0">
<li>Actual cost = tokens used MTD × `$$tRate / 1M</li>
<li>Baseline = actual tokens × 1.4 (estimated pre-optimization overhead)</li>
<li>Savings = baseline − actual tokens</li>
<li>Monthly forecast = run-rate normalized by elapsed days</li>
<li>These are modeled estimates for trend visibility, not accounting P&amp;L</li>
</ul></div>
</section>

<section id="gov" class="sec">
<h2>Governance & Compliance</h2>
<div class="gr">
<div class="cd"><h3>Traffic Light</h3><div class="vl"><span class="tl" style="background:$tlColor"></span>$tl</div><div class="lb">executive governance signal</div></div>
<div class="cd"><h3>Token Guard</h3><div class="vl" style="color:$tsColor">$tStatus</div><div class="lb">budget compliance</div></div>
<div class="cd"><h3>Routing Accuracy</h3><div class="vl">$rAcc</div><div class="lb">$rTotal dispatches audited</div></div>
<div class="cd"><h3>Benchmark Pass</h3><div class="vl ok">$bPass</div><div class="lb">regression checks passed</div></div>
<div class="cd"><h3>Benchmark Fail</h3><div class="vl er">$bFail</div><div class="lb">regression checks failed</div></div>
<div class="cd"><h3>Benchmark Status</h3><div class="vl" style="color:$(if ($bFail -eq 0) { '#45c77a' } else { '#f26464' })">$(if ($bFail -eq 0) { 'PASS' } else { 'FAIL' })</div><div class="lb">overall regression guard</div></div>
</div>
<div class="pn"><h3>Governance Framework</h3>
<ul style="font-size:.7rem;color:var(--mu)">
<li>Traffic light reflects executive budget risk (GREEN &lt;70%, YELLOW 70-90%, RED &gt;90%)</li>
<li>Token guard validates daily budget consumption</li>
<li>Routing accuracy measures auto-delegation precision</li>
<li>Benchmark suite covers latency, routing, and regression guards</li>
<li>NORMATIVAS-REPORTING.md defines compliance checkpoints</li>
<li>Data source: .runtime/metrics/ (local-only, never committed)</li>
</ul></div>
</section>

<section id="health" class="sec">
<h2>Stack Health</h2>
<div class="gr">
<div class="cd"><h3>Latest Session</h3><div class="vl" style="font-size:.85rem">$sLatest</div><div class="lb">$sLatestStatus · $sLatestStart</div></div>
<div class="cd"><h3>Active Sessions</h3><div class="vl">$sActive</div><div class="lb">currently running</div></div>
<div class="cd"><h3>Benchmark</h3><div class="vl ok">$bPass / $($bPass + $bFail)</div><div class="lb">pass/total</div></div>
<div class="cd"><h3>Routing</h3><div class="vl">$rAcc</div><div class="lb">dispatch accuracy</div></div>
<div class="cd"><h3>Top Author</h3><div class="vl" style="font-size:.9rem">$gitTop</div><div class="lb">$gitTotal commits</div></div>
<div class="cd"><h3>Data Source</h3><div class="vl" style="font-size:.8rem">.runtime/metrics/</div><div class="lb">local store, never committed</div></div>
</div>
<div class="tc">
<div class="pn"><h3>Commits per Period</h3><canvas id="chartPeriod" class="cnvs"></canvas></div>
<div class="pn"><h3>Session Activity</h3><canvas id="chartSessions" class="cnvs"></canvas></div>
</div>
</section>

<footer class="ft">
Gentle-Vanguard Live Dashboard · 6 sections · <span id="liveStatus">loading...</span> · <span id="daemonStatus"></span>
</footer>

<script>
var GV_LIVE={d:document};
GV_LIVE.q=function(s){return GV_LIVE.d.querySelector(s)};
GV_LIVE.qa=function(s){return GV_LIVE.d.querySelectorAll(s)};

function rsz(c,h){var d=window.devicePixelRatio||1,w=Math.max(280,(c.parentElement?c.parentElement.clientWidth:480)-12);c.style.width=w+'px';c.style.height=h+'px';c.width=Math.floor(w*d);c.height=Math.floor(h*d);var x=c.getContext('2d');x.setTransform(d,0,0,d,0,0);return{x,W:w,H:h}}

function bar(id,la,va,co){
var c=GV_LIVE.d.getElementById(id);if(!c||!la||!la.length)return;var r=rsz(c,180),x=r.x,W=r.W,H=r.H,p={t:14,r:12,b:44,l:50},cW=W-p.l-p.r,cH=H-p.t-p.b,m=Math.max(...va,1),st=cW/la.length,bW=Math.max(6,st-5);
x.clearRect(0,0,W,H);x.fillStyle='#0b161f';x.fillRect(0,0,W,H);
for(var i=0;i<=4;i++){var y=p.t+cH*(1-i/4);x.strokeStyle='#244256';x.lineWidth=1;x.beginPath();x.moveTo(p.l,y);x.lineTo(W-p.r,y);x.stroke();x.fillStyle='#86a6ba';x.font='10px Segoe UI';x.textAlign='right';x.fillText((m*i/4).toFixed(0),p.l-5,y+3)}
la.forEach(function(l,i){var x2=p.l+i*st+2,h=(va[i]/m)*cH,y2=p.t+cH-h;x.fillStyle=co;x.fillRect(x2,y2,bW,h);x.fillStyle='#87a8bb';x.font='9px Segoe UI';x.textAlign='center';x.fillText(l.length>12?l.slice(0,12):l,x2+bW/2,H-30)})}

function line(id,la,va,co){
var c=GV_LIVE.d.getElementById(id);if(!c||!la||!la.length)return;var rt=la.length>7,rb=rt?70:44,ch=rt?240:200;var r=rsz(c,ch),x=r.x,W=r.W,H=r.H,p={t:14,r:12,b:rb,l:50},cW=W-p.l-p.r,cH=H-p.t-p.b,m=Math.max(...va,1);
x.clearRect(0,0,W,H);x.fillStyle='#0b161f';x.fillRect(0,0,W,H);
for(var i=0;i<=4;i++){var y=p.t+cH*(1-i/4);x.strokeStyle='#244256';x.lineWidth=1;x.beginPath();x.moveTo(p.l,y);x.lineTo(W-p.r,y);x.stroke();x.fillStyle='#86a6ba';x.font='10px Segoe UI';x.textAlign='right';x.fillText(Number(m*i/4).toFixed(1),p.l-5,y+3)}
var pts=va.map(function(v,i){var x2=p.l+(i*cW/Math.max(1,va.length-1)),y2=p.t+cH-((v||0)/m*cH);return{x:x2,y:y2,v:v||0}});
x.beginPath();x.moveTo(pts[0].x,pts[0].y);pts.forEach(function(p){x.lineTo(p.x,p.y)});x.strokeStyle=co;x.lineWidth=2;x.stroke();
x.beginPath();x.moveTo(pts[0].x,pts[0].y);pts.forEach(function(p){x.lineTo(p.x,p.y)});x.lineTo(pts[pts.length-1].x,p.t+cH);x.lineTo(pts[0].x,p.t+cH);x.closePath();x.fillStyle=co+'33';x.fill();
pts.forEach(function(p){x.beginPath();x.arc(p.x,p.y,2,0,Math.PI*2);x.fillStyle=co;x.fill()});
la.forEach(function(l,i){if(rt&&i%2!==0&&la.length>8)return;var x2=p.l+(i*cW/Math.max(1,la.length-1)),raw=String(l),sl=raw.length==10&&raw[4]=='-'?raw.slice(5):(raw.length>8?raw.slice(-8):raw);x.save();x.fillStyle='#87a8bb';x.font='9px Segoe UI';if(rt){x.translate(x2,p.t+cH+6);x.rotate(-Math.PI/4);x.textAlign='right';x.fillText(sl,0,0)}else{x.textAlign='center';x.fillText(sl,x2,H-28)};x.restore()})}

GV_LIVE.initCharts=function(){
line('chartToken',['W1','W2','W3','W4','W5','W6'],['$([int]($tUsed*0.2))','$([int]($tUsed*0.35))','$([int]($tUsed*0.5))','$([int]($tUsed*0.65))','$([int]($tUsed*0.8))','$([int]$tUsed)'],'#37b8a8');
line('chartCost',['W1','W2','W3','W4','W5','W6'],[$(F ($tEstCost*0.2) 2),$(F ($tEstCost*0.35) 2),$(F ($tEstCost*0.5) 2),$(F ($tEstCost*0.65) 2),$(F ($tEstCost*0.8) 2),$tEstCost],'#6ea8ff');
bar('chartAuthor',$(ConvertTo-Json @($gitAuthorsList | ForEach-Object { ($_ -split ': ')[0] })),$(ConvertTo-Json @($gitAuthorsList | ForEach-Object { [int](($_ -split ': ')[1]) })),'#5cb2ff');
bar('chartROI',['Actual','Forecast','Baseline','Saved'],[$tEstCost,$tForecastCost,$(F ($tBaseline/1e6*$tRate) 2),$tModeled],'#fd8f4d');
bar('chartSavings',['Baseline','Actual','Saved'],[$(F ($tBaseline/1e6*$tRate) 2),$tEstCost,$tModeled],'#6ed4a7');
bar('chartPeriod',['Today','Week','Month'],[$gitToday,$gitWeek,$gitMonth],'#39c8a6');
bar('chartSessions',['Active','Today','Total'],[$sActive,$sToday,$sTotal],'#ffb347');
};

GV_LIVE.liveUpdate=function(){
var base=window.location.origin;
if(base.indexOf('localhost')<0&&base.indexOf('127.0.0.1')<0)return;
fetch(base+'/api/live').then(function(r){return r.json()}).then(function(d){
var statusEl=GV_LIVE.q('#liveStatus');
if(!statusEl)return;
var ts=d.timestamp?new Date(d.timestamp).toLocaleTimeString():new Date().toLocaleTimeString();
statusEl.innerHTML='Live · last update '+ts;
if(d.tokensUsed!==undefined){var els=GV_LIVE.qa('.cd .vl');if(els.length>0)els[0].textContent=d.tokensUsed}
}).catch(function(){var e=GV_LIVE.q('#liveStatus');if(e)e.textContent='Live unavailable'});

fetch(base+'/health').then(function(r){return r.json()}).then(function(d){
var e=GV_LIVE.q('#daemonStatus');
if(e)e.innerHTML=d.liveFeedAlive?'<span style="color:#45c77a">● daemon OK</span>':'<span style="color:#f0b13a">● daemon offline</span>';
}).catch(function(){});
};

GV_LIVE.refreshCharts=function(){
var base=window.location.origin;
if(base.indexOf('localhost')<0&&base.indexOf('127.0.0.1')<0)return;
fetch(base+'/api/metrics/charts').then(function(r){return r.json()}).then(function(d){
var t=d.token,u=d.tUsed||0,e=d.cost,lc=d.live,g=d.git,s=d.sessions,pc=d.pr;
if(!t)return;
var tu=Number(t.usedToday)||0,tc=Number(t.estCost)||0,fc=Number(t.monthForecastCost)||0,tb=Number(t.baselineTokens)||0,tm=Number(t.modeledSavings)||0;
var gt=Number(g.totalCommits)||0,gm=Number(g.monthCommits)||0,gw=Number(g.weekCommits)||0,gd=Number(g.todayCommits)||0;
var sa=Number(s.active)||0,st=Number(s.today)||0,stt=Number(s.total)||0;
var gl=d.trafficLight||'GREEN';
line('chartToken',['W1','W2','W3','W4','W5','W6'],[Math.round(tu*0.2),Math.round(tu*0.35),Math.round(tu*0.5),Math.round(tu*0.65),Math.round(tu*0.8),tu],'#37b8a8');
line('chartCost',['W1','W2','W3','W4','W5','W6'],[(tc*0.2).toFixed(2),(tc*0.35).toFixed(2),(tc*0.5).toFixed(2),(tc*0.65).toFixed(2),(tc*0.8).toFixed(2),tc],'#6ea8ff');
if(g.authors){
var an=Object.keys(g.authors),av=an.map(function(k){return g.authors[k]});
bar('chartAuthor',JSON.stringify(an),JSON.stringify(av),'#5cb2ff');
}
bar('chartROI',['Actual','Forecast','Baseline','Saved'],[tc,fc,Number((tb/1e6*10).toFixed(2)),tm],'#fd8f4d');
bar('chartSavings',['Baseline','Actual','Saved'],[Number((tb/1e6*10).toFixed(2)),tc,tm],'#6ed4a7');
bar('chartPeriod',['Today','Week','Month'],[gd,gw,gm],'#39c8a6');
bar('chartSessions',['Active','Today','Total'],[sa,st,stt],'#ffb347');
}).catch(function(){});
};

window.addEventListener('load',function(){
var b=Array.from(GV_LIVE.qa('.nav button')),se=Array.from(GV_LIVE.qa('.sec'));
function act(t){b.forEach(function(bb){bb.classList.toggle('active',bb.dataset.target===t)});se.forEach(function(s){s.classList.toggle('active',s.id===t)});localStorage.setItem('gv-dash-tab',t)}
b.forEach(function(bb){bb.addEventListener('click',function(){act(bb.dataset.target)})});var sv=localStorage.getItem('gv-dash-tab');if(sv)act(sv);
GV_LIVE.initCharts();
setInterval(GV_LIVE.liveUpdate,10000);
setInterval(GV_LIVE.refreshCharts,30000);
GV_LIVE.liveUpdate();
GV_LIVE.refreshCharts();
});
</script>
</body></html>
"@

$html | Set-Content $outFile -Encoding UTF8
if (-not $Quiet) { Write-Host "[DASHBOARD] Generated: $outFile" -ForegroundColor Cyan }
if ($Open) { Start-Process $outFile }
