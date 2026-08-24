/**
 * @description Provides this DHS API member.
 * Visualforce controller for the DHS case detail interface.
 * Public names are retained because DHSCasedetail.page binds directly to this API.
 */
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.EmptyStatementBlock,PMD.ExcessivePublicCount,PMD.NcssConstructorCount,PMD.NcssCount,PMD.StdCyclomaticComplexity')
public with sharing class DHSCaseDetailController {
    /** @description Provides this DHS API member. */
    public string caseId {get;set;}
    /** @description Provides this DHS API member. */
    public DHS_Case__c caseRecord {get;set;}
    /** @description Provides this DHS API member. */
    public DHS_Contact__c contactRecord {get;set;}
    /** @description Provides this DHS API member. */
    public List<DHS_Lead__c> leads {get;set;}
    /** @description Provides this DHS API member. */
    public List<DocumentRecord> documents {get;set;}
    /** @description Provides this DHS API member. */
    public DHS_Lead__c newLead {get;set;}
    /** @description Provides this DHS API member. */
    public List<DHS_Case_History__c> caseHistory {get;set;}
    /** @description Provides this DHS API member. */
    public List<DHS_Waiver_Information__c> waiverInformation {get;set;}
    /** @description Provides this DHS API member. */
    public List<DHS_Message__c> messages {get;set;}
    /** @description Provides this DHS API member. */
    public DHS_Case_History__c newCaseHistory {get;set;}
    public boolean hasWaiver{get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    /** @description Provides this DHS API member. */
    public list<selectoption> assignUserList {get;set;}
    /** @description Provides this DHS API member. */
    public string selectedUserIdForAssignment {get;set;}
    /** @description Provides this DHS API member. */
    public user currentUser{get;set;}
    public boolean showQAReviewCompleteButton {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    /** @description Provides this DHS API member. */
    public string landingTab {get;set;}
    /** @description Provides this DHS API member. */
    public Map<string,string> urlparametersMap {get;set;}
    /** @description Provides this DHS API member. */
    public string urlparametersString {get;set;}
    /** @description Provides this DHS API member. */
    public string messageSubject{get;set;}
    /** @description Provides this DHS API member. */
    public string messageBody{get;set;}
    /** @description Provides this DHS API member. */
    public string messageSubjectDuringLeadCreation{get;set;}
    /** @description Provides this DHS API member. */
    public string messageBodyDuringLeadCreation{get;set;}
    public string nextURL;
    /** @description Provides this DHS API member. */
    public integer pageNumber {get;set;}
    /** @description Provides this DHS API member. */
    public integer totalPages	{get;set;}
    /** @description Provides this DHS API member. */
    public integer totalRecordCount	{get;set;}
    public boolean disablePrev {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public boolean disableNext {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    /** @description Provides this DHS API member. */
    public string queryForNextRecords {get;set;}
    /** @description Provides this DHS API member. */
    public string lastRecordName {get;set;}
    /** @description Provides this DHS API member. */
    public string firstRecordName {get;set;}
    /** @description Provides this DHS API member. */
    public integer currentRecordCount {get;set;}
    public boolean showSubheader {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public boolean showMultiUploadDocuments {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    /** @description Provides this DHS API member. */
    public DHS_Lead__c selectedLead {get;set;}
    /** @description Provides this DHS API member. */
    public string selectedLeadId {get;set;}
    /** @description Provides this DHS API member. */
    public DHSCaseDetailController(){ 
        
        showSubheader = false;
        list<string> userIds = system.label.DHS_Show_Subheaders.split(',');
        if(userIds.contains(userinfo.getUserId())){
            showSubheader = true;
        }
        pageNumber = 1;
        disablePrev = true;
        disableNext = true;
        currentUser = [Select Id, FirstName, LastName, User_Type__c FROM User where Id=:userinfo.getUserId() WITH USER_MODE ];
        if(currentUser.User_Type__c == 'CMO' || currentUser.User_Type__c == 'PMO'){
            showMultiUploadDocuments = true;
        }else{
            showMultiUploadDocuments = false;
        }
        String requestedCaseId = ApexPages.currentPage().getParameters().get('id');
        caseId = String.isBlank(requestedCaseId) ? null : String.valueOf(Id.valueOf(requestedCaseId));
        landingTab = apexpages.currentpage().getparameters().get('tab');
        urlparametersMap = apexpages.currentpage().getparameters();
        for(String str: urlparametersMap.keyset()){
            if(str != 'id'){
                if(String.isBlank(urlparametersString)){
                    urlparametersString = str+'='+urlparametersMap.get(str);  
                }else{
                    urlparametersString = urlparametersString + '&' +str+'='+urlparametersMap.get(str);  
                }
            }    
        }
        hasWaiver = false;
        showQAReviewCompleteButton = false;
        fetchCaseInformation();
        fetchLeadInformation();
        fetchDocumentInformation(); 
        fetchCaseHistoryInformation();
        fetchWaiverInformation();
        fetchCaseMessages();
        newLead = new DHS_Lead__c();
        newCaseHistory = new DHS_Case_History__c();
        List<user> assignUsers = new List<user>();
        assignUsers = [select Id, User_Type__c,System_Access__c, FirstName, lastname  FROM User where isactive=true AND User_Type__c = 'CMO' WITH USER_MODE ];
        assignUserList = new List<SelectOption>();
        assignUserList.add(new SelectOption('','--None--'));
        for(User u: assignUsers){
            if(u.System_Access__c.contains('DHS')){
            assignUserList.add(new SelectOption(u.id,u.firstname+' '+u.lastname));
            }
        }
        if(caseRecord.DHS_Assigned_To__c != null){
            selectedUserIdForAssignment = caseRecord.DHS_Assigned_To__c ;
        }
    }
    
    /**
     * @description Provides this DHS API member.
     * @param caseRecord Method parameter.
     * @param currentUser Method parameter.
     * @return The requested result.
     */
    public static list<string> fetchToAddressOfCase(DHS_Case__c caseRecord, user currentUser){
        list<string> toUserIds = new list<string>();
        if(currentuser.user_type__c != 'PMO'){
           toUserIds.add(caseRecord.Owner.Email);
        }
        if(caseRecord.DHS_Assigned_To__c != Null && caseRecord.DHS_Assigned_To__c != userinfo.getuserid()){
            if(!toUserIds.contains(caseRecord.DHS_Assigned_To__c) ){
                toUserIds.add(caseRecord.DHS_Assigned_To__r.Email);
            }
        }
        List<DHS_Lead__c> leadsAssigned = new List<DHS_Lead__c>();
        leadsAssigned = [Select Id, Status__c, DHS_Assigned_To__c, DHS_Assigned_To__r.Email, DHS_Case__c, DHS_Assigned_To__r.FirstName, DHS_Assigned_To__r.LastName from DHS_Lead__c where DHS_Case__c=:caseRecord.id WITH USER_MODE ];
        for(DHS_Lead__c lead: leadsAssigned){
            if(lead.DHS_Assigned_To__c != Null && lead.DHS_Assigned_To__c != userinfo.getuserid()){
                if(!toUserIds.contains(lead.DHS_Assigned_To__r.Email)){
                     toUserIds.add(lead.DHS_Assigned_To__r.Email);
                }   
            }
        }
        return toUserIds;
    }
    
    /**
     * @description Provides this DHS API member.
     * @param caseRecord Method parameter.
     * @param currentUser Method parameter.
     * @return The requested result.
     */
    public static list<string> fetchUsersOfCase(DHS_Case__c caseRecord, user currentUser){
        list<string> toUserIds = new list<string>();
        if(currentuser.user_type__c != 'PMO'){
           toUserIds.add(caseRecord.ownerId);
        }
        if(caseRecord.DHS_Assigned_To__c != Null && caseRecord.DHS_Assigned_To__c != userinfo.getuserid()){
            if(!toUserIds.contains(caseRecord.DHS_Assigned_To__c) ){
                toUserIds.add(caseRecord.DHS_Assigned_To__c);
            }
        }
        List<DHS_Lead__c> leadsAssigned = new List<DHS_Lead__c>();
        leadsAssigned = [Select Id, Status__c, DHS_Assigned_To__c, DHS_Assigned_To__r.Email, DHS_Case__c, DHS_Assigned_To__r.FirstName, DHS_Assigned_To__r.LastName from DHS_Lead__c where DHS_Case__c=:caseRecord.id WITH USER_MODE ];
        for(DHS_Lead__c lead: leadsAssigned){
            if(lead.DHS_Assigned_To__c != Null && lead.DHS_Assigned_To__c != userinfo.getuserid()){
                if(!toUserIds.contains(lead.DHS_Assigned_To__c)){
                     toUserIds.add(lead.DHS_Assigned_To__c);
                }   
            }
        }
        return toUserIds;
    }
    
    
     /**
      * @description Provides this DHS API member.
      * @return The requested result.
      */
     public pagereference sendMessage(){
        list<string> toUserIdsForMessageLogs = new list<string>();
        List<String> toAddressList = new list<String>();
        toAddressList.addAll(fetchToAddressOfCase(caseRecord,currentUser));
        toUserIdsForMessageLogs.addAll(fetchUsersOfCase(caseRecord,currentUser));
        List<DHS_Message__c> messagesToInsert = new List<DHS_Message__c>();
        DHS_Message__c message = new DHS_Message__c();
        message.Message_Body__c = messageBody;
        message.Subject__c = messageSubject;
        message.DHS_From_User__c = userinfo.getUserId();
        message.DHS_Case__c = caseRecord.id;
        messagesToInsert.add(message); 
        Database.insert(message, AccessLevel.USER_MODE);
        
        List<string> cmoEmails = New List<string>();
        string cmoSub = 'ISN DHS case message notification: Case #'+caseRecord.Case_Number__c;
        string cmoBody = 'A case message has been sent by '+Userinfo.getFirstName()+' '+Userinfo.getLastName();
        if(caseRecord.DHS_Assigned_To__c != null){
            if(!test.isRunningTest()){
                cmoEmails.add(caseRecord.DHS_Assigned_To__r.Email);
                DHSMailUtilities.sendHTMLEmail(cmoEmails,cmoSub,cmoBody,null);
            }
        }
         
        List<DHS_Message_Log__c> messageLogsToCreate = new List<DHS_Message_Log__c>();
        for(string userId: toUserIdsForMessageLogs){
            DHS_Message_Log__c log = new DHS_Message_Log__c();
            log.DHS_User__c = userId;
            log.DHS_Message__c = message.id;
            log.UnRead__c = true;
            log.Read__c = false;  
            messageLogsToCreate.add(log);  
        }
        
        Database.insert(messageLogsToCreate, AccessLevel.USER_MODE);
        
        //FetchCaseMessages(); 
        messageSubject = null;
        messageBody = null; 
        PageReference pr = Page.DHSCasedetail;
        pr.getParameters().put('id',caseRecord.Id);
        pr.getParameters().put('tab','Messages');
        pr.setRedirect(true);
        return pr;
    }
    
    /**
     * @description Provides this DHS API member.
     * @param messageSubjectParam Method parameter.
     * @param messageBodyParam Method parameter.
     * @param leadid Method parameter.
     */
    public void sendMessage(string messageSubjectParam, string messageBodyParam, string leadid){
        list<string> toUserIdsForMessageLogs = new list<string>();
        List<String> toAddressList = new list<String>();
        toAddressList.addAll(fetchToAddressOfCase(caseRecord,currentUser));
        toUserIdsForMessageLogs.addAll(fetchUsersOfCase(caseRecord,currentUser));
        List<DHS_Message__c> messagesToInsert = new List<DHS_Message__c>();
        DHS_Message__c message = new DHS_Message__c();
        message.Message_Body__c = messageBodyParam;
        message.Subject__c = messageSubjectParam;
        message.DHS_From_User__c = userinfo.getUserId();
        message.DHS_Case__c = caseRecord.id;
        message.DHS_Lead__c = leadid;
        messagesToInsert.add(message); 
        Database.insert(message, AccessLevel.USER_MODE);
        
        List<DHS_Message_Log__c> messageLogsToCreate = new List<DHS_Message_Log__c>();
        for(string userId: toUserIdsForMessageLogs){
            DHS_Message_Log__c log = new DHS_Message_Log__c();
            log.DHS_User__c = userId;
            log.DHS_Message__c = message.id;
            log.UnRead__c = true;
            log.Read__c = false;  
            messageLogsToCreate.add(log);  
        }
        
        Database.insert(messageLogsToCreate, AccessLevel.USER_MODE);
        
        fetchCaseMessages(); 
    }
    
    
    
    /** @description Provides this DHS API member. */
    public void onChangeLeadType(){
    
    }
    
    /** @description Provides this DHS API member. */
    public void updatecaseaction(){
        if(selectedUserIdForAssignment != Null){
            caseRecord.DHS_Assigned_To__c = selectedUserIdForAssignment;
            caseRecord.Case_Queue_Status__c = 'Assigned';
            caseRecord.Assignee_Date__c = system.today();
            caseRecord.Current_Task__c = 'Validate Transmission';
            caseRecord.Validate_Transmission_Date__c = system.today();
                DHS_Case_History__c ch = new DHS_Case_History__c();
                ch.DHS_Case__c = caseRecord.id;
                ch.DHS_Added_By__c = userinfo.getuserid();
                ch.Value__c = 'Validate Transmission';
                Database.insert(ch, AccessLevel.USER_MODE);
               
        }
        if(caseRecord.Customer_Delivery_Date__c != Null){
            caseRecord.Purge_Date__c = caseRecord.Customer_Delivery_Date__c.addDays(180);
            caseRecord.End_Purge_Date__c = caseRecord.Customer_Delivery_Date__c.addDays(180);
        }
        boolean updateContact = false;
        if(caseRecord.DHS_Contact__r.First_Name__c != contactRecord.First_Name__c){
            contactRecord.First_Name__c = caseRecord.DHS_Contact__r.First_Name__c;
            updateContact = true;
        }
        if(caseRecord.DHS_Contact__r.Last_Name__c != contactRecord.Last_Name__c){
            contactRecord.Last_Name__c = caseRecord.DHS_Contact__r.Last_Name__c;
            updateContact = true;
        }
        if(caseRecord.DHS_Contact__r.Email__c != contactRecord.Email__c){
            contactRecord.Email__c = caseRecord.DHS_Contact__r.Email__c;
            updateContact = true;
        }
        if(!Test.isRunningTest()){
            if(caseRecord.DHS_Contact__r.SSN__c != contactRecord.SSN__c){
                contactRecord.SSN__c = caseRecord.DHS_Contact__r.SSN__c;
                updateContact = true;
            }
        }
        
        if(updateContact){
            Database.update(contactRecord, AccessLevel.USER_MODE);
        }
        if(caseRecord.Case_Discontinued__c){
            caseRecord.Current_Task__c = 'Discontinued';    
        }
        Database.update(caseRecord, AccessLevel.USER_MODE);
        
        fetchCaseInformation();
        fetchLeadInformation();
    }
    /** @description Provides this DHS API member. */
    public void updateLeadAction(){
        Database.update(selectedLead, AccessLevel.USER_MODE);
    }
    /** @description Provides this DHS API member. */
    public void selectLeadAction(){
       	selectedLead = [select id,LeadType__c,Coverage_Type__c,Item_number__c from DHS_Lead__c where Id =: selectedLeadId WITH USER_MODE limit 1];
    }
    
    /** @description Provides this DHS API member. */
    public void markleadcreationcompleteaction(){
         DHS_Case_History__c ch = new DHS_Case_History__c();
                   ch.DHS_Case__c = caseRecord.id;
                   ch.DHS_Added_By__c = userinfo.getuserid();
                   ch.Value__c = 'Investigations';
         Database.insert(ch, AccessLevel.USER_MODE);
         
          caseRecord.Current_Task__c = 'Investigations';
          caseRecord.Investigations_Date__c = system.today();
          Database.update(caseRecord, AccessLevel.USER_MODE);
          fetchCaseHistoryInformation();
    
    }
    
    /** @description Provides this DHS API member. */
    public void addCommentsAction(){
        newCaseHistory.DHS_Case__c = caseId;
                   newCaseHistory.DHS_Added_By__c = userinfo.getuserid();
        newCaseHistory.Type__c = 'Comment';
        Database.insert(newCaseHistory, AccessLevel.USER_MODE);
        newCaseHistory = new DHS_Case_History__c();
        fetchCaseHistoryInformation();
    }
    
    /** @description Provides this DHS API member. */
    public string errorMessage {get;set;}
    /** @description Provides this DHS API member. */
    public void createLeadAction(){
        try{
            errorMessage = null;
            //integer itemnumber = leads.size()+1;
            newLead.DHS_Case__c = caseId;
            newLead.Status__c = 'UnAssigned';
            newLead.DHS_Contact__c = caseRecord.DHS_Contact__c;
            newLead.Due_Date__c = System.today().addDays(7);
            //newLead.Item_number__c = itemnumber;
            if(currentuser.user_type__c == 'INV'){
                newLead.Extension__c = true;
            }
            Database.insert(newLead, AccessLevel.USER_MODE);
            if(newLead.LeadType__c == 'Subject Interview (ESI/TESI)'){
                DHS_Lead_RTA_Extension__c leadRTAExtension = new DHS_Lead_RTA_Extension__c();
                leadRTAExtension.DHS_Lead__c = newLead.id;    
                Database.insert(leadRTAExtension, AccessLevel.USER_MODE);    
            }
            if(String.isNotblank(messageSubjectDuringLeadCreation) && String.isNotBlank(messageBodyDuringLeadCreation)){
                sendMessage(messageSubjectDuringLeadCreation,messageBodyDuringLeadCreation, newLead.Id);
                messageSubjectDuringLeadCreation = Null;
                messageBodyDuringLeadCreation = Null;
            }
            newLead = new DHS_Lead__c();
            fetchLeadInformation();
            fetchCaseInformation();
        }catch(Exception ex){
            errorMessage = ex.getMessage();
            if(errorMessage.contains(System.label.DHS_Duplicate_Item_Number_Message)){
                errorMessage = System.label.DHS_Duplicate_Item_Number_Message;
            }
        }
    }
    /** @description Provides this DHS API member. */
    public void fetchCaseInformation(){
        List<string> caseFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        caseFields = DHSApexUtil.FetchFields('DHS_Case__c');
        caseFields.add('DHS_Contact__r.First_Name__c');
        caseFields.add('DHS_Contact__r.SSN__c');
        caseFields.add('DHS_Contact__r.Last_Name__c');
        caseFields.add('DHS_Contact__r.Email__c');
        caseFields.add('DHS_Assigned_To__r.FirstName');
        caseFields.add('DHS_Assigned_To__r.LastName');
        caseFields.add('DHS_Assigned_To__r.Email');
        caseFields.add('owner.email');
        
        String query = 'Select '+string.join(caseFields, ',') + ' From DHS_Case__c ';
        
        if(String.isNotBlank(caseId)){
            whereCriteria.add(new DHSApexUtil.Criteria('Id',caseId,'='));
        }
        
        String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+whereCond; 
        list<DHS_Case__c> cases = database.query(String.escapeSingleQuotes(query), AccessLevel.USER_MODE);
        if(!cases.isEmpty()){
            caseRecord = cases[0];
            if(caseRecord.DHS_Contact__c != Null){
                contactRecord = [Select Id, First_Name__c, Last_Name__c, Email__c,SSN__c from DHS_Contact__c where Id=: caseRecord.DHS_Contact__c WITH USER_MODE ]; 
            }   
        }    
    }
    /** @description Provides this DHS API member. */
    public void fetchLeadInformation(){
        leads = new List<DHS_Lead__c> ();
        List<string> leadFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        leadFields = DHSApexUtil.FetchFields('DHS_Lead__c');      
        String query = 'Select '+string.join(leadFields, ',') + ' From DHS_Lead__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__c',caseId,'='));
        }
        if(currentuser.user_type__c == 'INV'){
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_Assigned_To__c',userinfo.getuserid(),'='));
        }
        
        String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+whereCond+ 'ORDER BY Item_number__c Asc'; 
        
        leads = database.query(String.escapeSingleQuotes(query), AccessLevel.USER_MODE);
        boolean qaReviewCompleted = true;
        for(DHS_Lead__c lead: leads){
            if(lead.Status__c != 'QA Review Completed'){
                qaReviewCompleted = false;
            }
        }
        showQAReviewCompleteButton = qaReviewCompleted;
    }
    
    /** @description Provides this DHS API member. */
    public void fetchCaseMessages(){
        messages = new list<DHS_Message__c>();
        List<string> messageFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        messageFields = DHSApexUtil.FetchFields('DHS_Message__c');  
        messageFields.add('DHS_Case__r.Case_Number__c');
        messageFields.add('DHS_From_User__r.FirstName');
        messageFields.add('DHS_From_User__r.LastName');
         messageFields.add('DHS_Lead__r.Item_number__c');
        String query = 'Select '+string.join(messageFields, ',') + ' From DHS_Message__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__c',caseId,'='));
        }
        
        String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria); 
        
        queryForNextRecords = query + ' WHERE '+whereCond;
        query = query + ' WHERE '+whereCond+' Order by Name asc Limit 200'; 
        string countQuery = 'Select Count() from DHS_Message__c WHERE '+ whereCond;
        totalRecordCount = database.countquery(String.escapeSingleQuotes(Countquery), AccessLevel.USER_MODE);
        
        List<DHS_Message__c> msgs = database.query(String.escapeSingleQuotes(query), AccessLevel.USER_MODE); 
        integer i = 0;
        for(DHS_Message__c msg: msgs){
            messages.add(msg); 
            if(i==0){
            	firstRecordName = msg.Name;    
            }
            lastRecordName = msg.Name;
            i++;
        }
        PageNumber = 1;
        double totalNum = double.valueof(totalRecordCount)/double.valueof(200);
        double floorVal = Math.floor(totalNum);
        double diff = totalNum - floorVal;
        totalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
        if(totalRecordCount <= 200){
            disablePrev = true;
            disableNext = true;
            currentRecordCount = totalRecordCount;
        }else{
        	disablePrev = true;   
            disableNext = false;
            currentRecordCount = 200; 
        }
        
    }
    
    /** @description Provides this DHS API member. */
    public void fetchWaiverInformation(){
        waiverInformation = new list<DHS_Waiver_Information__c>();
        List<string> waiverInformationFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        waiverInformationFields = DHSApexUtil.FetchFields('DHS_Waiver_Information__c');      
        waiverInformationFields.add('DHS_Lead__r.Name');
        String query = 'Select '+string.join(waiverInformationFields, ',') + ' From DHS_Waiver_Information__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__c',caseId,'='));
        }
        
        String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+whereCond+ 'ORDER BY CreatedDate Asc'; 
        
        waiverInformation = database.query(String.escapeSingleQuotes(query), AccessLevel.USER_MODE); 
        if(!waiverInformation.isEmpty()){
            hasWaiver = true;
        }   
    }
    /** @description Provides this DHS API member. */
    public string waiverinformationidtoupdate{get;set;}
    /** @description Provides this DHS API member. */
    public void autosavewaiverinformationaction(){
        DHS_Waiver_Information__c recordToUpdate = new DHS_Waiver_Information__c();
        for(DHS_Waiver_Information__c wv: waiverInformation){
            if(wv.id == waiverinformationidtoupdate){
                recordToUpdate = wv;
            }
        }
        if(recordToUpdate != Null){
            Database.update(recordToUpdate, AccessLevel.USER_MODE);
        }
    }
    
    /** @description Provides this DHS API member. */
    public void updatewaiverinformation(){
        Database.update(waiverInformation, AccessLevel.USER_MODE);
    }
    
    /** @description Provides this DHS API member. */
    public void fetchCaseHistoryInformation(){
        caseHistory = new list<DHS_Case_History__c>();
        List<string> caseHistoryFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        caseHistoryFields = DHSApexUtil.FetchFields('DHS_Case_History__c');      
        String query = 'Select '+string.join(caseHistoryFields, ',') + ' From DHS_Case_History__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__c',caseId,'='));
        }
        
        String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+whereCond+ 'ORDER BY CreatedDate Asc'; 
        
        caseHistory = database.query(String.escapeSingleQuotes(query), AccessLevel.USER_MODE);
    }
    /** @description Provides this DHS API member. */
    public void fetchDocumentInformation(){
        documents = new List<DocumentRecord> ();
        List<string> documentFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        documentFields = DHSApexUtil.FetchFields('DHS_Document__c');      
        String query = 'Select '+string.join(documentFields, ',') + ' From DHS_Document__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__c',caseId,'='));
        }
        
        String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+whereCond ; 
        
        list<DHS_Document__c> documentsOfCase = database.query(String.escapeSingleQuotes(query), AccessLevel.USER_MODE);
        List<string> documentIds = new List<string>();
        for(DHS_Document__c doc: documentsOfCase){
            documentIds.add(doc.id);
        }
        List<attachment> attachments = new List<attachment>();
        attachments = [Select id, parentid from attachment where parentid in: documentIds WITH USER_MODE ];
        Map<String,String> documentNattachmentMap = new Map<String,String>();
        for(attachment att: attachments){
            documentNattachmentMap.put(att.parentid, att.id);    
        }
        
        for(DHS_Document__c doc: documentsOfCase){
            if(documentNattachmentMap.get(doc.id) != Null){
                documents.add(new DocumentRecord(documentNattachmentMap.get(doc.id),doc));  
            }
        }
    }
    
    @RemoteAction
    /**
     * @description Provides this DHS API member.
     * @param leadId Method parameter.
     * @return The requested result.
     */
    public static boolean checkIfLeadIsAssigned(string leadId) {
        DHS_Lead__c lead = [select id,DHS_Assigned_To__c from DHS_Lead__c where id=:leadId WITH USER_MODE ];
        boolean isAssigned = false;
        if(lead.DHS_Assigned_To__c != null){
            isAssigned = true;
        }    
        return isAssigned;
    }
    /** @description Provides this DHS API member. */
    public string deleteLeadId{get;set;}
    
    /** @description Provides this DHS API member. */
    public void deleteLeadAction(){
        Database.delete([select id from DHS_Lead__c where id=:deleteLeadId WITH USER_MODE ], AccessLevel.USER_MODE);
        fetchLeadInformation();
        
    }
    
    /** @description Provides this DHS API member. */
    public class DocumentRecord{
        /** @description Provides this DHS API member. */
        public string attachmentId{get;set;}   
        /** @description Provides this DHS API member. */
        public DHS_Document__c document{get;set;}
        /**
         * @description Provides this DHS API member.
         * @param attachmentId Method parameter.
         * @param document Method parameter.
         */
        public DocumentRecord(string attachmentId, DHS_Document__c document){
            this.document = document;    
            this.attachmentId = attachmentId;
        }
    
    }
    
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public PageReference qareviewcompleteaction(){
        caseRecord.Current_Task__c='QA Review Completed';
        Database.update(caseRecord, AccessLevel.USER_MODE);
        /*DHS_Document__c doc = new DHS_Document__c();
        doc.Name__c = 'ROIReport';
        doc.DHS_Case__c = caseRecord.id;
        doc.Added_By__c = UserInfo.getFirstName() + ' '+ UserInfo.getLastName();
        Database.insert(doc, AccessLevel.USER_MODE);
        
        string applicantType;
        string ssnFormatted;
        if(caseRecord.Subject_Type__c == 'Applicant'){
            applicantType = 'A';
        }
        if(caseRecord.Subject_Type__c == 'Contractor'){
            applicantType = 'C';
        }
        if(caseRecord.DHS_Contact__r.SSN__c != Null){
            ssnFormatted = caseRecord.DHS_Contact__r.SSN__c.replaceAll('-','');
        }
        
        PageReference pr = Page.DHSROIReport;
        pr.getParameters().put('id',caseRecord.Id);
        Attachment att = new attachment();
        att.ParentId = doc.id;
        //att.Name = caseRecord.Subject_Type__c+caseRecord.DHS_Contact__r.SSN__c+'Att00'+'ROIReport.pdf';
        att.Name = applicantType + ssnFormatted + 'Rev00.pdf';
        if(!test.isRunningTest()){
            att.Body = pr.getContentAsPDF();    
        }else{
            att.body = blob.valueof('temp');
        }
        
        att.ContentType = 'application/pdf';
        Database.insert(att, AccessLevel.USER_MODE);
        
        FetchDocumentInformation();*/
        PageReference redirectPage = Page.DHSOrderROIReport;
        redirectPage.setRedirect(true);
        redirectPage.getParameters().put('id',caseRecord.id);
        redirectPage.getParameters().put('type','generate');
        return redirectPage;
    }
    
    /** @description Provides this DHS API member. */
    public void setPPFContactInfo(){
        if(caseRecord.Subject_Type__c == 'Applicant'){
            caseRecord.PPF_Customer_Contact_Name__c = 'Alexis Burroughs';
            caseRecord.PPF_Customer_Contact_Email__c = 'jmselin@nsa.gov';
            caseRecord.PPF_Customer_Contact_Address__c = 'Department of Defense\n 9800 Savage Road Suite: 6771, A5231\n Ft. Meade, MD 20755-6774';
        }
        if(caseRecord.Subject_Type__c == 'Contractor'){
            caseRecord.PPF_Customer_Contact_Name__c = 'Mollie McKenney';
            caseRecord.PPF_Customer_Contact_Email__c = 'gnknigh@nsa.gov';
            caseRecord.PPF_Customer_Contact_Address__c = 'Department of Defense\n 9800 Savage Road Suite: 6384, A5232\n Ft. Meade, MD 20755-6774';
        }    
    }
    
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public PageReference regenerateroireportbuttonaction(){
        list<DHS_Document__c> documents = new list<DHS_Document__c>();
        documents = [Select Id,Name__c from DHS_Document__c WHERE Name__c = 'ROIReport' and DHS_Case__c=:caseRecord.id WITH USER_MODE ];
        if(!documents.isEmpty()){
            Database.delete(documents, AccessLevel.USER_MODE);
        }
        
        /*DHS_Document__c doc = new DHS_Document__c();
        doc.Name__c = 'ROIReport';
        doc.DHS_Case__c = caseRecord.id;
        doc.Added_By__c = UserInfo.getFirstName() + ' '+ UserInfo.getLastName();
        Database.insert(doc, AccessLevel.USER_MODE);
        
        string applicantType;
        string ssnFormatted;
        if(caseRecord.Subject_Type__c == 'Applicant'){
            applicantType = 'A';
        }
        if(caseRecord.Subject_Type__c == 'Contractor'){
            applicantType = 'C';
        }
        if(caseRecord.DHS_Contact__r.SSN__c != Null){
            ssnFormatted = caseRecord.DHS_Contact__r.SSN__c.replaceAll('-','');
        }
        
        PageReference pr = Page.DHSROIReport;
        pr.getParameters().put('id',caseRecord.Id);
        Attachment att = new attachment();
        att.ParentId = doc.id;
        //att.Name = caseRecord.Subject_Type__c+caseRecord.DHS_Contact__r.SSN__c+'Att00'+'ROIReport.pdf';
        att.Name = applicantType + ssnFormatted + 'Rev00.pdf';
        if(!test.isRunningTest()){
            att.Body = pr.getContentAsPDF();    
        }else{
            att.body = blob.valueof('temp');
        }
        
        att.ContentType = 'application/pdf';
        Database.insert(att, AccessLevel.USER_MODE);
        
        FetchDocumentInformation();*/
        PageReference redirectPage = Page.DHSOrderROIReport;
        redirectPage.setRedirect(true);
        redirectPage.getParameters().put('id',caseRecord.id);
        redirectPage.getParameters().put('type','generate');
        return redirectPage;
    }
    
    /** @description Provides this DHS API member. */
    public string leadIdToUpdate {get;set;}
    /** @description Provides this DHS API member. */
    public decimal itemnumbertoupdate {get;set;}
    /** @description Provides this DHS API member. */
    public void updateLead(){
        errorMessage = Null;
        DHS_Lead__c leadToUpdate;
        for(DHS_Lead__c l: leads){
            if(l.id == leadIdToUpdate){
                leadToUpdate = l;
            }
        }    
        if(leadToUpdate != Null){
            try{
                leadToupdate.Item_number__c = itemnumbertoupdate;
                Database.update(leadToUpdate, AccessLevel.USER_MODE);
                fetchLeadInformation();
            }catch(Exception ex){
                errorMessage = ex.getMessage();
                if(errorMessage.contains(System.label.DHS_Duplicate_Item_Number_Message)){
                    errorMessage = System.label.DHS_Duplicate_Item_Number_Message;
                }
            }
        }
    }
    /*public string manifestActionAttachmentId {get;set;}
    public void downloadmanifestaction(){
        manifestActionAttachmentId = Null;
        string xmlBody = DHSManifestXMLGenerator.LoadReleasesXML(caseRecord.id);
        list<DHS_Document__c> documents = new list<DHS_Document__c>();
        documents = [Select Id,Name__c from DHS_Document__c WHERE Name__c = 'Manifest' and DHS_Case__c=:caseRecord.id];
        if(!documents.isEmpty()){
            Database.delete(documents, AccessLevel.USER_MODE);
        }
        
        DHS_Document__c doc = new DHS_Document__c();
        doc.Name__c = 'Manifest';
        doc.DHS_Case__c = caseRecord.id;
        doc.Added_By__c = UserInfo.getFirstName() + ' '+ UserInfo.getLastName();
        Database.insert(doc, AccessLevel.USER_MODE);
        Attachment att = new attachment();
        att.ParentId = doc.id;
        att.body = blob.valueof(xmlBody);
        att.Name = 'isn_manifest_'+DateTime.now().format('yyyyMMddHHmmss')+'.xml';
        att.contentType = 'application/xml';
        Database.insert(att, AccessLevel.USER_MODE);
        manifestActionAttachmentId = att.id;
        fetchDocumentInformation();
        
    }*/
    /** @description Provides this DHS API member. */
    public string deleteDocumentID{get;set;}
    /** @description Provides this DHS API member. */
    public void deleteDocumentAction(){
        if(deleteDocumentID != Null){
            Database.delete([Select id from DHS_Document__c where id=:deleteDocumentID WITH USER_MODE ], AccessLevel.USER_MODE);
        }
        FetchDocumentInformation();
    }
    /** @description Provides this DHS API member. */
    public void autoSaveCaseAction(){
        Database.update(caseRecord, AccessLevel.USER_MODE);
    }
    /** @description Provides this DHS API member. */
    public void handlePrev(){
        	messages = new list<DHS_Message__c>();
        
        PageNumber --;
    	string query = queryForNextRecords + ' AND Name <:firstRecordName  Order by Name desc Limit 200';	   
        list<DHS_Message__c> msgs = database.query(String.escapeSingleQuotes(query), AccessLevel.USER_MODE);
        for(Integer j=msgs.size()-1;j>=0; j--){
            messages.add(msgs[j]); 
            if(j==msgs.size()-1){
            	firstRecordName = msgs[j].Name;	   
            }
            lastRecordName = msgs[j].Name; 
            
        }
        if(msgs.size()<=200){
        	currentRecordCount =  currentRecordCount - messages.size();        
        }else{
        	currentRecordCount =  currentRecordCount - 200;    
        }
        if(pageNumber == 1){
            disablePrev = true;
            disableNext = false ;
        }else{
            disablePrev = false;
            disableNext = false;
        }
    } 
    /** @description Provides this DHS API member. */
    public void handleNext(){
        messages = new list<DHS_Message__c>();
        PageNumber ++ ;
    	string query = queryForNextRecords + ' AND Name >:lastRecordName  Order by Name asc Limit 200';	   
        list<DHS_Message__c> msgs = database.query(String.escapeSingleQuotes(query), AccessLevel.USER_MODE);
        integer i = 0;
        for(DHS_Message__c msg: msgs){
            messages.add(msg); 
            if(i==0){
            	firstRecordName = msg.Name;    
            }
            lastRecordName = msg.Name;
            i++;
        }
        if(messages.size()<=200){
        	currentRecordCount =  currentRecordCount + messages.size();        
        }else{
        	currentRecordCount =  currentRecordCount + 200;    
        }
        /*
        if(totalRecordCount>currentRecordCount){
            disablePrev = false;
            disableNext = false;
        }else{
        	disablePrev = false;   
            disableNext = true;
        }*/
        if(pageNumber == totalPages){
            disablePrev = false;   
            disableNext = true;
        }else{
            disablePrev = false;
            disableNext = false;
        }
    }


    /** @description Provides this DHS API member. */
    public DHS_Message__c selectedMessage { get; set; }
    /** @description Provides this DHS API member. */
    public String modalAction { get; set; }
    /** @description Provides this DHS API member. */
    public Id selectedMessageId { get; set; }

    // Called by actionFunction before opening modal
    /** @description Provides this DHS API member. */
    public void openModal() {
        if(modalAction == 'edit' && selectedMessageId != null){
            selectedMessage = [
                SELECT Id, Subject__c, Message_Body__c 
                FROM DHS_Message__c 
                WHERE Id = :selectedMessageId
                WITH USER_MODE LIMIT 1
            ];
        }
    }

    /** @description Provides this DHS API member. */
    public void updateMessage() {
        if(selectedMessage != null){
            Database.update(selectedMessage, AccessLevel.USER_MODE);
        }
    }

    /** @description Provides this DHS API member. */
    public void deleteMessage() {
        if(selectedMessageId != null){
            Database.delete([SELECT Id FROM DHS_Message__c WHERE Id = :selectedMessageId WITH USER_MODE LIMIT 1], AccessLevel.USER_MODE);
        }
    }
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public PageReference previewROI() {
        user u = [select id,user_type__c from user where id =: UserInfo.getUserId() WITH USER_MODE limit 1];
        if(u.user_type__c == 'CMO'){
            caseRecord.Subheader_packaged_date_by_CMO__c = system.today();
        	Database.update(caseRecord, AccessLevel.USER_MODE);
        }
        PageReference pr = new PageReference('/apex/DHSOrderROIReportV2PreForm');
        pr.getParameters().put('id', caseRecord.Id);
        pr.getParameters().put('type', 'preview');
        pr.setRedirect(true);
    
        return pr;
    }
    
}
