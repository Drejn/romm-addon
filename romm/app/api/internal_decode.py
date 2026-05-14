# app/api/internal_decode.py
from fastapi import APIRouter, Request, HTTPException, Query
from fastapi.responses import FileResponse
from pathlib import Path
import urllib.parse
import os
import logging

logger = logging.getLogger("romm.internal_decode")
router = APIRouter()


INTERNAL_SECRET = os.environ.get("INTERNAL_SECRET", "change-me-default-secret")
ROM_LIBRARY = os.environ.get("ROM_LIBRARY_PATH", "/share/romm/library")

ALLOWED_ROOTS = [
    Path(ROM_LIBRARY).resolve(),
    Path("/var/lib/romm/library").resolve()
]
@router.get("/decode_internal")
async def decode_internal(request: Request, file_path: str = Query(...)):
    secret = request.headers.get("X-Internal-Secret")
    if secret != INTERNAL_SECRET:
        logger.warning("Forbidden: missing/invalid internal secret")
        raise HTTPException(status_code=403, detail="Forbidden")

    file_path = urllib.parse.unquote(file_path)
    p = Path(file_path).resolve()
    logger.debug("Resolved path: %s", p)

    if not any(str(p).startswith(str(root)) for root in ALLOWED_ROOTS):
        logger.warning("Access denied to path outside allowed roots: %s", p)
        raise HTTPException(status_code=403, detail="Access denied")

    if not p.exists() or not p.is_file():
        logger.info("File not found: %s", p)
        raise HTTPException(status_code=404, detail="File not found")

    return FileResponse(p)
