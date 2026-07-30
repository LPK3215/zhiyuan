$token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzg2MDA1NjYwLCJpc3MiOiJ5dXhpLWtub3c6aW5zdGFuY2UtY2I3NzNlMGU4ZmQwYzQwZiIsImF1ZCI6Inl1eGkta25vdy1hcGkifQ.SQeSg7zWm_DUj3FLy2q652GZPCsB4ZTrsvf9EfpNsnc"
$kbId = "kb_y6ev6g7a37"
$policiesDir = "d:\Develop\SourceCode\agent-projects\zhiyuan\data\policies"
$files = Get-ChildItem -Path $policiesDir -Filter "*.md"
$results = @()

foreach ($f in $files) {
    $fileName = $f.Name
    $filePath = $f.FullName
    Write-Host "Uploading: $fileName"

    $tempFile = [System.IO.Path]::GetTempFileName()
    $curlArgs = @(
        "-s", "-X", "POST",
        "http://localhost:5050/api/knowledge/files/upload?kb_id=$kbId",
        "-H", "Authorization: Bearer $token",
        "-F", "file=@$filePath",
        "-o", $tempFile
    )
    & curl.exe @curlArgs

    $responseStr = Get-Content $tempFile -Raw -Encoding UTF8
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

    try {
        $resp = $responseStr | ConvertFrom-Json
        if ($resp.file_path) {
            $results += [PSCustomObject]@{
                name = $fileName
                minio_url = $resp.file_path
                content_hash = $resp.content_hash
                size = $resp.size
            }
            Write-Host "  OK: $($resp.file_path)"
        } else {
            Write-Host "  FAILED: $responseStr"
        }
    } catch {
        Write-Host "  PARSE ERROR: $responseStr"
    }
}

# Save results for next step
$results | ConvertTo-Json -Depth 3 | Out-File "d:\Develop\SourceCode\agent-projects\zhiyuan\data\upload_results.json" -Encoding UTF8
Write-Host "`n=== Upload Summary ==="
$results | Format-Table -AutoSize
Write-Host "`nResults saved to data/upload_results.json"
