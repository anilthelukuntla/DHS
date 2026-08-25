/**
 * @description Retains the existing DHSScheduleCreateTimesheetsBatch integration and application behavior.
 */
@SuppressWarnings('PMD.ApexSharingViolations,PMD.AvoidGlobalModifier')
global class DHSScheduleCreateTimesheetsBatch implements Schedulable {
    /**
     * @description Provides this DHS API member.
     * @param ctx Method parameter.
     */
    global void execute(SchedulableContext ctx) {
        //Implement any logic to be scheduled
        DHSCreateTimesheetsBatch ctrl = new DHSCreateTimesheetsBatch();
        //Parameters of ExecuteBatch(context, BatchSize)
        Database.executeBatch(ctrl, 10);
    }
    
}