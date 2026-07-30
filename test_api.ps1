$base = "http://localhost:5050/api"
$results = @()

function Test-Endpoint($name, $method, $url, $headers, $body) {
    try {
        $params = @{Uri=$url; Method=$method}
        if ($headers) { $params.Headers = $headers }
        if ($body) { $params.Body = $body; $params.ContentType = "application/json" }
        $resp = Invoke-RestMethod @params
        return @{name=$name; status="PASS"; detail=($resp | ConvertTo-Json -Depth 2 -Compress)}
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        return @{name=$name; status="FAIL($code)"; detail=$_.Exception.Message}
    }
}

# 1. AUTH: Login
$loginResp = Invoke-RestMethod -Uri "$base/auth/token" -Method Post -ContentType "application/x-www-form-urlencoded" -Body @{username="zwj";password="zwj12138"}
$token = $loginResp.access_token
$h = @{Authorization="Bearer $token"}
Write-Output "AUTH LOGIN: PASS (token len=$($token.Length))"

# 2. AUTH: Current User
$r = Test-Endpoint "AUTH /auth/me" "GET" "$base/auth/me" $h
Write-Output "$($r.status): $($r.name)"

# 3. SYSTEM: Health
$r = Test-Endpoint "SYSTEM /system/health" "GET" "$base/system/health" $null
Write-Output "$($r.status): $($r.name) - $($r.detail)"

# 4. SYSTEM: Config
$r = Test-Endpoint "SYSTEM /system/config" "GET" "$base/system/config" $h
Write-Output "$($r.status): $($r.name)"

# 5. ZHIYUAN: Universities list
$r = Test-Endpoint "ZHIYUAN /zhiyuan/universities" "GET" "$base/zhiyuan/universities?page=1&page_size=5" $h
Write-Output "$($r.status): $($r.name) - $($r.detail)"

# 6. ZHIYUAN: University detail
$r = Test-Endpoint "ZHIYUAN /zhiyuan/universities/1" "GET" "$base/zhiyuan/universities/1" $h
Write-Output "$($r.status): $($r.name) - $($r.detail)"

# 7. ZHIYUAN: Majors
$r = Test-Endpoint "ZHIYUAN /zhiyuan/majors" "GET" "$base/zhiyuan/majors?page=1&page_size=5" $h
Write-Output "$($r.status): $($r.name) - $($r.detail)"

# 8. ZHIYUAN: Provinces
$r = Test-Endpoint "ZHIYUAN /zhiyuan/provinces" "GET" "$base/zhiyuan/provinces" $h
Write-Output "$($r.status): $($r.name) - $($r.detail)"

# 9. ZHIYUAN: Scores
$r = Test-Endpoint "ZHIYUAN /zhiyuan/scores?province=河南&year=2024" "GET" "$base/zhiyuan/scores?province=`河南&year=2024" $h
Write-Output "$($r.status): $($r.name) - $($r.detail)"

# 10. ZHIYUAN: Score rank
$r = Test-Endpoint "ZHIYUAN /zhiyuan/score-rank?province=河南&year=2024&score=600" "GET" "$base/zhiyuan/score-rank?province=`河南&year=2024&score=600" $h
Write-Output "$($r.status): $($r.name) - $($r.detail)"

# 11. ZHIYUAN: Province rules
$r = Test-Endpoint "ZHIYUAN /zhiyuan/rules?province=河南" "GET" "$base/zhiyuan/rules?province=`河南" $h
Write-Output "$($r.status): $($r.name) - $($r.detail)"

# 12. ZHIYUAN: Enrollment plans
$r = Test-Endpoint "ZHIYUAN /zhiyuan/plans?province=河南&year=2024" "GET" "$base/zhiyuan/plans?province=`河南&year=2024" $h
Write-Output "$($r.status): $($r.name) - $($r.detail)"

# 13. DASHBOARD
$r = Test-Endpoint "DASHBOARD /dashboard" "GET" "$base/dashboard" $h
Write-Output "$($r.status): $($r.name) - $($r.detail)"

# 14. AGENTS list
$r = Test-Endpoint "AGENTS /agent" "GET" "$base/agent" $h
Write-Output "$($r.status): $($r.name) - $($r.detail)"

# 15. CHAT threads
$r = Test-Endpoint "CHAT /chat/threads" "GET" "$base/chat/threads" $h
Write-Output "$($r.status): $($r.name) - $($r.detail)"

# 16. WORKSPACE
$r = Test-Endpoint "WORKSPACE /workspace" "GET" "$base/workspace" $h
Write-Output "$($r.status): $($r.name) - $($r.detail)"

# 17. SKILLS
$r = Test-Endpoint "SKILLS /skills" "GET" "$base/skills" $h
Write-Output "$($r.status): $($r.name) - $($r.detail)"

# 18. MCP servers
$r = Test-Endpoint "MCP /system/mcp-servers" "GET" "$base/system/mcp-servers" $h
Write-Output "$($r.status): $($r.name) - $($r.detail)"

# 19. Model providers
$r = Test-Endpoint "MODELS /system/model-providers" "GET" "$base/system/model-providers" $h
Write-Output "$($r.status): $($r.name) - $($r.detail)"

# 20. Tools
$r = Test-Endpoint "TOOLS /system/tools" "GET" "$base/system/tools" $h
Write-Output "$($r.status): $($r.name) - $($r.detail)"

# 21. User config
$r = Test-Endpoint "USER /user/config" "GET" "$base/user/config" $h
Write-Output "$($r.status): $($r.name) - $($r.detail)"

# 22. Departments
$r = Test-Endpoint "DEPT /departments" "GET" "$base/departments" $h
Write-Output "$($r.status): $($r.name) - $($r.detail)"

# 23. Tasks
$r = Test-Endpoint "TASKS /tasks" "GET" "$base/tasks" $h
Write-Output "$($r.status): $($r.name) - $($r.detail)"

# 24. Knowledge bases
$r = Test-Endpoint "KB /knowledge/databases" "GET" "$base/knowledge/databases" $h
Write-Output "$($r.status): $($r.name) - $($r.detail)"

# 25. Graph
$r = Test-Endpoint "GRAPH /graph/nodes?page=1&page_size=5" "GET" "$base/graph/nodes?page=1&page_size=5" $h
Write-Output "$($r.status): $($r.name) - $($r.detail)"

Write-Output "`n=== DONE ==="
