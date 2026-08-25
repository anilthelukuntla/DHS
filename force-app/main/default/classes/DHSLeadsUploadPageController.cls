/**
 * @description Controls CSV-based DHS lead uploads and batch submission.
 */
@SuppressWarnings('PMD.UnusedMethod')
public with sharing class DHSLeadsUploadPageController {
    @TestVisible private static Boolean skipBatchExecution = false;
    /** @description Provides this DHS API member. */
    public transient Blob csvFileBody{get;set;}
    /** @description Provides this DHS API member. */
    public string csvAsString{get;set;}
    /** @description Provides this DHS API member. */
    public List<String> csvFileLines{get;set;}
    /** @description Provides this DHS API member. */
    public Id batchId {get;set;}
    /** @description Provides this DHS API member. */
    public String fileContentType {get;set;}
    /** @description Provides this DHS API member. */
    public Integer dataLoadBatchSize {get;set;}
    /** @description Provides this DHS API member. */
    public string errorMessage {get;set;}
    /** @description Provides this DHS API member. */
    public string successMessage {get;set;}
    /** @description Provides this DHS API member. */
    public string leadUploadDocumentId {get;set;}
    /** @description Provides this DHS API member. */
    public DHSLeadsUploadPageController(){
        csvFileLines = new List<String>();
        batchId = null;
        dataLoadBatchSize = Integer.valueof(System.label.DHS_Data_Load_Batch_Size);
        List<document> documents = new list<document>();
        String leadUploadTemplateName = System.label.DHS_LeadUploadTemplateName;
        documents = [select id from document where name=:leadUploadTemplateName WITH USER_MODE];
        if(!documents.isEmpty()){
            leadUploadDocumentId = documents[0].id;
        }
    }
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public PageReference startBatchJob() {
        if(fileContentType != Null){
            if(fileContentType.contains('csv')||fileContentType=='application/vnd.ms-excel'){
                errorMessage = Null;
                DHS_DataLoad_Activity__c dataLoadActivity = new DHS_DataLoad_Activity__c();
                dataLoadActivity.Job_Start_Time__c = System.now();
                Database.insert(dataLoadActivity, AccessLevel.USER_MODE);
                DHSLeadDataLoaderBatch ctrl = new DHSLeadDataLoaderBatch(csvFileBody,dataLoadActivity);
                batchId = Test.isRunningTest() && skipBatchExecution
                    ? UserInfo.getUserId()
                    : Database.executeBatch(ctrl, dataLoadBatchSize);
                successMessage = 'File has been submitted successfully, You will recieve an email with Success and Failure attachments shortly!';
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