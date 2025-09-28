# Test script for nginx-azure-proxy
# This script tests the proxy functionality

Write-Host "🧪 Testing nginx-azure-proxy" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$testUrl = "http://localhost:8080/document/00ba72b42bec7d496e1987307d9c1404/data/1745743272270-f11d58c3c5acf1ad537da0bc1694d493"
$expectedAzureUrl = "https://jeendevisracardblob.blob.core.windows.net/jeendocs/00ba72b42bec7d496e1987307d9c1404/attachment/1745743272270-f11d58c3c5acf1ad537da0bc1694d493"

Write-Host "🔗 Test URL: $testUrl" -ForegroundColor Yellow
Write-Host "🎯 Expected Azure URL: $expectedAzureUrl" -ForegroundColor Green
Write-Host ""

Write-Host "📡 Making request..." -ForegroundColor Blue

try {
    $response = curl -s $testUrl
    Write-Host "📄 Response:" -ForegroundColor White
    Write-Host $response
    
    if ($response -match "BlobNotFound") {
        Write-Host ""
        Write-Host "✅ SUCCESS: Proxy is working! Request was forwarded to Azure Blob Storage." -ForegroundColor Green
        Write-Host "   The 'BlobNotFound' error confirms the proxy reached Azure storage." -ForegroundColor Green
    } elseif ($response -match "Invalid URL format") {
        Write-Host ""
        Write-Host "❌ ERROR: URL format not supported by current proxy configuration." -ForegroundColor Red
        Write-Host "   The proxy needs to be updated to handle '/data/' paths." -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host "ℹ️  Response received, checking if proxy is working..." -ForegroundColor Yellow
    }
} catch {
    Write-Host ""
    Write-Host "❌ ERROR: Failed to connect to proxy" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Make sure the nginx-azure-proxy container is running:" -ForegroundColor Yellow
    Write-Host "   docker-compose ps" -ForegroundColor Gray
}

Write-Host ""
Write-Host "🏁 Test complete!" -ForegroundColor Cyan