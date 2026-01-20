# -*- coding: utf-8 -*-
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from pathlib import Path
from datetime import datetime
import json
from typing import Optional

router = APIRouter()

BASE_DIR = Path(__file__).resolve().parent.parent
STATUS_FILE = BASE_DIR / "iot_status.json"
DEVICES_FILE = BASE_DIR / "iot_devices.json"


class HeartbeatPayload(BaseModel):
    member_id: Optional[int] = None
    device_id: Optional[str] = None
    status: str = "ok"
    timestamp: Optional[str] = None


def _read_status():
    try:
        if STATUS_FILE.exists():
            return json.loads(STATUS_FILE.read_text(encoding="utf-8"))
    except Exception:
        return {}
    return {}


def _write_status(data):
    try:
        STATUS_FILE.write_text(json.dumps(data), encoding="utf-8")
    except Exception:
        pass


def _read_devices():
    try:
        if DEVICES_FILE.exists():
            return json.loads(DEVICES_FILE.read_text(encoding="utf-8"))
    except Exception:
        return {}
    return {}


def _write_devices(data):
    try:
        DEVICES_FILE.write_text(json.dumps(data), encoding="utf-8")
    except Exception:
        pass


@router.post("/heartbeat")
async def heartbeat(payload: HeartbeatPayload):
    """Simple heartbeat endpoint from IoT devices. Stores last seen timestamp by member_id."""
    data = _read_status()
    devices = _read_devices()
    ts = payload.timestamp or datetime.utcnow().isoformat()

    # If device_id provided, update device mapping and device last_seen
    if payload.device_id:
        dev = devices.get(payload.device_id, {})
        # if payload contains member_id, persist mapping
        if payload.member_id:
            dev["member_id"] = payload.member_id
        dev["last_seen"] = ts
        dev["status"] = payload.status
        devices[payload.device_id] = dev
        _write_devices(devices)

    # If member_id provided, update member-level last_seen
    if payload.member_id:
        data[str(payload.member_id)] = {"last_seen": ts, "status": payload.status}
        _write_status(data)

    return {"success": True, "member_id": payload.member_id, "device_id": payload.device_id, "last_seen": ts}


@router.get("/status/{member_id}")
async def get_status(member_id: int):
    """Get last seen info for a given member_id. Returns connected if seen within 120s."""
    # Prefer devices file for accurate per-device last_seen
    devices = _read_devices()
    member_devices = [
        {"device_id": k, **v}
        for k, v in devices.items()
        if str(v.get("member_id")) == str(member_id)
    ]

    last_seen = None
    last_dt = None
    for d in member_devices:
        ls = d.get("last_seen")
        try:
            dt = datetime.fromisoformat(ls)
        except Exception:
            continue
        if last_dt is None or dt > last_dt:
            last_dt = dt
            last_seen = ls

    # Fallback to member-level status file
    if last_seen is None:
        data = _read_status()
        entry = data.get(str(member_id))
        if entry:
            last_seen = entry.get("last_seen")
            try:
                last_dt = datetime.fromisoformat(last_seen)
            except Exception:
                last_dt = None

    if last_seen is None:
        raise HTTPException(status_code=404, detail="No status for member")

    age = (datetime.utcnow() - last_dt).total_seconds() if last_dt else 999999
    connected = age < 30  # 30초 이내면 연결됨으로 표시
    return {"member_id": member_id, "last_seen": last_seen, "seconds_ago": age, "connected": connected, "devices": member_devices}


@router.post("/register-device")
async def register_device(payload: dict):
    """Register a device to a member. Payload: {device_id, member_id, alias?} """
    device_id = payload.get("device_id")
    member_id = payload.get("member_id")
    alias = payload.get("alias")
    if not device_id or not member_id:
        raise HTTPException(status_code=400, detail="device_id and member_id required")
    devices = _read_devices()
    dev = devices.get(device_id, {})
    dev["member_id"] = member_id
    if alias:
        dev["alias"] = alias
    dev.setdefault("last_seen", None)
    dev.setdefault("status", "ok")
    devices[device_id] = dev
    _write_devices(devices)
    return {"success": True, "device_id": device_id, "member_id": member_id}


@router.get("/devices/{member_id}")
async def list_devices(member_id: int):
    devices = _read_devices()
    member_devices = [
        {"device_id": k, **v}
        for k, v in devices.items()
        if str(v.get("member_id")) == str(member_id)
    ]
    return {"member_id": member_id, "devices": member_devices}
