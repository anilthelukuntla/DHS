/** JavaScript Remoting controller for chunked DHS customer-order uploads. */
@SuppressWarnings('PMD.ApexDoc,PMD.AvoidGlobalModifier,PMD.ExcessiveParameterList,PMD.OperationWithLimitsInLoop,PMD.UnusedMethod')
global with sharing class DHSOrderFileUploadController {

  public integer attachmentcount {get;set;}

   @RemoteAction
   global static integer attachmentcountmethod(string parentid){
      
       integer attachmentcount = 0;
       list<attachment> attachments = new list<attachment>();
       if(parentid != Null){
           attachments = [select id,name,parentid,Description from attachment where parentid =: parentid and Description != 'consent' and Description != 'sketch' WITH USER_MODE];
           attachmentcount = attachments.size();
       }
       return attachmentcount;
   }
   
   @RemoteAction
   global static string attachmentnames(string parentid){
      
       string attachmentnames = '';
       list<attachment> attachments = new list<attachment>();
       if(parentid != Null){
           attachments = [select id,name,parentid from attachment where parentid =: parentid WITH USER_MODE];
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
        //If recordId is blank this is the first part of a multi piece upload
        string descr ='';
        
        if(descriptioncheck == 'f2'){
           descr = 'consent';
        }
        
          
        if(descriptioncheck == 'f3'){
           descr = 'sketch';
        }
        
        DHS_Customer_Order__c co = new DHS_Customer_Order__c ();
        co.Status__c = 'Uploaded';
        database.insert(co,false,AccessLevel.USER_MODE);
        
        if(attachmentId == '' || attachmentId == null){
            Attachment att = new Attachment(
                ParentId = co.id,
                Body = EncodingUtil.Base64Decode(base64BlobValue),
                Name = fileName,
                ContentType = contentType,
                description = descr
                
            );
            database.insert(att,false,AccessLevel.USER_MODE);
            
            //Return the new attachment Id
            return att.Id;
            
        }else{
            for(Attachment atm : [select Id, Body from Attachment where Id = :attachmentId WITH USER_MODE ]){
                //Take the body of the current attachment, convert to base64 string, append base64 value sent from page, then convert back to binary for the body
                Database.update(new Attachment(Id = attachmentId, Body = EncodingUtil.Base64Decode(EncodingUtil.Base64Encode(atm.Body) + base64BlobValue)), AccessLevel.USER_MODE);
            }
            
            //Return the Id of the attachment we are currently processing
            return attachmentId;
        }
    }
    
  
}
