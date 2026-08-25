global with sharing class DIAKnowledgeBaseFileUploadController {

  public integer attachmentcount {get;set;}

   @RemoteAction
   global static integer attachmentcountmethod(string parentid){
      
       integer attachmentcount = 0;
       list<attachment> attachments = new list<attachment>();
       if(parentid != Null){
           attachments = [select id,name,parentid,Description from attachment where parentid =: parentid and Description != 'consent' and Description != 'sketch' WITH SECURITY_ENFORCED];
           attachmentcount = attachments.size();
       }
       return attachmentcount;
   }
   
   @RemoteAction
   global static string attachmentnames(string parentid){
      
       string attachmentnames = '';
       list<attachment> attachments = new list<attachment>();
       if(parentid != Null){
           attachments = [select id,name,parentid from attachment where parentid =: parentid WITH SECURITY_ENFORCED];
           for(attachment att:attachments){
               if(attachmentnames == ''){
                   attachmentnames = att.name + ';';
               }else {
                   attachmentnames = attachmentnames + ';' + att.name;
               }
           }
       }
       return attachmentnames;
   }
   
   
    
    @RemoteAction
    global static String attachBlob(String parentId, String attachmentId, String fileName, String contentType, String base64BlobValue, string descriptioncheck){
        /*
        parentId: The sfdc object Id this file will be attached to
        attachmentId: The record of the current Attachment file being processed
        fileName: Name of the attachment
        contentTye: Content Type of the file being attached
        base64BlobValue: Base64 encoded string of the file piece currently processing
        */
               system.debug('invoked...'+descriptioncheck);
        //If recordId is blank this is the first part of a multi piece upload
        string descr ='';
        
        if(descriptioncheck == 'f2'){
           descr = 'consent';
        }
        
          
        if(descriptioncheck == 'f3'){
           descr = 'sketch';
        }

        String parentDocumentId;
        if(String.isBlank(attachmentId)){
            DIA_Knowledge_Base__c document = new DIA_Knowledge_Base__c();
            document.Name__c = fileName;
            if(Schema.SobjectType.DIA_Knowledge_Base__c.iscreateable()){
                insert document;
                //Database.SaveResult dsr = database.insert(document, false, AccessLevel.USER_MODE);
                parentDocumentId = document.Id;
                /*if(dsr.isSuccess()){
                    parentDocumentId = dsr.getid();
                }*/
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to create Document'));
            }
        }
        System.debug('document...'+parentDocumentId);
        System.debug('attachmentId...'+attachmentId);
        if(attachmentId == '' || attachmentId == null){
            Attachment att = new Attachment(
                ParentId = parentDocumentId,
                Body = EncodingUtil.Base64Decode(base64BlobValue),
                Name = fileName,
                ContentType = contentType,
                description = descr
                
            );

            Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('Attachment');

            if(Schema.SobjectType.Attachment.iscreateable() && 
                fields.get('ParentId').getDescribe().isAccessible() && 
                fields.get('Body').getDescribe().isAccessible() &&
                fields.get('Name').getDescribe().isAccessible() &&
                fields.get('ContentType').getDescribe().isAccessible() &&
                fields.get('description').getDescribe().isAccessible()
                ){
                    insert att;
                    return att.Id;
                /*Database.SaveResult dsr = database.insert(att, false, AccessLevel.USER_MODE);
                if(dsr.isSuccess()){
                    return att.Id;
                }*/
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to create Attachment'));
                return null;
            }
        }else{
            List<attachment> attList = New List<attachment>();
            for(Attachment atm : [select Id, Body from Attachment where Id = :attachmentId WITH SECURITY_ENFORCED]){
                //Take the body of the current attachment, convert to base64 string, append base64 value sent from page, then convert back to binary for the body
                attList.add(new Attachment(Id = attachmentId, Body = EncodingUtil.Base64Decode(EncodingUtil.Base64Encode(atm.Body) + base64BlobValue)));
            }
            if(Schema.SobjectType.Attachment.isUpdateable()){
                update attList;
                //database.update(attList,false,AccessLevel.USER_MODE);
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update Attachment'));
            }
            //Return the Id of the attachment we are currently processing
            
        }
                return attachmentId;
    }
    
  
}