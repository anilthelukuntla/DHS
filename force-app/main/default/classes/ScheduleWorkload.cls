/** Schedules workload processing. */
@SuppressWarnings('PMD.ApexSharingViolations, PMD.AvoidGlobalModifier, PMD.ApexDoc')
global class ScheduleWorkload implements Schedulable{
	global void execute(SchedulableContext ctx) {
        database.executeBatch(New WorkloadBatch(),100);
    }
}