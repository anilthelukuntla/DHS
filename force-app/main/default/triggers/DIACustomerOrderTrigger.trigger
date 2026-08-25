trigger DIACustomerOrderTrigger on DIA_Customer_Order__c (before insert,after update) {
    if(trigger.isUpdate && trigger.isAfter){
    	list<string> orderIds = new list<string>();
        map<string,DIA_Customer_Order__c> orderMap = new map<string,DIA_Customer_Order__c>();
        for(DIA_Customer_Order__c diaOrder: Trigger.New){
            if(diaOrder.acd_date__c != Null && diaOrder.acd_date__c != trigger.oldMap.get(diaorder.id).acd_Date__c){
            	orderIds.add(diaOrder.id);  
                orderMap.put(diaOrder.id,diaorder);
            }   
        }
        if(!orderIds.isEmpty()){
            map<string,date> caseIdnACDDateMap = new map<string,date>();
        	map<string,dia_case__c> casesMap = new map<string,dia_case__c>([select id, Order__c from dia_case__c  where Order__c in :orderIds]);
            for(string caseID: casesMap.keyset()){
            	caseIdnACDDateMap.put(caseId, orderMap.get(casesMap.get(caseId).Order__c).acd_Date__c);    
            }
            list<dia_lead__c> leadsToUpdate = new list<dia_lead__c>();
            leadsToUpdate = [select id, Anticipated_Completion_Date__c ,case__c from dia_lead__c where Anticipated_Completion_Date__c = Null and case__c IN:casesMap.keyset()];
            for(dia_lead__c dl: leadsToUpdate){
             	dl.Anticipated_Completion_Date__c  =  caseIdnACDDateMap.get(dl.case__c);  
            }
            if(!leadsToUpdate.isEmpty()){
                update leadsToUpdate;
            }
        }
    }	
}