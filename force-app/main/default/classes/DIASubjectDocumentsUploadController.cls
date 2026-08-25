public with sharing class DIASubjectDocumentsUploadController{
    public string documentRequestId {get;set;}
    public DIA_Document_Request__c documentRequest {get;set;}
    public boolean showUploadPanel {get;set;}
    public boolean showAfterUploadPanel {get;set;}
    public boolean showExpiryPanel {get;set;}
    public list<attachment> attachmentsList {get;set;}
    
    public DIASubjectDocumentsUploadController(){
        documentRequestId = apexpages.currentpage().getparameters().get('id');
        System.debug('documentRequestId...'+documentRequestId);
        documentRequestId = decodeURLParams(documentRequestId);
        
        FetchDocumentRequest();
    }
    
    public void FetchDocumentRequest(){
        showUploadPanel = false;
        showAfterUploadPanel = false;
        showExpiryPanel = false;
        documentRequest = [Select Id, Lead__c, Lead__r.Assigned_To_Name__c,Lead__r.case__r.Case_Number__c, Expiration_Date__c, CreatedDate, Status__c, Subject_Comments__c, Request_Expired__c from DIA_Document_Request__c WHERE ID=: documentRequestId WITH SECURITY_ENFORCED];
        if(documentRequest.Status__c == 'Documents Requested' && !documentRequest.Request_Expired__c){
            showUploadPanel = true;    
        }
        if(documentRequest.Status__c == 'Documents Received' && !documentRequest.Request_Expired__c){
            showAfterUploadPanel = true;    
        }
        if(documentRequest.Request_Expired__c){
            showExpiryPanel = true;    
        }
        System.debug('showUploadPanel...'+showUploadPanel);
         System.debug('showAfterUploadPanel...'+showAfterUploadPanel);
         System.debug('documentRequest.Status__c...'+documentRequest.Status__c);
         System.debug('documentRequest.Request_Expired__c...'+documentRequest.Request_Expired__c);
        attachmentsList = new list<attachment>();
        attachmentsList = [Select Id, parentId, Name, CreatedDate, Description from Attachment where parentId =:documentRequestId WITH SECURITY_ENFORCED];
    
    }
    
    public void submitaction(){
        documentRequest.Status__c='Documents Received';
        Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_Document_Request__c');
            if(Schema.SobjectType.DIA_Document_Request__c.isUpdateable() &&
                fields.get('Status__c').getDescribe().isAccessible()){

                Database.SaveResult dsr = database.update(documentRequest, false, AccessLevel.USER_MODE);
                if(dsr.isSuccess()){
                    FetchDocumentRequest();
                }
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update Document Request'));
            }
    }
    public string deleteAttachmentId{get;set;}
    public void DeleteAttachment(){
        Attachment att = [select Id from Attachment where id=:deleteAttachmentId];
        if(Schema.SobjectType.DIA_document__c.isDeletable()){
            Database.DeleteResult drList = database.delete(att, false, AccessLevel.USER_MODE);
            if(drList.isSuccess()){
                FetchDocumentRequest();
            }
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to delete Attachment'));
        }
    }
    
    public void autosaveaction(){
        if(Schema.SobjectType.DIA_Document_Request__c.isUpdateable()){
            Database.SaveResult dsr = database.update(documentRequest, false, AccessLevel.USER_MODE);
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update Document Request'));
        }
        
    }
    
    private String decodeURLParams(String encodedString){
         // take the base64 encoded parameter and create base64 decoded Blob from it   
         Blob afterblob = EncodingUtil.base64Decode(encodedString);
         // Convert the blob back to a string and print it in the debug log
         System.debug(encodedString + 'is now decoded as: ' + afterblob.toString());
         return afterblob.toString();
        
    }

}