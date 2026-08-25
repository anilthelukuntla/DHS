global without sharing class MicrosoftGraphLifecycleScheduler
    implements Schedulable {

    private static final Integer POLLING_INTERVAL_MINUTES = 10;
    @TestVisible
    private static Boolean skipQueueableEnqueue = false;

    global void execute(SchedulableContext context) {
        if (!skipQueueableEnqueue) {
            System.enqueueJob(new MicrosoftGraphMaintenanceQueueable());
        }
        for (MS_Team_Call_Schedule__c schedule : [
            SELECT Id
            FROM MS_Team_Call_Schedule__c
            WHERE Online_Meeting_ID__c != null
              AND Status__c IN (
                  'Scheduled',
                  'In Progress',
                  'Completed',
                  'Sync Failed'
              )
              AND (
                  Last_Synchronized_At__c = null
                  OR Last_Synchronized_At__c <
                      :System.now().addMinutes(
                          -POLLING_INTERVAL_MINUTES
                      )
              )
            ORDER BY Last_Synchronized_At__c ASC NULLS FIRST
            LIMIT 24
        ]) {
            if (!skipQueueableEnqueue) {
                System.enqueueJob(
                    new MicrosoftGraphMeetingSyncQueueable(schedule.Id)
                );
            }
        }
    }
}