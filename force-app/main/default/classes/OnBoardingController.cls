public class OnBoardingController {
    public class BulkEditFieldConfig {
        public String apiName {get;set;}
        public String label {get;set;}
        public String inputType {get;set;}
        public Boolean isPicklist {get;set;}
        public Boolean isBoolean {get;set;}
        public Boolean isTextArea {get;set;}
        public Boolean showInputField {get;set;}
        public List<SelectOption> picklistOptions {get;set;}

        public BulkEditFieldConfig() {
            picklistOptions = new List<SelectOption>();
            inputType = 'text';
            isPicklist = false;
            isBoolean = false;
            isTextArea = false;
            showInputField = true;
        }
    }

    public user currentUser{get;set;}
    public list<onboarding__c> onboardingUsers{get;set;}
    public onboarding__c newUser {get;set;}
    public String bulkUpdatePayload {get;set;}
    public List<BulkEditFieldConfig> bulkEditFields {get;set;}
    public string UserSystemAccess {get;set;}
    private String auth;
    public string UserSystemAccess1 {get;set;}
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
    public boolean duplicateUsername {get;set;}
    public OnBoardingController(){
        duplicateUsername = false;
        currentUser = [select id, firstname, profile.Name, lastname, email, User_Type__c from User where id = :userinfo.getUserId()];  
        newUser = new onboarding__c();
        editOnboardingUser = new onboarding__c();
        bulkEditFields = buildBulkEditFields();
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

    public Boolean getCanManageOnboarding() {
        return currentUser != null &&
            (currentUser.Profile.Name == 'System Administrator' || currentUser.User_Type__c == 'PMO');
    }
    
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('Intel','Intel')); 
        options.add(new SelectOption('DIA','BI'));
		options.add(new SelectOption('Intel;DIA','Both')); 
        return options; 
    }
    public void CreateNewUser(){
        System.debug('inside createnewuser...!!'+newUSer);
        System.debug('User System Access...!!'+UserSystemAccess);
        newUser.System_Access__c = UserSystemAccess;
        list<string> usernames = getAllUsernames();
        if(usernames.contains(newUser.email__c)){
            duplicateUsername = true;
        }else{
            duplicateUsername = false;
            insert newUser;   
            fetchOnboardingUsers();
            newUser = new onboarding__c();
        }
    }
    
    public string deleteOnboardingUserId{get;set;}
    public void DeleteOnboardingUser(){
        if(!getCanManageOnboarding()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You do not have permission to deactivate onboarding users.'));
            return;
        }
        System.debug('deleteOnboardingUserId...'+deleteOnboardingUserId);
        onboarding__c deleteuser = new onboarding__c();
        for(onboarding__c onboardinguser: onboardingUsers){
            if(deleteOnboardingUserId == onboardinguser.id){
                deleteuser = onboardinguser;   
            }    
        }
        if(deleteuser.Id == null){
            return;
        }
        deleteuser.Status__c = 'Inactive';
        update deleteuser;   
        fetchOnboardingUsers();
    }
    
    public string editOnboardingUserId{get;set;}
    public onboarding__c editOnboardingUser{Get;set;}
    public void editOnboardingUser(){
        for(onboarding__c onboardinguser: onboardingUsers){
            if(editOnboardingUserId == onboardinguser.id){
                editOnboardingUser = onboardinguser;   
                UserSystemAccess1 =  editOnboardingUser.System_Access__c;
            }    
        }
    }
    
    public void SaveModifiedOnboardingUser(){
        editOnboardingUser.System_Access__c = UserSystemAccess1;
        list<string> usernames = getAllUsernames();
        if(usernames.contains(editOnboardingUser.email__c)){
            duplicateUsername = true;
        }else{
            duplicateUsername = false;
            update editOnboardingUser;
            fetchOnboardingUsers();
        }
        
    }

    public void SaveMainScreenUpdates(){
        if(!getCanManageOnboarding()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You do not have permission to update onboarding users from the dashboard.'));
            return;
        }
		system.debug('bulkUpdatePayload...'+bulkUpdatePayload);
        List<Onboarding__c> onboardingUsersToUpdate = new List<Onboarding__c>();
        Map<String, Schema.SObjectField> onboardingFieldsMap = Schema.SObjectType.Onboarding__c.fields.getMap();
        if(String.isNotBlank(bulkUpdatePayload)){
            List<Object> updateRows = (List<Object>)JSON.deserializeUntyped(bulkUpdatePayload);
            for(Object updateRow : updateRows){
                Map<String, Object> updateRowMap = (Map<String, Object>)updateRow;
                if(updateRowMap == null || !updateRowMap.containsKey('Id')){
                    continue;
                }

                Onboarding__c onboardingUserToUpdate = new Onboarding__c(
                    Id = Id.valueOf((String)updateRowMap.get('Id'))
                );

                for(String fieldApiName : updateRowMap.keySet()){
                    if(fieldApiName == 'Id' || !onboardingFieldsMap.containsKey(fieldApiName)){
                        continue;
                    }

                    Object convertedValue = convertBulkEditValue(updateRowMap.get(fieldApiName), onboardingFieldsMap.get(fieldApiName).getDescribe());
                    onboardingUserToUpdate.put(fieldApiName, convertedValue);
                }

                onboardingUsersToUpdate.add(onboardingUserToUpdate);
            }
        }

        if(!onboardingUsersToUpdate.isEmpty()){
            update onboardingUsersToUpdate;
        }
        bulkUpdatePayload = null;
        fetchOnboardingUsers();
    }
    
    public void fetchOnboardingUsers(){
        onboardingUsers = new list<onboarding__c>();
        List<string> onBoardingFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        onBoardingFields = ApexUtil.FetchFields('onboarding__c');
        String query = 'Select '+string.join(onBoardingFields, ',') + ' From onboarding__c ';
        if(currentUser.profile.Name != 'System Administrator'){
            whereCriteria.add(new ApexUtil.Criteria('System_Access__c','Intel','='));
		}
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria); 
        if(String.isNotBlank(where_cond)){
            query = query + ' WHERE '+where_cond;     
        }
        query = query +' ORDER BY Last_Name__c,Createddate desc';
        
        onboardingUsers = database.query(query);
    }

    private List<BulkEditFieldConfig> buildBulkEditFields(){
        List<BulkEditFieldConfig> configuredFields = new List<BulkEditFieldConfig>();
        Map<String, Schema.SObjectField> onboardingFieldsMap = Schema.SObjectType.Onboarding__c.fields.getMap();
        String configuredBulkEditFields = System.Label.onboarding_bulk_edit_fields;
        if(String.isBlank(configuredBulkEditFields)){
            return configuredFields;
        }

        for(String rawFieldApiName : configuredBulkEditFields.split(',')){
            String fieldApiName = rawFieldApiName != null ? rawFieldApiName.trim() : null;
            if(String.isBlank(fieldApiName) || !onboardingFieldsMap.containsKey(fieldApiName)){
                continue;
            }

            Schema.DescribeFieldResult fieldDescribe = onboardingFieldsMap.get(fieldApiName).getDescribe();
            BulkEditFieldConfig fieldConfig = new BulkEditFieldConfig();
            fieldConfig.apiName = fieldApiName;
            fieldConfig.label = fieldDescribe.getLabel();

            Schema.DisplayType displayType = fieldDescribe.getType();
            if(displayType == Schema.DisplayType.Picklist){
                fieldConfig.isPicklist = true;
                fieldConfig.showInputField = false;
                for(Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()){
                    fieldConfig.picklistOptions.add(new SelectOption(entry.getValue(), entry.getLabel()));
                }
            } else if(displayType == Schema.DisplayType.Boolean){
                fieldConfig.isBoolean = true;
                fieldConfig.showInputField = false;
                fieldConfig.picklistOptions.add(new SelectOption('true', 'True'));
                fieldConfig.picklistOptions.add(new SelectOption('false', 'False'));
            } else if(displayType == Schema.DisplayType.Date){
                fieldConfig.inputType = 'date';
            } else if(displayType == Schema.DisplayType.Integer ||
                displayType == Schema.DisplayType.Double ||
                displayType == Schema.DisplayType.Currency ||
                displayType == Schema.DisplayType.Percent){
                fieldConfig.inputType = 'number';
            } else if(displayType == Schema.DisplayType.TextArea){
                fieldConfig.isTextArea = true;
                fieldConfig.showInputField = false;
            }

            configuredFields.add(fieldConfig);
        }
        return configuredFields;
    }

    private Object convertBulkEditValue(Object rawValue, Schema.DescribeFieldResult fieldDescribe){
        if(rawValue == null){
            return null;
        }

        String stringValue = String.valueOf(rawValue).trim();
        if(stringValue == ''){
            return null;
        }

        Schema.DisplayType displayType = fieldDescribe.getType();
        if(displayType == Schema.DisplayType.Boolean){
            return stringValue.toLowerCase() == 'true';
        }
        if(displayType == Schema.DisplayType.Date){
            return Date.valueOf(stringValue);
        }
        if(displayType == Schema.DisplayType.DateTime){
            return DateTime.valueOf(stringValue);
        }
        if(displayType == Schema.DisplayType.Integer){
            return Integer.valueOf(stringValue);
        }
        if(displayType == Schema.DisplayType.Double ||
            displayType == Schema.DisplayType.Currency ||
            displayType == Schema.DisplayType.Percent){
            return Decimal.valueOf(stringValue);
        }

        return stringValue;
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
    public static list<string> getAllUsernames(){
        list<string> usernames = new list<string>();
        list<user> users = [select id,username__c from user];	
        for(user u : users){
            usernames.add(u.username__c);
        }
        return usernames;
    }	 
}