#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Health API 테스트
"""
import requests
import json

BASE_URL = "http://localhost:3000"

# 테스트 데이터
test_data = {
    "gender": "M",
    "height": 175.5,
    "weight": 70.0,
    "diseases": ["diabetes", "hypertension", "allergy-nuts", "allergy-dairy"],
    "exercise_frequency": "moderate",
    "sleep_duration": "good"
}

# member_id = 1 가정
member_id = 1

print("=" * 80)
print("Health API 테스트 시작")
print("=" * 80)
print(f"\n📤 요청 데이터:")
print(json.dumps(test_data, indent=2, ensure_ascii=False))

try:
    response = requests.put(
        f"{BASE_URL}/members/{member_id}/health",
        json=test_data,
        headers={"Content-Type": "application/json"}
    )
    
    print(f"\n📥 응답 코드: {response.status_code}")
    print(f"📥 응답 내용: {response.text}")
    
    if response.status_code == 200:
        print("\n✅ 성공!")
        
        # DB 확인
        from config.database import get_db_connection
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # members 테이블 확인
        cursor.execute(
            "SELECT gender, height_cm, weight_kg, activity_level, sleep_pattern FROM members WHERE member_id = %s",
            (member_id,)
        )
        member = cursor.fetchone()
        print(f"\n📋 members 테이블:")
        print(json.dumps(member, indent=2, ensure_ascii=False, default=str))
        
        # member_disease 확인
        cursor.execute(
            "SELECT disease_name FROM member_disease WHERE member_id = %s",
            (member_id,)
        )
        diseases = cursor.fetchall()
        print(f"\n📋 member_disease 테이블:")
        print(json.dumps(diseases, indent=2, ensure_ascii=False))
        
        # member_allergy 확인
        cursor.execute(
            "SELECT allergy_name FROM member_allergy WHERE member_id = %s",
            (member_id,)
        )
        allergies = cursor.fetchall()
        print(f"\n📋 member_allergy 테이블:")
        print(json.dumps(allergies, indent=2, ensure_ascii=False))
        
        cursor.close()
        conn.close()
    else:
        print(f"\n❌ 실패: {response.text}")
        
except Exception as e:
    print(f"\n❌ 오류 발생: {e}")
    import traceback
    traceback.print_exc()

print("\n" + "=" * 80)
