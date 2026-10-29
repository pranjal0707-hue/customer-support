public with sharing class CreateCaseAction {
    public class Request {
        @InvocableVariable(required=true label='Subject') public String subject;
        @InvocableVariable(label='Description') public String description;
        @InvocableVariable(label='Contact Id') public Id contactId;
        @InvocableVariable(label='AI Sentiment') public String sentiment;
        @InvocableVariable(label='AI Summary') public String summary;
    }
    public class Result {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String caseId;
        @InvocableVariable public String caseNumber;
        @InvocableVariable public String message;
    }
    @InvocableMethod(label='Create Support Case' description='Creates a Case from an Agentforce conversation')
    public static List<Result> run(List<Request> reqs) {
        List<Case> cases = new List<Case>();
        for (Request r : reqs) {
            cases.add(new Case(Subject = r.subject, Description = r.description, ContactId = r.contactId,
                Origin = 'Web', Status = 'New', AI_Sentiment__c = r.sentiment, AI_Summary__c = r.summary));
        }
        Database.SaveResult[] srs = Database.insert(cases, false);
        Set<Id> ids = new Set<Id>();
        for (Database.SaveResult sr : srs) if (sr.isSuccess()) ids.add(sr.getId());
        Map<Id, Case> byId = new Map<Id, Case>([SELECT CaseNumber FROM Case WHERE Id IN :ids]);
        List<Result> out = new List<Result>();
        for (Database.SaveResult sr : srs) {
            Result res = new Result();
            res.success = sr.isSuccess();
            if (res.success) {
                res.caseId = sr.getId();
                res.caseNumber = byId.get(sr.getId()).CaseNumber;
                res.message = 'Case ' + res.caseNumber + ' created.';
            } else {
                res.message = sr.getErrors()[0].getMessage();
            }
            out.add(res);
        }
        return out;
    }
}
