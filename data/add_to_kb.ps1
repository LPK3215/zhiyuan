$token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzg2MDA1NjYwLCJpc3MiOiJ5dXhpLWtub3c6aW5zdGFuY2UtY2I3NzNlMGU4ZmQwYzQwZiIsImF1ZCI6Inl1eGkta25vdy1hcGkifQ.SQeSg7zWm_DUj3FLy2q652GZPCsB4ZTrsvf9EfpNsnc"
$kbId = "kb_y6ev6g7a37"

# Read upload results
$results = Get-Content "d:\Develop\SourceCode\agent-projects\zhiyuan\data\upload_results.json" -Raw -Encoding UTF8 | ConvertFrom-Json

# Build request body
$items = @()
$contentHashes = @{}
foreach ($r in $results) {
    $items += $r.minio_url
    $contentHashes[$r.minio_url] = $r.content_hash
}

$body = @{
    items = $items
    params = @{
        content_type = "file"
        auto_index = $true
        content_hashes = $contentHashes
    }
} | ConvertTo-Json -Depth 5

Write-Host "Adding $($items.Count) documents to KB $kbId with auto_index=true..."
Write-Host "Request body length: $($body.Length) chars"

# Write body to temp file to avoid command length issues
$bodyFile = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($bodyFile, $body, [System.Text.Encoding]::UTF8)

$tempFile = [System.IO.Path]::GetTempFileName()
$curlArgs = @(
    "-s", "-X", "POST",
    "http://localhost:5050/api/knowledge/databases/$kbId/documents",
    "-H", "Authorization: Bearer $token",
    "-H", "Content-Type: application/json",
    "-d", "@$bodyFile",
    "-o", $tempFile
)
& curl.exe @curlArgs

$responseStr = Get-Content $tempFile -Raw -Encoding UTF8
Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
Remove-Item $bodyFile -Force -ErrorAction SilentlyContinue

Write-Host "`n=== Response ==="
try {
    $resp = $responseStr | ConvertFrom-Json
    $resp | ConvertTo-Json -Depth 5
} catch {
    Write-Host $responseStr
}
