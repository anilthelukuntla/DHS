public with sharing class DIACaseDetailController {
    public string caseId {get;set;}
    public DIA_Case__c caseRecord {get;set;}
    public DIA_Contact__c contactRecord {get;set;}
    public List<DIA_Lead__c> leads {get;set;}
    public List<DocumentRecord> documents {get;set;}
    public List<DocumentRecord> subjectDocuments {get;set;}
    public DIA_Lead__c newLead {get;set;}
    public List<DIA_Case_History__c> caseHistory {get;set;}
    public List<DIA_Waiver_Information__c> waiverInformation {get;set;}
    public List<DIA_Message__c> messages {get;set;}
    //public List<Subject_Message__c> subjectMessages {get;set;}
    public DIA_Case_History__c newCaseHistory {get;set;}
    public boolean hasWaiver{get;set;}
    public list<selectoption> assignUserList {get;set;}
    public string selectedUserIdForAssignment {get;set;}
    public user currentUser{get;set;}
    public boolean showQAReviewCompleteButton {get;set;}
    public string landingTab {get;set;}
    public Map<string,string> urlparametersMap {get;set;}
    public string urlparametersString {get;set;}
    public string messageEmailAddressesToSkip{get;set;}
    public string messageSubject{get;set;}
    public string messageBody{get;set;}
    public string messageSubjectForSubject{get;set;}
    public string messageBodyForSubject{get;set;}
    public string messageSubjectDuringLeadCreation{get;set;}
    public string messageBodyDuringLeadCreation{get;set;}
    public boolean sendUploadDocumentsLinkToSubject {get;set;}
    public string nextURL;
    public integer pageNumber {get;set;}
    public integer TotalPages   {get;set;}
    public integer totalRecordCount {get;set;}
    List<Object> records;
    public boolean disablePrev {get;set;}
    public boolean disableNext {get;set;}
    public boolean showautocreateleadbutton{get;set;}
    public string templatesUsed{get;set;}
    public static string caseRecordIDforDocUpload {get;set;}
    public string queryForNextRecords {get;set;}
    public string lastRecordName {get;set;}
    public string firstRecordName {get;set;}
    public integer currentRecordCount {get;set;}
    public string waiverreason {get;set;}
    public string type {get;set;}
    public string otherreason {get;set;}
    public string justification {get;set;}
    public User_Permission__mdt currentUserPermissions {get;set;}
    public string networkId {get;set;}
    public string CancelLeadId{get;set;}
    public string LeadCancellationStatus {get;set;}
    public dia_case__c currentCase {get;set;}
     @RemoteAction
    public static void CreateOrderNDocuments(list<string> contentversionIds,string caseRecordId){
        system.debug('contentversionIds....'+contentversionIds);
        system.debug('caseRecordId...'+caseRecordId);
        DIA_Case__c caseRecordforupload = new DIA_Case__c();
        List<DIA_Case__c> cases = [Select Subject_Type__c,Case_Number__c ,case_type__c, Contact__r.SSN__c from DIA_Case__c where Id=: caseRecordId];
        if(!cases.isEMpty()){
           caseRecordforupload = cases[0];
        }
        string uploadedby = [Select Id,Name from user where id=:userinfo.getuserid() ].Name;
 
        list<contentversion> contentVersions = [select id,ContentDocumentId,contentdocument.title from contentversion WHERE ID IN:contentversionIds];
        list<string> contentDocumentIds = new list<string>();
        map<string,string> contentdocumentIdandName = new map<string,string>();
        for(contentversion cv: contentVersions){
            contentDocumentIds.add(cv.ContentDocumentId);  
            contentdocumentIdandName.put(cv.ContentDocumentId,cv.contentdocument.title);
        }
        list<ContentDocumentLink> cdlsToCreate = new list<ContentDocumentLink>();
       
        for(string contentDocumentId : contentDocumentIds){
            string docName= contentdocumentIdandName.get(contentDocumentId);
             DIA_Document__c document = new DIA_Document__c();
             document.added_by__c = uploadedby;
             document.case__c = caseRecordforupload.id;
             document.Name__c = docName;
            insert document;
            
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentDocumentId;
            cdl.LinkedEntityId = document.id;
            cdl.ShareType = 'V'; 
            cdl.Visibility = 'AllUsers';
            cdlsToCreate.add(cdl);
        }
        if(!cdlsToCreate.isEmpty()){
            insert cdlsToCreate;    
        }
    }
    public list<selectoption> leadTemplateOptions {get;set;}
    public string selectedLeadTemplateId {get;set;}
    public map<string,Auto_Lead_Generation_Template__c> leadTemplatesMap {get;set;}
    public void FetchLeadGenerationTemplates(){
        list<Auto_Lead_Generation_Template__c> leadTemplates = new list<Auto_Lead_Generation_Template__c>();
        leadTemplates = [select Id,Name__c from Auto_Lead_Generation_Template__c];
        leadTemplateOptions = new list<selectoption>();
        leadTemplateOptions.add(new selectoption('','--None--'));
        for(Auto_Lead_Generation_Template__c template: leadTemplates){
            leadTemplateOptions.add(new selectoption(template.id,template.Name__c));    
        }
    }   
    public boolean disableautocreateleadbutton {get;set;}
    public void onleadtemplateselect(){
        showautocreateleadbutton = true;
        if(templateIdsUsed.contains(selectedLeadTemplateId)){
            disableautocreateleadbutton = true;     
        }else{
            disableautocreateleadbutton = false;
        }
        
    }
    public void cancelleadaction(){
        system.debug('CancelLeadId...'+CancelLeadId);
        dia_lead__c dialead = [select id from dia_lead__c where Id =: CancelLeadId];
        dialead.Status__c = 'Cancelled';
        update dialead;
        FetchLeadInformation();
    }
    public DIACaseDetailController(){
        LeadCancellationStatus = JSON.serialize(system.label.Cancel_Lead_Button.split(','));
        
        system.debug(LeadCancellationStatus);
        networkID = [SELECT Id,name FROM Network where name='foreSite' LIMIT 1].Id;
        sendUploadDocumentsLinkToSubject = false;
        FetchLeadGenerationTemplates();
        showautocreateleadbutton = false;
        disableautocreateleadbutton = false;
        pageNumber = 1;
        disablePrev = true;
        disableNext = true;
        records = New List<Object>();
        newLead = new DIA_Lead__c();
        currentUser = [Select Id,profile.Name,system_access__c,contact.Email, FirstName, LastName, User_Type__c FROM User where Id=:userinfo.getUserId()];
        currentUserPermissions = PermissionsUtil.GetUserPermssions(currentUser.User_Type__c);
        
        //currentUser = [Select Id,profile.Name,system_access__c,contact.Email, FirstName, LastName, User_Type__c FROM User where Id=:userinfo.getUserId()];
        caseId = apexpages.currentpage().getparameters().get('id');
        caseRecordIDforDocUpload = caseId;
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
        //FetchSubjectDocumentInformation(); 
        FetchCaseHistoryInformation();
        FetchWaiverInformation();
        FetchCaseMessages();
        //FetchCaseSubjectMessages();
        System.debug('caserecord....'+caserecord);
        newLead = new DIA_Lead__c();
        newCaseHistory = new DIA_Case_History__c();
        List<user> assignUsers = new List<user>();
        assignUsers = [select Id,system_access__c, User_Type__c, FirstName, lastname  FROM User where isactive=true AND User_Type__c = 'CMO' order by firstname];
        assignUserList = new List<SelectOption>();
        assignUserList.add(new SelectOption('','--None--'));
        for(User u: assignUsers){
            if(u.system_access__c.contains('DIA')){
                assignUserList.add(new SelectOption(u.id,u.firstname+' '+u.lastname));
            }
            
        }
        if(caseRecord.Assigned_To__c != null){
            selectedUserIdForAssignment = caseRecord.Assigned_To__c ;
        }
        FetchCaseNLeadTemplates();
         
    }
    
    public void FetchCaseNLeadTemplates(){
        list<Case_And_Lead_Template__c> leadTemplatesUsed = new list<Case_And_Lead_Template__c>();
        leadTemplatesUsed = [select Id,Auto_Lead_Generation_Template__c,Auto_Lead_Generation_Template__r.Name__c,case__c from Case_And_Lead_Template__c  where case__c=:caseId ];
        templateIdsUsed = new list<String>();
        templatesUsed = null;
        for(Case_And_Lead_Template__c algt: leadTemplatesUsed){
            if(string.isBlank(templatesUsed)){
                templatesUsed = '<a target="_blank" href="apex/AutoLeadGenerationSettings?templateId='+algt.Auto_Lead_Generation_Template__c+'">'+algt.Auto_Lead_Generation_Template__r.Name__c+'</a>';
            }else{
                templatesUsed = templatesUsed+',<a target="_blank" href="/apex/AutoLeadGenerationSettings?templateId='+algt.Auto_Lead_Generation_Template__c+'">'+algt.Auto_Lead_Generation_Template__r.Name__c+'</a>';    
            }
            templateIdsUsed.add((string)algt.Auto_Lead_Generation_Template__c);
        }    
    }
    
    public static list<string> FetchToAddressOfCase(DIA_Case__c caseRecord, user currentUser){
        list<string> toUserIds = new list<string>();
        if(currentuser.user_type__c != 'PMO' && currentuser.profile.Name != 'System Administrator'){
           //toUserIds.add(caseRecord.Owner.Email);
        }
        system.debug(toUserIds);
        if(caseRecord.Assigned_to__c != Null && caseRecord.Assigned_to__c != userinfo.getuserid()){
            dia_case__c caserec = [select id,Assigned_to__r.contact.Email from dia_case__c where id =: caseRecord.Id];
            if(!toUserIds.contains(caserec.Assigned_to__r.contact.Email) ){
                toUserIds.add(caserec.Assigned_to__r.contact.Email);
            }
        }
        system.debug(toUserIds);
        List<DIA_Lead__c> leadsAssigned = new List<DIA_Lead__c>();
        leadsAssigned = [Select Id, Status__c, Assigned_To__c, Assigned_to__r.contact.Email, Assigned_To__r.Email, Case__c, Assigned_to__r.FirstName, Assigned_to__r.LastName from DIA_Lead__c where Case__c=:caseRecord.id];
        for(DIA_Lead__c lead: leadsAssigned){
            if(lead.Assigned_To__c != Null && lead.Assigned_to__c != userinfo.getuserid()){
                if(!toUserIds.contains(lead.Assigned_to__r.contact.Email)){
                     toUserIds.add(lead.Assigned_to__r.contact.Email);
                }   
            }
        }
        system.debug(toUserIds);
        return toUserIds;
    }
    
    public static list<string> FetchUsersOfCase(DIA_Case__c caseRecord, user currentUser){
        list<string> toUserIds = new list<string>();
        if(currentuser.user_type__c != 'PMO'){
           toUserIds.add(caseRecord.ownerId);
        }
        if(caseRecord.Assigned_to__c != Null && caseRecord.Assigned_to__c != userinfo.getuserid()){
            if(!toUserIds.contains(caseRecord.Assigned_to__c) ){
                toUserIds.add(caseRecord.Assigned_to__c);
            }
        }
        List<DIA_Lead__c> leadsAssigned = new List<DIA_Lead__c>();
        leadsAssigned = [Select Id, Status__c, Assigned_To__c, Assigned_To__r.Email, Case__c, Assigned_to__r.FirstName, Assigned_to__r.LastName from DIA_Lead__c where Case__c=:caseRecord.id ];
        for(DIA_Lead__c lead: leadsAssigned){
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
        system.debug(toAddressList);
        list<string> newtoAddressList = new list<String>();
        if(String.isNotblank(messageEmailAddressesToSkip)){
            list<string> emailAddressesToSkip =  messageEmailAddressesToSkip.split(',');
            for(string str: toAddressList){
                if(!emailAddressesToSkip.contains(str)){
                    newtoAddressList.add(str);    
                }    
            }
        }else{
            newtoAddressList.addAll(toAddressList);    
        }
         System.debug('newtoAddressList..'+newtoAddressList);
        toUserIdsForMessageLogs.addAll(FetchUsersOfCase(caseRecord,currentUser));
        List<DIA_Message__c> messagesToInsert = new List<DIA_Message__c>();
        DIA_Message__c message = new DIA_Message__c();
        message.Message_Body__c = messageBody;
        message.subject__c = messageSubject;
        message.From_User__c = userinfo.getUserId();
        message.case__c = caseRecord.id;
        messagesToInsert.add(message);
        Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_Message__c');
        if(Schema.SobjectType.DIA_Message__c.iscreateable() && 
            fields.get('Message_Body__c').getDescribe().isAccessible() &&
            fields.get('subject__c').getDescribe().isAccessible() &&
            fields.get('From_User__c').getDescribe().isAccessible() &&
            fields.get('case__c').getDescribe().isAccessible()
            ){
                insert message;
                //Database.SaveResult dsr = database.insert(message,false,AccessLevel.USER_MODE);
            }else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to create Messages'));
            }
        
            Map<String, Schema.SObjectField> messageFields = ApexUtil.getObjectFieldsDescribe('DIA_Message_Log__c');
        List<DIA_Message_Log__c> messageLogsToCreate = new List<DIA_Message_Log__c>();
        for(string userId: toUserIdsForMessageLogs){
            DIA_Message_Log__c log = new DIA_Message_Log__c();
            log.user__c = userId;
            log.message__c = message.id;
            log.Unread__c = true;
            log.read__c = false;  
            messageLogsToCreate.add(log);  
        }
         //messageEmailAddressesToSkip
        if(Schema.SobjectType.DIA_Message_Log__c.iscreateable() && 
            messageFields.get('message__c').getDescribe().isAccessible() &&
            messageFields.get('Unread__c').getDescribe().isAccessible() &&
            messageFields.get('user__c').getDescribe().isAccessible() &&
            messageFields.get('read__c').getDescribe().isAccessible()
            ){
                insert messageLogsToCreate;
                String emailBody = 'Dear Member,<br/><br/>A new case message has been posted by '+Currentuser.firstname+' '+currentuser.lastname+' the for Case# '+caseRecord.case_Number__c+'. Please log in to the case management system to retrieve the message from case tab.<br/><br/>Thanks<br/>ISN Corporation';
                    if(!test.isRunningTest()){
                        if(!newtoAddressList.isEmpty())
                        MailUtilities.sendBIEmail(messageSubject,emailBody,newtoAddressList,null,null);
                        //FetchCaseMessages();
                    }
                    messageSubject = null;
                    messageBody = null; 
                    messageEmailAddressesToSkip = null;
                    PageReference pr = Page.BICaseDetail;
                    pr.getParameters().put('id',caseRecord.Id);
                    pr.getParameters().put('tab','Messages');
                    pr.setRedirect(true);
                    return pr;
                /*List<Database.SaveResult> dsr =  database.insert(messageLogsToCreate,false,AccessLevel.USER_MODE);
                integer i = 0;
                for(Database.SaveResult ds: dsr){
                    if(ds.isSuccess()) i++;
                }
                if(i == messageLogsToCreate.size()){
                    String emailBody = 'Dear Member,<br/><br/>A new case message has been posted by '+Currentuser.firstname+' '+currentuser.lastname+' the for Case# '+caseRecord.case_Number__c+'. Please log in to the case management system to retrieve the message from case tab.<br/><br/>Thanks<br/>ISN Corporation';
                    if(!test.isRunningTest()){
                        MailUtilities.sendHTMLEmail(toAddressList,messageSubject,emailBody,null);
                    }
                    //FetchCaseMessages(); 
                    messageSubject = null;
                    messageBody = null; 
                    PageReference pr = Page.BICaseDetail;
                    pr.getParameters().put('id',caseRecord.Id);
                    pr.getParameters().put('tab','Messages');
                    pr.setRedirect(true);
                    return pr;
                }
                else{
                    return null;
                }*/
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to create Messages Log'));
                return null;
            }
        
        
    }
    
    
    /*public pagereference SendSubjectMessage(){
        dia_case__c diacase = [select id,Contact__c, Contact__r.email__c from dia_case__c where id=:caseRecord.id];
        List<Subject_Message__c> messagesToInsert = new List<Subject_Message__c>();
        Subject_Message__c message = new Subject_Message__c();
        
        message.message_subject__c = messageSubjectForSubject;
        messageSubjectForSubject =  '#'+ diacase.contact__r.email__c + '#'+ messageSubjectForSubject;
        message.Subject__c = diacase.Contact__c;
        message.From_User__c = userinfo.getUserId();
        message.dia_case__c = caseRecord.id;
        message.message_type__c = 'Outbound';
       
        ID diacaseId = Id.valueOf(caseRecord.id);
        String formattedToken = EmailMessages.getFormattedThreadingToken(diacaseId);
		//https://isn-foresite--inteldev--c.sandbox.vf.force.com/apex/isn-foresite--inteldev.sandbox.my.salesforce-sites.com/SubjectFileUploadAuthPage
        //string fileuploadurl = '<a href="'+system.label.Subject_Site+'?id='+caseRecord.id+'">Please click below link to upload files</a>';
		string fileuploadurl = '<a href="'+system.label.Subject_Site+'/SubjectFileUploadAuthPage?id='+caseRecord.id+'">Please click below link to upload files</a>';        
        string signature = '<br/>Thanks,<br/>Background Investigation Team<br/>';
		signature = signature + 'ISN Corporation<br/>';
		signature = signature + '10411 Motor City Dr<br/>';
		signature = signature + 'Bethesda, MD 20874<br/>';
		signature = signature + 'email: Bi-team@isncorp.com';
        if(sendUploadDocumentsLinkToSubject){
        	messageBodyForSubject = messageBodyForSubject+'<br>'+fileuploadurl+'<br/>'+signature+'<br/><br/>'+formattedToken;    
        }else{
        	messageBodyForSubject = messageBodyForSubject+'<br/>'+signature+'<br/><br/>'+formattedToken;        
        }
		
        message.Message_Body__c = messageBodyForSubject;
        messagesToInsert.add(message);
       
                insert message;
              
	        
           
                    if(!test.isRunningTest()){
                        
                            //MailUtilities.sendBISubjectEmail(diacase.id,messageSubjectForSubject,messageBodyForSubject,new list<string>{diacase.contact__r.email__c},null,null);
                            MailUtilities.sendBISubjectEmail(diacase.id,messageSubjectForSubject,messageBodyForSubject,new list<string>{'BI-Contractor@isncorp.com'},null,new list<string>{'diainvtest@isncorp.com'});

                    }
                    messageBodyForSubject = null;
                    messageBodyForSubject = null; 
        sendUploadDocumentsLinkToSubject = false;
                    PageReference pr = Page.BICaseDetail;
                    pr.getParameters().put('id',caseRecord.Id);
                    //pr.getParameters().put('tab','SubjectMessages');
                    pr.setRedirect(true);
                   return pr;
                
               
           
    }*/
    
    public void SendMessage(string messageSubjectParam, string messageBodyParam){
        list<string> toUserIdsForMessageLogs = new list<string>();
        List<String> toAddressList = new list<String>();
        toAddressList.addAll(FetchToAddressOfCase(caseRecord,currentUser));
        System.debug('inside send message!!!!');
        system.debug(toAddressList);
        toUserIdsForMessageLogs.addAll(FetchUsersOfCase(caseRecord,currentUser));
        List<DIA_Message__c> messagesToInsert = new List<DIA_Message__c>();
        DIA_Message__c message = new DIA_Message__c();
        message.Message_Body__c = messageBodyParam;
        message.subject__c = messageSubjectParam;
        message.From_User__c = userinfo.getUserId();
        message.case__c = caseRecord.id;
        messagesToInsert.add(message); 
        Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_Message__c');
        if(Schema.SobjectType.DIA_Message__c.iscreateable() && 
            fields.get('Message_Body__c').getDescribe().isAccessible() &&
            fields.get('subject__c').getDescribe().isAccessible() &&
            fields.get('From_User__c').getDescribe().isAccessible() &&
            fields.get('case__c').getDescribe().isAccessible()
            ){
                insert message;
                List<DIA_Message_Log__c> messageLogsToCreate = new List<DIA_Message_Log__c>();
        for(string userId: toUserIdsForMessageLogs){
            DIA_Message_Log__c log = new DIA_Message_Log__c();
            log.user__c = userId;
            log.message__c = message.id;
            log.Unread__c = true;
            log.read__c = false;  
            messageLogsToCreate.add(log);   
            insert messageLogsToCreate;
            
            
            String emailBody = 'Dear Member,<br/><br/>A new case message has been posted by '+Currentuser.firstname+' '+currentuser.lastname+' the for Case# '+caseRecord.case_Number__c+'. Please log in to the case management system to retrieve the message from case tab.<br/><br/>Thanks<br/>ISN Corporation';
                    if(!test.isRunningTest()){
                        MailUtilities.sendBIEmail(messageSubject,emailBody,toAddressList,null,null);
                    }
                    FetchCaseMessages();

        }
                //database.insert(message,false,AccessLevel.USER_MODE);
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to create Messages'));
            }
        
        /*List<Message_Log__c> messageLogsToCreate = new List<Message_Log__c>();
        for(string userId: toUserIdsForMessageLogs){
            Message_Log__c log = new Message_Log__c();
            log.user__c = userId;
            log.message__c = message.id;
            log.Unread__c = true;
            log.read__c = false;  
            messageLogsToCreate.add(log);  
        }
        Map<String, Schema.SObjectField> messageFields = ApexUtil.getObjectFieldsDescribe('DIA_Message_Log__c');
        if(Schema.SobjectType.DIA_Message_Log__c.iscreateable() && 
            messageFields.get('message__c').getDescribe().isAccessible() &&
            messageFields.get('Unread__c').getDescribe().isAccessible() &&
            messageFields.get('user__c').getDescribe().isAccessible() &&
            messageFields.get('read__c').getDescribe().isAccessible()
            ){
                List<Database.SaveResult> dsr = database.insert(messageLogsToCreate,false,AccessLevel.USER_MODE);
                integer i = 0;
                for(Database.SaveResult ds : dsr){
                    if(ds.isSuccess()) i++;
                }
                if(i == messageLogsToCreate.size()){
                    String emailBody = 'Dear Member,<br/><br/>A new case message has been posted by '+Currentuser.firstname+' '+currentuser.lastname+' the for Case# '+caseRecord.case_Number__c+'. Please log in to the case management system to retrieve the message from case tab.<br/><br/>Thanks<br/>ISN Corporation';
                    if(!test.isRunningTest()){
                        MailUtilities.sendHTMLEmail(toAddressList,messageSubject,emailBody,null);
                    }
                    FetchCaseMessages(); 
                }
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to create Messages Log'));
            }*/
    }
    
    
    
    public void OnChangeLeadType(){
    
    }
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('','--None--'));
        options.add(new SelectOption('Subject not available','Subject not available'));
        options.add(new SelectOption('Other','Other'));
        return options; 
    }
    public PageReference applyforwaiveraction(){
        System.debug('waiverreason....'+waiverreason);
        system.debug('type...'+type);
        system.debug('otherreason...'+otherreason);
        system.debug('justification...'+justification);
        
                DIA_Waiver_Information__c wi = new DIA_Waiver_Information__c();
                wi.Case__c = caseRecord.Id;
                wi.Waiver_Reason__c = waiverreason;
                wi.Waiver_Flagged_Date__c = system.today();
                wi.Type__c = type;
                wi.Other_Reason__c = otherreason;
                wi.justification__c = justification;
                wi.Waiver_Initiated_Date__c =  system.today();
                insert wi;
        
        
        DIA_case_History__c ch = new DIA_case_History__c();
        ch.case__c = caseRecord.Id;
        ch.added_by__c = userinfo.getuserid();
        ch.value__c = 'Applied For Waiver - '+ waiverreason;
        Insert ch;
        PageReference redirectPage = Page.BICaseDetail;
        redirectPage.getParameters().put('id',caseRecord.id);
        redirectPage.setRedirect(true);
        return redirectPage;  
        
        
    }
    public void updatecaseaction(){
        if(selectedUserIdForAssignment != Null){
            caseRecord.Assigned_To__c = selectedUserIdForAssignment;
            caseRecord.Case_Queue_Status__c = 'Assigned';
            caseRecord.Assignee_Date__c = system.today();
            caseRecord.current_task__c = 'Validate Transmission';
            caseRecord.validate_transmission_date__c = system.today();
                DIA_case_History__C ch = new DIA_case_History__c();
                ch.case__c = caseRecord.id;
                ch.added_by__c = userinfo.getuserid();
                ch.value__c = 'Validate Transmission';
                Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_case_History__C');
                if(Schema.SobjectType.DIA_case_History__C.iscreateable() && 
                    fields.get('case__c').getDescribe().isAccessible() &&
                    fields.get('added_by__c').getDescribe().isAccessible() &&
                    fields.get('value__c').getDescribe().isAccessible()
                ){
                    database.insert(ch,false,AccessLevel.USER_MODE);
                }else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to create Case History'));
                }
               
        }
        if(caseRecord.Customer_Delivery_Date__c != Null){
            caseRecord.Purge_Date__c = caseRecord.Customer_Delivery_Date__c.addDays(90);
            caseRecord.End_Purge_Date__c = caseRecord.Customer_Delivery_Date__c.addDays(180);
        }
        boolean updateContact = false;
        if(caseRecord.contact__c != Null){
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
        }
        if(updateContact){
            if(Schema.SobjectType.DIA_Contact__c.isUpdateable()){
                database.update(contactRecord,false,AccessLevel.USER_MODE);
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update Contact'));
            }
        }
        if(caseRecord.case_discontinued__c){
            caseRecord.current_task__c = 'Discontinued';    
        }
        if(Schema.SobjectType.DIA_Case__c.isUpdateable()
        ){
            update caseRecord;
            FetchCaseInformation();
            FetchLeadInformation();
            /*Database.SaveResult dsr = database.update(caseRecord,false,AccessLevel.USER_MODE);
            system.debug('Result '+dsr);
            if(dsr.isSuccess()){
                
            }else{
                for(Database.Error err : dsr.getErrors()) {
                System.debug('The following error has occurred.');                    
                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                System.debug('Case fields that affected this error: ' + err.getFields());
        }
            }*/
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update Case'));
        }
    }
    
    public void markleadcreationcompleteaction(){
         DIA_case_History__c ch = new DIA_case_History__c();
                   ch.case__c = caseRecord.id;
                   ch.added_by__c = userinfo.getuserid();
                   ch.value__c = 'Investigations';
                   /*Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_case_History__c');
                   if(Schema.SobjectType.DIA_case_History__c.iscreateable() && 
                        fields.get('case__c').getDescribe().isAccessible()&&
                        fields.get('added_by__c').getDescribe().isAccessible()&&
                        fields.get('value__c').getDescribe().isAccessible()
                    ){
                        database.saveresult sr = database.insert(ch,false,AccessLevel.USER_MODE);
                        system.debug(sr);
                        
                    }else{
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to create Case History'));
                    }*/
         
            insert ch;
          caseRecord.current_task__c = 'Investigations';
          caseRecord.Investigations_Date__c = system.today();
          Map<String, Schema.SObjectField> caseFields= ApexUtil.getObjectFieldsDescribe('DIA_Case__c');
          if(Schema.SobjectType.Case__c.isUpdateable() && 
                caseFields.get('current_task__c').getDescribe().isAccessible()&&
                caseFields.get('Investigations_Date__c').getDescribe().isAccessible()
            ){
               // Database.SaveResult dsr = database.update(caseRecord,false,AccessLevel.USER_MODE);
               // system.debug(dsr);
              //  if(dsr.isSuccess()) FetchCaseHistoryInformation();
              
              
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update Case History'));
            }
        update caseRecord;
        FetchCaseHistoryInformation();
        }
    
    public void AddCommentsAction(){
        newCaseHistory.case__c = caseId;
        newCaseHistory.added_by__c = userinfo.getuserid();
        newCaseHistory.Type__c = 'Comment';
        Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_case_History__c');
        if(Schema.SobjectType.DIA_Case_History__c.iscreateable() && 
            fields.get('case__c').getDescribe().isAccessible()&&
            fields.get('added_by__c').getDescribe().isAccessible()&&
            fields.get('value__c').getDescribe().isAccessible()
        ){
            Database.SaveResult dsr = database.insert(newCaseHistory,false,AccessLevel.USER_MODE);
            if(dsr.isSuccess()){
                newCaseHistory = new DIA_Case_History__c();
                FetchCaseHistoryInformation();
            }
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to create Case History'));
        }
    }
    
    public string errorMessage {get;set;}
    
    public void autocreateleads(){
        List<Auto_Lead_Generation_Template__c> templates = new List<Auto_Lead_Generation_Template__c>();
        templates = [select id, name__c from Auto_Lead_Generation_Template__c where id=:selectedLeadTemplateId];
        List<string> autoLeadGenerationSettingsFields = new List<string>();
        autoLeadGenerationSettingsFields = ApexUtil.FetchFields('Auto_Lead_Generation_Setting__c');
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        String query = 'Select '+string.join(autoLeadGenerationSettingsFields, ',') + ' From Auto_Lead_Generation_Setting__c WHERE Auto_Lead_Generation_Template__c=:selectedLeadTemplateId Order by Item_Number__c ';
        System.debug('query...'+query);
        list<Auto_Lead_Generation_Setting__c> autoLeadGenerationSettingrecords = database.query(query);
        list<dia_lead__c> leadsToCreate = new list<dia_lead__c>();
        for(Auto_Lead_Generation_Setting__c algs: autoLeadGenerationSettingrecords){
            dia_lead__c dlead = new dia_lead__c();
            dlead.leadtype__c = algs.lead_type__c;
            dlead.coverage_type__c = algs.coverage_type__c;
            dlead.item_number__c = algs.item_number__c;
            dlead.Case__c = caseId;
            dlead.Status__c = 'UnAssigned';
            dlead.Contact__c = caseRecord.Contact__c;
            dlead.Due_Date__c = System.today().addDays(7);
            leadsToCreate.add(dlead);
        }
        try{
            if(!leadsToCreate.isEmpty()){
                insert leadsToCreate;
                FetchLeadInformation();
                FetchCaseInformation();
            }
            list<Lead_RTA_Extension__c> lrtaToCreate = new list<Lead_RTA_Extension__c>();
            for(dia_lead__c l:leadsToCreate){
                if(newLead.leadType__c == 'Subject Interview (ESI/TESI)'){
                    Lead_RTA_Extension__c leadRTAExtension = new Lead_RTA_Extension__c();
                    leadRTAExtension.lead__c = l.id;    
                    lrtaToCreate.add(leadRTAExtension);
                }
            }
            if(!lrtaToCreate.isEmpty()){
                insert lrtaToCreate;    
            }
            Case_And_Lead_Template__c clt = new Case_And_Lead_Template__c();
            clt.Auto_Lead_Generation_Template__c = selectedLeadTemplateId;
            clt.case__c = caseId;
            insert clt;
            FetchCaseNLeadTemplates();
            selectedLeadTemplateId = null;
           
        }catch(Exception ex){
            System.debug('insied exception message!!');
            errorMessage = ex.getMessage();
            if(errorMessage.contains(System.label.Duplicate_Item_Number_Message)){
                errorMessage = 'Duplicate Item number found while creating leads using this template!';
            } 
            system.debug(errorMessage);
        }
    }
    public list<string> templateIdsUsed {get;set;}   
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
            /*
            Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_Lead__c');
            if(Schema.SobjectType.DIA_Lead__c.iscreateable() && 
                fields.get('case__c').getDescribe().isAccessible()&&
                fields.get('Status__c').getDescribe().isAccessible()&&
                fields.get('Contact__c').getDescribe().isAccessible() &&
                fields.get('Due_Date__c').getDescribe().isAccessible()
            ){
                database.saveresult sr = database.insert(newLead,false,AccessLevel.USER_MODE);
                system.debug('Creating lead result...'+sr);
                  newLead = new DIA_Lead__c();
                        FetchLeadInformation();
                        FetchCaseInformation();
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to create Lead'));
            }*/
            if(newLead.leadType__c == 'Subject Interview (ESI/TESI)'){
                dia_Lead_RTA_Extension__c leadRTAExtension = new dia_Lead_RTA_Extension__c();
                leadRTAExtension.lead__c = newLead.id;    
                /*Map<String, Schema.SObjectField> rtaFields = ApexUtil.getObjectFieldsDescribe('Lead_RTA_Extension__c');
                if(Schema.SobjectType.Lead_RTA_Extension__c.iscreateable() && 
                    rtaFields.get('lead__c').getDescribe().isAccessible()
                ){
                    Database.SaveResult dsr = database.insert(leadRTAExtension,false,AccessLevel.USER_MODE);
                    system.debug('result...'+dsr);
                    if(dsr.isSuccess()){
                        if(String.isNotblank(messageSubjectDuringLeadCreation) && String.isNotBlank(messageBodyDuringLeadCreation)){
                            SendMessage(messageSubjectDuringLeadCreation,messageBodyDuringLeadCreation);
                            messageSubjectDuringLeadCreation = Null;
                            messageBodyDuringLeadCreation = Null;
                        }
                        newLead = new DIA_Lead__c();
                        FetchLeadInformation();
                        FetchCaseInformation();
                    }
                }else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to create Lead RTA Extension'));
                }*/
                    insert leadRTAExtension;
                  System.debug('messageSubjectDuringLeadCreation...'+messageSubjectDuringLeadCreation);       
                 System.debug('messageBodyDuringLeadCreation...'+messageBodyDuringLeadCreation);       
                
                       // newLead = new DIA_Lead__c();
                       // FetchLeadInformation();
                       // FetchCaseInformation();
            
            }
            
            if(String.isNotblank(messageSubjectDuringLeadCreation) && String.isNotBlank(messageBodyDuringLeadCreation)){
                            System.debug('inside leadcreation send message');       
                            SendMessage(messageSubjectDuringLeadCreation,messageBodyDuringLeadCreation);
                            messageSubjectDuringLeadCreation = Null;
                            messageBodyDuringLeadCreation = Null;
                 }
            
           
            newLead = new DIA_Lead__c();
            FetchTotalCaseInformation();
            //FetchLeadInformation();
            //FetchCaseInformation();
            //FetchCaseMessages();
        }catch(Exception ex){
            errorMessage = ex.getMessage();
            if(errorMessage.contains(System.label.Duplicate_Item_Number_Message)){
                errorMessage = System.label.Duplicate_Item_Number_Message;
            }
            system.debug(errorMessage);
        }
    }
    
    public void FetchTotalCaseInformation(){
        system.debug('FetchTotalCaseInformation...');
        FetchLeadInformation();
        FetchCaseInformation();
        FetchCaseMessages();    
        //FetchCaseSubjectMessages();    
    }
    public void FetchCaseInformation(){
        List<string> caseFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        caseFields = ApexUtil.FetchFields('DIA_Case__c');
        caseFields.add('contact__r.First_Name__c');
        caseFields.add('contact__r.SSN__c');
        caseFields.add('contact__r.Last_Name__c');
        caseFields.add('contact__r.Email__c');
        caseFields.add('Assigned_to__r.FirstName');
        caseFields.add('Assigned_to__r.LastName');
        caseFields.add('Assigned_to__r.Email');
        caseFields.add('owner.email');
        string systemFields = 'createddate,createdbyid,lastmodifieddate,lastmodifiedbyid,systemmodstamp,lastvieweddate,lastreferenceddate';
        for(string field : systemFields.split(',')){
            caseFields.remove(caseFields.indexOf(field));
        }
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
            System.debug('caseRecord.Subject__c...'+caseRecord.Contact__c);
            if(caseRecord.Contact__c != Null){
                contactRecord = [Select Id, First_Name__c, Last_Name__c, Email__c from DIA_Contact__c where Id=: caseRecord.Contact__c ]; 
            }   
        }    
    }
    public void FetchLeadInformation(){
        currentCase = [select id,assigned_to__r.Name,assigned_to__r.email,assigned_to__r.phone from dia_case__c where id =: caseId];
        leads = new List<DIA_Lead__c> ();
        List<string> leadFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        leadFields = ApexUtil.FetchFields('DIA_Lead__c');      
        String query = 'Select '+string.join(leadFields, ',') + ' From DIA_Lead__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new ApexUtil.Criteria('case__c',caseId,'='));
        }
        if(currentuser.user_type__c == 'INV'){
            whereCriteria.add(new ApexUtil.Criteria('assigned_to__c',userinfo.getuserid(),'='));
        }
        if(currentuser.user_type__c == 'QA'){
            whereCriteria.add(new ApexUtil.Criteria('status__c','Completed','='));
            whereCriteria.add(new ApexUtil.Criteria('assigned_to__c',userinfo.getuserid(),'!='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+ ' ORDER BY Item_Number__c Asc'; 
        
        leads = database.query(query);
        boolean qaReviewCompleted = true;
        for(DIA_Lead__c lead: leads){
            if(lead.status__c != 'QA Review Completed'){
                qaReviewCompleted = false;
            }
        }
        showQAReviewCompleteButton = qaReviewCompleted;
    }
    
    public void FetchCaseMessages(){
        List<Map<string,Object>> conditions = New List<Map<string,Object>>();
        messages = new list<DIA_Message__c>();
        List<string> messageFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        messageFields = ApexUtil.FetchFields('DIA_Message__c');  
        messageFields.add('case__r.case_number__c');
        messageFields.add('From_User__r.FirstName');
        messageFields.add('From_User__r.LastName');
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
    
    /*public void FetchCaseSubjectMessages(){
        List<Map<string,Object>> conditions = New List<Map<string,Object>>();
        subjectMessages = new list<Subject_Message__c>();
        List<string> subjectMessageFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        subjectMessageFields = ApexUtil.FetchFields('Subject_Message__c');  
        subjectMessageFields.add('DIA_Case__r.case_number__c');
        subjectMessageFields.add('From_User__r.FirstName');
        subjectMessageFields.add('From_User__r.LastName');
        String query = 'Select '+string.join(subjectMessageFields, ',') + ' From Subject_Message__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
         
            whereCriteria.add(new ApexUtil.Criteria('DIA_Case__c',caseId,'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        System.debug('where_cond...'+where_cond);
        subjectMessagequeryForNextRecords = query + ' WHERE '+where_cond;
        query = query + ' WHERE '+where_cond+' Order by Name asc Limit 200'; 
        System.debug('subject message query...'+query);
        string countQuery = 'Select Count() from Subject_Message__c WHERE '+ where_cond;
        System.debug('countQuery...'+countQuery);
        subjectMessagetotalRecordCount = database.countquery(Countquery);
        
        List<Subject_Message__c> msgs = database.query(query); 
        integer i = 0;
        for(Subject_Message__c msg: msgs){
            subjectMessages.add(msg); 
            if(i==0){
                subjectMessagefirstRecordName = msg.Name;    
            }
            subjectMessagelastRecordName = msg.Name;
            i++;
        }
        subjectMessagePageNumber = 1;
        double totalNum = double.valueof(subjectMessagetotalRecordCount)/double.valueof(200);
        double floorVal = Math.floor(totalNum);
        double diff = totalNum - floorVal;
        SubjectMessageTotalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
        system.debug('TotalPages...'+TotalPages);
        if(subjectMessagetotalRecordCount <= 200){
            subjectMessagedisablePrev = true;
            subjectMessagedisableNext = true;
            subjectMessagecurrentRecordCount = subjectMessagetotalRecordCount;
        }else{
            disablePrev = true;   
            disableNext = false;
            subjectMessagecurrentRecordCount = 200; 
        }
         
      
    }*/
    

    
    public void FetchWaiverInformation(){
        waiverInformation = new list<DIA_Waiver_Information__c>();
        List<string> waiverInformationFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        waiverInformationFields = ApexUtil.FetchFields('DIA_Waiver_Information__c');      
        waiverInformationFields.add('lead__r.Name');
        waiverInformationFields.add('case__r.Name');
        waiverInformationFields.add('Createdby.Name');
        String query = 'Select '+string.join(waiverInformationFields, ',') + ' From DIA_Waiver_Information__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new ApexUtil.Criteria('case__c',caseId,'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+ '  ORDER BY CreatedDate Asc'; 
        
        waiverInformation = database.query(query); 
        if(!waiverInformation.isEmpty()){
            hasWaiver = true;
        }   
    }
    public string waiverinformationidtoupdate{get;set;}
    public void autosavewaiverinformationaction(){
        DIA_Waiver_Information__c recordToUpdate = new DIA_Waiver_Information__c();
        for(DIA_Waiver_Information__c wv: waiverInformation){
            if(wv.id == waiverinformationidtoupdate){
                recordToUpdate = wv;
            }
        }
        if(recordToUpdate != Null){
            if(Schema.SobjectType.DIA_Waiver_Information__c.isUpdateable()
            ){
                update recordToUpdate;
                //database.update(recordToUpdate,false,AccessLevel.USER_MODE);
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update waiver information'));
            }
        }
    }
    
    public void updatewaiverinformation(){
        if(Schema.SobjectType.DIA_Waiver_Information__c.isUpdateable()
        ){
            update waiverInformation;
            //list<Database.SaveResult> dsr = database.update(waiverInformation,false,AccessLevel.USER_MODE);
            //system.debug(dsr);
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update waiver information'));
        }
    }
    
    public void FetchCaseHistoryInformation(){
        caseHistory = new list<DIA_case_history__c>();
        List<string> caseHistoryFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        caseHistoryFields = ApexUtil.FetchFields('DIA_Case_History__c');      
        String query = 'Select '+string.join(caseHistoryFields, ',') + ' From DIA_Case_History__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new ApexUtil.Criteria('case__c',caseId,'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+ '  ORDER BY CreatedDate Asc'; 
        
        caseHistory = database.query(query);
    }
    public void FetchDocumentInformation(){
        documents = new List<DocumentRecord> ();
        List<string> documentFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        documentFields = ApexUtil.FetchFields('DIA_document__c');      
        String query = 'Select '+string.join(documentFields, ',') + ' From DIA_document__c';
        
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new ApexUtil.Criteria('case__c',caseId,'='));
            //whereCriteria.add(new ApexUtil.Criteria('Uploaded_By_Subject__c ',caseId,'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+' order by createddate desc' ; 
        
        list<DIA_document__c> documentsOfCase = database.query(query);
        List<string> documentIds = new List<string>();
        for(DIA_document__c doc: documentsOfCase){
            documentIds.add(doc.id);
        }
        list<ContentDocumentLink> cdls = new list<ContentDocumentLink>();
        List<attachment> attachments = new List<attachment>();
        if(!documentids.isempty()){
            attachments = [Select id, parentid from attachment where parentid in: documentIds ];
            system.debug('documentids..'+documentids);
            cdls = [select id, contentdocument.title,contentdocumentid,linkedentityid from ContentDocumentLink where linkedentityid in:documentIds];
        }
        Map<String,String> documentNfileMap = new Map<String,String>();
        Map<String,String> documentNattachmentMap = new Map<String,String>();
        for(ContentDocumentLink att: cdls){
            documentNfileMap.put(att.linkedentityid, att.contentdocumentid);    
        }
         for(attachment att: attachments){
            documentNattachmentMap.put(att.parentid, att.id);    
        }
        for(DIA_document__c doc: documentsOfCase){
            if(documentNfileMap.get(doc.id) != Null){
                documents.add(new DocumentRecord(documentNfileMap.get(doc.id),doc,'file'));  
            }
            if(documentNattachmentMap.get(doc.id) != Null){
                documents.add(new DocumentRecord(documentNattachmentMap.get(doc.id),doc,'attachment'));  
            }
        }
    }
    
    /*public void FetchSubjectDocumentInformation(){
        subjectdocuments = new List<DocumentRecord> ();
        List<string> documentFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        documentFields = ApexUtil.FetchFields('DIA_document__c');      
        String query = 'Select '+string.join(documentFields, ',') + ' From DIA_document__c';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new ApexUtil.Criteria('case__c',caseId,'='));
            //whereCriteria.add(new ApexUtil.Criteria('Uploaded_By_Subject__c ',caseId,'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+' AND Uploaded_By_Subject__c = true order by createddate desc' ; 
        
        list<DIA_document__c> documentsOfCase = database.query(query);
        List<string> documentIds = new List<string>();
        for(DIA_document__c doc: documentsOfCase){
            documentIds.add(doc.id);
        }
        list<ContentDocumentLink> cdls = new list<ContentDocumentLink>();
        List<attachment> attachments = new List<attachment>();
        if(!documentids.isempty()){
            attachments = [Select id, parentid from attachment where parentid in: documentIds ];
            system.debug('documentids..'+documentids);
            cdls = [select id, contentdocument.title,contentdocumentid,linkedentityid from ContentDocumentLink where linkedentityid in:documentIds];
        }
        Map<String,String> documentNfileMap = new Map<String,String>();
        Map<String,String> documentNattachmentMap = new Map<String,String>();
        for(ContentDocumentLink att: cdls){
            documentNfileMap.put(att.linkedentityid, att.contentdocumentid);    
        }
         for(attachment att: attachments){
            documentNattachmentMap.put(att.parentid, att.id);    
        }
        for(DIA_document__c doc: documentsOfCase){
            if(documentNfileMap.get(doc.id) != Null){
                subjectdocuments.add(new DocumentRecord(documentNfileMap.get(doc.id),doc,'file'));  
            }
            if(documentNattachmentMap.get(doc.id) != Null){
                subjectdocuments.add(new DocumentRecord(documentNattachmentMap.get(doc.id),doc,'attachment'));  
            }
        }
    }*/
    
    @RemoteAction
    public static boolean CheckIfLeadIsAssigned(string leadId) {
        DIA_Lead__c lead = [select id,assigned_to__c from DIA_Lead__c where id=:leadId ];
        boolean isAssigned = false;
        if(lead.assigned_to__c != null){
            isAssigned = true;
        }    
        return isAssigned;
    }
    public string deleteLeadId{get;set;}
    
    
    public void DeleteLeadAction(){

        List<DIA_Lead__c> deleteLeads = [select id from DIA_Lead__c where id=:deleteLeadId ];
         
        if(Schema.SobjectType.DIA_Lead__c.isDeletable()){
            Database.DeleteResult[] drList = database.delete(deleteLeads,false,AccessLevel.USER_MODE);
            integer i = 0;
            for( Database.DeleteResult dr : drList){
                if(dr.isSuccess()) i++;
            }
            if(i == deleteLeads.size()){
                FetchLeadInformation();
            }
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to delete Lead'));
        }
    }
    
    public class DocumentRecord{
        public string attachmentId{get;set;}   
        public DIA_document__c document{get;set;}
        public string doctype{get;set;}
        public DocumentRecord(string attachmentId, DIA_document__c document,string doctype){
            this.document = document;    
            this.attachmentId = attachmentId;
            this.doctype = doctype;
        }
    
    }
    
    public PageReference qareviewcompleteaction(){
        Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_case__c');
        caseRecord.Current_Task__c='QA Review Completed';
        if(Schema.SobjectType.DIA_case__c.isUpdateable() &&
        fields.get('Current_Task__c').getDescribe().isAccessible()
        ){
            update caseRecord;
            //Database.SaveResult dsr = database.update(caseRecord,false,AccessLevel.USER_MODE);
           // if(dsr.isSuccess()){
                PageReference redirectPage = Page.BIOrderROIReport;
                redirectPage.setRedirect(true);
                redirectPage.getParameters().put('id',caseRecord.id);
                redirectPage.getParameters().put('type','generate');
                return redirectPage;
            //}else{
           //     return null;
            //}
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update Case'));
            return null;
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
        
    }
    
    public void SetPPFContactInfo(){
        if(caseRecord.Subject_Type__c == 'Applicant'){
            caseRecord.PPF_Customer_Contact_Name__c = 'Jeri Selinger';
            caseRecord.PPF_Customer_Contact_Email__c = 'jmselin@nsa.gov';
            caseRecord.PPF_Customer_Contact_Address__c = 'Department of Defense 9800 Savage Road Suite: 6771, A5231 Ft. Meade. MD 20755-6774';
        }
        if(caseRecord.Subject_Type__c == 'Contractor'){
            caseRecord.PPF_Customer_Contact_Name__c = 'Gracee Knight';
            caseRecord.PPF_Customer_Contact_Email__c = 'gnknigh@nsa.gov';
            caseRecord.PPF_Customer_Contact_Address__c = 'Department of Defense\n 9800 Savage Road Suite: 6384, A5232 Ft. Meade.\n MD 20755-6774';
        }    
    }
    
    public PageReference regenerateroireportbuttonaction(){
        list<DIA_document__c> documents = new list<DIA_document__c>();
        documents = [Select Id,Name__c from DIA_document__c WHERE Name__c = 'ROIReport' and case__c=:caseRecord.id ];
        if(!documents.isEmpty()){
            if(Schema.SobjectType.DIA_document__c.isDeletable()){
                Database.DeleteResult[] drList = database.delete(documents,false,AccessLevel.USER_MODE);
                integer i = 0;
                for( Database.DeleteResult dr : drList){
                    if(dr.isSuccess()) i++;
                }
                if(i == documents.size()){
                    PageReference redirectPage = Page.BIOrderROIReport;
                    redirectPage.setRedirect(true);
                    redirectPage.getParameters().put('id',caseRecord.id);
                    redirectPage.getParameters().put('type','generate');
                    return redirectPage;
                }else{
                    return null;
                }
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to Regenerate ROIReport'));
                return null;
            }
            
        }else{
            return null;
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
        
    }
    
    public string leadIdToUpdate {get;set;}
    public decimal itemnumbertoupdate {get;set;}
    public void UpdateLead(){
        errorMessage = Null;
        System.debug('itemnumbertoupdate...'+itemnumbertoupdate);
        System.debug('leadIdToUpdate...'+leadIdToUpdate);
        DIA_Lead__c leadToUpdate;
        for(DIA_Lead__c l: leads){
            if(l.id == leadIdToUpdate){
                leadToUpdate = l;
            }
        }    
        if(leadToUpdate != Null){
            try{
                Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_Lead__c');
                leadToupdate.item_number__c = itemnumbertoupdate;
                if(Schema.SobjectType.DIA_Lead__c.isUpdateable() &&
                    fields.get('item_number__c').getDescribe().isAccessible()
                ){
                    Database.SaveResult dsr = database.update(leadToUpdate,false,AccessLevel.USER_MODE);
                    if(dsr.isSuccess()){
                        FetchLeadInformation();
                    }
                }else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update Lead'));
                }
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
            List<DIA_document__c> deleteDocs = [Select id from DIA_document__c where id=:deleteDocumentID ];
            if(Schema.SobjectType.DIA_document__c.isDeletable()){
                Database.DeleteResult[] drList = database.delete(deleteDocs,false,AccessLevel.USER_MODE);
                integer i = 0;
                for( Database.DeleteResult dr : drList){
                    if(dr.isSuccess()) i++;
                }
                if(i == deleteDocs.size()){
                    FetchDocumentInformation();
                }
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to delete Document'));
            }
        }
    }
    public void AutoSaveCaseAction(){
        
        if(Schema.SobjectType.DIA_Case__c.isUpdateable()){
            database.update(caseRecord,false,AccessLevel.USER_MODE);
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update Case'));
        }
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
    
    /*public string subjectMessageQueryForNextRecords {get;set;}
    public string subjectMessageLastRecordName {get;set;}
    public string subjectMessageFirstRecordName {get;set;}
    public integer subjectMessageCurrentRecordCount {get;set;}
    public integer subjectMessagepageNumber {get;set;}
    public integer subjectMessageTotalPages   {get;set;}
    public integer subjectMessagetotalRecordCount {get;set;}
    List<Object> subjectMessagerecords;
    public boolean subjectMessagedisablePrev {get;set;}
    public boolean subjectMessagedisableNext {get;set;}
    
    public void SubjectMessagehandlePrev(){
        subjectMessages = new list<Subject_Message__c>();
        SubjectMessagePageNumber --;
        string query = subjectMessageQueryForNextRecords + ' AND Name <:subjectMessagefirstRecordName  Order by Name desc Limit 200';      
        list<Subject_Message__c> msgs = database.query(query);
        integer i = 0;
        for(Integer j=msgs.size()-1;j>=0; j--){
            System.debug('msgs size..'+msgs.size());
            System.debug('j..'+j);
            subjectMessages.add(msgs[j]); 
            if(j==msgs.size()-1){
                subjectMessageFirstRecordName = msgs[j].Name;    
            }
            subjectMessagelastRecordName = msgs[j].Name; 
            
        }
        if(msgs.size()<=200){
            subjectMessagecurrentRecordCount =  subjectMessagecurrentRecordCount - subjectmessages.size();        
        }else{
            subjectMessagecurrentRecordCount =  subjectMessagecurrentRecordCount - 200;    
        }
        if(subjectMessagepageNumber == 1){
            subjectMessagedisablePrev = true;
            subjectMessagedisableNext = false ;
        }else{
            subjectMessagedisablePrev = false;
            subjectMessagedisableNext = false;
        }
    } 
    public void subjectMessagehandleNext(){
        subjectMessages = new list<Subject_Message__c>();
        subjectMessagePageNumber ++ ;
        System.debug('subjectMessagequeryForNextRecords...'+subjectMessagequeryForNextRecords);
        system.debug('subjectMessagelastRecordName....'+subjectMessagelastRecordName);
        string query = subjectMessagequeryForNextRecords + ' AND Name >:subjectMessagelastRecordName  Order by Name asc Limit 200';    
        System.debug('query...'+query);
        list<Subject_Message__c> msgs = database.query(query);
        integer i = 0;
        for(Subject_Message__c msg: msgs){
            subjectmessages.add(msg); 
            if(i==0){
                subjectMessagefirstRecordName = msg.Name;    
            }
            subjectMessagelastRecordName = msg.Name;
            i++;
        }
        if(subjectMessages.size()<=200){
            subjectMessagecurrentRecordCount =  subjectMessagecurrentRecordCount + subjectmessages.size();        
        }else{
            subjectMessagecurrentRecordCount =  subjectMessagecurrentRecordCount + 200;    
        }
        
        if(subjectMessagepageNumber == subjectMessageTotalPages){
            subjectMessagedisablePrev = false;   
            subjectMessagedisableNext = true;
        }else{
            subjectMessagedisablePrev = false;
            subjectMessagedisableNext = false;
        }
         system.debug('subjectMessagefirstRecordName....'+subjectMessagefirstRecordName);
        system.debug('subjectMessagelastRecordName....'+subjectMessagelastRecordName);
         system.debug('subjectMessagecurrentRecordCount....'+subjectMessagecurrentRecordCount);
    }*/
}