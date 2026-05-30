function Invoke-Mcp {
  param([string]$Json)
  $tmp = [System.IO.Path]::GetTempFileName()
  try {
    Set-Content $tmp -Value $Json -NoNewline -Encoding Ascii
    return cmd /c "type $tmp | node dist/scripts/mcp/skill-server.js 2>nul"
  } finally {
    if (Test-Path $tmp) { Remove-Item $tmp -Force }
  }
}

function Parse-Mcp {
  param([string]$Raw, [string]$Expr)
  return $Raw | node -e "const d=[];process.stdin.on('data',c=>d.push(c));process.stdin.on('end',()=>{try{const r=JSON.parse(d.join(''));console.log($Expr)}catch(e){console.log('ERROR')}})"
}
