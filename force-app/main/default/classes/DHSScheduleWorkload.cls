/** Retains the existing DHSScheduleWorkload integration and application behavior. */
@SuppressWarnings('PMD.ApexSharingViolations, PMD.AvoidGlobalModifier, PMD.ApexDoc')
global class DHSScheduleWorkload implements Schedulable{
	global void execute(SchedulableContext ctx) {
        database.executeBatch(New DHSWorkloadBatch(),100);
    }
}