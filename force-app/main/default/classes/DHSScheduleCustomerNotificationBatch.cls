/** Retains the existing DHSScheduleCustomerNotificationBatch integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc,PMD.ApexSharingViolations,PMD.AvoidGlobalModifier')
global class DHSScheduleCustomerNotificationBatch implements Schedulable {
	global void execute(SchedulableContext ctx) {
        DHSCustomerNotificationBatch ctrl = new DHSCustomerNotificationBatch();
	        Database.executeBatch(ctrl);
    }
}
