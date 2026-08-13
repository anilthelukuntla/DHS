/** Retains the existing MicrosoftGraphMeetingSyncQueueable integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc')
public without sharing class MicrosoftGraphMeetingSyncQueueable
    implements Queueable, Database.AllowsCallouts {

    @TestVisible private static Boolean skipArtifactEnqueue = false;

    private final Id scheduleId;

    public MicrosoftGraphMeetingSyncQueueable(Id scheduleId) {
        this.scheduleId = scheduleId;
    }

    public void execute(QueueableContext context) {
        if (context != null) {
            System.attachFinalizer(new MicrosoftGraphNoOpFinalizer());
        }
        MicrosoftGraphLifecycleService.syncMeeting(scheduleId);
        if (!(Test.isRunningTest() && skipArtifactEnqueue)) {
            System.enqueueJob(
                new MicrosoftGraphArtifactSyncQueueable(scheduleId)
            );
        }
    }

    private class MicrosoftGraphNoOpFinalizer implements Finalizer {
        public void execute(FinalizerContext context) {
            context.getResult();
        }
    }
}