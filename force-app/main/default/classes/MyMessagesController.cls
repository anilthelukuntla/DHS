public class MyMessagesController {
    public user currentUser{get;set;}
    public list<MessageRecord> messages{get;set;}
    public boolean ShowCurrentMessagePanel{get;set;}
    public String currentMessageId{get;set;}
    public message__c currentMessage{get;set;} 
    public String messageBody{get;set;} 
    public String messageSubject{get;set;} 
    public Map<String,User> userMap {get;set;}
    public list<selectoption> toAddressOptions {get;set;}
    public string selecteToAddressOption {get;set;}
    public list<attachment> currentMessageAttachments{get;set;}
    public Integer unReadMessageCount{get;set;}
    public map<string,boolean> messageReadStatusMap {get;set;}
    
    public MyMessagesController(){
        currentUser = [select id, firstname, lastname, email, user_type__c from User where id=:userinfo.getuserid()];
        ShowCurrentMessagePanel = false;
        userMap = new Map<String,User>([Select Id,Firstname,lastname, Email from User]); 
        toAddressOptions = new list<selectoption>();
        toAddressOptions.add(new selectoption('','--None--'));
        for(String lType: apexUtil.getPickListValuesIntoList('Message__c','To_Address_Type__c')){
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
            toUsers = [Select Id, Email, User_Type__c from User where User_Type__c = 'PMO'];
            for(User u: toUsers){
                if(u.email != userinfo.getuseremail()){
                    toAddressList.add(u.email);
                    toUsersForMessageLogs.add(u);
                }     
            }
        }
        if(selecteToAddressOption == 'All Program Members'){
            toUsers = [Select Id, Email, User_Type__c from User where (User_Type__c = 'PMO' OR User_Type__c = 'CMO' OR User_Type__c = 'INV' OR User_Type__c = 'QA')];
            for(User u: toUsers){
                if(u.email != userinfo.getuseremail()){
                    toAddressList.add(u.email);
                    toUsersForMessageLogs.add(u);
                }     
            }
        }
        if(selecteToAddressOption == 'All CMOs'){
            toUsers = [Select Id, Email, User_Type__c from User where User_Type__c = 'CMO'];
            for(User u: toUsers){
                if(u.email != userinfo.getuseremail()){
                    toAddressList.add(u.email);
                    toUsersForMessageLogs.add(u);
                }     
            }
        }
        if(selecteToAddressOption == 'All Investigators'){
            toUsers = [Select Id, Email, User_Type__c from User where User_Type__c = 'INV'];
            for(User u: toUsers){
                toAddressList.add(u.email); 
                toUsersForMessageLogs.add(u);
            }
        }
        if(selecteToAddressOption == 'All QAs'){
            toUsers = [Select Id, Email, User_Type__c from User where User_Type__c = 'QA'];
            for(User u: toUsers){
                toAddressList.add(u.email);  
                toUsersForMessageLogs.add(u); 
            }
        }
       
        System.debug('messageBody,.'+messageBody);
        Message__c message = new Message__c();
        message.Message_Body__c = messageBody;
        message.subject__c = messageSubject;
        message.From_User__c = userinfo.getUserId();
        message.To_Address_Type__c = selecteToAddressOption;
        insert message;
        
        List<Message_Log__c> messageLogsToCreate = new List<Message_Log__c>();
        for(User u: toUsersForMessageLogs){
            Message_Log__c log = new Message_Log__c();
            log.user__c = u.id;
            log.message__c = message.id;
            log.Unread__c = true;
            log.read__c = false;  
            messageLogsToCreate.add(log);  
        }
        
        insert messageLogsToCreate;
        
        if(!test.isRunningTest()){
            //String htmlMessageBody = 'Dear,<br/><br/> A new message has been issued by the program’s office.<br/> Please log in to the case management system to retrieve.<br/><br/>Thanks,<br/>ISN Corporation';
            //MailUtilities.sendHTMLEmail(toAddressList,messageSubject,htmlMessageBody,null);
            MailUtilities.sendHTMLEmail(toAddressList,null,null,null,'General Blast Message',message.id);
        }
        System.debug('toAddressList,.'+toAddressList);
        FetchMessages();
        messageBody = null;
        messageSubject = null;
        selecteToAddressOption = null;
        
    }
    
    public void FetchCurrentMessageAction(){
        currentMessageAttachments = new list<attachment>();
        currentMessageAttachments = [Select id, parentid, Name, BodyLength  from attachment where parentid =: currentMessageId];
        list<message__c> messages = new list<message__c>(); 
        List<string> messageFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        messageFields = ApexUtil.FetchFields('message__c');
        messageFields.add('From_user__r.FirstName');
        messageFields.add('From_user__r.LastName');
        messageFields.add('From_user__r.Email');
        String query = 'Select '+string.join(messageFields, ',') + ' From message__c ';
        whereCriteria.add(new ApexUtil.Criteria('Id',currentMessageId,'='));
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+ 'ORDER BY Createddate desc'; 
        messages = database.query(query);
        currentMessage = messages[0];
        ShowCurrentMessagePanel = true;
        
        List<Message_Log__c> messageLogs = new List<Message_Log__c>();
        
        messageLogs = [Select Id, UnRead__c, Read__c, Message__c, User__c from Message_Log__c Where Message__c =:currentMessage.id AND User__c =: USerinfo.getuserid() AND UnRead__c = True];
        for(Message_Log__c mLog: messageLogs){
            mLog.UnRead__c = false;
            mLog.Read__c = true;
        }
        update messageLogs;
        
        FetchMessages();
    }
    
    public void FetchMessages(){
        messageReadStatusMap = new map<string,boolean>();
        messages = new list<MessageRecord>();
        list<message__c> allMessages = new list<message__c>(); 
        List<string> messageFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        messageFields = ApexUtil.FetchFields('message__c');
        messageFields.add('From_user__r.FirstName');
        messageFields.add('From_user__r.LastName');
        messageFields.add('From_user__r.Email');
        String query = 'Select '+string.join(messageFields, ',') + ' From message__c ';
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
        
        query = query + WhereCondition+' ORDER BY Createddate desc'; 
        System.debug('query..'+query);
        allmessages = database.query(query);
        List<string> messageIds = new List<string>();
        for(message__c doc: allMessages){
            messageIds.add(doc.id);
        }
        
        List<Message_Log__c> messageLogs = new List<Message_Log__c>();
        
        messageLogs = [Select Id, UnRead__c, Read__c, Message__c, User__c from Message_Log__c Where Message__c IN: messageIds AND User__c =: USerinfo.getuserid() AND UnRead__c = True];
        
        unReadMessageCount = messageLogs.size();
        
        for(Message_Log__c mLog: messageLogs){
            if(mLog.UnRead__c){
                messageReadStatusMap.put(mLog.message__c,false);
            }else{
                messageReadStatusMap.put(mLog.message__c,true);
            }
        }
        
        for(message__c doc: allMessages){
            if(!messageReadStatusMap.containsKey(doc.id)){
                messageReadStatusMap.put(doc.id,true);
            }
        }
        
        List<attachment> attachments = new List<attachment>();
        attachments = [Select id, parentid from attachment where parentid in: messageIds];
        Map<string,list<String>> messageNattachmentMap = new Map<string,list<String>>();
        for(attachment att: attachments){
            if(!messageNattachmentMap.containsKey(att.parentid)){
                messageNattachmentMap.put(att.parentid, new list<string>{att.id});
            }elsE{
                messageNattachmentMap.get(att.parentid).add(att.id);   
            } 
        }
        
        for(message__c message: allMessages){
            messages.add(new messageRecord(messageNattachmentMap.get(message.id),message));  
        }

    }
    
    public class MessageRecord{
        public list<string> attachments{get;set;}
        public message__c message{get;set;}
        public MessageRecord(list<string> attachments, message__c message){
            this.attachments  = attachments;
            this.message = message;
        }
    }
    public void RefreshAction(){
        FetchMessages();
    }
}