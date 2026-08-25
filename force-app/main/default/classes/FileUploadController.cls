global without sharing class FileUploadController {

  public integer attachmentcount {get;set;}

   @RemoteAction
   global static integer attachmentcountmethod(string parentid){
      
       integer attachmentcount = 0;
       list<attachment> attachments = new list<attachment>();
       if(parentid != Null){
           attachments = [select id,name,parentid,Description from attachment where parentid =: parentid and Description != 'consent' and Description != 'sketch'];
           attachmentcount = attachments.size();
       }
       return attachmentcount;
   }
   
   @RemoteAction
   global static string attachmentnames(string parentid){
      
       string attachmentnames = '';
       list<attachment> attachments = new list<attachment>();
       if(parentid != Null){
           attachments = [select id,name,parentid from attachment where parentid =: parentid];
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
        case__c caseRecord;
        if(parentId != Null){
            List<Case__c> cases = [Select Subject_Type__c, Contact__r.SSN__c from Case__c where Id=:parentId];
            if(!cases.isEMpty()){
                caseRecord = cases[0];
            }
        }
        
        String parentDocumentId;
        if(String.isBlank(attachmentId)){
           Document__c document = new Document__c();
            document.added_by__c = [Select Id,Name from user where id=:userinfo.getuserid()].Name;
            document.case__c = parentId;
            document.Name__c = fileName;
            insert document;
            parentDocumentId = document.id;
        }
        String modifiedFileName;
        if(caseRecord != Null){
                if(caseRecord.Subject_Type__c == 'Applicant'){
                    modifiedFileName = 'A'; 
                }else if(caseRecord.Subject_Type__c == 'Contractor'){
                    modifiedFileName = 'A'; 
                }
                modifiedFileName = modifiedFileName + caseRecord.Contact__r.SSN__c+'Att00_'+fileName;
            }else{
               modifiedFileName = fileName; 
            }
       
        
        if(attachmentId == '' || attachmentId == null){
            Attachment att = new Attachment(
                ParentId = parentDocumentId,
                Body = EncodingUtil.Base64Decode(base64BlobValue),
                Name = modifiedFileName,
                ContentType = contentType,
                description = descr
                
            );
            insert att;
            
            //Return the new attachment Id
            return att.Id;
            
        }else{
            for(Attachment atm : [select Id, Body from Attachment where Id = :attachmentId]){
                //Take the body of the current attachment, convert to base64 string, append base64 value sent from page, then convert back to binary for the body
                update new Attachment(Id = attachmentId, Body = EncodingUtil.Base64Decode(EncodingUtil.Base64Encode(atm.Body) + base64BlobValue));
            }
            
            //Return the Id of the attachment we are currently processing
            return attachmentId;
        }
    }
    
  
}