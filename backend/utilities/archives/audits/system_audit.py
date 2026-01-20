"""
TTM 시스템 전체 점검 스크립트
API, Frontend, Backend, DB 매칭 및 최적화 점검
"""
import os
import re
from collections import defaultdict

# ============================================================
# 1. Backend API 엔드포인트 추출
# ============================================================
def extract_backend_apis():
    """Backend 라우터에서 API 엔드포인트 추출"""
    routers_dir = 'routers'
    api_endpoints = defaultdict(list)
    
    for filename in os.listdir(routers_dir):
        if not filename.endswith('.py') or filename.startswith('__'):
            continue
        
        filepath = os.path.join(routers_dir, filename)
        router_name = filename.replace('.py', '')
        
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
            # @router.METHOD("/path") 패턴 찾기
            pattern = r'@router\.(get|post|put|delete|patch)\("([^"]+)"'
            matches = re.findall(pattern, content)
            
            for method, path in matches:
                full_path = f'/{router_name}{path}'
                api_endpoints[router_name].append({
                    'method': method.upper(),
                    'path': full_path,
                    'file': filename
                })
    
    return api_endpoints

# ============================================================
# 2. Frontend API 호출 추출
# ============================================================
def extract_frontend_apis():
    """Frontend 서비스에서 API 호출 추출"""
    services_dir = '../lib/services'
    api_calls = defaultdict(list)
    
    if not os.path.exists(services_dir):
        print(f"⚠️  Frontend 서비스 디렉토리 없음: {services_dir}")
        return api_calls
    
    for filename in os.listdir(services_dir):
        if not filename.endswith('.dart'):
            continue
        
        filepath = os.path.join(services_dir, filename)
        service_name = filename.replace('.dart', '')
        
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
            # http.METHOD + /api/path 패턴 찾기
            lines = content.split('\n')
            for i, line in enumerate(lines):
                # http.get/post/put/delete 찾기
                http_match = re.search(r'http\.(get|post|put|delete)', line)
                if http_match:
                    method = http_match.group(1).upper()
                    
                    # 다음 몇 줄에서 URL 찾기
                    for j in range(max(0, i-5), min(len(lines), i+10)):
                        url_match = re.search(r'/api/([^\'"\s]+)', lines[j])
                        if url_match:
                            path = '/api/' + url_match.group(1)
                            # 변수 치환 제거 ($postId -> {post_id})
                            path = re.sub(r'\$\w+', '{id}', path)
                            api_calls[service_name].append({
                                'method': method,
                                'path': path,
                                'file': filename,
                                'line': i + 1
                            })
                            break
    
    return api_calls

