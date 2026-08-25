global class ScheduleCMOWorkload implements Schedulable{
	global void execute(SchedulableContext ctx) {
        database.executeBatch(New WorkloadCMOBatch(),100);
    }
}