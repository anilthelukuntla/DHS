/** Controls subject-facing DHS document-request uploads. */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.ApexDoc, PMD.ApexXSSFromURLParam, PMD.AvoidBooleanMethodParameters, PMD.MethodNamingConventions')
public without sharing class DHSSubjectDocumentsUploadController{
    public string documentRequestId {get;set;}
    public DHS_Document_Request__c documentRequest {get;set;}
    public boolean showUploadPanel {get;set;}
    public boolean showAfterUploadPanel {get;set;}
    public boolean showExpiryPanel {get;set;}
    public list<attachment> attachmentsList {get;set;}
    
    public DHSSubjectDocumentsUploadController(){
        documentRequestId = apexpages.currentpage().getparameters().get('id');
        documentRequestId = String.valueOf(Id.valueOf(decodeURLParams(documentRequestId)));
        
        FetchDocumentRequest();
    }
    
    public void FetchDocumentRequest(){
        showUploadPanel = false;
        showAfterUploadPanel = false;
        showExpiryPanel = false;
        documentRequest = [Select Id, DHS_Lead__c, DHS_Lead__r.Assigned_To_Name__c,DHS_Lead__r.DHS_Case__r.Case_Number__c, Expiration_Date__c, CreatedDate, Status__c, Subject_Comments__c, Request_Expired__c from DHS_Document_Request__c WHERE ID=: documentRequestId];
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