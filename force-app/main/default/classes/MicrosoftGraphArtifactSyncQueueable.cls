public without sharing class MicrosoftGraphArtifactSyncQueueable
    implements Queueable, Database.AllowsCallouts {

    private final Id scheduleId;

    public MicrosoftGraphArtifactSyncQueueable(Id scheduleId) {
        this.scheduleId = scheduleId;
    }

    public void execute(QueueableContext context) {
        MicrosoftGraphLifecycleService.syncArtifactsForMeeting(
            scheduleId
        );
    }
}