/**
 * @description Controls DHS incoming and outgoing message searches.
 */
@SuppressWarnings('PMD.ApexSOQLInjection,PMD.AvoidDeeplyNestedIfStmts,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.NcssConstructorCount')
public with sharing class DHSOtherMessagesController{
    /** @description Provides this DHS API member. */
    public user currentUser {get;set;}
    /** @description Provides this DHS API member. */
    public list<selectoption> fromUserList {get;set;}
    /** @description Provides this DHS API member. */
    public list<selectoption> toUserList {get;set;}
    /** @description Provides this DHS API member. */
    public list<selectoption> typeOfMessages {get;set;}
    /** @description Provides this DHS API member. */
    public string selectedFromUserId {get;set;}
    /** @description Provides this DHS API member. */
    public string selectedToUserId {get;set;}
    /** @description Provides this DHS API member. */
    public string selectedTypeofMessage {get;set;}
    /** @description Provides this DHS API member. */
    public Date selectedDate {get;set;}
    /** @description Provides this DHS API member. */
    public list<DHS_Message__c> allIncomingMessages{get;set;}
    /** @description Provides this DHS API member. */
    public list<DHS_Message__c> allOutgoingMessages{get;set;}
    /** @description Provides this DHS API member. */
    public DHSOtherMessagesController(){
        fromUserList = new list<selectoption>();
        toUserList = new list<selectoption>();
        typeOfMessages = new list<selectoption>();
        fromUserList.add(new selectoption('','--None--'));
        toUserList.add(new selectoption('','--None--'));
        typeOfMessages.add(new selectoption('','--None--'));
        typeOfMessages.add(new selectoption('Incoming','Incoming'));
        typeOfMessages.add(new selectoption('Sent Items','Sent Items'));
        typeOfMessages.add(new selectoption('DHS_All','DHS_All'));
        currentUser = [select id, firstname, lastname, email, user_type__c from User where id=:userinfo.getuserid() WITH SECURITY_ENFORCED];
        List<String> userProfiles = new List<String>();
        if(!test.isRunningTest()){
          userProfiles.addAll(System.label.DHS_UserProfiles.split(','));    
        }else{
          userProfiles.add('System Administrator');        
        }
        Map<String, Profile> profileMap = new Map<String, Profile>([Select Id, Name from Profile WHERE Name IN:userProfiles ]);
        List<String> profileIds = new List<String> ();
        profileIds.addAll(profileMap.Keyset());
        List<string> userFields = new List<string>();
        userFields = DHSApexUtil.FetchFields('User');
        String query = 'Select '+string.join(userFields, ',') + ' From User ';
        query = query + ' WHERE ProfileId IN:profileIds and isActive = true'; 
        // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
        List<User> dhsUsers = database.query(query);
        
        for(user u: dhsUsers){
           if(currentUser.user_type__c == 'PMO'){
               if(u.user_type__c != 'PMO'){
                   if(u.System_Access__c.contains('DHS')){
                   fromUserList.add(new selectoption(u.id,u.FirstName+' '+u.LastName));   
                   toUserList.add(new selectoption(u.id,u.FirstName+' '+u.LastName));
                   }
               }
           }
           if(currentUser.user_type__c == 'CMO'){
               if(u.user_type__c != 'PMO' && u.user_type__c != 'CMO'){
                   if(u.System_Access__c.contains('DHS')){
                   fromUserList.add(new selectoption(u.id,u.FirstName+' '+u.LastName));   
                   toUserList.add(new selectoption(u.id,u.FirstName+' '+u.LastName));
                   }
               }
           }  
        }
            
    }
    
    /** @description Provides this DHS API member. */
    public void fetchmessages(){
        if(selectedTypeofMessage == 'DHS_All' || selectedTypeofMessage == 'Incoming'){
            fetchIncomingmessages();
        }
        if(selectedTypeofMessage == 'DHS_All' || selectedTypeofMessage == 'Sent Items'){
            fetchOutgoingmessages();
        }
    }
    
    /** @description Provides this DHS API member. */
    public void fetchIncomingmessages(){
        allIncomingMessages = new list<DHS_Message__c>();
        list<DHS_Message__c> messages = new list<DHS_Message__c>(); 
        List<string> messageFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        messageFields = DHSApexUtil.FetchFields('DHS_Message__c');
        messageFields.add('DHS_From_User__r.FirstName');
        messageFields.add('DHS_From_User__r.LastName');
        messageFields.add('DHS_From_User__r.Email');
        String query = 'Select '+string.join(messageFields, ',') + ' From DHS_Message__c ';
        if(String.isNotBlank(selectedFromUserId)){
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_From_User__c',selectedFromUserId,'='));
        }
        if(String.isNotBlank(selectedToUserId)){
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_To_User__c',selectedToUserId,'='));
        }
        
        if(String.isNotBlank(string.valueof(selectedDate))){
            whereCriteria.add(new DHSApexUtil.Criteria('Message_Date__c',String.valueof(selectedDate), '=', 'Date'));
        }
       
        String whereCondition = DHSApexUtil.generateWhereQuery(whereCriteria); 
        if(String.isNotBlank(whereCondition)){   
            query = query + ' WHERE '+whereCondition+ ' WITH SECURITY_ENFORCED ORDER BY Createddate desc'; 
        }else{
            query = query + ' WITH SECURITY_ENFORCED ORDER BY Createddate desc'; 
        }
        
        // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
        messages = database.query(query);
        for(DHS_Message__c doc: messages){
            allIncomingMessages.add(doc);
        }
    }
    /** @description Provides this DHS API member. */
    public void fetchOutgoingmessages(){
        allOutgoingMessages = new list<DHS_Message__c>();
        list<DHS_Message__c> messages = new list<DHS_Message__c>(); 
        List<string> messageFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        messageFields = DHSApexUtil.FetchFields('DHS_Message__c');
        messageFields.add('DHS_From_User__r.FirstName');
        messageFields.add('DHS_From_User__r.LastName');
        messageFields.add('DHS_From_User__r.Email');
        String query = 'Select '+string.join(messageFields, ',') + ' From DHS_Message__c ';
        if(String.isNotBlank(selectedFromUserId)){
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_To_User__c',selectedFromUserId,'='));
        }
        if(String.isNotBlank(selectedToUserId)){
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_From_User__c',selectedToUserId,'='));
        }
        
        if(String.isNotBlank(string.valueof(selectedDate))){
            whereCriteria.add(new DHSApexUtil.Criteria('Message_Date__c',String.valueof(selectedDate), '=', 'Date'));
        }
         
        String whereCondition = DHSApexUtil.generateWhereQuery(whereCriteria);    
        if(String.isNotBlank(whereCondition)){   
            query = query + ' WHERE '+whereCondition+ ' WITH SECURITY_ENFORCED ORDER BY Createddate desc'; 
        }else{
            query = query + ' WITH SECURITY_ENFORCED ORDER BY Createddate desc'; 
        }
        // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
        messages = database.query(query);
        for(DHS_Message__c doc: messages){
            allOutgoingMessages.add(doc);
        }

    }
    
    


}