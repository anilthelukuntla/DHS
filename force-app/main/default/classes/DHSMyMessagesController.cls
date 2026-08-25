/**
 * @description Controls DHS broadcast-message composition, display, and read tracking.
 */
@SuppressWarnings('PMD.AvoidDeeplyNestedIfStmts,PMD.AvoidNonRestrictiveQueries,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.NcssCount,PMD.NcssMethodCount,PMD.StdCyclomaticComplexity')
public with sharing class DHSMyMessagesController {
    /** @description Provides this DHS API member. */
    public user currentUser{get;set;}
    /** @description Provides this DHS API member. */
    public list<MessageRecord> messages{get;set;}
    public boolean showCurrentMessagePanel{get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    /** @description Provides this DHS API member. */
    public String currentMessageId{get;set;}
    /** @description Provides this DHS API member. */
    public DHS_Message__c currentMessage{get;set;} 
    /** @description Provides this DHS API member. */
    public String messageBody{get;set;} 
    /** @description Provides this DHS API member. */
    public String messageSubject{get;set;} 
    /** @description Provides this DHS API member. */
    public Map<String,User> userMap {get;set;}
    /** @description Provides this DHS API member. */
    public list<selectoption> toAddressOptions {get;set;}
    /** @description Provides this DHS API member. */
    public string selecteToAddressOption {get;set;}
    /** @description Provides this DHS API member. */
    public list<attachment> currentMessageAttachments{get;set;}
    /** @description Provides this DHS API member. */
    public Integer unReadMessageCount{get;set;}
    /** @description Provides this DHS API member. */
    public map<string,boolean> messageReadStatusMap {get;set;}
    
    /** @description Provides this DHS API member. */
    public DHSMyMessagesController(){
        currentUser = [select id, firstname, lastname, email, user_type__c from User where id=:userinfo.getuserid()];
        showCurrentMessagePanel = false;
        userMap = new Map<String,User>([Select Id,Firstname,lastname, Email from User]); 
        toAddressOptions = new list<selectoption>();
        toAddressOptions.add(new selectoption('','--None--'));
        for(String lType: apexUtil.getPickListValuesIntoList('DHS_Message__c','To_Address_Type__c')){
            toAddressOptions.add(new selectoption(lType,lType));
        }
        fetchMessages();
    }
    
    /** @description Provides this DHS API member. */
    public void sendMessage(){
        List<User> toUsers = new List<User>();
        List<User> toUsersForMessageLogs = new List<User>();
        List<String> toAddressList = new list<String>();
        if(selecteToAddressOption == 'All PMOs'){
            toUsers = [Select Id,System_Access__c, Email,contact.email, User_Type__c from User where User_Type__c = 'PMO' and isActive = true];
            for(User u: toUsers){
                if(u.contact.email != userinfo.getuseremail()){
                    if(u.System_Access__c.contains('DHS')){
                        toAddressList.add(u.contact.email);
                    	toUsersForMessageLogs.add(u);
                    }
                }     
            }
        }
        if(selecteToAddressOption == 'All Program Members'){
            toUsers = [Select Id,System_Access__c, Email,contact.email, User_Type__c from User where (User_Type__c = 'PMO' OR User_Type__c = 'CMO' OR User_Type__c = 'INV' OR User_Type__c = 'QA') and isActive = true];
            for(User u: toUsers){
                if(u.contact.email != userinfo.getuseremail()){
                    if(u.System_Access__c.contains('DHS')){
                    toAddressList.add(u.contact.email);
                    toUsersForMessageLogs.add(u);
                }     
                }
            }
        }
        if(selecteToAddressOption == 'All CMOs'){
            toUsers = [Select Id,System_Access__c, Email,contact.email, User_Type__c from User where User_Type__c = 'CMO' and isActive = true];
            for(User u: toUsers){
                if(u.contact.email != userinfo.getuseremail()){
                    if(u.System_Access__c.contains('DHS')){
                    toAddressList.add(u.contact.email);
                    toUsersForMessageLogs.add(u);
                    }
                }     
            }
        }
        if(selecteToAddressOption == 'All Investigators'){
            toUsers = [Select Id,System_Access__c, Email,contact.email, User_Type__c from User where User_Type__c = 'INV' and isActive = true];
            for(User u: toUsers){
                if(u.System_Access__c.contains('DHS')){
                toAddressList.add(u.contact.email); 
                toUsersForMessageLogs.add(u);
                }
            }
        }
        if(selecteToAddressOption == 'All QAs'){
            toUsers = [Select Id,System_Access__c, Email, User_Type__c from User where User_Type__c = 'QA' and isActive = true];
            for(User u: toUsers){
                if(u.System_Access__c.contains('DHS')){
                toAddressList.add(u.email);  
                toUsersForMessageLogs.add(u); 
                }
            }
        }
       
        DHS_Message__c message = new DHS_Message__c();
        message.Message_Body__c = messageBody;
        message.Subject__c = messageSubject;
        message.DHS_From_User__c = userinfo.getUserId();
        message.To_Address_Type__c = selecteToAddressOption;
        database.insert(message,false,AccessLevel.USER_MODE);
        
        List<DHS_Message_Log__c> messageLogsToCreate = new List<DHS_Message_Log__c>();
        for(User u: toUsersForMessageLogs){
            DHS_Message_Log__c log = new DHS_Message_Log__c();
            log.DHS_User__c = u.id;
            log.DHS_Message__c = message.id;
            log.UnRead__c = true;
            log.Read__c = false;  
            messageLogsToCreate.add(log);  
        }
        
        database.insert(messageLogsToCreate,false,AccessLevel.USER_MODE);
        
        fetchMessages();
        messageBody = null;
        messageSubject = null;
        selecteToAddressOption = null;
        
    }
    
    /** @description Provides this DHS API member. */
    public void fetchCurrentMessageAction(){
        currentMessageAttachments = new list<attachment>();
        currentMessageAttachments = [Select id, parentid, Name, BodyLength  from attachment where parentid =: currentMessageId WITH USER_MODE];
        list<DHS_Message__c> messages = new list<DHS_Message__c>(); 
        List<string> messageFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        messageFields = DHSApexUtil.FetchFields('DHS_Message__c');
        messageFields.add('DHS_From_User__r.FirstName');
        messageFields.add('DHS_From_User__r.LastName');
        messageFields.add('DHS_From_User__r.Email');
        String query = 'Select '+string.join(messageFields, ',') + ' From DHS_Message__c ';
        whereCriteria.add(new DHSApexUtil.Criteria('Id',currentMessageId,'='));
        String whereCondition = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+whereCondition+ 'ORDER BY Createddate desc'; 
        messages = database.query(query, AccessLevel.USER_MODE);
        currentMessage = messages[0];
        showCurrentMessagePanel = true;
        
        List<DHS_Message_Log__c> messageLogs = new List<DHS_Message_Log__c>();
        
        messageLogs = [Select Id, UnRead__c, Read__c, DHS_Message__c, DHS_User__c from DHS_Message_Log__c Where DHS_Message__c =:currentMessage.id AND DHS_User__c =: USerinfo.getuserid() AND UnRead__c = True WITH USER_MODE];
        for(DHS_Message_Log__c mLog: messageLogs){
            mLog.UnRead__c = false;
            mLog.Read__c = true;
        }
        database.update(messageLogs,false,AccessLevel.USER_MODE);
        
        fetchMessages();
    }
    
    /** @description Provides this DHS API member. */
    public void fetchMessages(){
        messageReadStatusMap = new map<string,boolean>();
        messages = new list<MessageRecord>();
        list<DHS_Message__c> allMessages = new list<DHS_Message__c>(); 
        List<string> messageFields = new List<string>();
        messageFields = DHSApexUtil.FetchFields('DHS_Message__c');
        messageFields.add('DHS_From_User__r.FirstName');
        messageFields.add('DHS_From_User__r.LastName');
        messageFields.add('DHS_From_User__r.Email');
        
        String query = 'Select '+string.join(messageFields, ',') + ' From DHS_Message__c ';
        String whereCondition = ' WHERE DHS_Case__c = \'\'';
        if(currentuser.user_type__c == 'PMO'){
            whereCondition = whereCondition + ' AND (To_Address_Type__c = \'All Program Members\' OR To_Address_Type__c = \'All PMOs\' OR DHS_From_User__c=\''+currentuser.id+'\')';       
        }
        if(currentuser.user_type__c == 'CMO'){
            whereCondition = whereCondition + ' AND (To_Address_Type__c = \'All Program Members\' OR To_Address_Type__c = \'All CMOs\' OR DHS_From_User__c=\''+currentuser.id+'\')';       
        }
        if(currentuser.user_type__c == 'INV'){
            whereCondition = whereCondition + ' AND (To_Address_Type__c = \'All Program Members\' OR To_Address_Type__c = \'All Investigators\')';       
        }
        if(currentuser.user_type__c == 'QA'){
            whereCondition = whereCondition + ' AND (To_Address_Type__c = \'All Program Members\' OR To_Address_Type__c = \'All QAs\')';       
        }
        
        query = query + whereCondition+' ORDER BY Createddate desc'; 
        allmessages = database.query(query, AccessLevel.USER_MODE);
        List<string> messageIds = new List<string>();
        for(DHS_Message__c doc: allMessages){
            messageIds.add(doc.id);
        }
        
        List<DHS_Message_Log__c> messageLogs = new List<DHS_Message_Log__c>();
        
        messageLogs = [Select Id, UnRead__c, Read__c, DHS_Message__c, DHS_User__c from DHS_Message_Log__c Where DHS_Message__c IN: messageIds AND DHS_User__c =: USerinfo.getuserid() AND UnRead__c = True WITH USER_MODE];
        
        unReadMessageCount = messageLogs.size();
        
        for(DHS_Message_Log__c mLog: messageLogs){
            if(mLog.UnRead__c){
                messageReadStatusMap.put(mLog.DHS_Message__c,false);
            }else{
                messageReadStatusMap.put(mLog.DHS_Message__c,true);
            }
        }
        
        for(DHS_Message__c doc: allMessages){
            if(!messageReadStatusMap.containsKey(doc.id)){
                messageReadStatusMap.put(doc.id,true);
            }
        }
        
        List<attachment> attachments = new List<attachment>();
        attachments = [Select id, parentid from attachment where parentid in: messageIds WITH USER_MODE];
        Map<string,list<String>> messageNattachmentMap = new Map<string,list<String>>();
        for(attachment att: attachments){
            if(!messageNattachmentMap.containsKey(att.parentid)){
                messageNattachmentMap.put(att.parentid, new list<string>{att.id});
            }elsE{
                messageNattachmentMap.get(att.parentid).add(att.id);   
            } 
        }
        
        for(DHS_Message__c message: allMessages){
            messages.add(new messageRecord(messageNattachmentMap.get(message.id),message));  
        }

    }
    
    /** @description Provides this DHS API member. */
    public class MessageRecord{
        /** @description Provides this DHS API member. */
        public list<string> attachments{get;set;}
        /** @description Provides this DHS API member. */
        public DHS_Message__c message{get;set;}
        /**
         * @description Provides this DHS API member.
         * @param attachments Method parameter.
         * @param message Method parameter.
         */
        public MessageRecord(list<string> attachments, DHS_Message__c message){
            this.attachments  = attachments;
            this.message = message;
        }
    }
    /** @description Provides this DHS API member. */
    public void refreshAction(){
        fetchMessages();
    }
}
