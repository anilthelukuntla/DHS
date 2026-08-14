@IsTest
/** Exercises the existing DHSCustomerNotificationBatch behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSCustomerNotificationBatchTest {
    @IsTest
    static void exportsCasesCompletedToday() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
        DHS_Contact__c subject = new DHS_Contact__c(
            First_Name__c = 'Customer', Last_Name__c = 'Notification',
            Email__c = 'customer.notification@example.com',
            Contact_Type__c = 'Subject', SSN__c = '123-45-6789'
        );
        insert subject;
        insert new DHS_Case__c(
            DHS_Contact__c = subject.Id,
            DHS_Assigned_To__c = UserInfo.getUserId(),
            Case_Completed_Date__c = Date.today()
        );

        Test.startTest();
        Id jobId = Database.executeBatch(new DHSCustomerNotificationBatch(), 1);
        Test.stopTest();

        AsyncApexJob job = [
            SELECT Status, NumberOfErrors, JobItemsProcessed
            FROM AsyncApexJob WHERE Id = :jobId
        ];
        System.assertEquals('Completed', job.Status, 'Assertion failed in DHSCustomerNotificationBatchTest at source line 29');
        System.assertEquals(0, job.NumberOfErrors, 'Assertion failed in DHSCustomerNotificationBatchTest at source line 30');
        System.assertEquals(1, job.JobItemsProcessed, 'Assertion failed in DHSCustomerNotificationBatchTest at source line 31');
        }
    }

    @IsTest
    static void schedulesCustomerNotificationBatch() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
        Test.startTest();
        new DHSScheduleCustomerNotificationBatch().execute(null);
        Test.stopTest();
        System.assertEquals(
            1,
            [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'BatchApex']
        , 'Assertion failed in DHSCustomerNotificationBatchTest at source line 42');
        }
    }
}