global class WorkloadBatch implements Database.Stateful,Database.Batchable<sObject>{
    public Map<Id,Map<string,integer>> workload;
    global Database.QueryLocator start(Database.BatchableContext BC) {
        workload = New Map<Id,Map<string,integer>>();
        List<string> statusFilter = New List<string>{'Assigned Not Accepted','In-Progress','QA Rejected'};
        string query = 'select id,Status__c,Leadtype__c,Assigned_To__c from Lead__c where Status__c IN : statusFilter';
        return Database.getQueryLocator(query); 
    }
    global void execute(Database.BatchableContext BC, List<Lead__c> Leads) {
        for(Lead__c lead : Leads){
            if(lead.Assigned_To__c != null){
                if(!workload.containsKey(lead.Assigned_To__c)) workload.put(lead.Assigned_To__c,New Map<string,integer>()); 
                if(lead.Status__c == 'Assigned Not Accepted'){
                    Map<string,integer> load = workload.get(lead.Assigned_To__c);
                    if(!load.containsKey('AssignedNotAccepted')) load.put('AssignedNotAccepted',0);
					integer count = load.get('AssignedNotAccepted');
					count = count + 1;
					load.put('AssignedNotAccepted',count);
					workload.put(lead.Assigned_To__c,load);
                }
                if(lead.Status__c == 'In-Progress'){
                    Map<string,integer> load = workload.get(lead.Assigned_To__c);
                    if(!load.containsKey('InProgress')) load.put('InProgress',0);
					integer count = load.get('InProgress');
					count = count + 1;
					load.put('InProgress',count);
					workload.put(lead.Assigned_To__c,load);
                }
                if(lead.Status__c == 'In-Progress' & lead.LeadType__c == 'Subject Interview (ESI/TESI)'){
                    Map<string,integer> load = workload.get(lead.Assigned_To__c);
                    if(!load.containsKey('InProgressESI')) load.put('InProgressESI',0);
					integer count = load.get('InProgressESI');
					count = count + 1;
					load.put('InProgressESI',count);
					workload.put(lead.Assigned_To__c,load);
                }
                if(lead.Status__c == 'QA Rejected'){
                    Map<string,integer> load = workload.get(lead.Assigned_To__c);
                    if(!load.containsKey('QARejected')) load.put('QARejected',0);
					integer count = load.get('QARejected');
					count = count + 1;
					load.put('QARejected',count);
					workload.put(lead.Assigned_To__c,load);
                }
            }
        }
    }
    global void finish(Database.BatchableContext BC) {
        system.debug('workload...Invs...'+workload.Keyset());
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
            wl.Type_of_Assignee__c = 'INV';
            wl.Items_Assigned_Not_Accepted__c = load.containsKey('AssignedNotAccepted') ? load.get('AssignedNotAccepted') : 0;
			wl.Items_In_Progress__c = load.containsKey('InProgress') ? load.get('InProgress') : 0;
			wl.ESI_Items_In_Progress__c = load.containsKey('InProgressESI') ? load.get('InProgressESI') : 0;
			wl.Items_QA_Rejected__c = load.containsKey('QARejected') ? load.get('QARejected') : 0;
			wl.User__c = inv;
			wlToUpsert.add(wl);
        }
        		upsert wlToUpsert;
        
        List<Workload__c> wloadsCleanUp = [select id,User__c from Workload__c where Type_of_Assignee__c = 'INV'];
        for(Workload__c wl : wloadsCleanUp){
            if(!workload.containsKey(wl.User__c)){
                wlToDelete.add(wl);
            }
        }
        	delete wlToDelete;
    }
}