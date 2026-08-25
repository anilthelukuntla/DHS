/**
 * @description JavaScript Remoting controller for chunked DHS case-file uploads.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.ExcessiveParameterList,PMD.OperationWithLimitsInLoop,PMD.StdCyclomaticComplexity,PMD.UnusedMethod')
global without sharing class DHSFileUploadController {

  /** @description Provides this DHS API member. */
  public integer attachmentcount {get;set;}

   @RemoteAction
   /**
    * @description Provides this DHS API member.
    * @param parentid Method parameter.
    * @return The requested result.
    */
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
   /**
    * @description Provides this DHS API member.
    * @param parentid Method parameter.
    * @return The requested result.
    */
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
    /**
     * @description Provides this DHS API member.
     * @param parentId Method parameter.
     * @param attachmentId Method parameter.
     * @param fileName Method parameter.
     * @param contentType Method parameter.
     * @param base64BlobValue Method parameter.
     * @param descriptioncheck Method parameter.
     * @return The requested result.
     */
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
        DHS_Case__c caseRecord;
        if(parentId != Null){
            List<DHS_Case__c> cases = [Select Subject_Type__c, DHS_Contact__r.SSN__c from DHS_Case__c where Id=:parentId WITH USER_MODE];
            if(!cases.isEMpty()){
                caseRecord = cases[0];
            }
        }
        
        String parentDocumentId;
        if(String.isBlank(attachmentId)){
           DHS_Document__c document = new DHS_Document__c();
            document.Added_By__c = [Select Id,Name from user where id=:userinfo.getuserid()].Name;
            document.DHS_Case__c = parentId;
            document.Name__c = fileName;
            database.insert(document,false,AccessLevel.USER_MODE);
            parentDocumentId = document.id;
        }
        String modifiedFileName;
        if(caseRecord != Null){
                if(caseRecord.Subject_Type__c == 'Applicant'){
                    modifiedFileName = 'A'; 
                }else if(caseRecord.Subject_Type__c == 'Contractor'){
                    modifiedFileName = 'A'; 
                }
                modifiedFileName = modifiedFileName + caseRecord.DHS_Contact__r.SSN__c+'Att00_'+fileName;
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
            database.insert(att,false,AccessLevel.USER_MODE);
            
            //Return the new attachment Id
            return att.Id;
            
        }else{
            for(Attachment atm : [select Id, Body from Attachment where Id = :attachmentId WITH USER_MODE]){
                //Take the body of the current attachment, convert to base64 string, append base64 value sent from page, then convert back to binary for the body
                Database.update(new Attachment(Id = attachmentId, Body = EncodingUtil.Base64Decode(EncodingUtil.Base64Encode(atm.Body) + base64BlobValue)), AccessLevel.USER_MODE);
            }
            
            //Return the Id of the attachment we are currently processing
            return attachmentId;
        }
    }
    
  
}
