$imagePath = "C:\Users\smhrd\Desktop\App\ttm\backend\uploads\meals\test_meal.jpg"
$apiUrl = "http://localhost:3000/api/meals/analyze-image"

Write-Host "흑미밥 이미지 AI 분석 API 테스트"

if (-not (Test-Path $imagePath)) {
    Write-Host "이미지 파일을 찾을 수 없습니다"
    exit 1
}

$fileInfo = Get-Item $imagePath
Write-Host "파일: $($fileInfo.Name), 크기: $($fileInfo.Length) bytes"

Write-Host "API 호출 중..."

try {
    $form = @{
        member_id = '1'
        meal_type = 'LUNCH'
        file = Get-Item -Path $imagePath
    }
    
    $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Form $form -TimeoutSec 30
    
    Write-Host "분석 완료: $($response.message)"
    
    if ($response.foods) {
        $i = 1
        foreach ($food in $response.foods) {
            Write-Host "[$i] $($food.food_name)"
            Write-Host "    칼로리: $($food.calories_kcal) kcal"
            Write-Host "    탄수화물: $($food.carbohydrates_g) g"
            Write-Host "    양: $($food.quantity_category)"
            $i++
        }
    }
} catch {
    Write-Host "API 호출 실패: $($_.Exception.Message)"
}
