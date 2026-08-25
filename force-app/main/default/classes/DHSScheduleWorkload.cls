/**
 * @description Retains the existing DHSScheduleWorkload integration and application behavior.
 */
@SuppressWarnings('PMD.ApexSharingViolations,PMD.AvoidGlobalModifier')
global class DHSScheduleWorkload implements Schedulable{
	/**
	 * @description Provides this DHS API member.
	 * @param ctx Method parameter.
	 */
	global void execute(SchedulableContext ctx) {
        database.executeBatch(New DHSWorkloadBatch(),100);
    }
}