/** Controls onboarding user administration and DocuSign actions. */
// Legacy Visualforce orchestration is intentionally kept together to preserve page state and actions.
@SuppressWarnings('PMD.CyclomaticComplexity,PMD.CognitiveComplexity,PMD.MethodNamingConventions,PMD.AvoidBooleanMethodParameters,PMD.ExcessivePublicCount,PMD.StdCyclomaticComplexity,PMD.NcssCount,PMD.FieldDeclarationsShouldBeAtStart')
public with sharing class OnBoardingController {
    /** Describes a field exposed by the bulk-edit interface. */
    public class BulkEditFieldConfig {
        /** Field API name. */
        public String apiName {get;set;}
        /** User-facing field label. */
        public String label {get;set;}
        /** HTML input type used to edit the field. */
        public String inputType {get;set;}
        /** Indicates whether the field uses picklist options. */
        public Boolean isPicklist {get;set;}
        /** Indicates whether the field contains a Boolean value. */
        public Boolean isBoolean {get;set;}
        /** Indicates whether the field uses a text area. */
        public Boolean isTextArea {get;set;}
        /** Indicates whether the standard input field is displayed. */
        public Boolean showInputField {get;set;}
        /** Available options when the field is a picklist. */
        public List<SelectOption> picklistOptions {get;set;}

        /** Initializes the default bulk-edit field configuration. */
        public BulkEditFieldConfig() {
            picklistOptions = new List<SelectOption>();
            inputType = 'text';
            isPicklist = false;
            isBoolean = false;
            isTextArea = false;
            showInputField = true;
        }
    }

    /** User currently accessing the onboarding page. */
    public user currentUser{get;set;}
    /** Onboarding records displayed on the page. */
    public list<onboarding__c> onboardingUsers{get;set;}
    /** New onboarding record being created. */
    public onboarding__c newUser {get;set;}
    /** JSON payload containing bulk-edit changes. */
    public String bulkUpdatePayload {get;set;}
    /** Field configurations available for bulk editing. */
    public List<BulkEditFieldConfig> bulkEditFields {get;set;}
    /** Selected system access for a new onboarding user. */
    @SuppressWarnings('PMD.PropertyNamingConventions')
    public string UserSystemAccess {get;set;}
    private String auth;
    /** Selected system access for an onboarding user being edited. */
    @SuppressWarnings('PMD.PropertyNamingConventions')
    public string UserSystemAccess1 {get;set;}
    /** Authentication endpoint used by the DocuSign integration. */
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
    private String docusignTemplateId {get;set;}
    /** Identifier of the DocuSign envelope created by the controller. */
    public String envelopeId {get;set;}
    /** Indicates whether the requested username already exists. */
    public boolean duplicateUsername {get;set;}
    /** Initializes page state and DocuSign configuration. */
    public OnBoardingController(){
        duplicateUsername = false;
        currentUser = [select id, firstname, profile.Name, lastname, email, User_Type__c from User where id = :userinfo.getUserId()];  
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
            docusignExpireAfter = Integer.valueOf(docusignTemplateSettings.DocusignExpireAfter__c);
            docusignExpireWarn = Integer.valueOf(docusignTemplateSettings.DocusignExpireWarn__c);
            docusignTemplateId = docusignTemplateSettings.Template_ID__c;
        }
    }

    /**
     * Determines whether the current user can manage onboarding records.
     * @return true when the current user has onboarding administration access
     */
    public Boolean getCanManageOnboarding() {
        return currentUser != null &&
            (currentUser.Profile.Name == 'System Administrator' || currentUser.User_Type__c == 'PMO');
    }
    
    /**
     * Returns the system-access options displayed by the page.
     * @return available system-access options
     */
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('Intel','Intel')); 
        options.add(new SelectOption('DIA','BI'));
		options.add(new SelectOption('Intel;DIA','Both')); 
        return options; 
    }
    /** Creates an onboarding record from the current page input. */
    public void CreateNewUser(){
        newUser.System_Access__c = UserSystemAccess;
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
    
    /** Identifier of the onboarding record selected for deactivation. */
    public string deleteOnboardingUserId{get;set;}
    /** Deactivates the selected onboarding record when access permits. */
    public void DeleteOnboardingUser(){
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
        Onboarding__c userToDeactivate = new Onboarding__c(
            Id = deleteuser.Id,
            Status__c = 'Inactive'
        );
        Database.update(userToDeactivate, AccessLevel.USER_MODE);
        fetchOnboardingUsers();
    }
    
    /** Identifier of the onboarding record selected for editing. */
    public string editOnboardingUserId{get;set;}
    /** Onboarding record currently being edited. */
    public onboarding__c editOnboardingUser{Get;set;}
    /** Loads the selected onboarding record into the edit state. */
    public void editOnboardingUser(){
        for(onboarding__c onboardinguser: onboardingUsers){
            if(editOnboardingUserId == onboardinguser.id){
                editOnboardingUser = onboardinguser;   
                UserSystemAccess1 =  editOnboardingUser.System_Access__c;
            }    
        }
    }
    
    /** Saves changes to the selected onboarding record. */
    public void SaveModifiedOnboardingUser(){
        editOnboardingUser.System_Access__c = UserSystemAccess1;
        list<string> usernames = getAllUsernames();
        if(usernames.contains(editOnboardingUser.email__c)){
            duplicateUsername = true;
        }else{
            duplicateUsername = false;
            Database.update(editOnboardingUser, AccessLevel.USER_MODE);
            fetchOnboardingUsers();
        }
        
    }

    /** Applies the bulk-edit payload to onboarding records. */
    public void SaveMainScreenUpdates(){
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
    
    /** Loads the onboarding records visible to the current user. */
    @SuppressWarnings('PMD.ApexSOQLInjection')
    public void fetchOnboardingUsers(){
        onboardingUsers = new list<onboarding__c>();
        List<string> onBoardingFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        onBoardingFields = ApexUtil.FetchFields('onboarding__c');
        String query = 'Select '+string.join(onBoardingFields, ',') + ' From onboarding__c ';
        if(currentUser.profile.Name != 'System Administrator'){
            whereCriteria.add(new ApexUtil.Criteria('System_Access__c','Intel','='));
		}
        String whereCondition = ApexUtil.generateWhereQuery(whereCriteria); 
        if(String.isNotBlank(whereCondition)){
            query = query + ' WHERE '+whereCondition;     
        }
        query = query +' ORDER BY Last_Name__c,Createddate desc';
        
        onboardingUsers = Database.query(query, AccessLevel.USER_MODE);
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
    
    /** Creates and sends a DocuSign envelope for the selected onboarding user. */
    public void SendToDocusign(){
        DocuSignAPI.APIServiceSoap dsApiSend = new DocuSignAPI.APIServiceSoap();
        dsApiSend.endpoint_x = webServiceUrl;
        String auth = '<DocuSignCredentials><Username>'+ userId+'</Username><Password>'+ password+'</Password><IntegratorKey>'+ integratorsKey+ '</IntegratorKey></DocuSignCredentials>';
        dsApiSend.inputHttpHeaders_x = new Map<String, String>();
        dsApiSend.inputHttpHeaders_x.put('X-DocuSign-Authentication', auth);
        DocuSignAPI.EnvelopeInformation envelope = new DocuSignAPI.EnvelopeInformation();
        envelope.Subject = docusignEmailSubject;
        envelope.EmailBlurb = docusignEmailMessage;
        envelope.AccountId  = accountId; 
        
        DocuSignAPI.Notification notification = new DocuSignAPI.Notification();
        notification.UseAccountDefaults = false;
        
        DocuSignAPI.Reminders reminders = new DocuSignAPI.Reminders();
        reminders.ReminderEnabled = docusignReminderEnabled;
        reminders.ReminderDelay = docusignReminderDelay;
        reminders.ReminderFrequency = docusignReminderFrequency;
        
        DocuSignAPI.Expirations expirations = new DocuSignAPI.Expirations();
        expirations.ExpireEnabled = docusignExpireEnabled;
        expirations.ExpireAfter = docusignExpireAfter;
        expirations.ExpireWarn = docusignExpireWarn;
        
        notification.Reminders = reminders;
        notification.Expirations = expirations;
        
        envelope.Notification = notification;
        
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
        templateReferences.TemplateReference.add(addTemplate(docusignTemplateId,recipient,recipient2)); 
        
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
     * Builds a DocuSign template reference and signer assignments.
     * @param templateId identifier of the DocuSign server template
     * @param recipient first signer assigned to the template
     * @param recipient2 second signer assigned to the template
     * @return configured DocuSign template reference
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
     * Returns usernames currently stored for Salesforce users.
     * @return existing username values
     */
    public static list<string> getAllUsernames(){
        list<string> usernames = new list<string>();
        list<user> users = [select id,username__c from user WHERE username__c != null];	
        for(user u : users){
            usernames.add(u.username__c);
        }
        return usernames;
    }	 
}
