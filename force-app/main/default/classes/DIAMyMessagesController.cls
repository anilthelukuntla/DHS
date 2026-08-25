public without sharing class DIAMyMessagesController {
    public user currentUser{get;set;}
    public list<MessageRecord> messages{get;set;}
    public boolean ShowCurrentMessagePanel{get;set;}
    public String currentMessageId{get;set;}
    public DIA_Message__c currentMessage{get;set;} 

    public String messageBody{get;set;} 
    public String messageSubject{get;set;} 
    public Map<String,User> userMap {get;set;}
    public list<selectoption> toAddressOptions {get;set;}
    public string selecteToAddressOption {get;set;}
    public list<attachment> currentMessageAttachments{get;set;}
    public Integer unReadMessageCount{get;set;}
    public map<string,boolean> messageReadStatusMap {get;set;}
    
    public DIAMyMessagesController(){
        currentUser = [select id, firstname, lastname, email, user_type__c from User where id=:userinfo.getuserid() WITH SECURITY_ENFORCED];
        ShowCurrentMessagePanel = false;
        userMap = new Map<String,User>([Select Id,Firstname,lastname, Email from User WITH SECURITY_ENFORCED]); 
        toAddressOptions = new list<selectoption>();
        toAddressOptions.add(new selectoption('','--None--'));
        for(String lType: apexUtil.getPickListValuesIntoList('DIA_Message__c','To_Address_Type__c')){
            toAddressOptions.add(new selectoption(lType,lType));
        }
        FetchMessages();
    }
    
    public void SendMessage(){
        List<User> toUsers = new List<User>();
        List<User> toUsersForMessageLogs = new List<User>();
        List<String> toAddressList = new list<String>();
        system.debug('selecteToAddressOption...'+selecteToAddressOption);
        if(selecteToAddressOption == 'All PMOs'){
            toUsers = [Select Id, Email,system_access__c, User_Type__c,contact.email from User where User_Type__c = 'PMO' and isActive = true];
            for(User u: toUsers){
                if(u.contact != null){
                    if(u.contact.email != userinfo.getuseremail()){
                    if(u.system_access__c.contains('DIA')){
                    toAddressList.add(u.contact.email);
                    toUsersForMessageLogs.add(u);
                    }
                } 
                }
                    
            }
        }
        if(selecteToAddressOption == 'All Program Members'){
            toUsers = [Select Id, Email,system_access__c, User_Type__c,contact.email from User where (User_Type__c = 'PMO' OR User_Type__c = 'CMO' OR User_Type__c = 'INV' OR User_Type__c = 'QA') and isActive = true];
            for(User u: toUsers){
                if(u.contact.email != userinfo.getuseremail()){
                    if(u.system_access__c.contains('DIA')){
                    toAddressList.add(u.contact.email);
                    toUsersForMessageLogs.add(u);
                    }
                }     
            }
        }
        if(selecteToAddressOption == 'All CMOs'){
            toUsers = [Select Id, Email,system_access__c, User_Type__c,contact.email from User where User_Type__c = 'CMO' and isActive = true];
            for(User u: toUsers){
                if(u.system_access__c.contains('DIA')){
                if(u.contact.email != userinfo.getuseremail()){
                    toAddressList.add(u.contact.email);
                    toUsersForMessageLogs.add(u);
                }     
                }
            }
        }
        if(selecteToAddressOption == 'All Investigators'){
            toUsers = [Select Id, Email,system_access__c, User_Type__c,contact.email from User where User_Type__c = 'INV' and isActive = true];
            system.debug(toUsers);
            for(User u: toUsers){
                if(u.system_access__c.contains('DIA')){
                    toAddressList.add(u.contact.email); 
                    toUsersForMessageLogs.add(u);
                }
            }
        }
        if(selecteToAddressOption == 'All QAs'){
            toUsers = [Select Id, Email,system_access__c, User_Type__c,contact.email from User where User_Type__c = 'QA' and isActive = true];
            for(User u: toUsers){
                toAddressList.add(u.contact.email);  
                toUsersForMessageLogs.add(u); 
            }
        }
       
        System.debug('messageBody,.'+messageBody);
        DIA_Message__c message = new DIA_Message__c();
        message.Message_Body__c = messageBody;
        message.subject__c = messageSubject;
        message.From_User__c = userinfo.getUserId();
        message.To_Address_Type__c = selecteToAddressOption;

        Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_Message__c');
        if(Schema.SobjectType.DIA_Message__c.iscreateable() && 
            fields.get('Message_Body__c').getDescribe().isAccessible() && 
            fields.get('subject__c').getDescribe().isAccessible() &&
            fields.get('From_User__c').getDescribe().isAccessible() && 
            fields.get('To_Address_Type__c').getDescribe().isAccessible()){

            Database.SaveResult dsr = database.insert(message, false, AccessLevel.USER_MODE);
            if(dsr.isSuccess()){
                List<DIA_Message_Log__c> messageLogsToCreate = new List<DIA_Message_Log__c>();
                for(User u: toUsersForMessageLogs){
                    DIA_Message_Log__c log = new DIA_Message_Log__c();
                    log.user__c = u.id;
                    log.message__c = dsr.getid();
                    log.Unread__c = true;
                    log.read__c = false;  
                    messageLogsToCreate.add(log);  
                }
                
                database.insert(messageLogsToCreate,false,AccessLevel.USER_MODE);
                if(!test.isRunningTest()){
                    system.debug('To address '+toAddressList);
                    //String htmlMessageBody = 'Dear,<br/><br/> A new message has been issued by the program’s office.<br/> Please log in to the case management system to retrieve.<br/><br/>Thanks,<br/>ISN Corporation';
                    //MailUtilities.sendHTMLEmail(toAddressList,messageSubject,htmlMessageBody,null);
                    try{
                        //MailUtilities.sendHTMLEmail(toAddressList,'BI Program Notification',null,null,'General Blast Message',dsr.getid());
                        //toAddressList = new list<String>();
                        //toAddressList.add('devdistro@isncorp.com');
                        string htmlBody = 'Dear Member,<br/><br/>A new message has been issued by the program’s office. Please log in to the case management system to retrieve.<br/><br/>Thanks,<br/>ISN Corporation';
                       // MailUtilities.sendHTMLEmail(toAddressList,'BI Program Notification',htmlBody,null); 
                        
                        MailUtilities.sendBIEmail('BI Program Notification',htmlBody,toAddressList,null,null);
                        
                         //MailUtilities.sendHTMLEmail(toAddressList,null,null,null,'General Blast Message',null);
                    }catch(exception e){
                        system.debug('Exception '+e);
}
                }
                System.debug('toAddressList,.'+toAddressList);
                FetchMessages();
                messageBody = null;
                messageSubject = null;
                selecteToAddressOption = null;
            }
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to create Message'));
        }
    }
    
    public void FetchCurrentMessageAction(){
        currentMessageAttachments = new list<attachment>();
        currentMessageAttachments = [Select id, parentid, Name, BodyLength  from attachment where parentid =: currentMessageId];
        list<DIA_Message__c> messages = new list<DIA_Message__c>(); 
        List<string> messageFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        messageFields = ApexUtil.FetchFields('DIA_Message__c');
        messageFields.add('From_user__r.FirstName');
        messageFields.add('From_user__r.LastName');
        messageFields.add('From_user__r.Email');
         messageFields.add('To_User__r.FirstName');
        messageFields.add('To_User__r.LastName');
        messageFields.add('To_User__r.Email');
        String query = 'Select '+string.join(messageFields, ',') + ' From DIA_Message__c ';
        whereCriteria.add(new ApexUtil.Criteria('Id',currentMessageId,'='));
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+ ' WITH SECURITY_ENFORCED ORDER BY Createddate desc '; 
        messages = database.query(query);
        currentMessage = messages[0];
        ShowCurrentMessagePanel = true;
        
        List<DIA_Message_Log__c> messageLogs = new List<DIA_Message_Log__c>();
        
        messageLogs = [Select Id, UnRead__c, Read__c, Message__c, User__c from DIA_Message_Log__c Where Message__c =:currentMessage.id AND User__c =: USerinfo.getuserid() AND UnRead__c = True WITH SECURITY_ENFORCED];
        for(DIA_Message_Log__c mLog: messageLogs){
            mLog.UnRead__c = false;
            mLog.Read__c = true;
        }
        Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_Message_Log__c');

        if(Schema.SobjectType.DIA_Message_Log__c.isUpdateable() && 
            fields.get('UnRead__c').getDescribe().isAccessible() && 
            fields.get('Read__c').getDescribe().isAccessible()){

            List<Database.SaveResult> dsr = database.update(messageLogs, false, AccessLevel.USER_MODE);
            integer i =0;
            for(Database.SaveResult dr : dsr){
                if(dr.isSuccess()) i++;
            }
            if(i == messageLogs.size()){
                FetchMessages(); 
            }
        }
        
    }
    
    public void FetchMessages(){
        messageReadStatusMap = new map<string,boolean>();
        messages = new list<MessageRecord>();
        list<DIA_Message__c> allMessages = new list<DIA_Message__c>(); 
        List<string> messageFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        messageFields = ApexUtil.FetchFields('DIA_Message__c');
        messageFields.add('From_user__r.FirstName');
        messageFields.add('From_user__r.LastName');
        messageFields.add('From_user__r.Email');
        String query = 'Select '+string.join(messageFields, ',') + ' From DIA_Message__c ';
        String WhereCondition = ' WHERE Case__c = \'\'';
        if(currentuser.user_type__c == 'PMO'){
            WhereCondition = WhereCondition + ' AND (To_Address_Type__c = \'All Program Members\' OR To_Address_Type__c = \'All PMOs\' OR From_user__c=\''+currentuser.id+'\')';       
        }
        if(currentuser.user_type__c == 'CMO'){
            WhereCondition = WhereCondition + ' AND (To_Address_Type__c = \'All Program Members\' OR To_Address_Type__c = \'All CMOs\' OR From_user__c=\''+currentuser.id+'\')';       
        }
        if(currentuser.user_type__c == 'INV'){
            WhereCondition = WhereCondition + ' AND (To_Address_Type__c = \'All Program Members\' OR To_Address_Type__c = \'All Investigators\')';       
        }
        if(currentuser.user_type__c == 'QA'){
            WhereCondition = WhereCondition + ' AND (To_Address_Type__c = \'All Program Members\' OR To_Address_Type__c = \'All QAs\')';       
        }
        
        query = query + WhereCondition+' WITH SECURITY_ENFORCED  ORDER BY Createddate desc LIMIT 1000 '; 
        System.debug('query..'+query);
        allmessages = database.query(query);
        List<string> messageIds = new List<string>();
        for(DIA_Message__c doc: allMessages){
            messageIds.add(doc.id);
        }
        
        List<DIA_Message_Log__c> messageLogs = new List<DIA_Message_Log__c>();
        
        messageLogs = [Select Id, UnRead__c, Read__c, Message__c, User__c from DIA_Message_Log__c Where Message__c IN: messageIds AND User__c =: USerinfo.getuserid() AND UnRead__c = True WITH SECURITY_ENFORCED];
        
        unReadMessageCount = messageLogs.size();
        
        for(DIA_Message_Log__c mLog: messageLogs){
            if(mLog.UnRead__c){
                messageReadStatusMap.put(mLog.message__c,false);
            }else{
                messageReadStatusMap.put(mLog.message__c,true);
            }
        }
        
        for(DIA_Message__c doc: allMessages){
            if(!messageReadStatusMap.containsKey(doc.id)){
                messageReadStatusMap.put(doc.id,true);
            }
        }
        
        List<attachment> attachments = new List<attachment>();
        attachments = [Select id, parentid from attachment where parentid in: messageIds WITH SECURITY_ENFORCED];
        Map<string,list<String>> messageNattachmentMap = new Map<string,list<String>>();
        for(attachment att: attachments){
            if(!messageNattachmentMap.containsKey(att.parentid)){
                messageNattachmentMap.put(att.parentid, new list<string>{att.id});
            }elsE{
                messageNattachmentMap.get(att.parentid).add(att.id);   
            } 
        }
        
        for(DIA_Message__c message: allMessages){
            messages.add(new messageRecord(messageNattachmentMap.get(message.id),message));  
        }

    }
    
    public class MessageRecord{
        public list<string> attachments{get;set;}
        public DIA_Message__c message{get;set;}
        public MessageRecord(list<string> attachments, DIA_Message__c message){
            this.attachments  = attachments;
            this.message = message;
        }
    }
    public void RefreshAction(){
        FetchMessages();
    }
}