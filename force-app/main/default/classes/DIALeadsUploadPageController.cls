public class DIALeadsUploadPageController {
    public transient Blob csvFileBody{get;set;}
    public string csvAsString{get;set;}
    public List<String> csvFileLines{get;set;}
    public Id batchId {get;set;}
    public String fileContentType {get;set;}
    public Integer DataLoadBatchSize {get;set;}
    public string errorMessage {get;set;}
    public string successMessage {get;set;}
    public string leadUploadDocumentId {get;set;}
    public DIALeadsUploadPageController(){
        csvFileLines = new List<String>();
        batchId = null;
        DataLoadBatchSize = Integer.valueof(System.label.Data_Load_Batch_Size);
        List<document> documents = new list<document>();
        String leadUploadTemplateName = System.label.LeadUploadTemplateName;
        documents = [select id from document where name=:leadUploadTemplateName WITH SECURITY_ENFORCED];
        if(!documents.isEmpty()){
            leadUploadDocumentId = documents[0].id;
        }
        System.debug('leadUploadDocumentId...'+leadUploadDocumentId);
    }
    public PageReference StartBatchJob() {
        System.debug('fileContentType....'+fileContentType);
        if(fileContentType != Null){
            if(fileContentType.contains('csv')||fileContentType=='application/vnd.ms-excel'){
                errorMessage = Null;
                DIA_DataLoad_Activity__c  DLActivity = new DIA_DataLoad_Activity__c();
                DLActivity.Job_Start_Time__c = System.now();
                Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_DataLoad_Activity__c');

                if(Schema.SobjectType.DIA_DataLoad_Activity__c.iscreateable() && 
                    fields.get('Success_Count__c').getDescribe().isAccessible() && 
                    fields.get('Activity_User__c').getDescribe().isAccessible() &&
                    fields.get('Total_Record_Count__c').getDescribe().isAccessible() &&
                    fields.get('Failure_Count__c').getDescribe().isAccessible() &&
                    fields.get('job_end_time__c').getDescribe().isAccessible()
                    ){
                    Database.SaveResult dsr = database.update(DLActivity, false, AccessLevel.USER_MODE);
                    if(dsr.isSuccess()){
                        DIALeadDataLoaderBatch ctrl = new DIALeadDataLoaderBatch(csvFileBody,DLActivity);
                        batchId=database.executebatch(ctrl,DataLoadBatchSize);
                        system.debug('************batchid:'+batchid);
                        successMessage = 'File has been submitted successfully, You will recieve an email with Success and Failure attachments shortly!';
                    }
                }else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update Data loader Activity'));
                }
                
            }else{
                errorMessage = 'Please upload valid file type!';  
                successMessage = Null;
            }
        }else{
             errorMessage = 'Please upload the file to import the records!';  
             successMessage = Null;
        }
        return null;
    }
}