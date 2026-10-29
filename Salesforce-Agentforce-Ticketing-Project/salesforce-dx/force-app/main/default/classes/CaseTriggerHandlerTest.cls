@IsTest
private class CaseTriggerHandlerTest {
    @IsTest static void platinumAccountGetsHighPriority() {
        Account a = new Account(Name = 'Big Co', AnnualRevenue = 20000000);
        insert a;
        Case c = new Case(Subject = 'Down', AccountId = a.Id, AI_Sentiment__c = 'Positive');
        insert c;
        c = [SELECT Customer_Tier__c, Priority FROM Case WHERE Id = :c.Id];
        System.assertEquals('Platinum VIP', c.Customer_Tier__c);
        System.assertEquals('High', c.Priority);
    }
    @IsTest static void bulkInsertDefaultsToStandardLow() {
        List<Case> cs = new List<Case>();
        for (Integer i = 0; i < 200; i++) cs.add(new Case(Subject = 'Q' + i));
        insert cs;
        System.assertEquals(200, [SELECT COUNT() FROM Case WHERE Priority = 'Low' AND Customer_Tier__c = 'Standard']);
    }
    @IsTest static void sentimentDrivesPriority() {
        System.assertEquals('High', CaseTriggerHandler.priorityFor('Standard', 'Severe'));
        System.assertEquals('Medium', CaseTriggerHandler.priorityFor('Standard', 'Negative'));
    }
}
