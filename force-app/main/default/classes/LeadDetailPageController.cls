global with sharing class LeadDetailPageController {
    @RemoteAction
    global static String grammarSendRequest(String inputText, String apiName) {
        system.debug('inputText...'+inputText);
        system.debug('apiName...'+apiName);
        return GrammarCheckController.sendRequest(inputText, apiName);
    }
    @RemoteAction
    public static string createLeadGrammarRecord(string fields,string leadId){
        if (String.isBlank(leadId)) {
            return '';
        }

        List<Lead_Grammar_Check__c> existingRecords = [
            SELECT Id, Fields__c
            FROM Lead_Grammar_Check__c
            WHERE Lead__c = :leadId
            LIMIT 1
        ];

        if (!existingRecords.isEmpty()) {
            existingRecords[0].Fields__c = fields;
            update existingRecords[0];
            return existingRecords[0].Fields__c;
        }

        Lead_Grammar_Check__c temp = New Lead_Grammar_Check__c(Lead__c = leadId, Fields__c =fields);
        insert temp;
        return temp.Fields__c;
    }
    @RemoteAction
    public static string updateLeadGrammarRecord(string fields,string leadId){
        if (String.isBlank(leadId)) {
            return '';
        }

        List<Lead_Grammar_Check__c> existingRecords = [
            SELECT Id, Fields__c
            FROM Lead_Grammar_Check__c
            WHERE Lead__c = :leadId
            LIMIT 1
        ];

        if (existingRecords.isEmpty()) {
            return createLeadGrammarRecord(fields, leadId);
        }

        existingRecords[0].Fields__c =fields;
        update existingRecords[0];
        return existingRecords[0].Fields__c;
    }
    @RemoteAction
    public static string getLeadGrammarRecord(string leadId){
        if (String.isBlank(leadId)) {
            return '';
        }

        List<Lead_Grammar_Check__c> existingRecords = [
            SELECT Id, Fields__c
            FROM Lead_Grammar_Check__c
            WHERE Lead__c = :leadId
            LIMIT 1
        ];

        if (existingRecords.isEmpty()) {
            return '';
        }

        return existingRecords[0].Fields__c;
    } 
    public string leadId {get;set;}
    public Lead__c leadRecord {get;set;}
    public Lead_RTA_Extension__c leadRecordRTAExtension {get;set;}
    public integer hoursofleadcompletion{get;set;}
    public integer minutesofleadcompletion{get;set;}
    public boolean collectEffortDuringCompletion {get;set;}
    public User currentUser {get;set;}
    public Document_Request__c documentRequest {get;set;}
    public Map<Id,Document_Request__c> documentrequestsmap{get;set;}
    public Map<Id,List<Attachment>> documentrequestnattachmentsmap {get;set;}
    public list<string> documentrequestids {get;set;}
    public string waiverreason {get;set;}
    public Map<string,string> urlparametersMap {get;set;}
    public string urlparametersString {get;set;}
    public boolean fromCase{get;set;}
    public string leadrejectionreason{get;set;}
    public string messageSubject{get;set;}
    public string messageBody{get;set;}
    public string caseId{get;set;}
    public case__c caseRecord{get;set;}
    public List<Message__c> messages {get;set;}
    public boolean isValidForRTAExtension{get;set;}
    public string nextURL;
    public integer pageNumber {get;set;}
    public integer TotalPages   {get;set;}
    public integer totalRecordCount {get;set;}
    public boolean disablePrev {get;set;}
    public boolean disableNext {get;set;}
    public string queryForNextRecords {get;set;}
    public string lastRecordName {get;set;}
    public string firstRecordName {get;set;}
    public integer currentRecordCount {get;set;}
    
    public User_Permission__mdt currentUserPermissions {get;set;}
    public List<SelectOption> StandardisedIssueOptions {
        get {
            List<SelectOption> options = new List<SelectOption>();
            for( Schema.PicklistEntry f :Lead__c.Standardised_Issues_Picklist__c.getDescribe().getPicklistValues()) {
                options.add(new SelectOption(f.getValue(), f.getLabel()));
            } 
            return options;
        }  
        set;
    }
    
    public boolean showstandardisedissuesotherexplanation{get;set;}
    public void standardisedissuesaction(){
        System.debug('StandardisedIssueItems...'+StandardisedIssueItems);
        if(StandardisedIssueItems.contains('Other')){
            showstandardisedissuesotherexplanation = true;
        }else{
            showstandardisedissuesotherexplanation = false;
        }
        System.debug('showstandardisedissuesotherexplanation...'+ showstandardisedissuesotherexplanation);
    }
    
    public String[] StandardisedIssueItems { 
        get {
            String[] selected = new List<String>();
            List<SelectOption> sos = this.StandardisedIssueOptions;
            for(SelectOption s : sos) {
                if (this.leadRecord.Standardised_Issues_Picklist__c !=null && this.leadRecord.Standardised_Issues_Picklist__c.contains(s.getValue()))
                    selected.add(s.getValue());
            }
            return selected;
        }
        public set {
            String selectedCheckBox = '';
            for(String s : value) {
                if (selectedCheckBox == '') 
                    selectedCheckBox += s;
                else selectedCheckBox += ';' + s;
            }
            
            system.debug('value of selectedcheckBox is @@@@@'+selectedCheckBox);
            leadRecord.Standardised_Issues_Picklist__c = selectedCheckBox;
        }
    }
   
    public LeadDetailPageController(){
        currentUser = [Select Id, User_Type__c, Candidate_Type__c FROM User where Id=:userinfo.getUserId() WITH SECURITY_ENFORCED];
        currentUserPermissions = PermissionsUtil.GetUserPermssions(currentUser.User_Type__c);
        pageNumber = 1;
        disablePrev = true;
        disableNext = true;
        
        showstandardisedissuesotherexplanation = false;
        toInsertleadRecordRTAExtension = false;
        isValidForRTAExtension = false;
        leadId = apexpages.currentpage().getparameters().get('id');
        if(apexpages.currentpage().getparameters().get('fromcase') != Null){
            fromCase = boolean.valueof(apexpages.currentpage().getparameters().get('fromcase'));
        }
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
        collectEffortDuringCompletion = false;
        
        list<String> applicableCandidateTypesForTimeEntry = new list<string>();
        string temp = GeneralSettings__c.getValues('TimeEntryDuringLeadConfirm').value__c;
        if(temp != Null){
            applicableCandidateTypesForTimeEntry = temp.split(',');
        }
        for(String applicableType: applicableCandidateTypesForTimeEntry){
            if(applicableType == currentUser.Candidate_Type__c){
                collectEffortDuringCompletion = true;
            }
        }
        System.debug('collectEffortDuringCompletion...'+collectEffortDuringCompletion);
        FetchLeadInformation();
        documentRequest = new Document_Request__c();
        documentRequest.to_Address__c = leadRecord.Contact__r.Email__c;
        documentRequest.Lead__c = leadId;
        FetchDocumentRequests();
        FetchCaseInformation();
        FetchCaseMessages();
    }
    public void FetchCaseInformation(){
        List<string> caseFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        caseFields = ApexUtil.FetchFields('Case__c');
        caseFields.add('contact__r.First_Name__c');
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
        query = query + ' WHERE '+where_cond+' WITH SECURITY_ENFORCED'; 
        System.debug('query...'+query);
        list<case__c> cases = database.query(query);
        if(!cases.isEmpty()){
            caseRecord = cases[0];    
        }    
    }
    public static list<string> FetchToAddressOfCase(case__c caseRecord, user currentUser){
        list<string> toUserIds = new list<string>();
        if(currentuser.user_type__c != 'PMO'){
           toUserIds.add(caseRecord.Owner.Email);
        }
        system.debug('toUserIds...'+toUserIds);
        if(caseRecord.Assigned_to__c != Null && caseRecord.Assigned_to__c != userinfo.getuserid()){
            if(!toUserIds.contains(caseRecord.Assigned_to__c) ){
                toUserIds.add(caseRecord.Assigned_to__r.Email__c);
            }
        }
        system.debug('toUserIds...'+toUserIds);
        List<Lead__c> leadsAssigned = new List<Lead__c>();
        leadsAssigned = [Select Id, Status__c, Assigned_To__c, Assigned_To__r.Email,Assigned_to__r.Email__c, Case__c, Assigned_to__r.FirstName, Assigned_to__r.LastName from Lead__c where Case__c=:caseRecord.id WITH SECURITY_ENFORCED];
        for(Lead__c lead: leadsAssigned){
            if(lead.Assigned_To__c != Null && lead.Assigned_to__c != userinfo.getuserid()){
                if(!toUserIds.contains(lead.Assigned_to__r.Email__c)){
                     toUserIds.add(lead.Assigned_to__r.Email__c);
                }   
            }
        }
        system.debug('toUserIds...'+toUserIds);
        return toUserIds;
    }
   
    public void SendMessage(){
        List<String> toAddressList = new list<String>();
        toAddressList.addAll(FetchToAddressOfCase(caseRecord,currentUser));
        List<Message__c> messagesToInsert = new List<Message__c>();
        Message__c message = new Message__c();
        message.Message_Body__c = messageBody;
        message.subject__c = messageSubject;
        message.From_User__c = userinfo.getUserId();
        message.case__c = caseRecord.id;
        message.lead__c = leadId;
        messagesToInsert.add(message); 
        database.insert(message,false,AccessLevel.USER_MODE);
        String emailBody = 'Message has been sent for the case #'+caseRecord.Case_Number__c+' Please login to check the message.';
        if(!test.isRunningTest()){
            system.debug('toAddressList...'+toAddressList);
            MailUtilities.sendHTMLEmail(toAddressList,messageSubject,emailBody,null);
        }
        //FetchCaseMessages(); 
        
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
        
        messageSubject = null;
        messageBody = null;   
    }
     
    public void FetchCaseMessages(){
        pageNumber = 1;
        disablePrev = true;
        
        messages = new list<message__c>();
        List<string> messageFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        messageFields = ApexUtil.FetchFields('message__c');  
        messageFields.add('case__r.case_number__c');
        messageFields.add('Lead__r.Name');
        messageFields.add('From_User__r.FirstName');
        messageFields.add('From_User__r.LastName');
        messageFields.add('To_User__r.FirstName');
        messageFields.add('To_User__r.LastName');
        messageFields.add('cc_User__r.FirstName');
        messageFields.add('cc_User__r.LastName');
        messageFields.add('Lead__r.Item_number__c');
        
        String query = 'Select '+string.join(messageFields, ',') + ' From message__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new ApexUtil.Criteria('case__c',caseId,'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        System.debug('where_cond...'+where_cond);
        queryForNextRecords = query + ' WHERE '+where_cond;
        query = query + ' WHERE '+where_cond+' WITH SECURITY_ENFORCED Order by Name asc Limit 200'; 
        System.debug('query...'+query);
        string countQuery = 'Select Count() from Message__c WHERE '+ where_cond+' WITH SECURITY_ENFORCED';
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
    
    public void FetchLeadInformation(){
        List<string> leadFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        leadFields = ApexUtil.FetchFields('lead__c');
        leadFields.add('contact__r.First_Name__c');
        leadFields.add('contact__r.Last_Name__c');
        leadFields.add('contact__r.Email__c');
        leadFields.add('Assigned_to__r.Name');
        leadFields.add('Assigned_to__r.Email');
        leadFields.add('case__r.case_number__c');
        leadFields.add('case__r.case_cancelled__c');
        leadFields.add('case__r.case_discontinued__c');
        
        String query = 'Select '+string.join(leadFields, ',') + ' From lead__c ';
        
        if(String.isNotBlank(leadId)){
            whereCriteria.add(new ApexUtil.Criteria('Id',leadId,'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+' WITH SECURITY_ENFORCED'; 
        System.debug('query...'+query);
        list<lead__c> leads = database.query(query);
        if(!leads.isEmpty()){
            leadRecord = leads[0]; 
            caseId = leadRecord.case__c; 
            if(leadRecord.leadType__c == 'Subject Interview (ESI/TESI)'){
                 isValidForRTAExtension = true;
                 leadRecordRTAExtension = new Lead_RTA_Extension__c();
                 List<Lead_RTA_Extension__c> leadRecordExtensions = new List<Lead_RTA_Extension__c>();
                 leadRecordExtensions = [Select Id, Foreign_Activities__c, Foreign_Contacts__c, Foreign_Travel1__c, Foreign_Travel2__c, Lead__c
                                         FROM Lead_RTA_Extension__c WHERE Lead__c =:leadRecord.Id WITH SECURITY_ENFORCED];
                 if(!leadRecordExtensions.isEmpty()){
                     leadRecordRTAExtension = leadRecordExtensions[0];
                 } else{
                     leadRecordRTAExtension = new Lead_RTA_Extension__c();
                     leadRecordRTAExtension.lead__c = leadRecord.id;    
                     //insert leadRecordRTAExtension;   
                     toInsertleadRecordRTAExtension = true; 
                 }                           
            } 
        } 
    }
    public boolean toInsertleadRecordRTAExtension {get;set;}
    public pagereference completeleadaction(){
        leadRecord.Status__c = 'Completed';
        leadRecord.Hours_of_completion__c = hoursofleadcompletion;
        leadRecord.Minutes_of_completion__c = minutesofleadcompletion;
        if(leadRecord.QA_Rejected_Date__c != null){
            leadRecord.Status__c = 'QA Rejection Complete';
            leadRecord.QA_Rejection_Complete_Date__c = date.today(); 
        }
        update leadRecord;
        //database.update(leadRecord,false,AccessLevel.USER_MODE);
        if(isValidForRTAExtension){
            if(toInsertleadRecordRTAExtension){
                insert leadRecordRTAExtension;
                //database.insert(leadRecordRTAExtension);
            }else{
                update leadRecordRTAExtension;
                //database.update(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
            }
        }
        return getLeadCompletionRedirectPage();
    }

    private PageReference getLeadCompletionRedirectPage() {
        PageReference redirectPage;
        if (fromCase == true) {
            redirectPage = Page.casedetail;
            redirectPage.getParameters().put('id', leadRecord.case__c);
            redirectPage.getParameters().put('tab', 'Leads');
        } else {
            redirectPage = Page.leaddashboard;
            if (urlparametersMap != null) {
                for (String parameterName : urlparametersMap.keySet()) {
                    if (parameterName != 'id' && parameterName != 'fromcase') {
                        redirectPage.getParameters().put(parameterName, urlparametersMap.get(parameterName));
                    }
                }
            }
        }
        redirectPage.setRedirect(true);
        return redirectPage;
    }
    
    public string errorMessage {get;set;}
    public void updateleadaction(){
        try{
            errorMessage = null;
            update leadRecord;
            //database.update(leadRecord,false,AccessLevel.USER_MODE);  
            if(isValidForRTAExtension){
                if(toInsertleadRecordRTAExtension){
                    insert leadRecordRTAExtension;
                    //database.insert(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
                }else{
                    update leadRecordRTAExtension;
                    //database.update(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
                }
            }
        }catch(Exception ex){
            errorMessage = ex.getMessage();
            if(errorMessage.contains(System.label.Duplicate_Item_Number_Message)){
                errorMessage = 'Update failed: '+System.label.Duplicate_Item_Number_Message;
            }
        }
    }
    
    public pagereference reviewcompletedaction(){
        leadRecord.Status__c = 'QA Review Completed';
        update leadRecord;
        //database.update(leadRecord,false,AccessLevel.USER_MODE);
        if(isValidForRTAExtension){
            if(toInsertleadRecordRTAExtension){
                insert leadRecordRTAExtension;
                //database.insert(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
            }else{
                update leadRecordRTAExtension;
                //database.update(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
            }
        }
        PageReference redirectPage = Page.casedetail;
        redirectPage.getParameters().put('id',leadRecord.case__c);
        redirectPage.getParameters().put('tab','Leads');
        redirectPage.setRedirect(true);
        return redirectPage; 
    }
    
    public void selfassignaction(){
         leadRecord.Assigned_To__c = currentuser.id;
         leadRecord.status__c = 'Assigned';
         leadRecord.Lead_Accepted_or_Rejected__c ='Accepted'; 
         leadRecord.Accepted_date__c =system.today();  
         leadRecord.Assignee_Date__c = system.today(); 
         if(!test.isRunningTest()){
            database.update(leadRecord,false,AccessLevel.USER_MODE); 
            if(isValidForRTAExtension){
                if(toInsertleadRecordRTAExtension){
                    database.insert(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
                }else{
                    database.update(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
                }
            }    
         }
         
    }
    
    public pagereference deleteleadaction(){
        delete leadRecord;
        //database.delete(leadRecord,false,AccessLevel.USER_MODE);
        PageReference redirectPage = Page.leaddashboard;
        redirectPage.setRedirect(true);
        return redirectPage;     
    }
    
    public void dummyaction(){
    
    }
    
     public void createdocumentrequestaction(){
        documentRequest.status__c = 'Documents Requested';
        system.debug('Document Request:' + documentRequest.to_address__c);
         insert documentRequest;
        //database.insert(documentRequest,false,AccessLevel.USER_MODE);
        documentRequest = new Document_Request__c();
        documentRequest.to_Address__c = leadRecord.Contact__r.Email__c;
        documentRequest.Lead__c = leadId;
        FetchDocumentRequests();
    }
    
    public  void FetchDocumentRequests(){
        documentrequestsmap = new Map<Id,Document_Request__c>([SELECT Id,Name,Status__c,To_Address__c, Additional_To_Address__c, Investigator_Comments__c FROM Document_Request__c WHERE Lead__c=:leadId WITH SECURITY_ENFORCED order by createddate desc ]);
        documentrequestnattachmentsmap = new Map<Id,List<Attachment>>();
        documentrequestids = new list<string>();
        for(string docId: documentrequestsmap.keyset()){
            documentrequestids.add(docId);
            documentrequestnattachmentsmap.put(docId,new list<Attachment> {});
        }
        System.debug('documentrequestids...'+documentrequestids);
        List<Attachment> attachments = [Select id, name, parentid, description from Attachment where parentid=:documentrequestsmap.keyset() WITH SECURITY_ENFORCED];
         System.debug('attachments...'+attachments);
        for(Attachment att: attachments){
            if(!documentrequestnattachmentsmap.containsKey(att.parentid)){
                documentrequestnattachmentsmap.put(att.parentid, new list<Attachment> {att});
            }else{
                documentrequestnattachmentsmap.get(att.parentid).add(att);
            }
        }
        System.debug('documentrequestnattachmentsmap...'+documentrequestnattachmentsmap);
    }
    
    public PageReference applyforwaiveraction(){
        System.debug('waiverreason....'+waiverreason);
        leadRecord.status__c = 'Applied For Waiver';
        leadRecord.Reason_for_Waiver__c = waiverreason;
        update leadRecord;
        //database.update(leadRecord,false,AccessLevel.USER_MODE);
        if(isValidForRTAExtension){
            if(toInsertleadRecordRTAExtension){
                insert leadRecordRTAExtension;
                //database.insert(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
            }else{
                update leadRecordRTAExtension;
                //database.update(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
            }
        }
        case_History__c ch = new case_History__c();
        ch.case__c = leadRecord.case__c;
        ch.added_by__c = userinfo.getuserid();
        ch.value__c = 'Applied For Waiver - '+ waiverreason;
        insert ch;
        //database.Insert(ch,false,AccessLevel.USER_MODE);
        PageReference redirectPage = Page.leaddashboard;
        redirectPage.setRedirect(true);
        return redirectPage;  
        
        
    }
    
    public pagereference rejectleadaction(){
        leadRecord.status__c = 'QA Rejected';
        leadRecord.QA_Rejection_Comments__c = leadrejectionreason;
        leadRecord.QA_Rejected_Date__c = system.today();
        update leadRecord;
        system.debug('Lead detail Controller...'+leadRecord.status__c);
        //database.update(leadRecord,false,AccessLevel.USER_MODE);
        if(isValidForRTAExtension){
            if(toInsertleadRecordRTAExtension){
                insert leadRecordRTAExtension;
                //database.insert(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
            }else{
                update leadRecordRTAExtension;
                //database.update(leadRecordRTAExtension,false,AccessLevel.USER_MODE);
            }
        }
        List<string> toAddress = new List<string>();
        toAddress.add(leadRecord.Assigned_To_Investigator_Email__c);
        system.debug(toAddress);
        
        
        String subject = 'ISN - PAPERPROOF: '+leadRecord.Item_number__c+' rejected on case '+leadrecord.case__r.case_number__c+'.';
        string body = 'ISN - PAPERPROOF: An item on the case referenced above has been returned to you for corrections in the ForeSite system. '+
            'Please review the case message associated with this request in ForeSite, make the appropriate corrections, and complete the item(s) within 24 hours.'+
            ' If you have any questions regarding this request, please contact the case reviewer and/or your Field Leader.'+
            '\n'+' Thank you!';
        if(!test.isRunningTest()){
            MailUtilities.sendHTMLEmail(toAddress,subject,body,null);    
        }
        PageReference redirectPage = Page.casedetail;
        redirectPage.getParameters().put('id',leadRecord.case__c);
        redirectPage.getParameters().put('tab','Leads');
        redirectPage.setRedirect(true);
        return redirectPage; 
    }
    
    public void reopenleadaction(){
        leadRecord.status__c = 'In-Progress';
        update leadRecord;
        //database.update(leadRecord,false,AccessLevel.USER_MODE);
    }
    
    /*public string sourcefieldtopopulatenarrative{get;set;}
    public string sourcefieldvaluetopopulatenarrative{get;set;}
    public void populatenarrativeaction(){
        System.debug('sourcefieldtopopulatenarrative...'+sourcefieldtopopulatenarrative);
       
        List<string> reportMatrixFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        reportMatrixFields = ApexUtil.FetchFields('ROI_Report_Matrix__c');
        
        String query = 'Select '+string.join(reportMatrixFields, ',') + ' From ROI_Report_Matrix__c ';
        
        if(String.isNotBlank(sourcefieldtopopulatenarrative)){
            whereCriteria.add(new ApexUtil.Criteria('Source_Field__c',sourcefieldtopopulatenarrative,'='));
        }
        if(String.isNotBlank(sourcefieldvaluetopopulatenarrative)){
            whereCriteria.add(new ApexUtil.Criteria('Value__c',sourcefieldvaluetopopulatenarrative,'='));
        }
        
        if(String.isNotBlank(leadRecord.LeadType__c)){
            whereCriteria.add(new ApexUtil.Criteria('Lead_Type__c',leadRecord.LeadType__c,'='));
        }
       
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond; 
        System.debug('query...'+query);
        list<ROI_Report_Matrix__c> reportMatrices = database.query(query);
        System.debug('reportMatrices...'+reportMatrices);
        if(!reportMatrices.isEmpty()){
            String textToPopulate = reportMatrices[0].Text_To_Populate__c;
            leadRecord.Narrator_Comments__c = MergeFieldsofROI();
        }
        
   
    }
    
    public string MergeFieldsofROI(){
        string mergedText;
        List<string> reportMatrixFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        reportMatrixFields = ApexUtil.FetchFields('ROI_Report_Matrix__c');
        
        String query = 'Select '+string.join(reportMatrixFields, ',') + ' From ROI_Report_Matrix__c ';
        if(String.isNotBlank(leadRecord.LeadType__c)){
            whereCriteria.add(new ApexUtil.Criteria('Lead_Type__c',leadRecord.LeadType__c,'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond; 
        System.debug('query...'+query);
        list<ROI_Report_Matrix__c> reportMatrices = database.query(query);
        
        for(ROI_Report_Matrix__c roi: reportMatrices){
            Map<String,String> mergeFieldsMap = new Map<String,String>();
            Pattern p = Pattern.compile('\\%.+?\\%');
            String unMergedText = roi.Text_To_Populate__c;
            Matcher m = p.matcher(unMergedText);
            while(m.find()) {
                System.debug(m.group(0));
                mergeFieldsMap.put(m.group(0),string.valueof(leadRecord.get(m.group(0).replaceAll('%',''))));
            }
            System.debug('mergeFieldsMap....'+mergeFieldsMap);
            for(String str: mergeFieldsMap.keyset()){
                if(string.isNotBlank(mergeFieldsMap.get(str))){
                    unMergedText = unMergedText.replace(str,mergeFieldsMap.get(str)); 
                }  else{
                    unMergedText = unMergedText.replace(str,''); 
                } 
            }
            if(leadRecord.get(roi.source_field__c) != Null){
                if(String.isNotBlank(mergedText)){
                    mergedText = mergedText + ' ' + unMergedText;
                }else{
                    mergedText = unMergedText;
                }
            }
        }
    
        return mergedText;
    }*/
    
    public void AutoSaveLeadAction(){
     if(leadRecord.leadType__c == 'Subject Interview (ESI/TESI)'){
         try{
             update leadRecordRTAExtension;
             system.debug('AutoSaveLeadAction... Success');
         }catch(exception e){
             system.debug('AutoSaveLeadAction exception...'+e);
         }
        
     }
        
        update leadRecord;
        //database.update(leadRecord,false,AccessLevel.USER_MODE);
    }
    

    
    public void handlePrev(){
            messages = new list<Message__c>();
        
        PageNumber --;
        string query = queryForNextRecords + ' AND Name <:firstRecordName WITH SECURITY_ENFORCED Order by Name desc Limit 200';    
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
        string query = queryForNextRecords + ' AND Name >:lastRecordName WITH SECURITY_ENFORCED Order by Name asc Limit 200';      
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
        System.debug('openModal called with modalAction: ' + modalAction + ', selectedMessageId: ' + selectedMessageId);
        if(modalAction == 'edit' && selectedMessageId != null){
            selectedMessage = [
                SELECT Id, Subject__c, Message_Body__c 
                FROM Message__c 
                WHERE Id = :selectedMessageId
                LIMIT 1
            ];
            System.debug('selectedMessage loaded for edit: ' + selectedMessage);
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
                FetchCaseMessages();
            } catch (Exception e) {
                System.debug('Error deleting message: ' + e.getMessage());
            }
        } else {
            System.debug('selectedMessageId is null - cannot delete message');
        }
    }
    public static datetime convertToDt(date dt){
        integer day;
        integer month;
        integer year;
        day = dt.day();
        month = dt.month();
        year = dt.year();
        datetime dtime = datetime.newinstance(day,month,year);
        return dtime;
    }
}