trigger DIAMessageTrigger on DIA_Message__c (before insert, before update) {
    if(trigger.isbefore ){
        if(trigger.isInsert || trigger.isupdate){
            for(DIA_Message__c msg: Trigger.New){
                if(msg.message_body__c != Null){
                    msg.message_body__c = msg.message_body__c.replaceAll('<o:p>','');
                    msg.message_body__c = msg.message_body__c.replaceAll('</o:p>','');
                }
            }
		}
    }
    /*
    if(trigger.isAfter && trigger.isInsert){
        set<Id> msgIds = New set<Id>();
        for(DIA_Message__c msg: Trigger.New){
            msgIds.add(msg.Id);
        }
        List<DIA_Message__c> msgs = [select id,To_Address_Type__c from dia_message__c where Id IN: msgIds];
        for(DIA_Message__c msg: Trigger.New){
            list<string> toAddressList = New List<string>();
            if(string.isNotBlank(msg.To_Address_Type__c )){
                string selecteToAddressOption = msg.To_Address_Type__c;
                list<User> toUsers = New List<User>();
                if(selecteToAddressOption == 'All PMOs'){
                    toUsers = [Select Id, Email,system_access__c, User_Type__c,contact.email from User where User_Type__c = 'PMO'];
                    for(User u: toUsers){
                        if(u.contact != null){
                            if(u.contact.email != userinfo.getuseremail()){
                                if(u.system_access__c.contains('DIA')){
                                    if(!toAddressList.contains(u.contact.email)) toAddressList.add(u.contact.email);
                                }
                            } 
                        }
                            
                    }
                }
                if(selecteToAddressOption == 'All Program Members'){
                    toUsers = [Select Id, Email,system_access__c, User_Type__c,contact.email from User where (User_Type__c = 'PMO' OR User_Type__c = 'CMO' OR User_Type__c = 'INV' OR User_Type__c = 'QA')];
                    for(User u: toUsers){
                        if(u.contact.email != userinfo.getuseremail()){
                            if(u.system_access__c.contains('DIA')){
                            	if(!toAddressList.contains(u.contact.email)) toAddressList.add(u.contact.email);
                            }
                        }     
                    }
                }
                if(selecteToAddressOption == 'All CMOs'){
                    toUsers = [Select Id, Email,system_access__c, User_Type__c,contact.email from User where User_Type__c = 'CMO'];
                    for(User u: toUsers){
                        if(u.system_access__c.contains('DIA')){
                        if(u.contact.email != userinfo.getuseremail()){
                            if(!toAddressList.contains(u.contact.email)) toAddressList.add(u.contact.email);
                        }     
                        }
                    }
                }
                if(selecteToAddressOption == 'All Investigators'){
                    toUsers = [Select Id, Email,system_access__c, User_Type__c,contact.email from User where User_Type__c = 'INV'];
                    system.debug(toUsers);
                    for(User u: toUsers){
                        if(u.system_access__c.contains('DIA')){
                            if(!toAddressList.contains(u.contact.email)) toAddressList.add(u.contact.email);
                        }
                    }
                }
                if(selecteToAddressOption == 'All QAs'){
                    toUsers = [Select Id, Email,system_access__c, User_Type__c,contact.email from User where User_Type__c = 'QA'];
                    for(User u: toUsers){
                        if(!toAddressList.contains(u.contact.email)) toAddressList.add(u.contact.email);
                    }
                }
			}
            system.debug('Users To Send...'+toAddressList);
            toAddressList = New list<string>{'athelukuntla@isncorp.com'};
                system.debug('Users To Send...'+toAddressList);
            string htmlBody = 'Dear Member,<br/><br/>A new message has been issued by the program’s office. Please log in to the case management system to retrieve.<br/><br/>Thanks,<br/>ISN Corporation';
			//MailUtilities.sendHTMLEmail(toAddressList,'BI Program Notification',htmlBody,null);
			MailUtilities.sendBIEmail('Test',htmlBody,toAddressList,string.valueOf(system.label.AdminEmail).split(','),null);
        }
        
    }*/
}