@isTest
public class DIALeadTriggerTest {
    
    @isTest
    static void testDIALeadTrigger() {
        DIA_case__c testCase = new DIA_case__c(
            Assigned_To__c = userinfo.getuserId(),
            Case_Number__c = 'C-001'
        );
        insert testCase;

        DIA_Lead__c newLead = new DIA_Lead__c(
            Case__c = testCase.Id,
            Item_Number__c = 123,
            Assigned_To__c = userinfo.getuserId(),
            Status__c = 'New'
        );

        insert newLead;

        newLead = [SELECT Id, Status__c FROM DIA_Lead__c WHERE Id = :newLead.Id];

        DIA_Lead__c duplicateLead = new DIA_Lead__c(
            Case__c = testCase.Id,
            Item_Number__c = 111,
            Assigned_To__c = userinfo.getuserId(),
            Status__c = 'New'
        );

        try {
            insert duplicateLead;
        } catch (DmlException e) {
        }

        newLead.Status__c = 'Assigned';
        update newLead;

        newLead = [SELECT Lead_Log__c FROM DIA_Lead__c WHERE Id = :newLead.Id];
        
        newLead.Status__c = 'Completed';
        update newLead;

        newLead = [SELECT Completed_Date__c FROM DIA_Lead__c WHERE Id = :newLead.Id];

        newLead.Status__c = 'QA Rejected';
        newlead.Issues_discrepancies_or_developed_acti__c = 'Yes';
        update newLead;
        newLead = [SELECT Lead_Log__c FROM DIA_Lead__c WHERE Id = :newLead.Id];
        List<dia_lead__c> completeLeads = [select id from Dia_lead__c];
        for(dia_lead__c ld : completeLeads){
            ld.status__c = 'QA Review Completed';
        }
        	update completeLeads;
        //delete [SELECT Id FROM DIA_Lead__c];
        delete [SELECT Id FROM DIA_case__c];
    }
}