/** Schedules the BI manifest process. */
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ApexDoc')
global class ScheduleBIManifest implements Schedulable {
    global void execute(SchedulableContext ctx) {
        BIManifest manifest = new BIManifest();
        manifest.regenerateManifest();
    }
}