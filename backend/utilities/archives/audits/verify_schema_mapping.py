"""MySQL ↔ 코드 스키마 검증 도구

이 스크립트는 실제 DB 스키마와 프런트/백엔드 코드에서 사용하는 컬럼명을 비교해
누락되었거나 불필요한 컬럼을 빠르게 확인하기 위한 용도로 사용한다.

사용법:
    python verify_schema_mapping.py
"""

from __future__ import annotations

from collections import defaultdict
from typing import Dict, Iterable

from config.database import get_db_connection

# 테이블별로 코드에서 기대하는 컬럼과 대략적인 타입 프리픽스를 정의한다.
# 타입은 SHOW COLUMNS 결과의 접두어로 비교한다.
EXPECTED_SCHEMA: Dict[str, Dict[str, str]] = {
    "members": {
        "member_id": "int",
        "login_id": "varchar",
        "nickname": "varchar",
        "email": "varchar",
        "password_hash": "varchar",
        "member_name": "varchar",
        "phone_number": "varchar",
        "birth_date": "date",
        "gender": "varchar",
        "region": "varchar",
        "height_cm": "decimal",
        "weight_kg": "decimal",
        "calorie_goal": "int",
        "water_goal": "decimal",
        "activity_level": "varchar",
        "member_status": "varchar",
        "terms_agreed": "tinyint",
        "social_login_agreed": "tinyint",
        "push_notification_enabled": "tinyint",
        "marketing_notification_enabled": "tinyint",
        "profile_image": "varchar",
        "created_at": "datetime",
        "updated_at": "datetime",
        "deleted_at": "datetime",
    },
    "post": {
        "post_id": "int",
        "member_id": "int",
        "category": "varchar",
        "title": "varchar",
        "content": "text",
        "likes_count": "int",
        "view_count": "int",
        "comments_count": "int",
        "created_at": "datetime",
        "updated_at": "datetime",
    },
    "post_image": {
        "post_image_id": "int",
        "post_id": "int",
        "image_path": "varchar",
        "image_order": "int",
        "created_at": "datetime",
    },
    "post_like": {
        "post_like_id": "int",
        "post_id": "int",
        "member_id": "int",
        "created_at": "datetime",
    },
    "meal_log": {
        "meal_log_id": "int",
        "member_id": "int",
        "meal_date": "date",
        "meal_type": "varchar",
        "memo": "text",
        "total_calories": "decimal",
        "created_at": "datetime",
        "updated_at": "datetime",
    },
    "meal_item": {
        "meal_item_id": "int",
        "meal_log_id": "int",
        "food_name": "varchar",
        "portion_size": "varchar",
        "calories_kcal": "decimal",
        "carbohydrates_g": "decimal",
        "protein_g": "decimal",
        "fat_g": "decimal",
        "created_at": "datetime",
    },
    "exercise_log": {
        "exercise_log_id": "int",
        "member_id": "int",
        "exercise_name": "varchar",
        "exercise_date": "date",
        "duration_minutes": "int",
        "calories_burned": "decimal",
        "memo": "text",
        "created_at": "datetime",
        "updated_at": "datetime",
    },
}


def describe_table(table: str) -> Dict[str, Dict[str, str]]:
    conn = get_db_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(f"SHOW COLUMNS FROM `{table}`")
        columns = {}
        for row in cursor.fetchall():
            columns[row["Field"]] = {"type": row["Type"], "nullable": row["Null"], "key": row["Key"]}
        return columns
    finally:
        if conn.is_connected():
            conn.close()


def normalise_type(db_type: str) -> str:
    return db_type.lower().split("(")[0]


def report_table(table: str, expected: Dict[str, str]) -> None:
    try:
        actual = describe_table(table)
    except Exception as exc:  # pragma: no cover - 단순 스크립트용 예외 처리
        print(f"[ERROR] {table}: {exc}")
        return

    actual_columns = set(actual.keys())
    expected_columns = set(expected.keys())

    missing = sorted(expected_columns - actual_columns)
    unexpected = sorted(actual_columns - expected_columns)

    type_mismatches: Dict[str, str] = {}
    for column in expected_columns & actual_columns:
        expected_prefix = expected[column]
        if expected_prefix == "any":
            continue
        actual_type = normalise_type(actual[column]["type"])
        if not actual_type.startswith(expected_prefix.lower()):
            type_mismatches[column] = f"expected {expected_prefix}, actual {actual[column]['type']}"

    print("=" * 80)
    print(f"TABLE: {table}")
    print("-" * 80)

    if missing:
        print("Missing columns:")
        for col in missing:
            print(f"  • {col} (expected type: {expected[col]})")
    else:
        print("Missing columns: None")

    if unexpected:
        print("Unexpected columns:")
        for col in unexpected:
            print(f"  • {col} (db type: {actual[col]['type']})")
    else:
        print("Unexpected columns: None")

    if type_mismatches:
        print("Type mismatches:")
        for col, msg in type_mismatches.items():
            print(f"  • {col}: {msg}")
    else:
        print("Type mismatches: None")

    print("\nCurrent DB columns:")
    for col, meta in actual.items():
        nullable = "NULLABLE" if meta["nullable"] == "YES" else "NOT NULL"
        key = f", KEY={meta['key']}" if meta["key"] else ""
        print(f"  - {col}: {meta['type']} ({nullable}{key})")


def list_unknown_tables(known_tables: Iterable[str]) -> None:
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("SHOW TABLES")
        tables = sorted(row[0] for row in cursor.fetchall())
    finally:
        if conn.is_connected():
            conn.close()

    unknown = [t for t in tables if t not in known_tables]
    if unknown:
        print("=" * 80)
        print("Tables not covered by EXPECTED_SCHEMA:")
        print("-" * 80)
        for table in unknown:
            print(f"  - {table}")
        print()
    else:
        print("모든 테이블이 EXPECTED_SCHEMA에 정의되어 있습니다.\n")


def main() -> None:
    list_unknown_tables(EXPECTED_SCHEMA.keys())
    for table, expected in EXPECTED_SCHEMA.items():
        report_table(table, expected)


if __name__ == "__main__":
    main()
