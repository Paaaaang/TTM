"""체중 API 테스트 스크립트"""
import requests
import json
from datetime import datetime, timedelta

# 테스트용 토큰 - 실제 토큰으로 교체 필요
# 로그인 먼저 수행
login_response = requests.post('http://localhost:3000/api/auth/login', json={
    'login_id': 'admin@ttm.com',
    'password': 'admin1234'
})

if login_response.status_code == 200:
    token = login_response.json()['access_token']
    print(f"✅ 로그인 성공! 토큰: {token[:20]}...")
    
    # 체중 이력 조회
    headers = {'Authorization': f'Bearer {token}'}
    
    # 주간 데이터 조회
    start_date = (datetime.now() - timedelta(days=7)).strftime('%Y-%m-%d')
    end_date = datetime.now().strftime('%Y-%m-%d')
    
    print(f"\n=== 체중 이력 조회 ({start_date} ~ {end_date}) ===")
    response = requests.get(
        f'http://localhost:3000/api/weight/history?start_date={start_date}&end_date={end_date}&limit=30',
        headers=headers
    )
    
    print(f"Status Code: {response.status_code}")
    print(f"Response Body:")
    print(json.dumps(response.json(), indent=2, ensure_ascii=False))
    
else:
    print(f"❌ 로그인 실패: {login_response.status_code}")
    print(login_response.text)
