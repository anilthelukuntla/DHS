/** Supports the legacy subject-document upload workflow. */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.ApexDoc, PMD.ApexSharingViolations, PMD.ApexXSSFromURLParam, PMD.AvoidBooleanMethodParameters, PMD.DebugsShouldUseLoggingLevel, PMD.MethodNamingConventions')
public class SubjectDocumentsUploadController{
    public string documentRequestId {get;set;}
    public Document_Request__c documentRequest {get;set;}
    public boolean showUploadPanel {get;set;}
    public boolean showAfterUploadPanel {get;set;}
    public boolean showExpiryPanel {get;set;}
    public list<attachment> attachmentsList {get;set;}
    
    public SubjectDocumentsUploadController(){
        documentRequestId = apexpages.currentpage().getparameters().get('id');
        documentRequestId = decodeURLParams(documentRequestId);
        
        FetchDocumentRequest();
    }
    
    public void FetchDocumentRequest(){
        showUploadPanel = false;
        showAfterUploadPanel = false;
        showExpiryPanel = false;
        documentRequest = [Select Id, Lead__c, Lead__r.Assigned_To_Name__c,Lead__r.case__r.Case_Number__c, Expiration_Date__c, CreatedDate, Status__c, Subject_Comments__c, Request_Expired__c from Document_Request__c WHERE ID=: documentRequestId];
        if(documentRequest.Status__c == 'Documents Requested' && !documentRequest.Request_Expired__c){
            showUploadPanel = true;    
        }
        if(documentRequest.Status__c == 'Documents Received' && !documentRequest.Request_Expired__c){
            showAfterUploadPanel = true;    
        }
        if(documentRequest.Request_Expired__c){
            showExpiryPanel = true;    
        }
        attachmentsList = new list<attachment>();
        attachmentsList = [Select Id, parentId, Name, CreatedDate, Description from Attachment where parentId =:documentRequestId];
    
    }
    
    public void submitaction(){
        documentRequest.Status__c='Documents Received';
        update documentRequest;
        FetchDocumentRequest();
    }
    public string deleteAttachmentId{get;set;}
    public void DeleteAttachment(){
        delete [select Id from Attachment where id=:deleteAttachmentId];
        FetchDocumentRequest();
    }
    
    public void autosaveaction(){
        update documentRequest;
    }
    
    private String decodeURLParams(String encodedString){
         // take the base64 encoded parameter and create base64 decoded Blob from it   
         Blob afterblob = EncodingUtil.base64Decode(encodedString);
         // Convert the blob back to a string and print it in the debug log
         return afterblob.toString();
        
    }

}