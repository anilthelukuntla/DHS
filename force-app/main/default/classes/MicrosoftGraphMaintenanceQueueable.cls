/** Retains the existing MicrosoftGraphMaintenanceQueueable integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc')
public without sharing class MicrosoftGraphMaintenanceQueueable
    implements Queueable, Database.AllowsCallouts {

    public void execute(QueueableContext context) {
        if (context != null) {
            System.attachFinalizer(new MicrosoftGraphNoOpFinalizer());
        }
        MicrosoftGraphSubscriptionService.renewExpiringSubscriptions();
    }

    private class MicrosoftGraphNoOpFinalizer implements Finalizer {
        public void execute(FinalizerContext context) {
            context.getResult();
        }
    }
}