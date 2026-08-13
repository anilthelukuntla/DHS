/** Schedules CMO workload processing. */
@SuppressWarnings('PMD.ApexSharingViolations, PMD.AvoidGlobalModifier, PMD.ApexDoc')
global class ScheduleCMOWorkload implements Schedulable{
	global void execute(SchedulableContext ctx) {
        database.executeBatch(New WorkloadCMOBatch(),100);
    }
}