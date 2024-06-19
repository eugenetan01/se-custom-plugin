from fastapi import FastAPI, HTTPException, Request, Query
from pydantic import BaseModel
import logging

app = FastAPI()
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Sample data for demonstration purposes
valid_tokens = {
    "token1": "token1"
}

active_token = None

customer_permissions = {
    "token1": ["custId1", "custId2"]
}

class TokenRequest(BaseModel):
    token: str

@app.get("/auth/validate/token")
async def validate_token(request: Request):
    global active_token
    auth_header = request.headers.get("authorization")
    if not auth_header:
        raise HTTPException(status_code=400, detail="Authorization header missing")

    token = auth_header.split(" ")[1] if len(auth_header.split(" ")) == 2 else None
    if not token or token not in valid_tokens:
        raise HTTPException(status_code=401, detail="Invalid token")
    active_token = auth_header
    logger.info(f"Active token set: {active_token}")
    return {"valid": True}

@app.get("/auth/validate/customer")
async def validate_customer_permission(request: Request, custId: str = Query(...)):
    global active_token
    try:
        auth_header = active_token
        logger.info(f"Using active token: {auth_header}")
        logger.info(f"Customer ID: {custId}")
        if not auth_header:
            raise HTTPException(status_code=400, detail="Authorization header missing")

        token = auth_header.split(" ")[1] if len(auth_header.split(" ")) == 2 else None
        logger.info(token)
        if not token or token not in valid_tokens:
            raise HTTPException(status_code=401, detail="Invalid token")

        user = valid_tokens[token]
        if custId not in customer_permissions.get(user, []):
            raise HTTPException(status_code=403, detail="Permission denied")

        return {"has_permission": True}
    finally:
        active_token=None
        logger.info("Active token cleared")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
