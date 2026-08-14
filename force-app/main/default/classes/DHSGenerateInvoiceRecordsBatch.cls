/** Retains the existing DHSGenerateInvoiceRecordsBatch integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc, PMD.FormalParameterNamingConventions, PMD.EmptyStatementBlock')
public class DHSGenerateInvoiceRecordsBatch implements Database.Stateful,Database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext BC) {
        List<string> leadFields = new List<string>();
        leadFields = DHSApexUtil.FetchFields('DHS_Lead__c');
        string completeStatus = 'Completed';
        List<String> candidateType = new List<String>{'Employee','SCA','Non-SCA'};
        String query = 'Select '+string.join(leadFields, ',') + ' From DHS_Lead__c where Status__c =: completeStatus and DHS_Assigned_To__r.Candidate_type__c IN (\'' +String.join(candidateType, '\',\'') +'\')';
        return database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<DHS_Lead__c> leads) {
        Map<Id,string> paychexIdMap = DHSLeadTriggerHandler.getPaychexIds(leads);
        List<DHS_Invoice__c> createInvoices = new List<DHS_Invoice__c>();
        for(DHS_Lead__c l : leads){
            createInvoices.add(DHSLeadTriggerHandler.generateInvoices(l,paychexIdMap.get(l.DHS_Assigned_To__c)));
        }
        insert createInvoices;
    }
    public void finish(Database.BatchableContext BC) {
        
    }
}