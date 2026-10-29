"""Mock Service Cloud + Agentforce simulator. In-memory, keyword-based. Not the real Atlas engine."""
import re, time
from pathlib import Path
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from pydantic import BaseModel

app = FastAPI(title="Agentforce Ticketing Simulator")
KB = [
    {"id": "KB-1", "title": "Reset your password", "kw": ["password", "login", "locked", "sign in"], "body": "Use Forgot password on the sign-in page. The link expires in 30 minutes."},
    {"id": "KB-2", "title": "Understand your invoice", "kw": ["invoice", "billing", "charge", "refund"], "body": "Invoices post on the 1st. Duplicate charges are refunded in 5 business days."},
    {"id": "KB-3", "title": "Fix sync errors", "kw": ["sync", "error", "crash", "outage", "down"], "body": "Update to the latest version, then clear the local cache and sign in again."},
]
TIERS = {"Platinum VIP": 1, "Gold": 4, "Standard": 8}  # SLA hours
NEG = ["angry", "terrible", "worst", "unacceptable", "furious", "cancel", "lawsuit"]
SEV = ["outage", "down", "data loss", "breach", "lawsuit", "furious"]
cases, chats = [], []

def sentiment(t):
    t = t.lower()
    if any(w in t for w in SEV): return "Severe"
    if any(w in t for w in NEG): return "Negative"
    if any(w in t for w in ["thanks", "great", "love"]): return "Positive"
    return "Neutral"

def priority(tier, s):
    if s == "Severe" or tier == "Platinum VIP": return "High"
    if s == "Negative" or tier == "Gold": return "Medium"
    return "Low"

def queue(text, tier):
    t = text.lower()
    if tier == "Platinum VIP": return "VIP Queue"
    if any(k in t for k in KB[1]["kw"]): return "Billing"
    return "Tier 2 Technical"

def ground(text):
    t = text.lower()
    scored = sorted(KB, key=lambda a: -sum(k in t for k in a["kw"]))
    return scored[0] if any(k in t for k in scored[0]["kw"]) else None

def make_case(subject, body, customer, tier, deflected=False):
    s = sentiment(subject + " " + body)
    art = ground(subject + " " + body)
    c = {"id": len(cases) + 1, "number": f"{len(cases)+1:08d}", "subject": subject, "customer": customer, "tier": tier,
         "sentiment": s, "priority": priority(tier, s), "queue": queue(subject + " " + body, tier), "status": "New",
         "summary": f"{customer} reports: {subject}. Sentiment {s}.", "action": f"Share {art['id']}: {art['title']}" if art else "Investigate and reply",
         "deflected": deflected, "created": time.time(), "due": time.time() + TIERS[tier] * 3600, "escalation_reason": None}
    cases.append(c); return c

for subj, who, tier in [("Cannot log in after password reset", "Asha Rao", "Standard"), ("Production outage on checkout", "Northwind Ltd", "Platinum VIP"), ("Duplicate charge on invoice", "Dev Mehta", "Gold")]:
    make_case(subj, subj, who, tier)

class CaseIn(BaseModel): subject: str; body: str = ""; customer: str = "Guest"; tier: str = "Standard"
class ChatIn(BaseModel): message: str; customer: str = "Guest"; tier: str = "Standard"
class Patch(BaseModel): status: str | None = None; priority: str | None = None

@app.get("/", response_class=HTMLResponse)
def index(): return (Path(__file__).parent / "index.html").read_text(encoding="utf-8")
@app.get("/api/cases")
def list_cases(): return cases
@app.post("/api/cases")
def new_case(c: CaseIn):
    if c.tier not in TIERS: raise HTTPException(422, "Unknown tier")
    return make_case(c.subject, c.body, c.customer, c.tier)
@app.patch("/api/cases/{cid}")
def patch(cid: int, p: Patch):
    c = next((x for x in cases if x["id"] == cid), None)
    if not c: raise HTTPException(404, "Case not found")
    for k, v in p.model_dump(exclude_none=True).items(): c[k] = v
    return c
@app.get("/api/kb")
def kb(q: str = ""):
    q = q.lower(); return [a for a in KB if not q or q in a["title"].lower() or any(k in q for k in a["kw"])]
@app.post("/api/chat")
def chat(m: ChatIn):
    t = m.message.lower()
    chats.append(m.message)
    if any(w in t for w in ["human", "agent", "person"]) or sentiment(m.message) in ("Severe", "Negative"):
        c = make_case(m.message[:60], m.message, m.customer, m.tier)
        c["escalation_reason"] = "Customer asked for a human or sentiment was negative"; c["status"] = "Escalated"; c["priority"] = "High"
        return {"reply": f"I'm sorry about this. I've opened case {c['number']} and passed you to a human agent.", "case": c, "intent": "escalate"}
    m_num = re.search(r"\b(\d{8})\b", t)
    if m_num:
        c = next((x for x in cases if x["number"] == m_num.group(1)), None)
        return {"reply": f"Case {c['number']} is {c['status']} with {c['priority']} priority." if c else "I couldn't find that case number.", "intent": "status"}
    art = ground(t)
    if art:
        c = make_case(m.message[:60], m.message, m.customer, m.tier, deflected=True); c["status"] = "Closed"
        return {"reply": f"{art['title']}: {art['body']} I've logged this as case {c['number']} and closed it. Reply if it didn't help.", "intent": "deflect", "case": c}
    c = make_case(m.message[:60], m.message, m.customer, m.tier)
    return {"reply": f"I've opened case {c['number']} and routed it to {c['queue']}.", "intent": "create", "case": c}
@app.get("/api/analytics")
def analytics():
    n = len(cases) or 1; now = time.time()
    closed = [c for c in cases if c["status"] == "Closed"]
    ok = [c for c in cases if c["status"] == "Closed" or c["due"] > now]
    return {"total": len(cases), "deflection_rate": round(100 * sum(c["deflected"] for c in cases) / n), "sla_compliance": round(100 * len(ok) / n),
            "escalated": sum(c["status"] == "Escalated" for c in cases), "resolved": len(closed), "by_queue": {q: sum(c["queue"] == q for c in cases) for q in {c["queue"] for c in cases}}}

if __name__ == "__main__":
    import uvicorn; uvicorn.run(app, host="127.0.0.1", port=8000)
