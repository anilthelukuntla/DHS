@IsTest
/** Verifies maintenance and meeting-sync scheduling decisions. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class MicrosoftGraphLifecycleSchedulerTest {
    @IsTest
    static void enqueuesMaintenanceAndEligibleMeetingSync() {
        insert new MS_Team_Call_Schedule__c(
            Subject__c = 'Lifecycle scheduler test',
            Start_Date_Time__c = '2026-08-01T10:00:00',
            End_Date_Time__c = '2026-08-01T11:00:00',
            Microsoft_Time_Zone__c = 'India Standard Time',
            Online_Meeting_ID__c = 'scheduler-meeting',
            Status__c = 'Scheduled',
            Last_Synchronized_At__c = System.now().addHours(-1)
        );

        Integer jobsBefore = Limits.getQueueableJobs();
        new MicrosoftGraphLifecycleScheduler().execute(null);

        System.assertEquals(jobsBefore + 2, Limits.getQueueableJobs(), 'Assertion failed in MicrosoftGraphLifecycleSchedulerTest at source line 20');
    }
}