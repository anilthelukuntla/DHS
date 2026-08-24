/**
 * @description Provides DHS multi-document upload JavaScript Remoting actions.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.ExcessiveParameterList,PMD.UnusedMethod')
global without sharing class DHSMultipleDocumentUploadController {
 /** @description Provides this DHS API member. */
 public integer attachmentcount {get;set;}
    /** @description Provides this DHS API member. */
    public string caseId {get;set;}
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public PageReference uploadAndRedirect() {
        PageReference redirect = new PageReference('/apex/DHSCasedetail?id='+caseId+'&tab=Documents');
        redirect.setRedirect(true);
        return redirect;
    }
        
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
    * @param caseid Method parameter.
    * @return The requested result.
    */
   global static string createDocumentRecord(string caseid){
		DHS_Document__c document = new DHS_Document__c();
		document.Added_By__c = [Select Id,Name from user where id=:userinfo.getuserid() WITH USER_MODE ].Name;
		document.DHS_Case__c = caseid;
		Database.insert(document, AccessLevel.USER_MODE);
		return document.Id;
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
        DHS_Case__c caseRecord;
        List<DHS_Case__c> cases = [Select Subject_Type__c,Case_Number__c ,Case_Type__c, DHS_Contact__r.SSN__c from DHS_Case__c where Id=: parentId WITH USER_MODE ];
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
		document.Added_By__c = [Select Id,Name from user where id=:userinfo.getuserid() WITH USER_MODE ].Name;
		document.DHS_Case__c = parentId;
        document.Name__c = fileName;
		Database.insert(document, AccessLevel.USER_MODE);
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

				Database.insert(att, AccessLevel.USER_MODE);
				return att.Id;
        }else{
            List<attachment> attList = New List<attachment>();
            for(Attachment atm : [select Id, Body from Attachment where Id = :attachmentId WITH USER_MODE ]){
                attList.add(new Attachment(Id = attachmentId, Body = EncodingUtil.Base64Decode(EncodingUtil.Base64Encode(atm.Body) + base64BlobValue)));
            }
				Database.update(attList, AccessLevel.USER_MODE);
        }
                return attachmentId;
        
    }
}
