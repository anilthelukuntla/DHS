public class CaseDetailController {
    public string caseId {get;set;}
    public Case__c caseRecord {get;set;}
    public Contact__c contactRecord {get;set;}
    public List<Lead__c> leads {get;set;}
    public List<DocumentRecord> documents {get;set;}
    public Lead__c newLead {get;set;}
    public List<Case_History__c> caseHistory {get;set;}
    public List<Waiver_Information__c> waiverInformation {get;set;}
    public List<Message__c> messages {get;set;}
    public Case_History__c newCaseHistory {get;set;}
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
    public string nextURL;
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
    public Lead__c selectedLead {get;set;}
    public string selectedLeadId {get;set;}
    public CaseDetailController(){ 
        
        showSubheader = false;
        list<string> userIds = system.label.Show_Subheaders.split(',');
        if(userIds.contains(userinfo.getUserId())){
            showSubheader = true;
        }
        system.debug(showSubheader);
        pageNumber = 1;
        disablePrev = true;
        disableNext = true;
        currentUser = [Select Id, FirstName, LastName, User_Type__c FROM User where Id=:userinfo.getUserId()];
        if(currentUser.User_Type__c == 'CMO' || currentUser.User_Type__c == 'PMO'){
            showMultiUploadDocuments = true;
        }else{
            showMultiUploadDocuments = false;
        }
        caseId = apexpages.currentpage().getparameters().get('id');
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
        System.debug('urlparametersString..'+urlparametersString);
        hasWaiver = false;
        showQAReviewCompleteButton = false;
        FetchCaseInformation();
        FetchLeadInformation();
        FetchDocumentInformation(); 
        FetchCaseHistoryInformation();
        FetchWaiverInformation();
        FetchCaseMessages();
        System.debug('caserecord....'+caserecord);
        newLead = new Lead__c();
        newCaseHistory = new Case_History__c();
        List<user> assignUsers = new List<user>();
        assignUsers = [select Id, User_Type__c,system_access__c, FirstName, lastname  FROM User where isactive=true AND User_Type__c = 'CMO'];
        assignUserList = new List<SelectOption>();
        assignUserList.add(new SelectOption('','--None--'));
        for(User u: assignUsers){
            if(u.system_access__c.contains('Intel')){
            assignUserList.add(new SelectOption(u.id,u.firstname+' '+u.lastname));
            }
        }
        if(caseRecord.Assigned_To__c != null){
            selectedUserIdForAssignment = caseRecord.Assigned_To__c ;
        }
    }
    
    public static list<string> FetchToAddressOfCase(case__c caseRecord, user currentUser){
        list<string> toUserIds = new list<string>();
        if(currentuser.user_type__c != 'PMO'){
           toUserIds.add(caseRecord.Owner.Email);
        }
        if(caseRecord.Assigned_to__c != Null && caseRecord.Assigned_to__c != userinfo.getuserid()){
            if(!toUserIds.contains(caseRecord.Assigned_to__c) ){
                toUserIds.add(caseRecord.Assigned_to__r.Email);
            }
        }
        List<Lead__c> leadsAssigned = new List<Lead__c>();
        leadsAssigned = [Select Id, Status__c, Assigned_To__c, Assigned_To__r.Email, Case__c, Assigned_to__r.FirstName, Assigned_to__r.LastName from Lead__c where Case__c=:caseRecord.id];
        for(Lead__c lead: leadsAssigned){
            if(lead.Assigned_To__c != Null && lead.Assigned_to__c != userinfo.getuserid()){
                if(!toUserIds.contains(lead.Assigned_to__r.Email)){
                     toUserIds.add(lead.Assigned_to__r.Email);
                }   
            }
        }
        return toUserIds;
    }
    
    public static list<string> FetchUsersOfCase(case__c caseRecord, user currentUser){
        list<string> toUserIds = new list<string>();
        if(currentuser.user_type__c != 'PMO'){
           toUserIds.add(caseRecord.ownerId);
        }
        if(caseRecord.Assigned_to__c != Null && caseRecord.Assigned_to__c != userinfo.getuserid()){
            if(!toUserIds.contains(caseRecord.Assigned_to__c) ){
                toUserIds.add(caseRecord.Assigned_to__c);
            }
        }
        List<Lead__c> leadsAssigned = new List<Lead__c>();
        leadsAssigned = [Select Id, Status__c, Assigned_To__c, Assigned_To__r.Email, Case__c, Assigned_to__r.FirstName, Assigned_to__r.LastName from Lead__c where Case__c=:caseRecord.id];
        for(Lead__c lead: leadsAssigned){
            if(lead.Assigned_To__c != Null && lead.Assigned_to__c != userinfo.getuserid()){
                if(!toUserIds.contains(lead.Assigned_to__c)){
                     toUserIds.add(lead.Assigned_to__c);
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
        List<Message__c> messagesToInsert = new List<Message__c>();
        Message__c message = new Message__c();
        message.Message_Body__c = messageBody;
        message.subject__c = messageSubject;
        message.From_User__c = userinfo.getUserId();
        message.case__c = caseRecord.id;
        messagesToInsert.add(message); 
        insert message;
        
        List<string> cmoEmails = New List<string>();
        string cmoSub = 'ISN PPF case message notification: Case #'+caseRecord.Case_Number__c;
        string cmoBody = 'A case message has been sent by '+Userinfo.getFirstName()+' '+Userinfo.getLastName();
        if(caseRecord.Assigned_to__c != null){
            if(!test.isRunningTest()){
                cmoEmails.add(caseRecord.Assigned_to__r.Email__c);
                system.debug('toAddressList...'+toAddressList);
                MailUtilities.sendHTMLEmail(cmoEmails,cmoSub,cmoBody,null);
            }
        }
         
        List<Message_Log__c> messageLogsToCreate = new List<Message_Log__c>();
        for(string userId: toUserIdsForMessageLogs){
            Message_Log__c log = new Message_Log__c();
            log.user__c = userId;
            log.message__c = message.id;
            log.Unread__c = true;
            log.read__c = false;  
            messageLogsToCreate.add(log);  
        }
        
        insert messageLogsToCreate;
        
        String emailBody = 'Dear Member,<br/><br/>A new case message has been posted by '+Currentuser.firstname+' '+currentuser.lastname+' the for Case# '+caseRecord.case_Number__c+'. Please log in to the case management system to retrieve the message from case tab.<br/><br/>Thanks<br/>ISN Corporation';
        if(!test.isRunningTest()){
            //MailUtilities.sendHTMLEmail(toAddressList,messageSubject,emailBody,null);
        }
        //FetchCaseMessages(); 
        messageSubject = null;
        messageBody = null; 
        PageReference pr = Page.CaseDetail;
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
        List<Message__c> messagesToInsert = new List<Message__c>();
        Message__c message = new Message__c();
        message.Message_Body__c = messageBodyParam;
        message.subject__c = messageSubjectParam;
        message.From_User__c = userinfo.getUserId();
        message.case__c = caseRecord.id;
        message.lead__c = leadid;
        messagesToInsert.add(message); 
        insert message;
        
        List<Message_Log__c> messageLogsToCreate = new List<Message_Log__c>();
        for(string userId: toUserIdsForMessageLogs){
            Message_Log__c log = new Message_Log__c();
            log.user__c = userId;
            log.message__c = message.id;
            log.Unread__c = true;
            log.read__c = false;  
            messageLogsToCreate.add(log);  
        }
        
        insert messageLogsToCreate;
        
        String emailBody = 'Dear Member,<br/><br/>A new case message has been posted by '+Currentuser.firstname+' '+currentuser.lastname+' the for Case# '+caseRecord.case_Number__c+'. Please log in to the case management system to retrieve the message from case tab.<br/><br/>Thanks<br/>ISN Corporation';
        if(!test.isRunningTest()){
            //MailUtilities.sendHTMLEmail(toAddressList,messageSubject,emailBody,null);
        }
        FetchCaseMessages(); 
    }
    
    
    
    public void OnChangeLeadType(){
    
    }
    
    public void updatecaseaction(){
        if(selectedUserIdForAssignment != Null){
            caseRecord.Assigned_To__c = selectedUserIdForAssignment;
            caseRecord.Case_Queue_Status__c = 'Assigned';
            caseRecord.Assignee_Date__c = system.today();
            caseRecord.current_task__c = 'Validate Transmission';
            caseRecord.validate_transmission_date__c = system.today();
                case_History__C ch = new case_History__c();
                ch.case__c = caseRecord.id;
                ch.added_by__c = userinfo.getuserid();
                ch.value__c = 'Validate Transmission';
                insert ch;
               
        }
        if(caseRecord.Customer_Delivery_Date__c != Null){
            caseRecord.Purge_Date__c = caseRecord.Customer_Delivery_Date__c.addDays(180);
            caseRecord.End_Purge_Date__c = caseRecord.Customer_Delivery_Date__c.addDays(180);
        }
        boolean updateContact = false;
        if(caseRecord.contact__r.First_Name__c != contactRecord.First_Name__c){
            contactRecord.First_Name__c = caseRecord.contact__r.First_Name__c;
            updateContact = true;
        }
        if(caseRecord.contact__r.Last_Name__c != contactRecord.Last_Name__c){
            contactRecord.Last_Name__c = caseRecord.contact__r.Last_Name__c;
            updateContact = true;
        }
        if(caseRecord.contact__r.Email__c != contactRecord.Email__c){
            contactRecord.Email__c = caseRecord.contact__r.Email__c;
            updateContact = true;
        }
        if(!Test.isRunningTest()){
            if(caseRecord.contact__r.SSN__c != contactRecord.SSN__c){
                contactRecord.SSN__c = caseRecord.contact__r.SSN__c;
                updateContact = true;
            }
        }
        
        if(updateContact){
            update contactRecord;
        }
        if(caseRecord.case_discontinued__c){
            caseRecord.current_task__c = 'Discontinued';    
        }
        update caseRecord;
        
        FetchCaseInformation();
        FetchLeadInformation();
    }
    public void updateLeadAction(){
        system.debug('selectedLead...'+selectedLead);
        update selectedLead;
    }
    public void selectLeadAction(){
        system.debug('selectedLeadId...'+selectedLeadId);
       	selectedLead = [select id,leadtype__c,coverage_type__c,item_number__c from lead__c where Id =: selectedLeadId limit 1];
    	system.debug('selectedLead...'+selectedLead);
    }
    
    public void markleadcreationcompleteaction(){
         case_History__c ch = new case_History__c();
                   ch.case__c = caseRecord.id;
                   ch.added_by__c = userinfo.getuserid();
                   ch.value__c = 'Investigations';
         insert ch;
         
          caseRecord.current_task__c = 'Investigations';
          caseRecord.Investigations_Date__c = system.today();
          update caseRecord;
          FetchCaseHistoryInformation();
    
    }
    
    public void AddCommentsAction(){
        newCaseHistory.case__c = caseId;
        newCaseHistory.added_by__c = userinfo.getuserid();
        newCaseHistory.Type__c = 'Comment';
        insert newCaseHistory;
        newCaseHistory = new Case_History__c();
        FetchCaseHistoryInformation();
    }
    
    public string errorMessage {get;set;}
    public void CreateLeadAction(){
        try{
            errorMessage = null;
            //integer itemnumber = leads.size()+1;
            newLead.Case__c = caseId;
            newLead.Status__c = 'UnAssigned';
            newLead.Contact__c = caseRecord.Contact__c;
            newLead.Due_Date__c = System.today().addDays(7);
            //newLead.item_number__c = itemnumber;
            if(currentuser.user_type__c == 'INV'){
                newLead.Extension__c = true;
            }
            insert newLead;
            if(newLead.leadType__c == 'Subject Interview (ESI/TESI)'){
                Lead_RTA_Extension__c leadRTAExtension = new Lead_RTA_Extension__c();
                leadRTAExtension.lead__c = newLead.id;    
                insert leadRTAExtension;    
            }
            if(String.isNotblank(messageSubjectDuringLeadCreation) && String.isNotBlank(messageBodyDuringLeadCreation)){
                SendMessage(messageSubjectDuringLeadCreation,messageBodyDuringLeadCreation, newLead.Id);
                messageSubjectDuringLeadCreation = Null;
                messageBodyDuringLeadCreation = Null;
            }
            newLead = new Lead__c();
            FetchLeadInformation();
            FetchCaseInformation();
        }catch(Exception ex){
            errorMessage = ex.getMessage();
            if(errorMessage.contains(System.label.Duplicate_Item_Number_Message)){
                errorMessage = System.label.Duplicate_Item_Number_Message;
            }
        }
    }
    public void FetchCaseInformation(){
        List<string> caseFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        caseFields = ApexUtil.FetchFields('Case__c');
        caseFields.add('contact__r.First_Name__c');
        caseFields.add('contact__r.SSN__c');
        caseFields.add('contact__r.Last_Name__c');
        caseFields.add('contact__r.Email__c');
        caseFields.add('Assigned_to__r.FirstName');
        caseFields.add('Assigned_to__r.LastName');
        caseFields.add('Assigned_to__r.Email');
        caseFields.add('Assigned_to__r.Email__c');
        caseFields.add('owner.email');
        
        String query = 'Select '+string.join(caseFields, ',') + ' From Case__c ';
        
        if(String.isNotBlank(caseId)){
            whereCriteria.add(new ApexUtil.Criteria('Id',caseId,'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond; 
        System.debug('query...'+query);
        list<case__c> cases = database.query(query);
        if(!cases.isEmpty()){
            caseRecord = cases[0];
            System.debug('caseRecord.Subject__c...'+caseRecord.Contact__c);
            if(caseRecord.Contact__c != Null){
                contactRecord = [Select Id, First_Name__c, Last_Name__c, Email__c,SSN__c from contact__c where Id=: caseRecord.Contact__c]; 
            }   
        }    
    }
    public void FetchLeadInformation(){
        leads = new List<Lead__c> ();
        List<string> leadFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        leadFields = ApexUtil.FetchFields('Lead__c');      
        String query = 'Select '+string.join(leadFields, ',') + ' From Lead__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new ApexUtil.Criteria('case__c',caseId,'='));
        }
        if(currentuser.user_type__c == 'INV'){
            whereCriteria.add(new ApexUtil.Criteria('assigned_to__c',userinfo.getuserid(),'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+ 'ORDER BY Item_Number__c Asc'; 
        
        leads = database.query(query);
        boolean qaReviewCompleted = true;
        for(Lead__c lead: leads){
            if(lead.status__c != 'QA Review Completed'){
                qaReviewCompleted = false;
            }
        }
        showQAReviewCompleteButton = qaReviewCompleted;
    }
    
    public void FetchCaseMessages(){
        List<Map<string,Object>> conditions = New List<Map<string,Object>>();
        messages = new list<message__c>();
        List<string> messageFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        messageFields = ApexUtil.FetchFields('message__c');  
        messageFields.add('case__r.case_number__c');
        messageFields.add('From_User__r.FirstName');
        messageFields.add('From_User__r.LastName');
         messageFields.add('Lead__r.Item_number__c');
        String query = 'Select '+string.join(messageFields, ',') + ' From message__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new ApexUtil.Criteria('case__c',caseId,'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria); 
        
        System.debug('where_cond...'+where_cond);
        queryForNextRecords = query + ' WHERE '+where_cond;
        query = query + ' WHERE '+where_cond+' Order by Name asc Limit 200'; 
        System.debug('query...'+query);
        string countQuery = 'Select Count() from Message__c WHERE '+ where_cond;
        System.debug('countQuery...'+countQuery);
        totalRecordCount = database.countquery(Countquery);
        
        List<message__c> msgs = database.query(query); 
        integer i = 0;
        for(message__c msg: msgs){
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
        system.debug('TotalPages...'+TotalPages);
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
        waiverInformation = new list<Waiver_Information__c>();
        List<string> waiverInformationFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        waiverInformationFields = ApexUtil.FetchFields('Waiver_Information__c');      
        waiverInformationFields.add('lead__r.Name');
        String query = 'Select '+string.join(waiverInformationFields, ',') + ' From Waiver_Information__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new ApexUtil.Criteria('case__c',caseId,'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+ 'ORDER BY CreatedDate Asc'; 
        
        waiverInformation = database.query(query); 
        if(!waiverInformation.isEmpty()){
            hasWaiver = true;
        }   
    }
    public string waiverinformationidtoupdate{get;set;}
    public void autosavewaiverinformationaction(){
        waiver_information__c recordToUpdate = new waiver_information__c();
        for(waiver_information__c wv: waiverInformation){
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
        caseHistory = new list<case_history__c>();
        List<string> caseHistoryFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        caseHistoryFields = ApexUtil.FetchFields('Case_History__c');      
        String query = 'Select '+string.join(caseHistoryFields, ',') + ' From Case_History__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new ApexUtil.Criteria('case__c',caseId,'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+ 'ORDER BY CreatedDate Asc'; 
        
        caseHistory = database.query(query);
    }
    public void FetchDocumentInformation(){
        documents = new List<DocumentRecord> ();
        List<string> documentFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        documentFields = ApexUtil.FetchFields('document__c');      
        String query = 'Select '+string.join(documentFields, ',') + ' From document__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new ApexUtil.Criteria('case__c',caseId,'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond ; 
        
        list<document__c> documentsOfCase = database.query(query);
        system.debug('documentsOfCase...'+documentsOfCase.size());
        List<string> documentIds = new List<string>();
        for(document__c doc: documentsOfCase){
            documentIds.add(doc.id);
        }
        List<attachment> attachments = new List<attachment>();
        attachments = [Select id, parentid from attachment where parentid in: documentIds];
        Map<String,String> documentNattachmentMap = new Map<String,String>();
        for(attachment att: attachments){
            documentNattachmentMap.put(att.parentid, att.id);    
        }
        
        for(document__c doc: documentsOfCase){
            if(documentNattachmentMap.get(doc.id) != Null){
                documents.add(new DocumentRecord(documentNattachmentMap.get(doc.id),doc));  
            }
        }
    }
    
    @RemoteAction
    public static boolean CheckIfLeadIsAssigned(string leadId) {
        lead__c lead = [select id,assigned_to__c from lead__c where id=:leadId];
        boolean isAssigned = false;
        if(lead.assigned_to__c != null){
            isAssigned = true;
        }    
        return isAssigned;
    }
    public string deleteLeadId{get;set;}
    
    public void DeleteLeadAction(){
        delete [select id from Lead__c where id=:deleteLeadId];
        FetchLeadInformation();
        
    }
    
    public class DocumentRecord{
        public string attachmentId{get;set;}   
        public document__c document{get;set;}
        public DocumentRecord(string attachmentId, document__c document){
            this.document = document;    
            this.attachmentId = attachmentId;
        }
    
    }
    
    public PageReference qareviewcompleteaction(){
        caseRecord.Current_Task__c='QA Review Completed';
        update caseRecord;
        /*Document__c doc = new Document__c();
        doc.Name__c = 'ROIReport';
        doc.case__c = caseRecord.id;
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
        if(caseRecord.Contact__r.SSN__c != Null){
            ssnFormatted = caseRecord.Contact__r.SSN__c.replaceAll('-','');
        }
        
        PageReference pr = Page.ROIReport;
        pr.getParameters().put('id',caseRecord.Id);
        Attachment att = new attachment();
        att.ParentId = doc.id;
        //att.Name = caseRecord.Subject_Type__c+caseRecord.Contact__r.SSN__c+'Att00'+'ROIReport.pdf';
        att.Name = applicantType + ssnFormatted + 'Rev00.pdf';
        if(!test.isRunningTest()){
            att.Body = pr.getContentAsPDF();    
        }else{
            att.body = blob.valueof('temp');
        }
        
        att.ContentType = 'application/pdf';
        insert att;
        
        FetchDocumentInformation();*/
        PageReference redirectPage = Page.OrderROIReport;
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
        list<Document__c> documents = new list<Document__c>();
        documents = [Select Id,Name__c from Document__c WHERE Name__c = 'ROIReport' and case__c=:caseRecord.id];
        if(!documents.isEmpty()){
            delete documents;
        }
        
        /*Document__c doc = new Document__c();
        doc.Name__c = 'ROIReport';
        doc.case__c = caseRecord.id;
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
        if(caseRecord.Contact__r.SSN__c != Null){
            ssnFormatted = caseRecord.Contact__r.SSN__c.replaceAll('-','');
        }
        
        PageReference pr = Page.ROIReport;
        pr.getParameters().put('id',caseRecord.Id);
        Attachment att = new attachment();
        att.ParentId = doc.id;
        //att.Name = caseRecord.Subject_Type__c+caseRecord.Contact__r.SSN__c+'Att00'+'ROIReport.pdf';
        att.Name = applicantType + ssnFormatted + 'Rev00.pdf';
        if(!test.isRunningTest()){
            att.Body = pr.getContentAsPDF();    
        }else{
            att.body = blob.valueof('temp');
        }
        
        att.ContentType = 'application/pdf';
        insert att;
        
        FetchDocumentInformation();*/
        PageReference redirectPage = Page.OrderROIReport;
        redirectPage.setRedirect(true);
        redirectPage.getParameters().put('id',caseRecord.id);
        redirectPage.getParameters().put('type','generate');
        return redirectPage;
    }
    
    public string leadIdToUpdate {get;set;}
    public decimal itemnumbertoupdate {get;set;}
    public void UpdateLead(){
        errorMessage = Null;
        System.debug('itemnumbertoupdate...'+itemnumbertoupdate);
        System.debug('leadIdToUpdate...'+leadIdToUpdate);
        lead__c leadToUpdate;
        for(Lead__c l: leads){
            if(l.id == leadIdToUpdate){
                leadToUpdate = l;
            }
        }    
        if(leadToUpdate != Null){
            try{
                leadToupdate.item_number__c = itemnumbertoupdate;
                update leadToUpdate;
                FetchLeadInformation();
            }catch(Exception ex){
                errorMessage = ex.getMessage();
                if(errorMessage.contains(System.label.Duplicate_Item_Number_Message)){
                    errorMessage = System.label.Duplicate_Item_Number_Message;
                }
            }
        }
    }
    /*public string manifestActionAttachmentId {get;set;}
    public void downloadmanifestaction(){
        manifestActionAttachmentId = Null;
        string xmlBody = ManifestXMLGenerator.LoadReleasesXML(caseRecord.id);
        list<Document__c> documents = new list<Document__c>();
        documents = [Select Id,Name__c from Document__c WHERE Name__c = 'Manifest' and case__c=:caseRecord.id];
        if(!documents.isEmpty()){
            delete documents;
        }
        
        Document__c doc = new Document__c();
        doc.Name__c = 'Manifest';
        doc.case__c = caseRecord.id;
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
            delete [Select id from document__c where id=:deleteDocumentID];
        }
        FetchDocumentInformation();
    }
    public void AutoSaveCaseAction(){
        update caseRecord;
    }
    public void handlePrev(){
        	messages = new list<Message__c>();
        
        PageNumber --;
    	string query = queryForNextRecords + ' AND Name <:firstRecordName  Order by Name desc Limit 200';	   
        list<Message__c> msgs = database.query(query);
        integer i = 0;
        for(Integer j=msgs.size()-1;j>=0; j--){
            System.debug('msgs size..'+msgs.size());
             System.debug('j..'+j);
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
        messages = new list<Message__c>();
        PageNumber ++ ;
        System.debug('queryForNextRecords...'+queryForNextRecords);
        system.debug('lastRecordName....'+lastRecordName);
    	string query = queryForNextRecords + ' AND Name >:lastRecordName  Order by Name asc Limit 200';	   
        System.debug('query...'+query);
        list<Message__c> msgs = database.query(query);
        integer i = 0;
        for(Message__c msg: msgs){
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
         system.debug('firstRecordName....'+firstRecordName);
        system.debug('lastRecordName....'+lastRecordName);
         system.debug('currentRecordCount....'+currentRecordCount);
    }


    public Message__c selectedMessage { get; set; }
    public String modalAction { get; set; }
    public Id selectedMessageId { get; set; }

    // Called by actionFunction before opening modal
    public void openModal() {
        if(modalAction == 'edit' && selectedMessageId != null){
            selectedMessage = [
                SELECT Id, Subject__c, Message_Body__c 
                FROM Message__c 
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
        System.debug('deleteMessage called with selectedMessageId: ' + selectedMessageId);
        if(selectedMessageId != null){
            try {
                delete [SELECT Id FROM Message__c WHERE Id = :selectedMessageId LIMIT 1];
                System.debug('Message deleted successfully');
                // Refresh messages after deletion
                //FetchCaseMessages();
            } catch (Exception e) {
                System.debug('Error deleting message: ' + e.getMessage());
            }
        } else {
            System.debug('selectedMessageId is null - cannot delete message');
        }
    }
    public PageReference previewROI() {
        user u = [select id,user_type__c from user where id =: UserInfo.getUserId() limit 1];
        system.debug(u);
        if(u.user_type__c == 'CMO'){
            caseRecord.Subheader_packaged_date_by_CMO__c = system.today();
        	update caseRecord;
        }
        PageReference pr = new PageReference('/apex/OrderROIReportV2PreForm');
        pr.getParameters().put('id', caseRecord.Id);
        pr.getParameters().put('type', 'preview');
        pr.setRedirect(true);
    
        return pr;
    }
    
}