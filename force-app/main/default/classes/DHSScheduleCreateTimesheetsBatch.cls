/** Retains the existing DHSScheduleCreateTimesheetsBatch integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc,PMD.ApexSharingViolations,PMD.AvoidGlobalModifier')
global class DHSScheduleCreateTimesheetsBatch implements Schedulable {
    global void execute(SchedulableContext ctx) {
        //Implement any logic to be scheduled
        DHSCreateTimesheetsBatch ctrl = new DHSCreateTimesheetsBatch();
        //Parameters of ExecuteBatch(context, BatchSize)
        Database.executeBatch(ctrl, 10);
    }
    
}
