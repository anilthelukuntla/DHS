/** Retains the existing DHSScheduleWorkload integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc,PMD.ApexSharingViolations,PMD.AvoidGlobalModifier')
global class DHSScheduleWorkload implements Schedulable{
	global void execute(SchedulableContext ctx) {
        database.executeBatch(New DHSWorkloadBatch(),100);
    }
}
