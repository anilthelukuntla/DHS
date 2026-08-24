/**
 * @description Retains the existing DHSCustomerNotificationBatch integration and application behavior.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class DHSCustomerNotificationBatch implements Database.Stateful,Database.Batchable<sObject> {
    global string csvContent;
    global integer totalCasesCompleted;
    /**
     * @description Provides this DHS API member.
     * @param bC Method parameter.
     * @return The requested result.
     */
    global Database.QueryLocator start(Database.BatchableContext bC) {
      
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
    /**
     * @description Provides this DHS API member.
     * @param bC Method parameter.
     * @param cases Method parameter.
     */
    global void execute(Database.BatchableContext bC, List<DHS_Case__c> cases) {
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
            if (availableFields.containsKey(fieldName)) {
                fields.add(fieldName);
            }
        }
        return fields;
    }
    /**
     * @description Provides this DHS API member.
     * @param bC Method parameter.
     */
    global void finish(Database.BatchableContext bC) {
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
