# 흑미밥 이미지 API 테스트 스크립트
$imagePath = "C:\Users\smhrd\Desktop\App\ttm\backend\uploads\meals\test_meal.jpg"
$apiUrl = "http://localhost:3000/api/meals/analyze-image"

Write-Host "================================================================================"
Write-Host "흑미밥 이미지 AI 분석 API 테스트"
Write-Host "================================================================================"

# 이미지 파일 확인
if (-not (Test-Path $imagePath)) {
    Write-Host "❌ 이미지 파일을 찾을 수 없습니다: $imagePath"
    exit 1
}

$fileInfo = Get-Item $imagePath
Write-Host "`n📸 이미지 정보:"
Write-Host "  파일명: $($fileInfo.Name)"
Write-Host "  크기: $($fileInfo.Length) bytes"
Write-Host "  수정일: $($fileInfo.LastWriteTime)"

# API 호출
Write-Host "`n🚀 API 호출 중..."

try {
    $form = @{
        member_id = '1'
        meal_type = 'LUNCH'
        file = Get-Item -Path $imagePath
    }
    
    $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Form $form -TimeoutSec 30
    
    Write-Host "`n✅ 분석 완료!"
    Write-Host "`n📊 결과:"
    Write-Host "  성공: $($response.success)"
    Write-Host "  메시지: $($response.message)"
    
    if ($response.foods) {
        Write-Host "`n음식 목록:"
        $response.foods | ForEach-Object -Begin { $i = 1 } -Process {
            Write-Host "`n  [$i] $($_.food_name)"
            Write-Host "      칼로리: $($_.calories_kcal) kcal"
            Write-Host "      탄수화물: $($_.carbohydrates_g) g"
            Write-Host "      단백질: $($_.protein_g) g"
            Write-Host "      지방: $($_.fat_g) g"
            Write-Host "      양: $($_.quantity_category) (x$($_.quantity_multiplier))"
            if ($null -ne $_.confidence) {
                $confidencePct = [math]::Round($_.confidence * 100, 1)
                Write-Host "      신뢰도: $confidencePct%"
            }
            $i++
        }
    }
} catch {
    Write-Host "`n❌ API 호출 실패:"
    Write-Host "  오류: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "  응답: $responseBody"
    }
}

Write-Host ""
Write-Host "================================================================================"
