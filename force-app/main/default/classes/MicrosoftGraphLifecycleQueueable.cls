/** Retains the existing MicrosoftGraphLifecycleQueueable integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc')
public without sharing class MicrosoftGraphLifecycleQueueable
    implements Queueable, Database.AllowsCallouts {

    private final String notificationJson;

    public MicrosoftGraphLifecycleQueueable(String notificationJson) {
        this.notificationJson = notificationJson;
    }

    public void execute(QueueableContext context) {
        if (context != null) {
            System.attachFinalizer(new MicrosoftGraphNoOpFinalizer());
        }
        MicrosoftGraphLifecycleService.processNotification(
            notificationJson
        );
    }

    private class MicrosoftGraphNoOpFinalizer implements Finalizer {
        public void execute(FinalizerContext context) {
            context.getResult();
        }
    }
}