trigger DIAWaiverTrigger on DIA_Waiver_Information__c (before insert,after update, after insert) {
    if(trigger.isafter && trigger.isupdate){
        /*set<Id> leadIds = New set<Id>();
        for(DIA_Waiver_Information__c waiver : trigger.New){
            leadIds.add(waiver.Lead__c);
        }
        List<dia_lead__c> updateleads = New List<dia_lead__c>();
        List<dia_lead__c> leads = [select id,(select id,Waiver_Approved_Date__c,Waiver_Flagged_Date__c,Waiver_Initiated_Date__c from DIA_Waiver_Information__r order by createddate desc) from dia_lead__c where id IN: leadIds];
        for(dia_lead__c ld : leads){
            if(ld.DIA_Waiver_Information__r.size() > 0){
                DIA_Waiver_Information__c waiver = ld.DIA_Waiver_Information__r[0];
                ld.Waiver_Approved_Date__c = waiver.Waiver_Approved_Date__c;
                ld.Waiver_Flagged_Date__c = waiver.Waiver_Flagged_Date__c;
                ld.Waiver_Initiated_Date__c = waiver.Waiver_Initiated_Date__c;
                updateleads.add(ld);
            }
        }
        update updateleads;*/
        Map<Id,list<DIA_Waiver_Information__c>> caseNWaiverMap = New Map<Id,list<DIA_Waiver_Information__c>>();
        for(DIA_Waiver_Information__c waiver : trigger.New){
            if(waiver.Waiver_Approved_Date__c != trigger.oldmap.get(waiver.id).Waiver_Approved_Date__c){
                if(!caseNWaiverMap.containskey(waiver.Case__c))caseNWaiverMap.put(waiver.Case__c,New list<DIA_Waiver_Information__c>());
                caseNWaiverMap.get(waiver.Case__c).add(waiver);
            }
        }
        list<dia_case__c> updateCases = New list<dia_case__c>();
        list<dia_case__c> parentCases = [select id from dia_case__c where id IN: caseNWaiverMap.keyset()];
        for(dia_case__c parentCase : parentCases){
            list<DIA_Waiver_Information__c> modifiedWaivers = caseNWaiverMap.get(parentCase.Id);
            system.debug(modifiedWaivers);
            for(DIA_Waiver_Information__c modifiedWaiver : modifiedWaivers){
                if(modifiedWaiver.Type__c == 'Waiver'){
                    system.debug(modifiedWaiver.Waiver_Approved_Date__c);
                    parentCase.Waiver_Approved_Date__c = modifiedWaiver.Waiver_Approved_Date__c;
                    system.debug(parentCase.Waiver_Approved_Date__c);
                }else if(modifiedWaiver.Type__c == 'Extension'){
                    parentCase.Extension_Approved_Date__c = modifiedWaiver.Waiver_Approved_Date__c;
                }
            }
            		updateCases.add(parentCase);
        }
        if(!updateCases.isempty()){
            update updateCases;
        }
        
    }
    if(trigger.isafter && trigger.isinsert){
        set<Id> caseIds = New set<Id>();
        Map<Id,list<string>> caseIdNType = New Map<Id,list<string>>();
        for(DIA_Waiver_Information__c waiver : trigger.New){
            caseIds.add(waiver.case__c);
            if(!caseIdNType.containsKey(waiver.case__c)) caseIdNType.put(waiver.case__c,New list<string>());
                caseIdNType.get(waiver.case__c).add(waiver.type__c);
        }
        List<dia_case__c> updateCases = New List<dia_case__c>();
        List<dia_case__c> cases = [select id from dia_case__c where Id IN: caseIdNType.keyset()];
        for(dia_case__c dCase : cases){
            list<string> types = caseIdNType.get(dCase.Id);
            if(types.contains('Waiver')){
                dCase.ISP_requested_Waiver__c = 'Yes';
            }
            if(types.contains('Extension')){
                dCase.ISP_requested_Extension__c = 'Yes';
            }
            updateCases.add(dCase);
        }
        if(!updateCases.isEmpty()){
            update updateCases;
        }
    }
}