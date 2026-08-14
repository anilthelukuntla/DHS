@IsTest
/** Exercises the existing DHSLeadTrigger behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSLeadTriggerTest {
    @IsTest
    static void initializesAndUpdatesLeadLifecycle() {
        DHS_Contact__c subject = new DHS_Contact__c(
            First_Name__c = 'Lead',
            Last_Name__c = 'Trigger Test'
        );
        insert subject;
        DHS_Case__c parentCase = new DHS_Case__c(DHS_Contact__c = subject.Id);
        insert parentCase;
        DHS_Lead__c lead = new DHS_Lead__c(
            DHS_Case__c = parentCase.Id,
            LeadType__c = 'Subject Interview (ESI/TESI)',
            Coverage_Type__c = 'Subject Interview'
        );
        insert lead;
        lead = [
            SELECT Status__c, Last_Status_Change__c, DHS_Contact__c
            FROM DHS_Lead__c WHERE Id = :lead.Id
        ];
        System.assertEquals('Unassigned', lead.Status__c, 'Assertion failed in DHSLeadTriggerTest at source line 24');
        System.assertEquals(subject.Id, lead.DHS_Contact__c, 'Assertion failed in DHSLeadTriggerTest at source line 25');
        lead.Coverage_Type__c = 'Personal';
        update lead;
        delete lead;
        undelete lead;
        System.assertNotEquals(null, lead.Last_Status_Change__c, 'Assertion failed in DHSLeadTriggerTest at source line 30');
    }
}