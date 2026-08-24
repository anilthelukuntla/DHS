/** Retains the existing DHSWorkloadBatch integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc,PMD.AvoidGlobalModifier,PMD.AvoidNonRestrictiveQueries,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity')
global class DHSWorkloadBatch implements Database.Stateful,Database.Batchable<sObject>{
    public Map<Id,Map<string,integer>> workload;
    global Database.QueryLocator start(Database.BatchableContext bC) {
        workload = New Map<Id,Map<string,integer>>();
        List<string> statusFilter = New List<string>{'Assigned Not Accepted','In-Progress','QA Rejected'};
        string query = 'select id,Status__c,LeadType__c,DHS_Assigned_To__c from DHS_Lead__c where Status__c IN : statusFilter';
        return Database.getQueryLocator(query); 
    }
    global void execute(Database.BatchableContext bC, List<DHS_Lead__c> leads) {
        for(DHS_Lead__c lead : leads){
            if(lead.DHS_Assigned_To__c != null){
                if(lead.Status__c == 'Assigned Not Accepted'){
                    incrementLoad(lead.DHS_Assigned_To__c, 'AssignedNotAccepted');
                }
                if(lead.Status__c == 'In-Progress'){
                    incrementLoad(lead.DHS_Assigned_To__c, 'InProgress');
                }
                if(lead.LeadType__c == 'Subject Interview (ESI/TESI)'){
                    incrementLoad(lead.DHS_Assigned_To__c, 'InProgressESI');
                }
                if(lead.Status__c == 'QA Rejected'){
                    incrementLoad(lead.DHS_Assigned_To__c, 'QARejected');
                }
            }
        }
    }
    private void incrementLoad(Id assigneeId, String key) {
        if(!workload.containsKey(assigneeId)) {
            workload.put(assigneeId,New Map<string,integer>());
        }
        Map<string,integer> load = workload.get(assigneeId);
        if(!load.containsKey(key)) {
            load.put(key,0);
        }
        load.put(key, load.get(key) + 1);
        workload.put(assigneeId,load);
    }
    global void finish(Database.BatchableContext bC) {
        Map<Id,DHS_Workload__c> existingInvWork = New Map<Id,DHS_Workload__c>();
        List<DHS_Workload__c> wloads = [select id,DHS_User__c from DHS_Workload__c];
        for(DHS_Workload__c wl : wloads){
            existingInvWork.put(wl.DHS_User__c,wl);
        }
        List<DHS_Workload__c> wlToUpsert = New List<DHS_Workload__c>();
        List<DHS_Workload__c> wlToDelete = New List<DHS_Workload__c>();
        for(Id inv : workload.Keyset()){
            Map<string,integer> load = workload.get(inv);
            DHS_Workload__c wl = New DHS_Workload__c();
            if(existingInvWork.containsKey(inv)){
                wl = existingInvWork.get(inv);
            }
            wl.Items_Assigned_Not_Accepted__c = load.containsKey('AssignedNotAccepted') ? load.get('AssignedNotAccepted') : 0;
			wl.Items_In_Progress__c = load.containsKey('InProgress') ? load.get('InProgress') : 0;
			wl.ESI_Items_In_Progress__c = load.containsKey('InProgressESI') ? load.get('InProgressESI') : 0;
			wl.Items_QA_Rejected__c = load.containsKey('QARejected') ? load.get('QARejected') : 0;
			wl.DHS_User__c = inv;
			wlToUpsert.add(wl);
        }
        		upsert wlToUpsert;
        
        List<DHS_Workload__c> wloadsCleanUp = [select id,DHS_User__c from DHS_Workload__c];
        for(DHS_Workload__c wl : wloadsCleanUp){
            if(!workload.containsKey(wl.DHS_User__c)){
                wlToDelete.add(wl);
            }
        }
        	delete wlToDelete;
    }
}
