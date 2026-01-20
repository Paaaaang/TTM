"""
친구 관계 검증 테스트
"""
import requests
import json

BASE_URL = "http://localhost:3000"

def test_friend_validation():
    """친구 관계 검증 테스트"""
    
    # 1. 그룹 생성 (member_id=15가 생성자)
    print("1️⃣ 그룹 생성 테스트...")
    response = requests.post(
        f"{BASE_URL}/api/groups/",
        json={
            "group_name": "테스트 그룹",
            "creator_member_id": 15
        }
    )
    
    if response.status_code == 200:
        group = response.json()
        group_id = group['group_id']
        print(f"✅ 그룹 생성 성공: group_id={group_id}")
        
        # 2. 친구인 사용자 추가 시도 (member_id=15와 친구인 사용자)
        print("\n2️⃣ 친구 추가 테스트...")
        response = requests.post(
            f"{BASE_URL}/api/groups/{group_id}/members",
            json={"member_id": 1}  # member_id=1은 15와 친구
        )
        
        if response.status_code == 200:
            print(f"✅ 친구 추가 성공: {response.json()}")
        else:
            print(f"❌ 친구 추가 실패: {response.status_code} - {response.json()}")
        
        # 3. 친구가 아닌 사용자 추가 시도 (존재하지만 친구 아님)
        # 먼저 member_id 20을 생성하고 테스트하거나
        # 이미 존재하는 회원 중 15와 친구가 아닌 사람을 찾아야 함
        # 현재는 모든 회원이 친구이므로 이 테스트는 생략
        
        print("\n3️⃣ 그룹 멤버 목록 조회...")
        response = requests.get(f"{BASE_URL}/api/groups/{group_id}/members")
        if response.status_code == 200:
            members = response.json()
            print(f"✅ 그룹 멤버: {len(members)}명")
            for member in members:
                print(f"   - {member['nickname']} (ID: {member['member_id']})")
        
        # 4. 그룹 삭제 (테스트 정리)
        print("\n4️⃣ 그룹 삭제...")
        response = requests.delete(
            f"{BASE_URL}/api/groups/{group_id}",
            params={"member_id": 15}
        )
        if response.status_code == 200:
            print("✅ 그룹 삭제 완료")
        else:
            print(f"❌ 그룹 삭제 실패: {response.json()}")
            
    else:
        print(f"❌ 그룹 생성 실패: {response.status_code} - {response.json()}")

if __name__ == "__main__":
    print("="*50)
    print("친구 관계 검증 테스트")
    print("="*50)
    test_friend_validation()
    print("\n" + "="*50)
    print("테스트 완료")
    print("="*50)
