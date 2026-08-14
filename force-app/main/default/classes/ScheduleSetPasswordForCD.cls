/** Schedules customer-deliverable password processing. */
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ApexDoc')
global class ScheduleSetPasswordForCD implements Schedulable {
    global void execute(SchedulableContext ctx) {
        SetPasswordForCD.setPassword();
    }
}