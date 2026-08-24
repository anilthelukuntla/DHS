/**
 * @description Retains the existing DHSExportRecordsBatch integration and application behavior.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.EmptyStatementBlock')
global class DHSExportRecordsBatch implements Database.Batchable<sObject>,Database.Stateful {
	/**
	 * @description Provides this DHS API member.
	 * @param bc Method parameter.
	 * @return The requested result.
	 */
	global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Name FROM Account');
    }

    /**
     * @description Provides this DHS API member.
     * @param bc Method parameter.
     * @param scope Method parameter.
     */
    global void execute(Database.BatchableContext bc, List<sObject> scope) {
        // process each batch of records
        // Can give callout request
    }

    /**
     * @description Provides this DHS API member.
     * @param bc Method parameter.
     */
    global void finish(Database.BatchableContext bc) {
        // execute any post-processing operations - send emails, notify clients,
        // give a call to another batch class
        // Can give to another batch class
        // Can give callout request
    }
}
