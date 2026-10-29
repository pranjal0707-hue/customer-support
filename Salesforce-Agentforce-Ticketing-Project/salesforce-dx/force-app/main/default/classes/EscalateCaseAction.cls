public with sharing class EscalateCaseAction {
    public class Request {
        @InvocableVariable(required=true label='Case Id') public Id caseId;
        @InvocableVariable(required=true label='Reason') public String reason;
    }
    public class Result {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
    }
    @InvocableMethod(label='Escalate Case to Human' description='Warm handoff: raises priority and records why')
    public static List<Result> run(List<Request> reqs) {
        Map<Id, String> reasons = new Map<Id, String>();
        for (Request r : reqs) reasons.put(r.caseId, r.reason);
        List<Case> cases = [SELECT Id FROM Case WHERE Id IN :reasons.keySet() WITH USER_MODE];
        for (Case c : cases) { c.Priority = 'High'; c.Status = 'Escalated'; c.Escalation_Reason__c = reasons.get(c.Id); }
        update as user cases;
        List<Result> out = new List<Result>();
        for (Case c : cases) { Result res = new Result(); res.success = true; res.message = 'Escalated to a human agent.'; out.add(res); }
        return out;
    }
}
