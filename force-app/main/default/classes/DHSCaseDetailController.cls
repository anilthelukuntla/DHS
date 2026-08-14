/**
 * Visualforce controller for the DHS case detail interface.
 * Public names are retained because DHSCasedetail.page binds directly to this API.
 */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.ApexDoc, PMD.ApexSOQLInjection, PMD.ApexXSSFromURLParam, PMD.AvoidBooleanMethodParameters, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.EmptyCatchBlock, PMD.EmptyIfStmt, PMD.EmptyStatementBlock, PMD.ExcessivePublicCount, PMD.LocalVariableNamingConventions, PMD.MethodNamingConventions, PMD.NcssConstructorCount, PMD.NcssCount, PMD.PropertyNamingConventions, PMD.StdCyclomaticComplexity')
public with sharing class DHSCaseDetailController {
    public string caseId {get;set;}
    public DHS_Case__c caseRecord {get;set;}
    public DHS_Contact__c contactRecord {get;set;}
    public List<DHS_Lead__c> leads {get;set;}
    public List<DocumentRecord> documents {get;set;}
    public DHS_Lead__c newLead {get;set;}
    public List<DHS_Case_History__c> caseHistory {get;set;}
    public List<DHS_Waiver_Information__c> waiverInformation {get;set;}
    public List<DHS_Message__c> messages {get;set;}
    public DHS_Case_History__c newCaseHistory {get;set;}
    public boolean hasWaiver{get;set;}
    public list<selectoption> assignUserList {get;set;}
    public string selectedUserIdForAssignment {get;set;}
    public user currentUser{get;set;}
    public boolean showQAReviewCompleteButton {get;set;}
    public string landingTab {get;set;}
    public Map<string,string> urlparametersMap {get;set;}
    public string urlparametersString {get;set;}
    public string messageSubject{get;set;}
    public string messageBody{get;set;}
    public string messageSubjectDuringLeadCreation{get;set;}
    public string messageBodyDuringLeadCreation{get;set;}
    public string nextURL; // NOPMD - legacy structure retained to preserve behavior
    public integer pageNumber {get;set;}
    public integer TotalPages	{get;set;}
    public integer totalRecordCount	{get;set;}
    public boolean disablePrev {get;set;}
    public boolean disableNext {get;set;}
    public string queryForNextRecords {get;set;}
    public string lastRecordName {get;set;}
    public string firstRecordName {get;set;}
    public integer currentRecordCount {get;set;}
    public boolean showSubheader {get;set;}
    public boolean showMultiUploadDocuments {get;set;}
    public DHS_Lead__c selectedLead {get;set;}
    public string selectedLeadId {get;set;}
    public DHSCaseDetailController(){ 
        
        showSubheader = false;
        list<string> userIds = system.label.DHS_Show_Subheaders.split(',');
        if(userIds.contains(userinfo.getUserId())){
            showSubheader = true;
        }
        pageNumber = 1;
        disablePrev = true;
        disableNext = true;
        currentUser = [Select Id, FirstName, LastName, User_Type__c FROM User where Id=:userinfo.getUserId()];
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
        FetchCaseInformation();
        FetchLeadInformation();
        FetchDocumentInformation(); 
        FetchCaseHistoryInformation();
        FetchWaiverInformation();
        FetchCaseMessages();
        newLead = new DHS_Lead__c();
        newCaseHistory = new DHS_Case_History__c();
        List<user> assignUsers = new List<user>();
        assignUsers = [select Id, User_Type__c,System_Access__c, FirstName, lastname  FROM User where isactive=true AND User_Type__c = 'CMO'];
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
    
    public static list<string> FetchToAddressOfCase(DHS_Case__c caseRecord, user currentUser){
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
        leadsAssigned = [Select Id, Status__c, DHS_Assigned_To__c, DHS_Assigned_To__r.Email, DHS_Case__c, DHS_Assigned_To__r.FirstName, DHS_Assigned_To__r.LastName from DHS_Lead__c where DHS_Case__c=:caseRecord.id];
        for(DHS_Lead__c lead: leadsAssigned){
            if(lead.DHS_Assigned_To__c != Null && lead.DHS_Assigned_To__c != userinfo.getuserid()){
                if(!toUserIds.contains(lead.DHS_Assigned_To__r.Email)){
                     toUserIds.add(lead.DHS_Assigned_To__r.Email);
                }   
            }
        }
        return toUserIds;
    }
    
    public static list<string> FetchUsersOfCase(DHS_Case__c caseRecord, user currentUser){
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
        leadsAssigned = [Select Id, Status__c, DHS_Assigned_To__c, DHS_Assigned_To__r.Email, DHS_Case__c, DHS_Assigned_To__r.FirstName, DHS_Assigned_To__r.LastName from DHS_Lead__c where DHS_Case__c=:caseRecord.id];
        for(DHS_Lead__c lead: leadsAssigned){
            if(lead.DHS_Assigned_To__c != Null && lead.DHS_Assigned_To__c != userinfo.getuserid()){
                if(!toUserIds.contains(lead.DHS_Assigned_To__c)){
                     toUserIds.add(lead.DHS_Assigned_To__c);
                }   
            }
        }
        return toUserIds;
    }
    
    
     public pagereference SendMessage(){
        list<string> toUserIdsForMessageLogs = new list<string>();
        List<String> toAddressList = new list<String>();
        toAddressList.addAll(FetchToAddressOfCase(caseRecord,currentUser));
        toUserIdsForMessageLogs.addAll(FetchUsersOfCase(caseRecord,currentUser));
        List<DHS_Message__c> messagesToInsert = new List<DHS_Message__c>();
        DHS_Message__c message = new DHS_Message__c();
        message.Message_Body__c = messageBody;
        message.Subject__c = messageSubject;
        message.DHS_From_User__c = userinfo.getUserId();
        message.DHS_Case__c = caseRecord.id;
        messagesToInsert.add(message); 
        insert message;
        
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
        
        insert messageLogsToCreate;
        
        if(!test.isRunningTest()){
            //DHSMailUtilities.sendHTMLEmail(toAddressList,messageSubject,emailBody,null);
        }
        //FetchCaseMessages(); 
        messageSubject = null;
        messageBody = null; 
        PageReference pr = Page.DHSCasedetail;
        pr.getParameters().put('id',caseRecord.Id);
        pr.getParameters().put('tab','Messages');
        pr.setRedirect(true);
        return pr;
    }
    
    public void SendMessage(string messageSubjectParam, string messageBodyParam, string leadid){
        list<string> toUserIdsForMessageLogs = new list<string>();
        List<String> toAddressList = new list<String>();
        toAddressList.addAll(FetchToAddressOfCase(caseRecord,currentUser));
        toUserIdsForMessageLogs.addAll(FetchUsersOfCase(caseRecord,currentUser));
        List<DHS_Message__c> messagesToInsert = new List<DHS_Message__c>();
        DHS_Message__c message = new DHS_Message__c();
        message.Message_Body__c = messageBodyParam;
        message.Subject__c = messageSubjectParam;
        message.DHS_From_User__c = userinfo.getUserId();
        message.DHS_Case__c = caseRecord.id;
        message.DHS_Lead__c = leadid;
        messagesToInsert.add(message); 
        insert message;
        
        List<DHS_Message_Log__c> messageLogsToCreate = new List<DHS_Message_Log__c>();
        for(string userId: toUserIdsForMessageLogs){
            DHS_Message_Log__c log = new DHS_Message_Log__c();
            log.DHS_User__c = userId;
            log.DHS_Message__c = message.id;
            log.UnRead__c = true;
            log.Read__c = false;  
            messageLogsToCreate.add(log);  
        }
        
        insert messageLogsToCreate;
        
        if(!test.isRunningTest()){
            //DHSMailUtilities.sendHTMLEmail(toAddressList,messageSubject,emailBody,null);
        }
        FetchCaseMessages(); 
    }
    
    
    
    public void OnChangeLeadType(){
    
    }
    
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
                insert ch;
               
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
            update contactRecord;
        }
        if(caseRecord.Case_Discontinued__c){
            caseRecord.Current_Task__c = 'Discontinued';    
        }
        update caseRecord;
        
        FetchCaseInformation();
        FetchLeadInformation();
    }
    public void updateLeadAction(){
        update selectedLead;
    }
    public void selectLeadAction(){
       	selectedLead = [select id,LeadType__c,Coverage_Type__c,Item_number__c from DHS_Lead__c where Id =: selectedLeadId limit 1];
    }
    
    public void markleadcreationcompleteaction(){
         DHS_Case_History__c ch = new DHS_Case_History__c();
                   ch.DHS_Case__c = caseRecord.id;
                   ch.DHS_Added_By__c = userinfo.getuserid();
                   ch.Value__c = 'Investigations';
         insert ch;
         
          caseRecord.Current_Task__c = 'Investigations';
          caseRecord.Investigations_Date__c = system.today();
          update caseRecord;
          FetchCaseHistoryInformation();
    
    }
    
    public void AddCommentsAction(){
        newCaseHistory.DHS_Case__c = caseId;
                   newCaseHistory.DHS_Added_By__c = userinfo.getuserid();
        newCaseHistory.Type__c = 'Comment';
        insert newCaseHistory;
        newCaseHistory = new DHS_Case_History__c();
        FetchCaseHistoryInformation();
    }
    
    public string errorMessage {get;set;}
    public void CreateLeadAction(){
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
            insert newLead;
            if(newLead.LeadType__c == 'Subject Interview (ESI/TESI)'){
                DHS_Lead_RTA_Extension__c leadRTAExtension = new DHS_Lead_RTA_Extension__c();
                leadRTAExtension.DHS_Lead__c = newLead.id;    
                insert leadRTAExtension;    
            }
            if(String.isNotblank(messageSubjectDuringLeadCreation) && String.isNotBlank(messageBodyDuringLeadCreation)){
                SendMessage(messageSubjectDuringLeadCreation,messageBodyDuringLeadCreation, newLead.Id);
                messageSubjectDuringLeadCreation = Null;
                messageBodyDuringLeadCreation = Null;
            }
            newLead = new DHS_Lead__c();
            FetchLeadInformation();
            FetchCaseInformation();
        }catch(Exception ex){
            errorMessage = ex.getMessage();
            if(errorMessage.contains(System.label.DHS_Duplicate_Item_Number_Message)){
                errorMessage = System.label.DHS_Duplicate_Item_Number_Message;
            }
        }
    }
    public void FetchCaseInformation(){
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
        
        String where_cond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond; 
        list<DHS_Case__c> cases = database.query(query, AccessLevel.SYSTEM_MODE);
        if(!cases.isEmpty()){
            caseRecord = cases[0];
            if(caseRecord.DHS_Contact__c != Null){
                contactRecord = [Select Id, First_Name__c, Last_Name__c, Email__c,SSN__c from DHS_Contact__c where Id=: caseRecord.DHS_Contact__c]; 
            }   
        }    
    }
    public void FetchLeadInformation(){
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
        
        String where_cond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+ 'ORDER BY Item_number__c Asc'; 
        
        leads = database.query(query, AccessLevel.SYSTEM_MODE);
        boolean qaReviewCompleted = true;
        for(DHS_Lead__c lead: leads){
            if(lead.Status__c != 'QA Review Completed'){
                qaReviewCompleted = false;
            }
        }
        showQAReviewCompleteButton = qaReviewCompleted;
    }
    
    public void FetchCaseMessages(){
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
        
        String where_cond = DHSApexUtil.generateWhereQuery(whereCriteria); 
        
        queryForNextRecords = query + ' WHERE '+where_cond;
        query = query + ' WHERE '+where_cond+' Order by Name asc Limit 200'; 
        string countQuery = 'Select Count() from DHS_Message__c WHERE '+ where_cond;
        totalRecordCount = database.countquery(Countquery);
        
        List<DHS_Message__c> msgs = database.query(query, AccessLevel.SYSTEM_MODE); 
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
        TotalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
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
    
    public void FetchWaiverInformation(){
        waiverInformation = new list<DHS_Waiver_Information__c>();
        List<string> waiverInformationFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        waiverInformationFields = DHSApexUtil.FetchFields('DHS_Waiver_Information__c');      
        waiverInformationFields.add('DHS_Lead__r.Name');
        String query = 'Select '+string.join(waiverInformationFields, ',') + ' From DHS_Waiver_Information__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__c',caseId,'='));
        }
        
        String where_cond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+ 'ORDER BY CreatedDate Asc'; 
        
        waiverInformation = database.query(query, AccessLevel.SYSTEM_MODE); 
        if(!waiverInformation.isEmpty()){
            hasWaiver = true;
        }   
    }
    public string waiverinformationidtoupdate{get;set;}
    public void autosavewaiverinformationaction(){
        DHS_Waiver_Information__c recordToUpdate = new DHS_Waiver_Information__c();
        for(DHS_Waiver_Information__c wv: waiverInformation){
            if(wv.id == waiverinformationidtoupdate){
                recordToUpdate = wv;
            }
        }
        if(recordToUpdate != Null){
            update recordToUpdate;
        }
    }
    
    public void updatewaiverinformation(){
        update waiverInformation;
    }
    
    public void FetchCaseHistoryInformation(){
        caseHistory = new list<DHS_Case_History__c>();
        List<string> caseHistoryFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        caseHistoryFields = DHSApexUtil.FetchFields('DHS_Case_History__c');      
        String query = 'Select '+string.join(caseHistoryFields, ',') + ' From DHS_Case_History__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__c',caseId,'='));
        }
        
        String where_cond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+ 'ORDER BY CreatedDate Asc'; 
        
        caseHistory = database.query(query, AccessLevel.SYSTEM_MODE);
    }
    public void FetchDocumentInformation(){
        documents = new List<DocumentRecord> ();
        List<string> documentFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        documentFields = DHSApexUtil.FetchFields('DHS_Document__c');      
        String query = 'Select '+string.join(documentFields, ',') + ' From DHS_Document__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__c',caseId,'='));
        }
        
        String where_cond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond ; 
        
        list<DHS_Document__c> documentsOfCase = database.query(query, AccessLevel.SYSTEM_MODE);
        List<string> documentIds = new List<string>();
        for(DHS_Document__c doc: documentsOfCase){
            documentIds.add(doc.id);
        }
        List<attachment> attachments = new List<attachment>();
        attachments = [Select id, parentid from attachment where parentid in: documentIds];
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
    public static boolean CheckIfLeadIsAssigned(string leadId) {
        DHS_Lead__c lead = [select id,DHS_Assigned_To__c from DHS_Lead__c where id=:leadId];
        boolean isAssigned = false;
        if(lead.DHS_Assigned_To__c != null){
            isAssigned = true;
        }    
        return isAssigned;
    }
    public string deleteLeadId{get;set;}
    
    public void DeleteLeadAction(){
        delete [select id from DHS_Lead__c where id=:deleteLeadId];
        FetchLeadInformation();
        
    }
    
    public class DocumentRecord{
        public string attachmentId{get;set;}   
        public DHS_Document__c document{get;set;}
        public DocumentRecord(string attachmentId, DHS_Document__c document){
            this.document = document;    
            this.attachmentId = attachmentId;
        }
    
    }
    
    public PageReference qareviewcompleteaction(){
        caseRecord.Current_Task__c='QA Review Completed';
        update caseRecord;
        /*DHS_Document__c doc = new DHS_Document__c();
        doc.Name__c = 'ROIReport';
        doc.DHS_Case__c = caseRecord.id;
        doc.Added_By__c = UserInfo.getFirstName() + ' '+ UserInfo.getLastName();
        insert doc;
        
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
        insert att;
        
        FetchDocumentInformation();*/
        PageReference redirectPage = Page.DHSOrderROIReport;
        redirectPage.setRedirect(true);
        redirectPage.getParameters().put('id',caseRecord.id);
        redirectPage.getParameters().put('type','generate');
        return redirectPage;
    }
    
    public void SetPPFContactInfo(){
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
    
    public PageReference regenerateroireportbuttonaction(){
        list<DHS_Document__c> documents = new list<DHS_Document__c>();
        documents = [Select Id,Name__c from DHS_Document__c WHERE Name__c = 'ROIReport' and DHS_Case__c=:caseRecord.id];
        if(!documents.isEmpty()){
            delete documents;
        }
        
        /*DHS_Document__c doc = new DHS_Document__c();
        doc.Name__c = 'ROIReport';
        doc.DHS_Case__c = caseRecord.id;
        doc.Added_By__c = UserInfo.getFirstName() + ' '+ UserInfo.getLastName();
        insert doc;
        
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
        insert att;
        
        FetchDocumentInformation();*/
        PageReference redirectPage = Page.DHSOrderROIReport;
        redirectPage.setRedirect(true);
        redirectPage.getParameters().put('id',caseRecord.id);
        redirectPage.getParameters().put('type','generate');
        return redirectPage;
    }
    
    public string leadIdToUpdate {get;set;}
    public decimal itemnumbertoupdate {get;set;}
    public void UpdateLead(){
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
                update leadToUpdate;
                FetchLeadInformation();
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
            delete documents;
        }
        
        DHS_Document__c doc = new DHS_Document__c();
        doc.Name__c = 'Manifest';
        doc.DHS_Case__c = caseRecord.id;
        doc.Added_By__c = UserInfo.getFirstName() + ' '+ UserInfo.getLastName();
        insert doc;
        Attachment att = new attachment();
        att.ParentId = doc.id;
        att.body = blob.valueof(xmlBody);
        att.Name = 'isn_manifest_'+DateTime.now().format('yyyyMMddHHmmss')+'.xml';
        att.contentType = 'application/xml';
        insert att;
        manifestActionAttachmentId = att.id;
        FetchDocumentInformation();
        
    }*/
    public string deleteDocumentID{get;set;}
    public void DeleteDocumentAction(){
        if(deleteDocumentID != Null){
            delete [Select id from DHS_Document__c where id=:deleteDocumentID];
        }
        FetchDocumentInformation();
    }
    public void AutoSaveCaseAction(){
        update caseRecord;
    }
    public void handlePrev(){
        	messages = new list<DHS_Message__c>();
        
        PageNumber --;
    	string query = queryForNextRecords + ' AND Name <:firstRecordName  Order by Name desc Limit 200';	   
        list<DHS_Message__c> msgs = database.query(query, AccessLevel.SYSTEM_MODE);
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
    public void handleNext(){
        messages = new list<DHS_Message__c>();
        PageNumber ++ ;
    	string query = queryForNextRecords + ' AND Name >:lastRecordName  Order by Name asc Limit 200';	   
        list<DHS_Message__c> msgs = database.query(query, AccessLevel.SYSTEM_MODE);
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
        if(pageNumber == TotalPages){
            disablePrev = false;   
            disableNext = true;
        }else{
            disablePrev = false;
            disableNext = false;
        }
    }


    public DHS_Message__c selectedMessage { get; set; }
    public String modalAction { get; set; }
    public Id selectedMessageId { get; set; }

    // Called by actionFunction before opening modal
    public void openModal() {
        if(modalAction == 'edit' && selectedMessageId != null){
            selectedMessage = [
                SELECT Id, Subject__c, Message_Body__c 
                FROM DHS_Message__c 
                WHERE Id = :selectedMessageId
                LIMIT 1
            ];
        }
    }

    public void updateMessage() {
        if(selectedMessage != null){
            update selectedMessage;
        }
    }

    public void deleteMessage() {
        if(selectedMessageId != null){
            try {
                delete [SELECT Id FROM DHS_Message__c WHERE Id = :selectedMessageId LIMIT 1];
                // Refresh messages after deletion
                //FetchCaseMessages();
            } catch (Exception e) {
            }
        } else {
        }
    }
    public PageReference previewROI() {
        user u = [select id,user_type__c from user where id =: UserInfo.getUserId() limit 1];
        if(u.user_type__c == 'CMO'){
            caseRecord.Subheader_packaged_date_by_CMO__c = system.today();
        	update caseRecord;
        }
        PageReference pr = new PageReference('/apex/DHSOrderROIReportV2PreForm');
        pr.getParameters().put('id', caseRecord.Id);
        pr.getParameters().put('type', 'preview');
        pr.setRedirect(true);
    
        return pr;
    }
    
}