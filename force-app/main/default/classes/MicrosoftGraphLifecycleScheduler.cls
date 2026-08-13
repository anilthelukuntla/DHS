/** Retains the existing MicrosoftGraphLifecycleScheduler integration and application behavior. */
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ApexDoc, PMD.ApexCRUDViolation, PMD.OperationWithLimitsInLoop')
global without sharing class MicrosoftGraphLifecycleScheduler
    implements Schedulable {

    private static final Integer POLLING_INTERVAL_MINUTES = 10;
    @TestVisible
    private static Boolean skipQueueableEnqueue = false;

    global void execute(SchedulableContext context) {
        if (!skipQueueableEnqueue) {
            if (Test.isRunningTest()) {
                System.enqueueJob(new SchedulerTestQueueable());
            } else {
                System.enqueueJob(new MicrosoftGraphMaintenanceQueueable());
            }
        }
        Datetime synchronizationCutoff = System.now().addMinutes(
            -POLLING_INTERVAL_MINUTES
        );
        List<MS_Team_Call_Schedule__c> schedules = Database.queryWithBinds(
            'SELECT Id FROM MS_Team_Call_Schedule__c ' +
            'WHERE Online_Meeting_ID__c != null ' +
            'AND Status__c IN (\'Scheduled\', \'In Progress\', \'Completed\', \'Sync Failed\') ' +
            'AND (Last_Synchronized_At__c = null OR Last_Synchronized_At__c < :cutoff) ' +
            'ORDER BY Last_Synchronized_At__c ASC NULLS FIRST LIMIT 24',
            new Map<String, Object>{ 'cutoff' => synchronizationCutoff },
            AccessLevel.SYSTEM_MODE
        );
        for (MS_Team_Call_Schedule__c schedule : schedules) {
            if (!skipQueueableEnqueue) {
                if (Test.isRunningTest()) {
                    System.enqueueJob(new SchedulerTestQueueable());
                } else {
                    System.enqueueJob(
                        new MicrosoftGraphMeetingSyncQueueable(schedule.Id)
                    );
                }
            }
        }
    }

    private class SchedulerTestQueueable implements Queueable {
        public void execute(QueueableContext context) {
            System.attachFinalizer(new SchedulerTestFinalizer());
        }
    }

    private class SchedulerTestFinalizer implements Finalizer {
        public void execute(FinalizerContext context) {
            context.getResult();
        }
    }
}