[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$base = "http://localhost:5050/api"
$loginResp = Invoke-RestMethod -Uri "$base/auth/token" -Method Post -ContentType "application/x-www-form-urlencoded" -Body @{username="zwj";password="zwj12138"}
$token = $loginResp.access_token
$h = @{Authorization="Bearer $token"}

function Test-EP($name, $method, $url, $headers, $body) {
    try {
        $params = @{Uri=$url; Method=$method}
        if ($headers) { $params.Headers = $headers }
        if ($body) { $params.Body = $body; $params.ContentType = "application/json" }
        $resp = Invoke-RestMethod @params
        $json = $resp | ConvertTo-Json -Depth 4 -Compress
        if ($json.Length -gt 300) { $json = $json.Substring(0,300) + "..." }
        Write-Output "PASS: $name"
        Write-Output "  $json"
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        $msg = $_.ErrorDetails.Message
        if ($msg -and $msg.Length -gt 300) { $msg = $msg.Substring(0,300) + "..." }
        Write-Output "FAIL($code): $name"
        Write-Output "  $msg"
    }
}

$henan = [System.Web.HttpUtility]::UrlEncode("河南")
$physics = [System.Web.HttpUtility]::UrlEncode("物理")
$chem = [System.Web.HttpUtility]::UrlEncode("物理+化学")
$qinghua = [System.Web.HttpUtility]::UrlEncode("清华大学")
$cs = [System.Web.HttpUtility]::UrlEncode("计算机")

Test-EP "POST /zhiyuan/recommend" "POST" ($base + "/zhiyuan/recommend") $h '{"rank":50000,"province":"河南","subject_type":"物理"}'
Test-EP "POST /zhiyuan/plan" "POST" ($base + "/zhiyuan/plan") $h '{"score":580,"rank":50000,"province":"河南","subject_type":"物理","subject_combination":"物理+化学+生物"}'
Test-EP "GET /zhiyuan/rank" "GET" ($base + "/zhiyuan/rank?score=580&province=" + $henan + "&year=2024") $h
Test-EP "GET /zhiyuan/rules" "GET" ($base + "/zhiyuan/rules/" + $henan) $h
Test-EP "POST /zhiyuan/majors/compare" "POST" ($base + "/zhiyuan/majors/compare") $h '{"major_names":["计算机科学与技术","软件工程"]}'
Test-EP "GET /zhiyuan/subject-check" "GET" ($base + "/zhiyuan/subject-check?combination=" + $chem) $h
Test-EP "GET /zhiyuan/graph" "GET" ($base + "/zhiyuan/graph?start_entity=" + $qinghua + "&depth=1") $h
Test-EP "GET /zhiyuan/scores" "GET" ($base + "/zhiyuan/scores?province=" + $henan + "&year=2024") $h
Test-EP "GET /zhiyuan/admin/scores" "GET" ($base + "/zhiyuan/admin/scores?province=" + $henan + "&page=1&size=5") $h
Test-EP "GET /zhiyuan/admin/plans" "GET" ($base + "/zhiyuan/admin/plans?province=" + $henan) $h
Test-EP "GET /zhiyuan/admin/rules" "GET" ($base + "/zhiyuan/admin/rules") $h
Test-EP "GET /zhiyuan/admin/majors" "GET" ($base + "/zhiyuan/admin/majors?keyword=" + $cs + "&page=1&size=5") $h

Write-Output ""
Write-Output "=== ZHIYUAN TESTS DONE ==="
