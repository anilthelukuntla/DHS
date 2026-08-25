public class DIAHeaderController {
    public User currentUser {get;set;}
    public boolean isPMOUser {get;set;}
    public boolean isCMOUser {get;set;}
    public boolean isINVUser {get;set;}
    public boolean isQAUser {get;set;}
    public boolean isAdminUser {get;set;}
    public boolean isSecurityUser {get;set;}
    public boolean isCustomerUser {get;set;} 
    public integer unreadmessagecount {Get;set;}
    public integer unreadmessagecountfrommymessages{get;set;}
    public integer unreadmessagecountforotherpages{get;set;}
    public string pagename{get;set;}
    public User_Permission__mdt currentUserPermissions {get;set;}
    public boolean hasAccessToLeadUpload{get;set;}
    public DIAHeaderController(){
        hasAccessToLeadUpload = false;
         currentUser = [Select Id,profile.Name,system_access__c,contact.Email, FirstName, LastName, User_Type__c FROM User where Id=:userinfo.getUserId()];
       
        currentUserPermissions = PermissionsUtil.GetUserPermssions(currentUser.User_Type__c);
        System.debug('currentUserPermissions...'+currentUserPermissions.User_Type__c);
        System.debug('currentUserPermissions...'+currentUserPermissions);
        if(currentUser.User_Type__c == 'PMO'){
            isPMOUser = true;
        }
        if(currentUser.User_Type__c == 'CMO'){
            isCMOUser = true;
        }
        if(currentUser.User_Type__c == 'INV'){
            isINVUser = true;
        }
        if(currentUser.User_Type__c == 'QA'){
            isQAUser = true;
        }
        if(currentUser.User_Type__c == 'Security'){
            isSecurityUser = true;
        }
        if(currentUser.User_Type__c == 'Customer User'){
            isCustomerUser = true;
        }  
       
        List<String> leadUploadPageAccessList = System.label.Access_To_Lead_Upload.split(',');
        if(leadUploadPageAccessList.contains(currentUser.User_Type__c)){
            hasAccessToLeadUpload = true;
        }
        if(pagename != 'MyMessages'){
            unreadmessagecountforotherpages = 0;
            FetchMessages(); 
        }    
    }
    
      public void FetchMessages(){
        System.debug('FetchMessages..');
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
        
        query = query + WhereCondition+' ORDER BY Createddate desc '; 
        System.debug('query..'+query);
        allmessages = database.query(query);
        List<string> messageIds = new List<string>();
        for(DIA_Message__c doc: allMessages){
            messageIds.add(doc.id);
        }
        
        List<DIA_Message_Log__c> messageLogs = new List<DIA_Message_Log__c>();
        
        messageLogs = [Select Id, UnRead__c, Read__c, Message__c, User__c from DIA_Message_Log__c Where Message__c IN: messageIds AND User__c =: USerinfo.getuserid() AND UnRead__c = True];
        
        unreadmessagecountforotherpages = messageLogs.size();
        System.debug('unreadmessagecountforotherpages..'+unreadmessagecountforotherpages);
    }
}