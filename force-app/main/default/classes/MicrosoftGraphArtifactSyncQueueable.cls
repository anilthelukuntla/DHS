/** Retains the existing MicrosoftGraphArtifactSyncQueueable integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc')
public without sharing class MicrosoftGraphArtifactSyncQueueable
    implements Queueable, Database.AllowsCallouts {

    private final Id scheduleId;

    public MicrosoftGraphArtifactSyncQueueable(Id scheduleId) {
        this.scheduleId = scheduleId;
    }

    public void execute(QueueableContext context) {
        if (context != null) {
            System.attachFinalizer(new MicrosoftGraphNoOpFinalizer());
        }
        MicrosoftGraphLifecycleService.syncArtifactsForMeeting(
            scheduleId
        );
    }

    private class MicrosoftGraphNoOpFinalizer implements Finalizer {
        public void execute(FinalizerContext context) {
            context.getResult();
        }
    }
}