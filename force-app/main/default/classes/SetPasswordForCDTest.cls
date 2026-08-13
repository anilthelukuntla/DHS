@IsTest
/** Exercises scheduled customer-deliverable manifest generation. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class SetPasswordForCDTest {
    @IsTest
    static void generatesAndRefreshesManifestContent() {
        insert new Account(Name = 'ISN');
        DIA_Contact__c subjectRecord = new DIA_Contact__c(
            First_Name__c = 'Manifest',
            Last_Name__c = 'Subject',
            SSN__c = '123-45-6789'
        );
        insert subjectRecord;
        insert new DIA_Case__c(
            Contact__c = subjectRecord.Id,
            Case_Queue_Status__c = 'Completed',
            Status__c = 'Completed',
            Case_Completed_Date__c = Date.today()
        );
        DIA_Contact__c incompleteSubject = new DIA_Contact__c(
            First_Name__c = 'Incomplete',
            Last_Name__c = 'Subject'
        );
        insert incompleteSubject;
        insert new DIA_Case__c(Contact__c = incompleteSubject.Id);

        new ScheduleSetPasswordForCD().execute(null);
        new ScheduleSetPasswordForCD().execute(null);
        SetPasswordForCD controller = new SetPasswordForCD();
        SetPasswordForCD.sendMail(
            'Manifest test',
            'Manifest body',
            new List<String>{ 'recipient@example.com' },
            new List<String>{ 'copy@example.com' }
        );

        System.assertEquals(
            2,
            [SELECT COUNT() FROM ContentVersion WHERE Title LIKE 'Manifest%']
        , 'Assertion failed in SetPasswordForCDTest at source line 37');
        System.assertNotEquals(null, controller.mwList, 'Assertion failed in SetPasswordForCDTest at source line 41');
        System.assertEquals(
            Date.today(),
            SetPasswordForCD.convertdatetimetodate(System.now())
        , 'Assertion failed in SetPasswordForCDTest at source line 42');
    }
}