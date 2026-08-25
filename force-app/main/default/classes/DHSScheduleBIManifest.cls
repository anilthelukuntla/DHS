/**
 * @description Retains the existing DHSScheduleBIManifest integration and application behavior.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class DHSScheduleBIManifest implements Schedulable {
    /**
     * @description Provides this DHS API member.
     * @param ctx Method parameter.
     */
    global void execute(SchedulableContext ctx) {
        BIManifest manifest = new BIManifest();
        manifest.regenerateManifest();
    }
}