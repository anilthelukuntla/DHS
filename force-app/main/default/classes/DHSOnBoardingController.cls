/**
 * @description Controls DHS onboarding records, bulk edits, and DocuSign submission.
 */
@SuppressWarnings('PMD.AvoidNonRestrictiveQueries,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.ExcessivePublicCount,PMD.FieldDeclarationsShouldBeAtStart,PMD.NcssCount,PMD.StdCyclomaticComplexity')
public without sharing class DHSOnBoardingController {
    /** @description Provides this DHS API member. */
    public class BulkEditFieldConfig {
        /** @description Provides this DHS API member. */
        public String apiName {get;set;}
        /** @description Provides this DHS API member. */
        public String label {get;set;}
        /** @description Provides this DHS API member. */
        public String inputType {get;set;}
        /** @description Provides this DHS API member. */
        public Boolean isPicklist { get; private set; }
        /** @description Provides this DHS API member. */
        public Boolean isBoolean { get; private set; }
        /** @description Provides this DHS API member. */
        public Boolean isTextArea { get; private set; }
        /** @description Provides this DHS API member. */
        public Boolean showInputField { get; private set; }
        /** @description Provides this DHS API member. */
        public List<SelectOption> picklistOptions {get;set;}

        /** @description Provides this DHS API member. */
        public BulkEditFieldConfig() {
            picklistOptions = new List<SelectOption>();
            inputType = 'text';
            isPicklist = false;
            isBoolean = false;
            isTextArea = false;
            showInputField = true;
        }

        /** @description Provides this DHS API member. */
        public void markPicklist() {
            isPicklist = true;
        }

        /** @description Provides this DHS API member. */
        public void markBoolean() {
            isBoolean = true;
        }

        /** @description Provides this DHS API member. */
        public void markTextArea() {
            isTextArea = true;
        }

        /** @description Provides this DHS API member. */
        public void hideInputField() {
            showInputField = false;
        }
    }

    /** @description Provides this DHS API member. */
    public user currentUser{get;set;}
    /** @description Provides this DHS API member. */
    public list<onboarding__c> onboardingUsers{get;set;}
    /** @description Provides this DHS API member. */
    public onboarding__c newUser {get;set;}
    /** @description Provides this DHS API member. */
    public String bulkUpdatePayload {get;set;}
    /** @description Provides this DHS API member. */
    public List<BulkEditFieldConfig> bulkEditFields {get;set;}
    /** @description Provides this DHS API member. */
    public string userSystemAccess {get;set;}
    private String auth;
    /** @description Provides this DHS API member. */
    public string userSystemAccess1 {get;set;}
    /** @description Provides this DHS API member. */
    public string tokenURL {get; set;}
    private String accountId = System.Label.DocusignAccountId;
    private String userId = System.Label.DocusignUserId;
    private String password = System.Label.DocusignPassword;
    private String integratorsKey = System.Label.DocusignIntegratorsKey;
    private String webServiceUrl = System.Label.DocusignWebServiceUrl;
    private String devHost = System.Label.DocusignHostURL;
    private String docusignEmailSubject {get;set;}
    private String docusignEmailMessage {get;set;}
    private boolean docusignReminderEnabled {get;set;}
    private Integer docusignReminderDelay {get;set;}
    private Integer docusignReminderFrequency {get;set;}
    private boolean docusignExpireEnabled {get;set;}
    private Integer docusignExpireAfter {get;set;}
    private Integer docusignExpireWarn {get;set;}
    private String docusignTemplateID {get;set;}
    /** @description Provides this DHS API member. */
    public String envelopeId {get;set;}
    /** @description Provides this DHS API member. */
    public boolean duplicateUsername { get; private set; }
    /** @description Provides this DHS API member. */
    public DHSOnBoardingController(){
        duplicateUsername = false;
        currentUser = [select id, firstname, profile.Name, lastname, email, User_Type__c from User where id = :userinfo.getUserId() WITH USER_MODE ];  
        newUser = new onboarding__c();
        editOnboardingUser = new onboarding__c();
        bulkEditFields = buildBulkEditFields();
        fetchOnboardingUsers();
        
        String intelOnboardingDocusignTemplateName = System.Label.intelOnboardingDocusignTemplateName;
        Intel_Docusign_Templates__c docusignTemplateSettings = Intel_Docusign_Templates__c.getValues(intelOnboardingDocusignTemplateName);
        if(docusignTemplateSettings != Null){
            docusignEmailSubject =  docusignTemplateSettings.DocusignEmailSubject__c;
            docusignEmailMessage = docusignTemplateSettings.DocusignEmailMessage__c;
            docusignReminderEnabled = Boolean.valueof(docusignTemplateSettings.DocusignEmailSubject__c);
            docusignReminderDelay = Integer.valueof(docusignTemplateSettings.DocusignReminderDelay__c);
            docusignReminderFrequency = Integer.valueof(docusignTemplateSettings.DocusignReminderFrequency__c);
            docusignExpireEnabled = Boolean.valueof(docusignTemplateSettings.DocusignExpireEnabled__c);
            docusignExpireAfter = Integer.valueof(docusignTemplateSettings.DocusignExpireAfter__c);
            docusignExpireWarn = Integer.valueof(docusignTemplateSettings.DocusignExpireWarn__c);
            docusignTemplateID = docusignTemplateSettings.Template_ID__c;
        }
    }

    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public Boolean getCanManageOnboarding() {
        return currentUser != null &&
            (currentUser.Profile.Name == 'System Administrator' || currentUser.User_Type__c == 'PMO');
    }
    
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('Intel','Intel')); 
        options.add(new SelectOption('DHS','DHS'));
		options.add(new SelectOption('Intel;DHS','Both')); 
        return options; 
    }
    /** @description Provides this DHS API member. */
    public void createNewUser(){
        newUser.System_Access__c = userSystemAccess;
        list<string> usernames = getAllUsernames();
        if(usernames.contains(newUser.email__c)){
            duplicateUsername = true;
        }else{
            duplicateUsername = false;
            Database.insert(newUser, AccessLevel.USER_MODE);   
            fetchOnboardingUsers();
            newUser = new onboarding__c();
        }
    }
    
    /** @description Provides this DHS API member. */
    public string deleteOnboardingUserId{get;set;}
    /** @description Provides this DHS API member. */
    public void deleteOnboardingUser(){
        if(!getCanManageOnboarding()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You do not have permission to deactivate onboarding users.'));
            return;
        }
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
        Database.update(deleteuser, AccessLevel.USER_MODE);   
        fetchOnboardingUsers();
    }
    
    /** @description Provides this DHS API member. */
    public string editOnboardingUserId{get;set;}
    /** @description Provides this DHS API member. */
    public onboarding__c editOnboardingUser{Get;set;}
    /** @description Provides this DHS API member. */
    public void editOnboardingUser(){
        for(onboarding__c onboardinguser: onboardingUsers){
            if(editOnboardingUserId == onboardinguser.id){
                editOnboardingUser = onboardinguser;   
                userSystemAccess1 =  editOnboardingUser.System_Access__c;
            }    
        }
    }
    
    /** @description Provides this DHS API member. */
    public void saveModifiedOnboardingUser(){
        editOnboardingUser.System_Access__c = userSystemAccess1;
        list<string> usernames = getAllUsernames();
        if(usernames.contains(editOnboardingUser.email__c)){
            duplicateUsername = true;
        }else{
            duplicateUsername = false;
            Database.update(editOnboardingUser, AccessLevel.USER_MODE);
            fetchOnboardingUsers();
        }
        
    }

    /** @description Provides this DHS API member. */
    public void saveMainScreenUpdates(){
        if(!getCanManageOnboarding()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You do not have permission to update onboarding users from the dashboard.'));
            return;
        }
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
            Database.update(onboardingUsersToUpdate, AccessLevel.USER_MODE);
        }
        bulkUpdatePayload = null;
        fetchOnboardingUsers();
    }
    
    /** @description Provides this DHS API member. */
    public void fetchOnboardingUsers(){
        onboardingUsers = new list<onboarding__c>();
        List<string> onBoardingFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        onBoardingFields = ApexUtil.FetchFields('onboarding__c');
        String query = 'Select '+string.join(onBoardingFields, ',') + ' From onboarding__c ';
        if(currentUser.profile.Name != 'System Administrator'){
            whereCriteria.add(new ApexUtil.Criteria('System_Access__c','DHS','='));
		}
        String whereCond = ApexUtil.generateWhereQuery(whereCriteria); 
        if(String.isNotBlank(whereCond)){
            query = query + ' WHERE '+whereCond;     
        }
        query = query +' ORDER BY Last_Name__c,Createddate desc';
        
        onboardingUsers = database.query(String.escapeSingleQuotes(query), AccessLevel.USER_MODE);
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
                fieldConfig.markPicklist();
                fieldConfig.hideInputField();
                for(Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()){
                    fieldConfig.picklistOptions.add(new SelectOption(entry.getValue(), entry.getLabel()));
                }
            } else if(displayType == Schema.DisplayType.Boolean){
                fieldConfig.markBoolean();
                fieldConfig.hideInputField();
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
                fieldConfig.markTextArea();
                fieldConfig.hideInputField();
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
    
    /** @description Provides this DHS API member. */
    public void sendToDocusign(){
        DocuSignAPI.APIServiceSoap dsApiSend = new DocuSignAPI.APIServiceSoap();
        dsApiSend.endpoint_x = webServiceUrl;
        String auth = '<DocuSignCredentials><Username>'+ userId+'</Username><Password>'+ password+'</Password><IntegratorKey>'+ integratorsKey+ '</IntegratorKey></DocuSignCredentials>';
        dsApiSend.inputHttpHeaders_x = new Map<String, String>();
        dsApiSend.inputHttpHeaders_x.put('X-DocuSign-Authentication', auth);
        DocuSignAPI.EnvelopeInformation envelope = new DocuSignAPI.EnvelopeInformation();
        envelope.Subject = docusignEmailSubject;
        envelope.EmailBlurb = docusignEmailMessage;
        envelope.AccountId  = accountId; 
        
        DocuSignAPI.notification notification = new DocuSignAPI.notification();
        notification.UseAccountDefaults = false;
        
        DocuSignAPI.reminders reminders = new DocuSignAPI.reminders();
        reminders.ReminderEnabled = docusignReminderEnabled;
        reminders.ReminderDelay = docusignReminderDelay;
        reminders.ReminderFrequency = docusignReminderFrequency;
        
        DocuSignAPI.expirations expirations = new DocuSignAPI.expirations();
        expirations.ExpireEnabled = docusignExpireEnabled;
        expirations.ExpireAfter = docusignExpireAfter;
        expirations.ExpireWarn = docusignExpireWarn;
        
        notification.reminders = reminders;
        notification.expirations = expirations;
        
        envelope.notification = notification;
        
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
        templateReferences.TemplateReference.add(addTemplate(docusignTemplateID,recipient,recipient2)); 
        
        DocuSignAPI.CustomField field = new DocuSignAPI.CustomField();
        field.Name = 'DSFSSourceObjectId';
        field.Show = 'false';
        field.Value = editOnboardingUser.Id;
        
        envelope.CustomFields = new DocuSignAPI.ArrayOfCustomField();
        envelope.CustomFields.CustomField = new DocuSignAPI.CustomField[22];
        envelope.CustomFields.CustomField[0] = field;
        
        try {
            if(!test.isRunningTest()){
                DocuSignAPI.EnvelopeStatus es = dsApiSend.CreateEnvelopeFromTemplates(templateReferences, recipients, envelope, true);
                envelopeId = es.EnvelopeID;
            }
        } catch ( CalloutException e) {
            envelopeId = 'Exception - ' + e;
        }
    }
    
    /**
     * @description Provides this DHS API member.
     * @param templateId Method parameter.
     * @param recipient Method parameter.
     * @param recipient2 Method parameter.
     * @return The requested result.
     */
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
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public static list<string> getAllUsernames(){
        list<string> usernames = new list<string>();
        list<user> users = [select id,username__c from user WITH USER_MODE ];	
        for(user u : users){
            usernames.add(u.username__c);
        }
        return usernames;
    }	 
}
