public without sharing class MicrosoftGraphMeetingSyncQueueable
    implements Queueable, Database.AllowsCallouts {

    @TestVisible private static Boolean skipArtifactEnqueue = false;

    private final Id scheduleId;

    public MicrosoftGraphMeetingSyncQueueable(Id scheduleId) {
        this.scheduleId = scheduleId;
    }

    public void execute(QueueableContext context) {
        MicrosoftGraphLifecycleService.syncMeeting(scheduleId);
        if (!(Test.isRunningTest() && skipArtifactEnqueue)) {
            System.enqueueJob(
                new MicrosoftGraphArtifactSyncQueueable(scheduleId)
            );
        }
    }
}