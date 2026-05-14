from fastapi import APIRouter, Request, HTTPException, Query
from fastapi.responses import FileResponse
from pathlib import Path
import urllib.parse

router = APIRouter()

@router.get("/decode_internal")
async def decode_internal(request: Request, file_path: str = Query(...)):
    client = request.client.host if request.client else None
    if client not in ("127.0.0.1", "::1", "localhost"):
        raise HTTPException(status_code=403, detail="Forbidden")

    file_path = urllib.parse.unquote(file_path)
    p = Path(file_path).resolve()

    allowed_roots = [
        Path("/share/romm/library").resolve(),
        Path("/var/lib/romm/library").resolve()
    ]
    if not any(str(p).startswith(str(root)) for root in allowed_roots):
        raise HTTPException(status_code=403, detail="Access denied")

    if not p.exists() or not p.is_file():
        raise HTTPException(status_code=404, detail="File not found")

    return FileResponse(p)
