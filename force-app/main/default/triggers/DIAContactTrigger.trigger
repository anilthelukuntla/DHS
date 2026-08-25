trigger DIAContactTrigger on DIA_Contact__c (before insert) {
    for(DIA_Contact__c con: Trigger.New){
        if(con.Manifest__c == Null){
        	con.Manifest__c = system.today();    
        }    
    }
}