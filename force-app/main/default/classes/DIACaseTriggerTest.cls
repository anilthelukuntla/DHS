@isTest
public class DIACaseTriggerTest {

    @isTest
    static void testDIACaseTrigger() {
        // Create test data
        DIA_contact__c testContact = new DIA_contact__c();
        insert testContact;

        // Test before insert
        DIA_Case__c newCase = new DIA_Case__c(
            contact__c = testContact.Id,
            case_discontinued__c = false,
            Assigned_to__c = null,
            current_task__c = 'Initiated State',
            Status__c = 'Open'
        );

        // Insert a new case to trigger the before insert logic
        insert newCase;

        // Verify before insert logic
        DIA_Case__c insertedCase = [SELECT Id, Current_Task__c, Initiated_State_Date__c, Submission_Date__c, case_queue_status__c FROM DIA_Case__c WHERE Id = :newCase.Id];
        System.assertEquals('Initiated State', insertedCase.Current_Task__c);
        System.assertEquals(System.today(), insertedCase.Initiated_State_Date__c);
        System.assertEquals(System.today(), insertedCase.Submission_Date__c);
        System.assertEquals('New', insertedCase.case_queue_status__c);

        // Test after insert
        List<DIA_Case_History__c> histories = [SELECT Id, case__c, added_by__c, value__c FROM DIA_case_History__c WHERE case__c = :insertedCase.Id];
        System.assertEquals(1, histories.size());
        System.assertEquals(insertedCase.Id, histories[0].case__c);
        System.assertEquals(UserInfo.getUserId(), histories[0].added_by__c);
        System.assertEquals('Initiated State', histories[0].value__c);

        // Test before update
        insertedCase.Assigned_to__c = UserInfo.getUserId();
        update insertedCase;

        // Verify before update logic
        DIA_Case__c updatedCase = [SELECT Id, case_queue_status__c, Assignee_Date__c FROM DIA_Case__c WHERE Id = :insertedCase.Id];
        System.assertEquals('Assigned', updatedCase.case_queue_status__c);
        System.assertEquals(System.today(), updatedCase.Assignee_Date__c);

        // Test after update logic for discontinuation
        insertedCase.case_discontinued__c = true;
        update insertedCase;

        // Verify the lead status update for discontinuation
        List<DIA_lead__c> leads = [SELECT Id, Status__c FROM DIA_lead__c WHERE Case__c = :insertedCase.Id];
        for (DIA_lead__c lead : leads) {
            System.assertEquals('Discontinued', lead.Status__c);
        }

        // Verify Case SLA Code updates
        insertedCase.current_task__c = 'Scoping';
        update insertedCase;
        
        

        DIA_Case__c updatedSLA = [SELECT Id, Case_SLA_Code__c FROM DIA_Case__c WHERE Id = :insertedCase.Id];
        System.assertEquals('#1e90ff', updatedSLA.Case_SLA_Code__c);

        // Test for cancellation
        insertedCase.Status__c = 'Canceled';
        update insertedCase;

        DIA_Case__c canceledCase = [SELECT Id, Case_Cancellation_Date__c, Closed_Date__c FROM DIA_Case__c WHERE Id = :insertedCase.Id];
        System.assertEquals(System.today(), canceledCase.Case_Cancellation_Date__c);
        System.assertEquals(System.today(), canceledCase.Closed_Date__c);
        
        
        insertedCase.current_task__c = 'QA Review Completed';
        update insertedCase;
    }
}