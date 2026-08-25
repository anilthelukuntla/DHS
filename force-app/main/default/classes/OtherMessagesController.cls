public class OtherMessagesController{
    public user currentUser {get;set;}
    public list<selectoption> fromUserList {get;set;}
    public list<selectoption> toUserList {get;set;}
    public list<selectoption> typeOfMessages {get;set;}
    public string selectedFromUserId {get;set;}
    public string selectedToUserId {get;set;}
    public string selectedTypeofMessage {get;set;}
    public Date selectedDate {get;set;}
    public list<Message__c> allIncomingMessages{get;set;}
    public list<Message__c> allOutgoingMessages{get;set;}
    public OtherMessagesController(){
        fromUserList = new list<selectoption>();
        toUserList = new list<selectoption>();
        typeOfMessages = new list<selectoption>();
        fromUserList.add(new selectoption('','--None--'));
        toUserList.add(new selectoption('','--None--'));
        typeOfMessages.add(new selectoption('','--None--'));
        typeOfMessages.add(new selectoption('Incoming','Incoming'));
        typeOfMessages.add(new selectoption('Sent Items','Sent Items'));
        typeOfMessages.add(new selectoption('All','All'));
        currentUser = [select id, firstname, lastname, email, user_type__c from User where id=:userinfo.getuserid()];
        List<String> userProfiles = new List<String>();
        if(!test.isRunningTest()){
          userProfiles.addAll(System.label.IntelUserProfiles.split(','));    
        }else{
          userProfiles.add('System Administrator');        
        }
        Map<String, Profile> profileMap = new Map<String, Profile>([Select Id, Name from Profile WHERE Name IN:userProfiles ]);
        List<String> profileIds = new List<String> ();
        profileIds.addAll(profileMap.Keyset());
        List<string> userFields = new List<string>();
        userFields = ApexUtil.FetchFields('User');
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        String query = 'Select '+string.join(userFields, ',') + ' From User ';
        String where_cond;
        query = query + ' WHERE ProfileId IN:profileIds'; 
        System.debug('query....'+query);
        List<User> intelUsers = database.query(query);
        
        for(user u: intelUsers){
           if(currentUser.user_type__c == 'PMO'){
               if(u.user_type__c != 'PMO'){
                   fromUserList.add(new selectoption(u.id,u.FirstName+' '+u.LastName));   
                   toUserList.add(new selectoption(u.id,u.FirstName+' '+u.LastName));     
               }
           }
           if(currentUser.user_type__c == 'CMO'){
               if(u.user_type__c != 'PMO' && currentUser.user_type__c != 'CMO'){
                   fromUserList.add(new selectoption(u.id,u.FirstName+' '+u.LastName));   
                   toUserList.add(new selectoption(u.id,u.FirstName+' '+u.LastName));     
               }
           }  
        }
        System.debug('fromUserList....'+fromUserList);
        System.debug('toUserList....'+toUserList);
            
    }
    
    public void fetchmessages(){
        if(selectedTypeofMessage == 'All' || selectedTypeofMessage == 'Incoming'){
            FetchIncomingmessages();
        }
        if(selectedTypeofMessage == 'All' || selectedTypeofMessage == 'Sent Items'){
            FetchOutgoingmessages();
        }
    }
    
    public void FetchIncomingmessages(){
        allIncomingMessages = new list<message__c>();
        list<message__c> messages = new list<message__c>(); 
        List<string> messageFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        messageFields = ApexUtil.FetchFields('message__c');
        messageFields.add('From_user__r.FirstName');
        messageFields.add('From_user__r.LastName');
        messageFields.add('From_user__r.Email');
        String query = 'Select '+string.join(messageFields, ',') + ' From message__c ';
        if(String.isNotBlank(selectedFromUserId)){
            whereCriteria.add(new ApexUtil.Criteria('from_user__c',selectedFromUserId,'='));
        }
        if(String.isNotBlank(selectedToUserId)){
            whereCriteria.add(new ApexUtil.Criteria('to_user__c',selectedToUserId,'='));
        }
        
        if(String.isNotBlank(string.valueof(selectedDate))){
            whereCriteria.add(new ApexUtil.Criteria('Message_Date__c',String.valueof(selectedDate), '=', 'Date'));
        }
       
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria); 
        if(String.isNotBlank(where_cond)){   
            query = query + ' WHERE '+where_cond+ ' ORDER BY Createddate desc'; 
        }else{
            query = query + ' ORDER BY Createddate desc'; 
        }
        
        System.debug('query....'+query);
        messages = database.query(query);
        List<string> messageIds = new List<string>();
        for(message__c doc: messages){
            allIncomingMessages.add(doc);
        }
    }
    public void FetchOutgoingmessages(){
        allOutgoingMessages = new list<message__c>();
        list<message__c> messages = new list<message__c>(); 
        List<string> messageFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        messageFields = ApexUtil.FetchFields('message__c');
        messageFields.add('From_user__r.FirstName');
        messageFields.add('From_user__r.LastName');
        messageFields.add('From_user__r.Email');
        String query = 'Select '+string.join(messageFields, ',') + ' From message__c ';
        if(String.isNotBlank(selectedFromUserId)){
            whereCriteria.add(new ApexUtil.Criteria('to_user__c',selectedFromUserId,'='));
        }
        if(String.isNotBlank(selectedToUserId)){
            whereCriteria.add(new ApexUtil.Criteria('from_user__c',selectedToUserId,'='));
        }
        
        if(String.isNotBlank(string.valueof(selectedDate))){
            whereCriteria.add(new ApexUtil.Criteria('Message_Date__c',String.valueof(selectedDate), '=', 'Date'));
        }
         
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        if(String.isNotBlank(where_cond)){   
            query = query + ' WHERE '+where_cond+ ' ORDER BY Createddate desc'; 
        }else{
            query = query + ' ORDER BY Createddate desc'; 
        }
        System.debug('query...'+query);
        messages = database.query(query);
        List<string> messageIds = new List<string>();
        for(message__c doc: messages){
            allOutgoingMessages.add(doc);
        }

    }
    
    


}