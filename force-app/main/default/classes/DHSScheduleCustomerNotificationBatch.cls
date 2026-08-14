/** Retains the existing DHSScheduleCustomerNotificationBatch integration and application behavior. */
@SuppressWarnings('PMD.ApexSharingViolations, PMD.AvoidGlobalModifier, PMD.ApexDoc')
global class DHSScheduleCustomerNotificationBatch implements Schedulable {
	global void execute(SchedulableContext ctx) {
        DHSCustomerNotificationBatch ctrl = new DHSCustomerNotificationBatch();
	        Database.executeBatch(ctrl);
    }
}