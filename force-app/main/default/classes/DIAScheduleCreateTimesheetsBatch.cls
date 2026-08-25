global with sharing class DIAScheduleCreateTimesheetsBatch implements Schedulable {
    global void execute(SchedulableContext ctx) {
        //Implement any logic to be scheduled
        DIACreateTimesheetsBatch ctrl = new DIACreateTimesheetsBatch();
        //Parameters of ExecuteBatch(context, BatchSize)
        Id batchId = Database.executeBatch(ctrl, 10);
    }
    
}