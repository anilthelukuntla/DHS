global class ScheduleCreateTimesheetsBatch implements Schedulable {
    global void execute(SchedulableContext ctx) {
        //Implement any logic to be scheduled
        CreateTimesheetsBatch ctrl = new CreateTimesheetsBatch();
        //Parameters of ExecuteBatch(context, BatchSize)
        Id batchId = Database.executeBatch(ctrl, 10);
    }
    
}