/** Retains the existing WorkloadCMOBatch integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc, PMD.AvoidGlobalModifier, PMD.AvoidNonRestrictiveQueries, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.DebugsShouldUseLoggingLevel, PMD.FormalParameterNamingConventions, PMD.IfElseStmtsMustUseBraces, PMD.IfStmtsMustUseBraces, PMD.StdCyclomaticComplexity')
global class WorkloadCMOBatch implements Database.Stateful,Database.Batchable<sObject>{
	public Map<Id,Map<string,integer>> workload;
    global Database.QueryLocator start(Database.BatchableContext BC) {
        workload = New Map<Id,Map<string,integer>>();
        List<string> statusFilter = New List<string>{'Assigned Not Accepted','In-Progress','QA Rejected'};
        string query = 'select id,Status__c,Leadtype__c,Assigned_To__c,case__r.Assigned_To__c from Lead__c where Status__c IN : statusFilter';
        return Database.getQueryLocator(query); 
    }
    global void execute(Database.BatchableContext BC, List<Lead__c> Leads) {
        for(Lead__c lead : Leads){
            if(lead.case__r.Assigned_To__c != null){
                if(lead.Status__c == 'Assigned Not Accepted'){
                    incrementLoad(lead.case__r.Assigned_To__c, 'AssignedNotAccepted');
                }
                if(lead.Status__c == 'In-Progress'){
                    incrementLoad(lead.case__r.Assigned_To__c, 'InProgress');
                }
                if(lead.Status__c == 'In-Progress' & lead.LeadType__c == 'Subject Interview (ESI/TESI)'){
                    incrementLoad(lead.case__r.Assigned_To__c, 'InProgressESI');
                }
                if(lead.Status__c == 'QA Rejected'){
                    incrementLoad(lead.case__r.Assigned_To__c, 'QARejected');
                }
            }
        }
    }
    private void incrementLoad(Id assigneeId, String key) {
        if(!workload.containsKey(assigneeId)) workload.put(assigneeId,New Map<string,integer>());
        Map<string,integer> load = workload.get(assigneeId);
        if(!load.containsKey(key)) load.put(key,0);
        load.put(key, load.get(key) + 1);
        workload.put(assigneeId,load);
    }
    global void finish(Database.BatchableContext BC) {
        Map<Id,Workload__c> existingInvWork = New Map<Id,Workload__c>();
        List<Workload__c> wloads = [select id,User__c from Workload__c];
        for(Workload__c wl : wloads){
            existingInvWork.put(wl.User__c,wl);
        }
        List<Workload__c> wlToUpsert = New List<Workload__c>();
        List<Workload__c> wlToDelete = New List<Workload__c>();
        for(Id inv : workload.Keyset()){
            Map<string,integer> load = workload.get(inv);
            Workload__c wl = New Workload__c();
            if(existingInvWork.containsKey(inv)){
                wl = existingInvWork.get(inv);
            }
            wl.Type_of_Assignee__c = 'CMO';
            wl.Items_Assigned_Not_Accepted__c = load.containsKey('AssignedNotAccepted') ? load.get('AssignedNotAccepted') : 0;
			wl.Items_In_Progress__c = load.containsKey('InProgress') ? load.get('InProgress') : 0;
			wl.ESI_Items_In_Progress__c = load.containsKey('InProgressESI') ? load.get('InProgressESI') : 0;
			wl.Items_QA_Rejected__c = load.containsKey('QARejected') ? load.get('QARejected') : 0;
			wl.User__c = inv;
			wlToUpsert.add(wl);
        }
        		upsert wlToUpsert;
        
        List<Workload__c> wloadsCleanUp = [select id,User__c from Workload__c where Type_of_Assignee__c = 'CMO'];
        for(Workload__c wl : wloadsCleanUp){
            if(!workload.containsKey(wl.User__c)){
                wlToDelete.add(wl);
            }
        }
        	delete wlToDelete;
    }
}