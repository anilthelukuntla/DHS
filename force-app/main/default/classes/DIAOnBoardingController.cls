public with sharing class DIAOnBoardingController {
    public user currentUser{get;set;}
    public list<onboarding__c> onboardingUsers{get;set;}
    public onboarding__c newUser {get;set;}
    public string UserSystemAccess {get;set;}
    public string UserSystemAccess1 {get;set;}
    private String auth;
    public string tokenURL {get; set;}
    private String accountId = System.Label.DocusignAccountId;
    private String userId = System.Label.DocusignUserId;
    private String password = System.Label.DocusignPassword;
    private String integratorsKey = System.Label.DocusignIntegratorsKey;
    private String webServiceUrl = System.Label.DocusignWebServiceUrl;
    private String devHost = System.Label.DocusignHostURL;
    private String DocusignEmailSubject {get;set;}
    private String DocusignEmailMessage {get;set;}
    private boolean DocusignReminderEnabled {get;set;}
    private Integer DocusignReminderDelay {get;set;}
    private Integer DocusignReminderFrequency {get;set;}
    private boolean DocusignExpireEnabled {get;set;}
    private Integer DocusignExpireAfter {get;set;}
    private Integer DocusignExpireWarn {get;set;}
    private String DocusignTemplateID {get;set;}
    public String envelopeId {get;set;}
    
    public DIAOnBoardingController(){
        currentUser = [select id, firstname, lastname, email,profile.name from USer where id=:userinfo.getuserid()];  
        newUser = new onboarding__c();
        editOnboardingUser = new onboarding__c();
        fetchOnboardingUsers();
        
        String IntelOnboardingDocusignTemplateName = System.Label.IntelOnboardingDocusignTemplateName;
        Intel_Docusign_Templates__c docusignTemplateSettings = Intel_Docusign_Templates__c.getValues(IntelOnboardingDocusignTemplateName);
        System.debug('docusignTemplateSettings....'+docusignTemplateSettings);
        if(docusignTemplateSettings != Null){
            DocusignEmailSubject =  docusignTemplateSettings.DocusignEmailSubject__c;
            DocusignEmailMessage = docusignTemplateSettings.DocusignEmailMessage__c;
            DocusignReminderEnabled = Boolean.valueof(docusignTemplateSettings.DocusignEmailSubject__c);
            DocusignReminderDelay = Integer.valueof(docusignTemplateSettings.DocusignReminderDelay__c);
            DocusignReminderFrequency = Integer.valueof(docusignTemplateSettings.DocusignReminderFrequency__c);
            DocusignExpireEnabled = Boolean.valueof(docusignTemplateSettings.DocusignExpireEnabled__c);
            DocusignExpireAfter = Integer.valueof(docusignTemplateSettings.DocusignExpireAfter__c);
            DocusignExpireWarn = Integer.valueof(docusignTemplateSettings.DocusignExpireWarn__c);
            DocusignTemplateID = docusignTemplateSettings.Template_ID__c;
        }
    }
    
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('DIA','BI')); 
        if(currentUser.profile.Name == 'System Administrator'){
            options.add(new SelectOption('Intel','Intel'));
            options.add(new SelectOption('Intel;DIA','Both')); 
		}
        return options; 
    }
    
    public void CreateNewUser(){
        System.debug('inside createnewuser...!!'+newUSer);
        System.debug('User System Access...!!'+UserSystemAccess);
        system.debug(UserSystemAccess);
        newUser.System_Access__c = UserSystemAccess;
        Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('onboarding__c');

        if(Schema.SobjectType.onboarding__c.iscreateable() && 
            fields.get('System_Access__c').getDescribe().isAccessible()){

            Database.SaveResult dsr = database.insert(newUser, false, AccessLevel.USER_MODE);
            if(dsr.isSuccess()){
                fetchOnboardingUsers();
                newUser = new onboarding__c();
            }
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to create Onboarding User'));
        }
    }
    
    public string deleteOnboardingUserId{get;set;}
    public void DeleteOnboardingUser(){
        System.debug('deleteOnboardingUserId...'+deleteOnboardingUserId);
        onboarding__c deleteuser = new onboarding__c();
        for(onboarding__c onboardinguser: onboardingUsers){
            if(deleteOnboardingUserId == onboardinguser.id){
                deleteuser = onboardinguser;   
            }    
        }
        if(Schema.SobjectType.onboarding__c.isDeletable()){
            delete deleteuser;
            /*Database.DeleteResult drList = database.delete(deleteuser,false,AccessLevel.USER_MODE);
            if(drList.isSuccess()){
                fetchOnboardingUsers();
            }*/
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to delete Onboarding User'));
        }
    }
    
    public string editOnboardingUserId{get;set;}
    public onboarding__c editOnboardingUser{Get;set;}
    public void editOnboardingUser(){
        system.debug('Came Here');
        for(onboarding__c onboardinguser: onboardingUsers){
            if(editOnboardingUserId == onboardinguser.id){
                editOnboardingUser = onboardinguser;  
                UserSystemAccess1 =  editOnboardingUser.System_Access__c;
            }    
        }
    }
    
    public void SaveModifiedOnboardingUser(){
        if(Schema.SobjectType.onboarding__c.isUpdateable()){
            system.debug('UserSystemAccess1....'+UserSystemAccess1);
            editOnboardingUser.System_Access__c = UserSystemAccess1;
            update editOnboardingUser;
            /*Database.SaveResult dsr = database.update(editOnboardingUser, false, AccessLevel.USER_MODE);
            if(dsr.isSuccess()){
                fetchOnboardingUsers();
            }else{
                
            }*/
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update Onboarding User'));
        }
    }
    
    public void fetchOnboardingUsers(){
        onboardingUsers = new list<onboarding__c>();
        List<string> onBoardingFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        onBoardingFields = ApexUtil.FetchFields('onboarding__c');
        //onBoardingFields.remove(onBoardingFields.indexOf('docusign_status__c'));
       
        String query = 'Select '+string.join(onBoardingFields, ',') + ' From onboarding__c ';
        if(currentUser.profile.Name != 'System Administrator'){
            whereCriteria.add(new ApexUtil.Criteria('System_Access__c','DIA','='));
		}
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria); 
        if(String.isNotBlank(where_cond)){
            query = query + ' WHERE '+where_cond;     
        }
        query = query +' ORDER BY Last_Name__c,Createddate desc ';
        
        onboardingUsers = database.query(query);
        system.debug(onboardingUsers);
    }
    
    public void SendToDocusign(){
        DocuSignAPI.APIServiceSoap dsApiSend = new DocuSignAPI.APIServiceSoap();
        dsApiSend.endpoint_x = webServiceUrl;
        String auth = '<DocuSignCredentials><Username>'+ userId+'</Username><Password>'+ password+'</Password><IntegratorKey>'+ integratorsKey+ '</IntegratorKey></DocuSignCredentials>';
        System.debug('Setting authentication to: ' + auth);
        dsApiSend.inputHttpHeaders_x = new Map<String, String>();
        dsApiSend.inputHttpHeaders_x.put('X-DocuSign-Authentication', auth);
        DocuSignAPI.EnvelopeInformation envelope = new DocuSignAPI.EnvelopeInformation();
        envelope.Subject = DocusignEmailSubject;
        envelope.EmailBlurb = DocusignEmailMessage;
        envelope.AccountId  = accountId; 
        
        DocuSignAPI.Notification Notification = new DocuSignAPI.Notification();
        Notification.UseAccountDefaults = false;
        
        DocuSignAPI.Reminders Reminders = new DocuSignAPI.Reminders();
        Reminders.ReminderEnabled = DocusignReminderEnabled;
        Reminders.ReminderDelay = DocusignReminderDelay;
        Reminders.ReminderFrequency = DocusignReminderFrequency;
        
        DocuSignAPI.Expirations Expirations = new DocuSignAPI.Expirations();
        Expirations.ExpireEnabled = DocusignExpireEnabled;
        Expirations.ExpireAfter = DocusignExpireAfter;
        Expirations.ExpireWarn = DocusignExpireWarn;
        
        Notification.Reminders = Reminders;
        Notification.Expirations = Expirations;
        
        envelope.Notification = Notification;
        
        DocuSignAPI.Recipient recipient = new DocuSignAPI.Recipient();
        recipient.ID = 1;
        recipient.Type_x = 'Signer';
        recipient.RoutingOrder = 1;
        recipient.Email = editOnboardingUser.Email__c;
        recipient.RoleName = 'Signer 1';
        recipient.UserName = editOnboardingUser.First_Name__c + ' ' + editOnboardingUser.Last_Name__c;
        recipient.RequireIDLookup = false;
        
        DocuSignAPI.Recipient recipient2 = new DocuSignAPI.Recipient();
        recipient2.ID = 2;
        recipient2.Type_x = 'Signer';
        recipient2.RoutingOrder = 2;
        recipient2.Email = 'ukunvar@isncorp.com';
        recipient2.RoleName = 'Signer 2';
        recipient2.UserName = 'contracts';
        recipient2.RequireIDLookup = false;
        
        DocuSignAPI.ArrayOfRecipient1 recipients = new DocuSignAPI.ArrayOfRecipient1();
        recipients.Recipient = new List<DocuSignAPI.Recipient>(); 
        recipients.Recipient.add(recipient);
        recipients.Recipient.add(recipient2); 
        
        DocuSignAPI.ArrayOfTemplateReference templateReferences = new DocuSignAPI.ArrayOfTemplateReference();
        templateReferences.TemplateReference = new List<DocuSignAPI.TemplateReference>();  
        templateReferences.TemplateReference.add(addTemplate(DocusignTemplateID,recipient,recipient2)); 
        
        DocuSignAPI.CustomField field = new DocuSignAPI.CustomField();
        field.Name = 'DSFSSourceObjectId';
        field.Show = 'false';
        field.Value = editOnboardingUser.Id;
        
        envelope.CustomFields = new DocuSignAPI.ArrayOfCustomField();
        envelope.CustomFields.CustomField = new DocuSignAPI.CustomField[22];
        envelope.CustomFields.CustomField[0] = field;
        
        System.debug('Calling the API');
        try {
            System.debug('Signers=:' + recipients);
            if(!test.isRunningTest()){
                DocuSignAPI.EnvelopeStatus es = dsApiSend.CreateEnvelopeFromTemplates(templateReferences, recipients, envelope, true);
                envelopeId = es.EnvelopeID;
            }
        } catch ( CalloutException e) {
            System.debug('Exception - ' + e );
            envelopeId = 'Exception - ' + e;
        }
    }
    
    public DocuSignAPI.TemplateReference addTemplate(string templateId, DocuSignAPI.Recipient recipient,DocuSignAPI.Recipient recipient2 ){
        DocuSignAPI.TemplateReference myTemplateReference = new DocuSignAPI.TemplateReference();
        myTemplateReference.Template = templateId;
        myTemplateReference.TemplateLocation = 'Server';
        
        myTemplateReference.RoleAssignments = new DocuSignAPI.ArrayOfTemplateReferenceRoleAssignment();
        myTemplateReference.RoleAssignments.RoleAssignment = new DocuSignAPI.TemplateReferenceRoleAssignment[2];
        
        if(recipient != Null){
            DocuSignAPI.TemplateReferenceRoleAssignment roleAssignment = new DocuSignAPI.TemplateReferenceRoleAssignment();
            roleAssignment.RoleName = recipient.RoleName;
            roleAssignment.RecipientID = recipient.ID;
            myTemplateReference.RoleAssignments.RoleAssignment[0] = roleAssignment;
        }
        
            
            if(recipient2 != Null){
                DocuSignAPI.TemplateReferenceRoleAssignment roleAssignment1 = new DocuSignAPI.TemplateReferenceRoleAssignment();
                roleAssignment1.RoleName = recipient2.RoleName;
                roleAssignment1.RecipientID = recipient2.ID;
                myTemplateReference.RoleAssignments.RoleAssignment[1] = roleAssignment1;
            }        
            
            myTemplateReference.FieldData = new DocuSignAPI.TemplateReferenceFieldData();
            myTemplateReference.FieldData.DataValues = new DocuSignAPI.ArrayOfTemplateReferenceFieldDataDataValue();
            myTemplateReference.FieldData.DataValues.DataValue = new DocuSignAPI.TemplateReferenceFieldDataDataValue[31];
            
           return myTemplateReference;
           
    }
        
}