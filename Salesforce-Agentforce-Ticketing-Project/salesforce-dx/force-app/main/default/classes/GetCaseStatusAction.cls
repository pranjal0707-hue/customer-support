public with sharing class GetCaseStatusAction {
    public class Request { @InvocableVariable(required=true label='Case Number') public String caseNumber; }
    public class Result {
        @InvocableVariable public Boolean found;
        @InvocableVariable public String status;
        @InvocableVariable public String priority;
        @InvocableVariable public String message;
    }
    @InvocableMethod(label='Get Case Status' description='Looks up a case by case number')
    public static List<Result> run(List<Request> reqs) {
        Set<String> nums = new Set<String>();
        for (Request r : reqs) nums.add(r.caseNumber);
        Map<String, Case> byNum = new Map<String, Case>();
        for (Case c : [SELECT CaseNumber, Status, Priority FROM Case WHERE CaseNumber IN :nums WITH USER_MODE]) byNum.put(c.CaseNumber, c);
        List<Result> out = new List<Result>();
        for (Request r : reqs) {
            Result res = new Result();
            Case c = byNum.get(r.caseNumber);
            res.found = c != null;
            if (res.found) { res.status = c.Status; res.priority = c.Priority; res.message = 'Status: ' + c.Status + ', priority: ' + c.Priority; }
            else res.message = 'No case found with that number.';
            out.add(res);
        }
        return out;
    }
}
