# romm/app/main.py
import logging
from fastapi import FastAPI
from app.api import internal_decode_router

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("romm")

app = FastAPI(title="RomM Addon Backend")

# registra il router interno
app.include_router(internal_decode_router)

@app.get("/health")
async def health():
    return {"status": "ok"}

@app.on_event("startup")
async def on_startup():
    logger.info("RomM backend starting up")

@app.on_event("shutdown")
async def on_shutdown():
    logger.info("RomM backend shutting down")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8080, log_level="info")
