/** Retains the existing DHSCustomerNotificationBatch integration and application behavior. */
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ApexDoc, PMD.FormalParameterNamingConventions, PMD.DebugsShouldUseLoggingLevel, PMD.IfStmtsMustUseBraces, PMD.IfElseStmtsMustUseBraces')
global with sharing class DHSCustomerNotificationBatch implements Database.Stateful,Database.Batchable<sObject> {
    global string csvContent;
    global integer totalCasesCompleted;
    global Database.QueryLocator start(Database.BatchableContext BC) {
      
        map<string,string> apiNameNLabelMap = new map<string,string>();
        list<string> notificationCaseFields = new list<String>();
        Map<String,Schema.SObjectField> mfields = Schema.DHS_Case__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();
        notificationCaseFields = getConfiguredFields(mfields);
        for(string fieldName: notificationCaseFields){
            Schema.DescribeFieldResult fieldResult = mfields.get(fieldName).getDescribe();
        	apiNameNLabelMap.put(fieldname,fieldResult.getLabel());     
        }
        for(string fieldName: notificationCaseFields){
            if(string.isblank(csvContent)){
            	csvContent =  apiNameNLabelMap.get(fieldName);   
            }else{
            	csvContent = csvContent + ',' +  apiNameNLabelMap.get(fieldName);    
            }
        	
        }
        csvContent = csvContent+'\n';
        totalCasesCompleted = 0;
		string query = 'select '+String.join(notificationCaseFields, ',')+' From DHS_Case__c WHERE Case_Completed_Date__c=TODAY WITH SECURITY_ENFORCED';
        return Database.getQueryLocator(query);       
    }
    global void execute(Database.BatchableContext BC, List<DHS_Case__c> cases) {
        list<string> notificationCaseFields = new list<String>();
        notificationCaseFields = getConfiguredFields(Schema.DHS_Case__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap());
        integer sizeOfFields = notificationCaseFields.size();
        for(DHS_Case__c c: cases){
            totalCasesCompleted = totalCasesCompleted + 1;
            integer i = 1;
            for(string str: notificationCaseFields){
                if(i != sizeOfFields){
                	csvContent = csvContent + c.get(str) +',';     
                }else{
                	csvContent = csvContent + c.get(str);    
                }
            	
            }
            csvContent = csvContent +'\n';
        }
    }
    private static List<String> getConfiguredFields(Map<String, Schema.SObjectField> availableFields) {
        List<String> fields = new List<String>();
        for (String configuredField : System.Label.DHS_Customer_Notification_Case_Fields.split(',')) {
            String fieldName = configuredField == null ? null : configuredField.trim();
            if (!availableFields.containsKey(fieldName) && fieldName != null && fieldName.startsWith('DHS_')) {
                fieldName = fieldName.substring(4);
            }
            if (availableFields.containsKey(fieldName)) fields.add(fieldName);
        }
        return fields;
    }
    global void finish(Database.BatchableContext BC) {
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
        blob csvBlob = Blob.valueOf(csvContent);
        string csvname= 'CustomerNotification.csv';
        csvAttc.setFileName(csvname);
        csvAttc.setBody(csvBlob);
        Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
        String[] toAddresses = system.label.DHS_Customer_Notification_Emails.split(',');
        String subject ='Cases Completed Today';
        email.setSubject(subject);
        email.setToAddresses( toAddresses );
        email.setHTMLBody('Hi,<br/><br/>Total Number of cases completed today: '+totalCasesCompleted+'<br/>Please find the attached report of cases completed today.<br/><br/>Regards,<br/>ISN Team');
        email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        }
    }
}