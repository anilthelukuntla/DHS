/**
 * @description Retains the existing DHSGenerateInvoiceRecordsBatch integration and application behavior.
 */
@SuppressWarnings('PMD.EmptyStatementBlock')
public class DHSGenerateInvoiceRecordsBatch implements Database.Stateful,Database.Batchable<sObject>{
    /**
     * @description Provides this DHS API member.
     * @param bC Method parameter.
     * @return The requested result.
     */
    public Database.QueryLocator start(Database.BatchableContext bC) {
        List<string> leadFields = new List<string>();
        leadFields = DHSApexUtil.FetchFields('DHS_Lead__c');
        string completeStatus = 'Completed';
        List<String> candidateType = new List<String>{'Employee','SCA','Non-SCA'};
        String query = 'Select '+string.join(leadFields, ',') + ' From DHS_Lead__c where Status__c =: completeStatus and DHS_Assigned_To__r.Candidate_type__c IN (\'' +String.join(candidateType, '\',\'') +'\')';
        return database.getQueryLocator(query);
    }
    /**
     * @description Provides this DHS API member.
     * @param bC Method parameter.
     * @param leads Method parameter.
     */
    public void execute(Database.BatchableContext bC, List<DHS_Lead__c> leads) {
        Map<Id,string> paychexIdMap = DHSLeadTriggerHandler.getPaychexIds(leads);
        List<DHS_Invoice__c> createInvoices = new List<DHS_Invoice__c>();
        for(DHS_Lead__c l : leads){
            createInvoices.add(DHSLeadTriggerHandler.generateInvoices(l,paychexIdMap.get(l.DHS_Assigned_To__c)));
        }
        Database.insert(createInvoices, AccessLevel.USER_MODE);
    }
    /**
     * @description Provides this DHS API member.
     * @param bC Method parameter.
     */
    public void finish(Database.BatchableContext bC) {
        
    }
}