/** Retains the existing DHSScheduleBIManifest integration and application behavior. */
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ApexDoc')
global class DHSScheduleBIManifest implements Schedulable {
    global void execute(SchedulableContext ctx) {
        BIManifest manifest = new BIManifest();
        manifest.regenerateManifest();
    }
}