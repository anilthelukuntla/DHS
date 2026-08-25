public without sharing class MicrosoftGraphMaintenanceQueueable
    implements Queueable, Database.AllowsCallouts {

    public void execute(QueueableContext context) {
        MicrosoftGraphSubscriptionService.renewExpiringSubscriptions();
    }
}