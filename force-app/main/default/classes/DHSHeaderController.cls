/**
 * @description Supplies DHS navigation state, unread-message counts, and session timing actions.
 */
@SuppressWarnings('PMD.NcssConstructorCount,PMD.UnusedMethod')
public with sharing class DHSHeaderController {
    /** @description Provides this DHS API member. */
    public User currentUser {get;set;}
    public boolean isPMOUser {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public boolean isCMOUser {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public boolean isINVUser {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public boolean isQAUser {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public boolean isSecurityUser {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public boolean isCustomerUser {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    /** @description Provides this DHS API member. */
    public integer unreadmessagecount {Get;set;}
    /** @description Provides this DHS API member. */
    public integer unreadmessagecountfrommymessages{get;set;}
    /** @description Provides this DHS API member. */
    public integer unreadmessagecountforotherpages{get;set;}
    /** @description Provides this DHS API member. */
    public string pagename{get;set;}
    public boolean hasAccessToLeadUpload{get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    /** @description Provides this DHS API member. */
    public DHSHeaderController(){
        hasAccessToLeadUpload = false;
        currentUser = [Select Id, User_Type__c from User where Id=:userinfo.getuserid() WITH USER_MODE];
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
        List<String> leadUploadPageAccessList = System.label.DHS_Access_To_Lead_Upload.split(',');
        if(leadUploadPageAccessList.contains(currentUser.User_Type__c)){
            hasAccessToLeadUpload = true;
        }
        if(pagename != 'MyMessages'){
            unreadmessagecountforotherpages = 0;
            fetchMessages(); 
        }    
    }
    
      /** @description Provides this DHS API member. */
      public void fetchMessages(){
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
        
        query = query + whereCondition+' WITH USER_MODE ORDER BY Createddate desc'; 
        allmessages = database.query(String.escapeSingleQuotes(query), AccessLevel.USER_MODE);
        List<string> messageIds = new List<string>();
        for(DHS_Message__c doc: allMessages){
            messageIds.add(doc.id);
        }
        
        List<DHS_Message_Log__c> messageLogs = new List<DHS_Message_Log__c>();
        
        messageLogs = [Select Id, UnRead__c, Read__c, DHS_Message__c, DHS_User__c from DHS_Message_Log__c Where DHS_Message__c IN: messageIds AND DHS_User__c =: USerinfo.getuserid() AND UnRead__c = True WITH USER_MODE ];
        
        unreadmessagecountforotherpages = messageLogs.size();
    }
     @RemoteAction
    /** @description Provides this DHS API member. */
    public static void updateLogoutTime(){
        id contextUser = userinfo.getuserid();
        date todayDate = system.today();
        list<DHS_TimeSheet__c> timesheets = [select id,Login_Time__c,Logout_Time__c from DHS_TimeSheet__c where DHS_User__c =:contextUser and Date__c=:todayDate WITH USER_MODE ];
        list<DHS_TimeSheet__c> updateTS = New list<DHS_TimeSheet__c>();
        if(timesheets.size() > 0){
            DHS_TimeSheet__c timeSheet = New DHS_TimeSheet__c();
            timeSheet.id = timesheets[0].Id;
            if(timeSheet.Logout_Time__c == null){
                timeSheet.Logout_Time__c = system.now();
            }
            timeSheet.Logout_Time__c = timeSheet.Logout_Time__c.addminutes(5);
            updateTS.add(timeSheet);
            Database.update(updateTS, AccessLevel.USER_MODE);
        }
        
    }
    @RemoteAction
    /**
     * @description Provides this DHS API member.
     * @param idleMinutes Method parameter.
     */
    public static void updateIdleTime(Integer idleMinutes) {
        if (idleMinutes == null || idleMinutes <= 0) {
            return;
        }
        Id contextUser = UserInfo.getUserId();
        Date todayDate = System.today();
        List<DHS_TimeSheet__c> timesheets = [
            SELECT Id, Idle_Minutes__c, Last_Active_Time__c 
            FROM DHS_TimeSheet__c 
            WHERE DHS_User__c = :contextUser AND Date__c = :todayDate
            WITH USER_MODE LIMIT 1
        ];
        
        if (!timesheets.isEmpty()) {
            DHS_TimeSheet__c timeSheet = timesheets[0];
            if (timeSheet.Idle_Minutes__c == null) {
                timeSheet.Idle_Minutes__c = 0;
            }
            if (timeSheet.Last_Active_Time__c == null) {
                timeSheet.Last_Active_Time__c = System.now();
            }
            timeSheet.Idle_Minutes__c += idleMinutes;
            timeSheet.Last_Active_Time__c = System.now();
            Database.update(timeSheet, AccessLevel.USER_MODE);
        }
    }
}
