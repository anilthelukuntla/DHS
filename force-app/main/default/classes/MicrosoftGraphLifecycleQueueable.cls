public without sharing class MicrosoftGraphLifecycleQueueable
    implements Queueable, Database.AllowsCallouts {

    private final String notificationJson;

    public MicrosoftGraphLifecycleQueueable(String notificationJson) {
        this.notificationJson = notificationJson;
    }

    public void execute(QueueableContext context) {
        MicrosoftGraphLifecycleService.processNotification(
            notificationJson
        );
    }
}