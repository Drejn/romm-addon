from fastapi import FastAPI
from app.api.internal_decode import router as internal_decode_router

app = FastAPI(title="RomM Addon Backend")
app.include_router(internal_decode_router)

@app.get("/health")
async def health():
    return {"status": "ok"}
