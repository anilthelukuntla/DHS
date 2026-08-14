/** Provides DHS multi-document upload JavaScript Remoting actions. */
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ApexDoc, PMD.ApexCRUDViolation, PMD.ExcessiveParameterList')
global without sharing class DHSMultipleDocumentUploadController {
 public integer attachmentcount {get;set;}
    public string caseId {get;set;}
    public PageReference uploadAndRedirect() {
        PageReference redirect = new PageReference('/apex/DHSCasedetail?id='+caseId+'&tab=Documents');
        redirect.setRedirect(true);
        return redirect;
    }
        
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
   global static string createDocumentRecord(string caseid){
		DHS_Document__c document = new DHS_Document__c();
		document.Added_By__c = [Select Id,Name from user where id=:userinfo.getuserid()].Name;
		document.DHS_Case__c = caseid;
		insert document;
		return document.Id;
   }
   
   
    
    @RemoteAction
    global static String attachBlob(String parentId, String attachmentId, String fileName, String contentType, String base64BlobValue, string descriptioncheck){
        DHS_Case__c caseRecord;
        List<DHS_Case__c> cases = [Select Subject_Type__c,Case_Number__c ,Case_Type__c, DHS_Contact__r.SSN__c from DHS_Case__c where Id=: parentId];
        if(!cases.isEMpty()){
           caseRecord = cases[0];
        }
        
        string descr ='';
        if(descriptioncheck == 'f2'){
           descr = 'consent';
        }
        if(descriptioncheck == 'f3'){
           descr = 'sketch';
        }
        String parentDocumentId;
        
        DHS_Document__c document = new DHS_Document__c();
		document.Added_By__c = [Select Id,Name from user where id=:userinfo.getuserid()].Name;
		document.DHS_Case__c = parentId;
        document.Name__c = fileName;
		insert document;
        parentDocumentId = document.Id;
        
        String modifiedFileName;
        if(caseRecord.Subject_Type__c == 'Applicant'){
            modifiedFileName = 'A'; 
        }else if(caseRecord.Subject_Type__c == 'Contractor'){
            modifiedFileName = 'C'; 
        }
         modifiedFileName = modifiedFileName + caseRecord.DHS_Contact__r.SSN__c+'Att00_'+fileName;
        
        if(attachmentId == '' || attachmentId == null){
            Attachment att = new Attachment(
                ParentId = parentDocumentId,
                Body = EncodingUtil.Base64Decode(base64BlobValue),
                Name = modifiedFileName,
                ContentType = contentType,
                description = descr
                
            );

				insert att;
				return att.Id;
        }else{
            List<attachment> attList = New List<attachment>();
            for(Attachment atm : [select Id, Body from Attachment where Id = :attachmentId]){
                attList.add(new Attachment(Id = attachmentId, Body = EncodingUtil.Base64Decode(EncodingUtil.Base64Encode(atm.Body) + base64BlobValue)));
            }
				update attList;
        }
                return attachmentId;
        
    }
}