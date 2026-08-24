/** Retains the existing DHSExportRecordsBatch integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc,PMD.AvoidGlobalModifier,PMD.EmptyStatementBlock')
global class DHSExportRecordsBatch implements Database.Batchable<sObject>,Database.Stateful {
	global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Name FROM Account');
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope) {
        // process each batch of records
        // Can give callout request
    }

    global void finish(Database.BatchableContext bc) {
        // execute any post-processing operations - send emails, notify clients,
        // give a call to another batch class
        // Can give to another batch class
        // Can give callout request
    }
}
