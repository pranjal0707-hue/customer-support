@IsTest
private class AgentforceCaseActionsTest {
    @IsTest static void createStatusEscalate() {
        CreateCaseAction.Request r = new CreateCaseAction.Request();
        r.subject = 'Cannot log in'; r.sentiment = 'Negative';
        CreateCaseAction.Result created = CreateCaseAction.run(new List<CreateCaseAction.Request>{ r })[0];
        System.assert(created.success, created.message);

        GetCaseStatusAction.Request s = new GetCaseStatusAction.Request();
        s.caseNumber = created.caseNumber;
        System.assert(GetCaseStatusAction.run(new List<GetCaseStatusAction.Request>{ s })[0].found);
        s.caseNumber = 'nope';
        System.assert(!GetCaseStatusAction.run(new List<GetCaseStatusAction.Request>{ s })[0].found);

        EscalateCaseAction.Request e = new EscalateCaseAction.Request();
        e.caseId = created.caseId; e.reason = 'Customer requested human';
        EscalateCaseAction.run(new List<EscalateCaseAction.Request>{ e });
        Case c = [SELECT Priority, Escalation_Reason__c FROM Case WHERE Id = :created.caseId];
        System.assertEquals('High', c.Priority);
        System.assertEquals('Customer requested human', c.Escalation_Reason__c);
    }
}
