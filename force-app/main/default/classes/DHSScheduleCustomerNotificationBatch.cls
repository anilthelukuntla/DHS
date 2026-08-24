/**
 * @description Retains the existing DHSScheduleCustomerNotificationBatch integration and application behavior.
 */
@SuppressWarnings('PMD.ApexSharingViolations,PMD.AvoidGlobalModifier')
global class DHSScheduleCustomerNotificationBatch implements Schedulable {
	/**
	 * @description Provides this DHS API member.
	 * @param ctx Method parameter.
	 */
	global void execute(SchedulableContext ctx) {
        DHSCustomerNotificationBatch ctrl = new DHSCustomerNotificationBatch();
	        Database.executeBatch(ctrl);
    }
}
