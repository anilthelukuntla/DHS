/** Schedules timesheet creation. */
@SuppressWarnings('PMD.ApexSharingViolations, PMD.AvoidGlobalModifier, PMD.ApexDoc')
global class ScheduleCreateTimesheetsBatch implements Schedulable {
    global void execute(SchedulableContext ctx) {
        //Implement any logic to be scheduled
        CreateTimesheetsBatch ctrl = new CreateTimesheetsBatch();
        //Parameters of ExecuteBatch(context, BatchSize)
        Database.executeBatch(ctrl, 10);
    }
    
}