/**
 * @description Controls subject-facing DHS document-request uploads.
 */

public without sharing class DHSSubjectDocumentsUploadController{
    /** @description Provides this DHS API member. */
    public string documentRequestId {get;set;}
    /** @description Provides this DHS API member. */
    public DHS_Document_Request__c documentRequest {get;set;}
    public boolean showUploadPanel {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public boolean showAfterUploadPanel {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public boolean showExpiryPanel {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    /** @description Provides this DHS API member. */
    public list<attachment> attachmentsList {get;set;}
    
    /** @description Provides this DHS API member. */
    public DHSSubjectDocumentsUploadController(){
        documentRequestId = ApexPages.currentPage().getParameters().get('id').escapeHtml4();
        documentRequestId = String.valueOf(Id.valueOf(decodeURLParams(documentRequestId)));
        
        fetchDocumentRequest();
    }
    
    /** @description Provides this DHS API member. */
    public void fetchDocumentRequest(){
        showUploadPanel = false;
        showAfterUploadPanel = false;
        showExpiryPanel = false;
        documentRequest = [Select Id, DHS_Lead__c, DHS_Lead__r.Assigned_To_Name__c,DHS_Lead__r.DHS_Case__r.Case_Number__c, Expiration_Date__c, CreatedDate, Status__c, Subject_Comments__c, Request_Expired__c from DHS_Document_Request__c WHERE ID=: documentRequestId ];
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
        attachmentsList = [Select Id, parentId, Name, CreatedDate, Description from Attachment where parentId =:documentRequestId ];
    
    }
    
    /** @description Provides this DHS API member. */
    public void submitaction(){
        documentRequest.Status__c='Documents Received';
        Database.update(documentRequest);
        fetchDocumentRequest();
    }
    /** @description Provides this DHS API member. */
    public string deleteAttachmentId{get;set;}
    /** @description Provides this DHS API member. */
    public void deleteAttachment(){
        Database.delete([select Id from Attachment where id=:deleteAttachmentId ]);
        fetchDocumentRequest();
    }
    
    /** @description Provides this DHS API member. */
    public void autosaveaction(){
        Database.update(documentRequest);
    }
    
    private String decodeURLParams(String encodedString){
         // take the base64 encoded parameter and create base64 decoded Blob from it   
         Blob afterblob = EncodingUtil.base64Decode(encodedString);
         // Convert the blob back to a string and print it in the debug log
         return afterblob.toString();
        
    }

}