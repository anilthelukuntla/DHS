public class DIALeadDetailPageController {
    public string otherNameUsed	{get;set;}
    public string leadId {get;set;}
    public DIA_Lead__c leadRecord {get;set;}
    public DIA_Lead_RTA_Extension__c leadRecordRTAExtension {get;set;}
    public integer hoursofleadcompletion{get;set;}
    public integer minutesofleadcompletion{get;set;}
    public boolean collectEffortDuringCompletion {get;set;}
    public User currentUser {get;set;}
    public DIA_Document_Request__c documentRequest {get;set;}
    public Map<Id,DIA_Document_Request__c> documentrequestsmap{get;set;}
    public Map<Id,List<Attachment>> documentrequestnattachmentsmap {get;set;}
    public list<string> documentrequestids {get;set;}
    public string waiverreason {get;set;}
    public string type {get;set;}
    public Map<string,string> urlparametersMap {get;set;}
    public string urlparametersString {get;set;}
    public boolean fromCase{get;set;}
    public string leadrejectionreason{get;set;}
    public string messageSubject{get;set;}
    public string messageBody{get;set;}
    public string caseId{get;set;}
    public DIA_case__c caseRecord{get;set;}
    public List<DIA_Message__c> messages {get;set;}
    public boolean isValidForRTAExtension{get;set;}
    public string nextURL;
    public integer pageNumber {get;set;}
    public integer TotalPages   {get;set;}
    public integer totalRecordCount {get;set;}
    List<Object> records;
    public boolean disablePrev {get;set;}
    public boolean disableNext {get;set;}
    public string otherreason {get;set;}
    public string justification {get;set;}
     public string queryForNextRecords {get;set;}
    public string lastRecordName {get;set;}
    public string firstRecordName {get;set;}
    public integer currentRecordCount {get;set;}
    public User_Permission__mdt currentUserPermissions {get;set;}
    public List<SelectOption> StandardisedIssueOptions {
        get {
            List<SelectOption> options = new List<SelectOption>();
            for( Schema.PicklistEntry f :DIA_Lead__c.Standardised_Issues_Picklist__c.getDescribe().getPicklistValues()) {
                options.add(new SelectOption(f.getValue(), f.getLabel()));
            } 
            return options;
        }  
        set;
    }
    
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('','--None--'));
        options.add(new SelectOption('Subject not available','Subject not available'));
        options.add(new SelectOption('Other','Other'));
        return options; 
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
   
    public DIALeadDetailPageController(){
        currentUser = [Select Id, User_Type__c, Candidate_Type__c FROM User where Id=:userinfo.getUserId()];
        currentUserPermissions = PermissionsUtil.GetUserPermssions(currentUser.User_Type__c);
        
        otherNameUsed = 'Test \nData';
         pageNumber = 1;
        disablePrev = true;
        disableNext = true;
        records = New List<Object>();
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
        //currentUser = [Select Id, User_Type__c, Candidate_Type__c FROM User where Id=:userinfo.getUserId()];
        list<String> applicableCandidateTypesForTimeEntry = new list<string>();
        string temp = DIA_GeneralSettings__c.getValues('TimeEntryDuringLeadConfirm').value__c;
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
        documentRequest = new DIA_Document_Request__c();
        documentRequest.to_Address__c = leadRecord.Contact__r.Email__c;
        documentRequest.Lead__c = leadId;
        FetchDocumentRequests();
        FetchCaseInformation();
        FetchCaseMessages();
    }
    public void FetchCaseInformation(){
        List<string> caseFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        caseFields = ApexUtil.FetchFields('DIA_Case__c');
        caseFields.add('contact__r.First_Name__c');
        caseFields.add('contact__r.Last_Name__c');
        caseFields.add('contact__r.Email__c');
        caseFields.add('Assigned_to__r.FirstName');
        caseFields.add('Assigned_to__r.LastName');
        caseFields.add('Assigned_to__r.Email');
        caseFields.add('Assigned_to__r.Phone');
        caseFields.add('owner.email');
        
        String query = 'Select '+string.join(caseFields, ',') + ' From DIA_Case__c ';
        
        if(String.isNotBlank(caseId)){
            whereCriteria.add(new ApexUtil.Criteria('Id',caseId,'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond; 
        System.debug('query...'+query);
        list<DIA_Case__c> cases = database.query(query);
        if(!cases.isEmpty()){
            caseRecord = cases[0];    
        }    
    }
    public static list<string> FetchToAddressOfCase(DIA_Case__c caseRecord, user currentUser){
        list<string> toUserIds = new list<string>();
        /*if(currentuser.user_type__c != 'PMO'){
           toUserIds.add(caseRecord.Owner.Email);
        }*/
        list<string> ExtendedEmailsForMessages = string.valueOf(system.label.ExtendedEmailsForMessages).split(',');
        toUserIds.addAll(ExtendedEmailsForMessages);
        if(caseRecord.Assigned_to__c != Null && caseRecord.Assigned_to__c != userinfo.getuserid()){
            DIA_Case__c caseRec = [select id,Assigned_to__r.contact.Email from DIA_Case__c where id =: caseRecord.Id];
            if(!toUserIds.contains(caseRecord.Assigned_to__c) ){
                toUserIds.add(caseRec.Assigned_to__r.contact.Email);
            }
        }
        List<DIA_Lead__c> leadsAssigned = new List<DIA_Lead__c>();
        leadsAssigned = [Select Id, Status__c, Assigned_To__c,Assigned_To__r.contact.Email, Assigned_To__r.Email, Case__c, Assigned_to__r.FirstName, Assigned_to__r.LastName from DIA_Lead__c where Case__c=:caseRecord.id];
        for(DIA_Lead__c lead: leadsAssigned){
            if(lead.Assigned_To__c != Null && lead.Assigned_to__c != userinfo.getuserid()){
                if(!toUserIds.contains(lead.Assigned_To__r.contact.Email)){
                     toUserIds.add(lead.Assigned_To__r.contact.Email);
                }   
            }
        }
        return toUserIds;
    }
   
    public void SendMessage(){
        List<String> toAddressList = new list<String>();
        toAddressList.addAll(FetchToAddressOfCase(caseRecord,currentUser));
        List<DIA_Message__c> messagesToInsert = new List<DIA_Message__c>();
        DIA_Message__c message = new DIA_Message__c();
        message.Message_Body__c = messageBody;
        message.subject__c = messageSubject;
        message.From_User__c = userinfo.getUserId();
        message.case__c = caseRecord.id;
        messagesToInsert.add(message); 
        insert message;
        String emailBody = 'Message has been sent for the case #'+caseRecord.Case_Number__c+' Please login to check the message.';
        if(!test.isRunningTest()){
            MailUtilities.sendBIEmail(messageSubject,emailBody,toAddressList,null,null);
        }
        //FetchCaseMessages(); 
        messageSubject = null;
        messageBody = null;   
    }
     
    public void FetchCaseMessages(){
        
        messages = new list<DIA_Message__c>();
        List<string> messageFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        messageFields = ApexUtil.FetchFields('DIA_Message__c');  
        messageFields.add('case__r.case_number__c');
        messageFields.add('From_User__r.FirstName');
        messageFields.add('From_User__r.LastName');
        messageFields.add('To_User__r.FirstName');
        messageFields.add('To_User__r.LastName');
        messageFields.add('cc_User__r.FirstName');
        messageFields.add('cc_User__r.LastName');    
        String query = 'Select '+string.join(messageFields, ',') + ' From DIA_Message__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
         
            whereCriteria.add(new ApexUtil.Criteria('case__c',caseId,'='));
        }
        
      String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        System.debug('where_cond...'+where_cond);
        queryForNextRecords = query + ' WHERE '+where_cond;
        query = query + ' WHERE '+where_cond+' Order by Name asc Limit 200'; 
        System.debug('query...'+query);
        string countQuery = 'Select Count() from DIA_Message__c WHERE '+ where_cond;
        System.debug('countQuery...'+countQuery);
        totalRecordCount = database.countquery(Countquery);
        
        List<DIA_Message__c> msgs = database.query(query); 
        integer i = 0;
        for(DIA_Message__c msg: msgs){
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
        leadFields = ApexUtil.FetchFields('DIA_Lead__c');
        leadFields.add('contact__r.First_Name__c');
        leadFields.add('contact__r.Last_Name__c');
        leadFields.add('contact__r.Email__c');
        leadFields.add('Assigned_to__r.Name');
        leadFields.add('Assigned_to__r.Email');
        leadFields.add('case__r.case_number__c');
        leadFields.add('case__r.case_cancelled__c');
        leadFields.add('case__r.case_discontinued__c');
        
        String query = 'Select '+string.join(leadFields, ',') + ' From DIA_Lead__c ';
        
        if(String.isNotBlank(leadId)){
            whereCriteria.add(new ApexUtil.Criteria('Id',leadId,'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond; 
        System.debug('query...'+query);
        list<DIA_Lead__c> leads = database.query(query);
        if(!leads.isEmpty()){
            leadRecord = leads[0]; 
            caseId = leadRecord.case__c; 
            if(leadRecord.leadType__c == 'Subject Interview (ESI/TESI)'){
                 isValidForRTAExtension = true;
                 leadRecordRTAExtension = new DIA_Lead_RTA_Extension__c();
                 List<DIA_Lead_RTA_Extension__c> leadRecordExtensions = new List<DIA_Lead_RTA_Extension__c>();
                 leadRecordExtensions = [Select Id, Foreign_Activities__c, Foreign_Contacts__c, Foreign_Travel1__c, Foreign_Travel2__c, Lead__c
                                         FROM DIA_Lead_RTA_Extension__c WHERE Lead__c =:leadRecord.Id];
                 if(!leadRecordExtensions.isEmpty()){
                     leadRecordRTAExtension = leadRecordExtensions[0];
                 } else{
                     leadRecordRTAExtension = new DIA_Lead_RTA_Extension__c();
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
        update leadRecord;
        if(isValidForRTAExtension){
            if(toInsertleadRecordRTAExtension){
                insert leadRecordRTAExtension;
                toInsertleadRecordRTAExtension = false;
            }else{
                update leadRecordRTAExtension;
            }
        }
        PageReference redirectPage = Page.BIleaddashboard;
        redirectPage.setRedirect(true);
        return redirectPage;  
    }
    
    public string errorMessage {get;set;}
    public void updateleadaction(){
        try{
            errorMessage = null;
            update leadRecord;  
            if(isValidForRTAExtension){
                if(toInsertleadRecordRTAExtension){
                    insert leadRecordRTAExtension;
                    toInsertleadRecordRTAExtension = false;
                }else{
                    update leadRecordRTAExtension;
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
        if(isValidForRTAExtension){
            if(toInsertleadRecordRTAExtension){
                insert leadRecordRTAExtension;
                toInsertleadRecordRTAExtension = false;
            }else{
                update leadRecordRTAExtension;
            }
        }
        PageReference redirectPage =  Page.BIcasedetail;
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
            update leadRecord; 
            if(isValidForRTAExtension){
                if(toInsertleadRecordRTAExtension){
                    insert leadRecordRTAExtension;
                    toInsertleadRecordRTAExtension = false;
                }else{
                    update leadRecordRTAExtension;
                }
            }    
         }
         
    }
    
    public pagereference deleteleadaction(){
        delete leadRecord;
        PageReference redirectPage = Page.BIleaddashboard;
        redirectPage.setRedirect(true);
        return redirectPage;     
    }
    
    public void dummyaction(){
    
    }
    
     public void createdocumentrequestaction(){
        documentRequest.status__c = 'Documents Requested';
        system.debug('Document Request:' + documentRequest.to_address__c);
        insert documentRequest;
        documentRequest = new DIA_Document_Request__c();
        documentRequest.to_Address__c = leadRecord.Contact__r.Email__c;
        documentRequest.Lead__c = leadId;
        FetchDocumentRequests();
    }
    
    public  void FetchDocumentRequests(){
        documentrequestsmap = new Map<Id,DIA_Document_Request__c>([SELECT Id,Name,Status__c,To_Address__c, Additional_To_Address__c, Investigator_Comments__c FROM DIA_Document_Request__c WHERE Lead__c=:leadId order by createddate desc ]);
        documentrequestnattachmentsmap = new Map<Id,List<Attachment>>();
        documentrequestids = new list<string>();
        for(string docId: documentrequestsmap.keyset()){
            documentrequestids.add(docId);
            documentrequestnattachmentsmap.put(docId,new list<Attachment> {});
        }
        System.debug('documentrequestids...'+documentrequestids);
        List<Attachment> attachments = [Select id, name, parentid, description from Attachment where parentid=:documentrequestsmap.keyset()];
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
        system.debug('type...'+type);
        system.debug('otherreason...'+otherreason);
        system.debug('justification...'+justification);
        leadRecord.status__c = 'Applied For Waiver';
        leadRecord.Reason_for_Waiver__c = waiverreason;
        leadRecord.Other_Reason__c = otherreason;
        leadRecord.waiver_extension_justification__c = justification;
        leadRecord.Type__c = type;
        update leadRecord;
        if(isValidForRTAExtension){
            if(toInsertleadRecordRTAExtension){
                insert leadRecordRTAExtension;
                toInsertleadRecordRTAExtension = false;
            }else{
                update leadRecordRTAExtension;
            }
        }
        DIA_case_History__c ch = new DIA_case_History__c();
        ch.case__c = leadRecord.case__c;
        ch.added_by__c = userinfo.getuserid();
        ch.value__c = 'Applied For Waiver - '+ waiverreason;
        Insert ch;
        PageReference redirectPage = Page.BIleaddashboard;
        redirectPage.setRedirect(true);
        return redirectPage;  
        
        
    }
    
    public pagereference rejectleadaction(){
        leadRecord.status__c = 'QA Rejected';
        leadRecord.QA_Rejection_Comments__c = leadrejectionreason;
        update leadRecord;
        if(isValidForRTAExtension){
            if(toInsertleadRecordRTAExtension){
                insert leadRecordRTAExtension;
                toInsertleadRecordRTAExtension = false;
            }else{
                update leadRecordRTAExtension;
            }
        }
        List<string> toAddress = new List<string>();
        dia_lead__c diaLead = [select id,Assigned_to__r.contact.Email from dia_lead__c where id =: leadRecord.Id];
        toAddress.add(diaLead.Assigned_to__r.contact.Email);
        String subject = 'Lead '+leadRecord.LeadType__c + 'related to Case '+leadrecord.case__r.case_number__c+' is rejected, Please review.';
        if(!test.isRunningTest()){
            MailUtilities.sendBIEmail(subject,'',toAddress,null,null);
        }
        PageReference redirectPage = Page.BIcasedetail;
        redirectPage.getParameters().put('id',leadRecord.case__c);
        redirectPage.getParameters().put('tab','Leads');
        redirectPage.setRedirect(true);
        return redirectPage; 
    }
    
    public void reopenleadaction(){
        leadRecord.status__c = 'In-Progress';
        update leadRecord;
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
        update leadRecord;
    }
       public void handlePrev(){
            messages = new list<DIA_Message__c>();
        
        PageNumber --;
        string query = queryForNextRecords + ' AND Name <:firstRecordName  Order by Name desc Limit 200';      
        list<DIA_Message__c> msgs = database.query(query);
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
        messages = new list<DIA_Message__c>();
        PageNumber ++ ;
        System.debug('queryForNextRecords...'+queryForNextRecords);
        system.debug('lastRecordName....'+lastRecordName);
        string query = queryForNextRecords + ' AND Name >:lastRecordName  Order by Name asc Limit 200';    
        System.debug('query...'+query);
        list<DIA_Message__c> msgs = database.query(query);
        integer i = 0;
        for(DIA_Message__c msg: msgs){
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
}