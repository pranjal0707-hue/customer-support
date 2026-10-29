public with sharing class CaseTriggerHandler {
    public static void beforeSave(List<Case> cases) {
        Set<Id> acctIds = new Set<Id>();
        for (Case c : cases) if (c.AccountId != null && c.Customer_Tier__c == null) acctIds.add(c.AccountId);
        Map<Id, Account> accts = new Map<Id, Account>([SELECT Id, AnnualRevenue FROM Account WHERE Id IN :acctIds]);
        for (Case c : cases) {
            if (c.Customer_Tier__c == null) c.Customer_Tier__c = tierFor(accts.get(c.AccountId));
            c.Priority = priorityFor(c.Customer_Tier__c, c.AI_Sentiment__c);
        }
    }
    @TestVisible static String tierFor(Account a) {
        if (a == null || a.AnnualRevenue == null) return 'Standard';
        if (a.AnnualRevenue >= 10000000) return 'Platinum VIP';
        if (a.AnnualRevenue >= 1000000) return 'Gold';
        return 'Standard';
    }
    @TestVisible static String priorityFor(String tier, String sentiment) {
        if (sentiment == 'Severe' || tier == 'Platinum VIP') return 'High';
        if (sentiment == 'Negative' || tier == 'Gold') return 'Medium';
        return 'Low';
    }
}
