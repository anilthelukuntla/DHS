/** Retains the existing DHSScheduleBIManifest integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc,PMD.AvoidGlobalModifier')
global class DHSScheduleBIManifest implements Schedulable {
    global void execute(SchedulableContext ctx) {
        BIManifest manifest = new BIManifest();
        manifest.regenerateManifest();
    }
}
