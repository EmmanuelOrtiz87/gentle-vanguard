BeforeAll {
  function global:Invoke-Mcp($Json) {
    return cmd /c "echo $Json 2>nul | node dist/scripts/mcp/skill-server.js"
  }
  function global:Parse-Mcp($Raw, $Expr) {
    if (-not $Raw) { return "NO_OUTPUT" }
    return $Raw | node -e "const d=[];process.stdin.on('data',c=>d.push(c));process.stdin.on('end',()=>{try{const r=JSON.parse(d.join(''));console.log($Expr)}catch(e){console.log('ERROR')}})"
  }
}

Describe "MCP Skill Server" {
  It "should be compiled" {
    "dist/scripts/mcp/skill-server.js" | Should -Exist
  }
  It "should respond to tools/list with 3 tools" {
    $raw = Invoke-Mcp '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
    [int](Parse-Mcp $raw "r.result?.tools?.length||0") | Should -Be 3
  }
  It "should have list_skills tool" {
    $raw = Invoke-Mcp '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
    Parse-Mcp $raw "(r.result?.tools||[]).map(t=>t.name).includes('list_skills')?'YES':'NO'" | Should -Be "YES"
  }
  It "should have search_skills tool" {
    $raw = Invoke-Mcp '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
    Parse-Mcp $raw "(r.result?.tools||[]).map(t=>t.name).includes('search_skills')?'YES':'NO'" | Should -Be "YES"
  }
  It "should have get_skill tool" {
    $raw = Invoke-Mcp '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
    Parse-Mcp $raw "(r.result?.tools||[]).map(t=>t.name).includes('get_skill')?'YES':'NO'" | Should -Be "YES"
  }
  It "should search skills by keyword" {
    $raw = Invoke-Mcp '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"search_skills","arguments":{"query":"mcp"}}}'
    Parse-Mcp $raw "(r.result?.content?.[0]?.text||'').toLowerCase().includes('mcp')?'YES':'NO'" | Should -Be "YES"
  }
  It "should get a specific skill" {
    $raw = Invoke-Mcp '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"get_skill","arguments":{"name":"sdd-lifecycle"}}}'
    Parse-Mcp $raw "r.result?.content?.[0]?.text?'YES':'NO'" | Should -Be "YES"
  }
  It "should list skills resource" {
    $raw = Invoke-Mcp '{"jsonrpc":"2.0","id":4,"method":"resources/read","params":{"uri":"skill://registry"}}'
    Parse-Mcp $raw "r.result?.contents?.[0]?.text?'YES':'NO'" | Should -Be "YES"
  }
}
