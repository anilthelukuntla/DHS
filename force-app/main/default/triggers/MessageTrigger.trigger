trigger MessageTrigger on Message__c (before insert, before update) { // NOPMD
    for(Message__c msg: Trigger.New){
        if(msg.message_body__c != Null){
            msg.message_body__c = msg.message_body__c.replaceAll('<o:p>','');
            msg.message_body__c = msg.message_body__c.replaceAll('</o:p>','');
        }
    }
}