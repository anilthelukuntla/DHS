/** Retains the existing GenerateInvoiceRecordsBatch integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc, PMD.FormalParameterNamingConventions, PMD.EmptyStatementBlock')
public class GenerateInvoiceRecordsBatch implements Database.Stateful,Database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext BC) {
        List<string> leadFields = new List<string>();
        leadFields = ApexUtil.FetchFields('Lead__c');
        string completeStatus = 'Completed';
        String query = 'Select '+string.join(leadFields, ',') + ' From Lead__c where status__c =: completeStatus';
        return database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<Lead__c> leads) {
        List<Invoice__c> createInvoices = new List<Invoice__c>();
        for(Lead__c l : leads){
            createInvoices.add(LeadTriggerHandler.generateInvoices(l));
        }
        insert createInvoices;
    }
    public void finish(Database.BatchableContext BC) {
        
    }
}