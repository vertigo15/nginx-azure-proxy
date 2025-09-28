# Simple curl test for the specific URL
Write-Host "🔗 Testing specific document URL..." -ForegroundColor Cyan

$url = "http://localhost:8080/document/00ba72b42bec7d496e1987307d9c1404/data/1745743272270-f11d58c3c5acf1ad537da0bc1694d493"

Write-Host "URL: $url" -ForegroundColor Yellow
Write-Host "Executing curl..." -ForegroundColor Blue

curl $url