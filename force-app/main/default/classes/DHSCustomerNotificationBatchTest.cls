@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexAssertionsShouldIncludeMessage')
private class DHSCustomerNotificationBatchTest {
    @IsTest
    static void exportsCasesCompletedToday() {
        DHS_Contact__c subject = new DHS_Contact__c(
            First_Name__c = 'Customer', Last_Name__c = 'Notification',
            Email__c = 'customer.notification@example.com',
            Contact_Type__c = 'Subject'
        );
        insert subject;
        insert new DHS_Case__c(
            DHS_Contact__c = subject.Id,
            Case_Completed_Date__c = Date.today()
        );

        Test.startTest();
        Id jobId = Database.executeBatch(new DHSCustomerNotificationBatch(), 1);
        Test.stopTest();

        AsyncApexJob job = [
            SELECT Status, NumberOfErrors, JobItemsProcessed
            FROM AsyncApexJob WHERE Id = :jobId
        ];
        System.assertEquals('Completed', job.Status);
        System.assertEquals(0, job.NumberOfErrors);
        System.assertEquals(1, job.JobItemsProcessed);
    }

    @IsTest
    static void schedulesCustomerNotificationBatch() {
        new DHSScheduleCustomerNotificationBatch().execute(null);
        System.assertEquals(
            1,
            [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'BatchApex']
        );
    }
}