# ============================================================
# 3. DB 스키마 분석
# ============================================================
def analyze_db_schema():
    """데이터베이스 스키마 분석"""
    schema_file = 'database/schema.sql'
    
    if not os.path.exists(schema_file):
        print(f"⚠️  스키마 파일 없음: {schema_file}")
        return {}
    
    with open(schema_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 테이블별 칼럼 추출
    tables = {}
    current_table = None
    
    lines = content.split('\n')
    for line in lines:
        # CREATE TABLE 찾기
        table_match = re.search(r'CREATE TABLE.*?(\w+)\s*\(', line)
        if table_match:
            current_table = table_match.group(1)
            tables[current_table] = {'columns': [], 'fks': [], 'indexes': []}
            continue
        
        if current_table:
            # 칼럼 찾기 (인덱스/FK 아닌 경우)
            col_match = re.match(r'\s+(\w+)\s+(VARCHAR|INT|BIGINT|DECIMAL|DATE|DATETIME|TEXT|ENUM|TINYINT)', line)
            if col_match:
                col_name = col_match.group(1)
                col_type = col_match.group(2)
                tables[current_table]['columns'].append((col_name, col_type))
            
            # FK 찾기
            fk_match = re.search(r'FOREIGN KEY.*?REFERENCES\s+(\w+)', line)
            if fk_match:
                tables[current_table]['fks'].append(fk_match.group(1))
            
            # 인덱스 찾기
            idx_match = re.search(r'INDEX\s+(\w+)', line)
            if idx_match:
                tables[current_table]['indexes'].append(idx_match.group(1))
            
            # 테이블 종료
            if line.strip().startswith(')'):
                current_table = None
    
    return tables

# ============================================================
# 4. 중복 코드 검사
# ============================================================
def check_duplicate_logic():
    """Frontend 서비스에서 중복 로직 검사"""
    services_dir = '../lib/services'
    duplicates = []
    
    if not os.path.exists(services_dir):
        return duplicates
    
    # 공통 패턴들
    patterns_count = defaultdict(list)
    
    for filename in os.listdir(services_dir):
        if not filename.endswith('.dart'):
            continue
        
        filepath = os.path.join(services_dir, filename)
        
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
            # TokenManager 사용 패턴
            if 'TokenManager.getToken()' in content:
                patterns_count['TokenManager'].append(filename)
            
            # 에러 처리 패턴
            if 'try {' in content and 'catch (e)' in content:
                patterns_count['try-catch'].append(filename)
            
            # 캐싱 패턴
            if 'SharedPreferences' in content:
                patterns_count['캐싱'].append(filename)
    
    return patterns_count

# ============================================================
# 5. 메인 실행
# ============================================================
def main():
    print("=" * 80)
    print("TTM 시스템 전체 점검")
    print("=" * 80)
    
    # 1. Backend API 엔드포인트
    print("\n📡 1. Backend API 엔드포인트")
    print("-" * 80)
    backend_apis = extract_backend_apis()
    total_backend = 0
    for router, endpoints in sorted(backend_apis.items()):
        print(f"\n[{router}] ({len(endpoints)}개)")
        for ep in endpoints:
            print(f"  {ep['method']:6s} {ep['path']}")
            total_backend += 1
    print(f"\n✅ 총 Backend API: {total_backend}개")
    
    # 2. Frontend API 호출
    print("\n\n📱 2. Frontend API 호출")
    print("-" * 80)
    frontend_apis = extract_frontend_apis()
    total_frontend = 0
    for service, calls in sorted(frontend_apis.items()):
        print(f"\n[{service}] ({len(calls)}개)")
        unique_calls = {}
        for call in calls:
            key = f"{call['method']} {call['path']}"
            if key not in unique_calls:
                unique_calls[key] = call
        
        for key, call in sorted(unique_calls.items()):
            print(f"  {call['method']:6s} {call['path']}")
            total_frontend += 1
    print(f"\n✅ 총 Frontend API 호출: {total_frontend}개")
    
    # 3. API 매칭 검사
    print("\n\n🔗 3. API 매칭 검사")
    print("-" * 80)
    
    # Backend API 플랫 리스트
    backend_flat = set()
    for router, endpoints in backend_apis.items():
        for ep in endpoints:
            backend_flat.add(f"{ep['method']} {ep['path']}")
    
    # Frontend API 플랫 리스트
    frontend_flat = set()
    for service, calls in frontend_apis.items():
        for call in calls:
            # 정규화: /api/posts/{id} -> /posts/{id}
            normalized_path = call['path'].replace('/api', '')
            frontend_flat.add(f"{call['method']} {normalized_path}")
    
    # 매칭되지 않은 Frontend 호출
    unmatched_frontend = []
    for fe_call in sorted(frontend_flat):
        method, path = fe_call.split(' ', 1)
        # {id} -> {post_id}, {meal_log_id} 등으로 변환 가능
        normalized = path
        normalized = re.sub(r'\{id\}', '{post_id}', normalized)
        normalized = re.sub(r'\{id\}', '{meal_log_id}', normalized)
        
        # Backend에서 찾기
        matched = False
        for be_call in backend_flat:
            if be_call.startswith(method) and path.split('/')[1:3] == be_call.split(' ')[1].split('/')[1:3]:
                matched = True
                break
        
        if not matched:
            unmatched_frontend.append(fe_call)
    
    if unmatched_frontend:
        print("⚠️  Frontend에서 호출하지만 Backend에 없는 API:")
        for api in unmatched_frontend[:10]:  # 상위 10개만
            print(f"  {api}")
    else:
        print("✅ 모든 Frontend API 호출이 Backend와 매칭됨")
    
    # 4. DB 스키마 분석
    print("\n\n🗄️  4. 데이터베이스 스키마")
    print("-" * 80)
    tables = analyze_db_schema()
    print(f"총 테이블: {len(tables)}개\n")
    
    for table_name, info in sorted(tables.items()):
        print(f"[{table_name}]")
        print(f"  칼럼: {len(info['columns'])}개")
        if info['fks']:
            print(f"  FK: {', '.join(info['fks'])}")
        if info['indexes']:
            print(f"  인덱스: {len(info['indexes'])}개")
        print()
    
    # 5. 중복 코드 패턴
    print("\n📦 5. 공통 패턴 사용")
    print("-" * 80)
    patterns = check_duplicate_logic()
    for pattern, files in sorted(patterns.items()):
        print(f"{pattern}: {len(files)}개 파일")
        if len(files) > 3:
            print(f"  ✅ 공통 로직으로 추출 가능")
    
    # 6. 최종 요약
    print("\n\n" + "=" * 80)
    print("📊 최종 점검 요약")
    print("=" * 80)
    print(f"✅ Backend API: {total_backend}개")
    print(f"✅ Frontend API 호출: {total_frontend}개")
    print(f"✅ 데이터베이스 테이블: {len(tables)}개")
    print(f"⚠️  매칭 안 됨: {len(unmatched_frontend)}개")
    
    if total_backend > 0 and total_frontend > 0 and len(unmatched_frontend) < 5:
        print("\n🎉 전체적으로 잘 매칭되어 있습니다!")
    else:
        print("\n⚠️  일부 매칭 문제가 있습니다. 위 내용을 확인하세요.")

if __name__ == '__main__':
    main()
