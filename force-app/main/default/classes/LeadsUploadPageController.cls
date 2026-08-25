public class LeadsUploadPageController {
    public transient Blob csvFileBody{get;set;}
    public string csvAsString{get;set;}
    public List<String> csvFileLines{get;set;}
    public Id batchId {get;set;}
    public String fileContentType {get;set;}
    public Integer DataLoadBatchSize {get;set;}
    public string errorMessage {get;set;}
    public string successMessage {get;set;}
    public string leadUploadDocumentId {get;set;}
    public LeadsUploadPageController(){
        csvFileLines = new List<String>();
        batchId = null;
        DataLoadBatchSize = Integer.valueof(System.label.Data_Load_Batch_Size);
        List<document> documents = new list<document>();
        String leadUploadTemplateName = System.label.LeadUploadTemplateName;
        documents = [select id from document where name=:leadUploadTemplateName];
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
                DataLoad_Activity__c  DLActivity = new DataLoad_Activity__c();
                DLActivity.Job_Start_Time__c = System.now();
                insert DLActivity;
                LeadDataLoaderBatch ctrl = new LeadDataLoaderBatch(csvFileBody,DLActivity);
                batchId=database.executebatch(ctrl,DataLoadBatchSize);
                system.debug('************batchid:'+batchid);
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