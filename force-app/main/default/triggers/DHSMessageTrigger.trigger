trigger DHSMessageTrigger on DHS_Message__c (before insert, before update) { // NOPMD
    for(DHS_Message__c msg: Trigger.New){
        if(msg.Message_Body__c != Null){
            msg.Message_Body__c = msg.Message_Body__c.replaceAll('<o:p>','');
            msg.Message_Body__c = msg.Message_Body__c.replaceAll('</o:p>','');
        }
    }
}