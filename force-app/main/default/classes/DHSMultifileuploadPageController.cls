/**
 * @description Provides DHS multi-file upload and document-linking remoting actions.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.AvoidHardcodingId,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.ExcessiveParameterList,PMD.NcssCount,PMD.NcssMethodCount,PMD.StdCyclomaticComplexity,PMD.UnusedMethod')
global without sharing class DHSMultifileuploadPageController {
    /** @description Provides this DHS API member. */
    public string recordId {get;set;}
    /** @description Provides this DHS API member. */
    public string networkId {get;set;}
    /** @description Provides this DHS API member. */
    public string caseId {get;set;}
    /** @description Provides this DHS API member. */
    public string parentId {get;set;}
    /** @description Provides this DHS API member. */
    public string fId {get;set;}
    /** @description Provides this DHS API member. */
    public string sessionId {get;set;}
    /** @description Provides this DHS API member. */
    public DHSMultifileuploadPageController(){
        networkId = Network.getNetworkId();
        recordId = 'a02cn000000xbhtAAA';
        fId = 'f1';
        caseId = String.valueOf(Id.valueOf(
            ApexPages.currentPage().getParameters().get('caseid').escapeHtml4()
        ));
        parentId = caseId;
    }
    /** @description Provides this DHS API member. */
    public integer attachmentcount {get;set;}
    //public string caseId {get;set;}
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
		document.Added_By__c = [Select Id,Name from user where id=:userinfo.getuserid() ].Name;
		document.DHS_Case__c = caseid;
		Database.insert(document, AccessLevel.USER_MODE);
		return document.Id;
   }
   
   
    
    @RemoteAction
    @AuraEnabled
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
        try {
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
            
            // Validate file size before processing (max 25MB)
            Blob fileBlob = EncodingUtil.Base64Decode(base64BlobValue);
            if(fileBlob.size() > 26214400) { // 25MB in bytes
                throw new CustomException('File size exceeds 25MB limit');
            }
            
            String parentDocumentId;
            
            // Only create document record if this is the first chunk
            if(attachmentId == '' || attachmentId == null){
                DHS_Document__c document = new DHS_Document__c();
                document.Added_By__c = [Select Id,Name from user where id=:userinfo.getuserid() ].Name;
                document.DHS_Case__c = parentId;
                document.Name__c = fileName;
                Database.insert(document, AccessLevel.USER_MODE);
                parentDocumentId = document.Id;
            } else {
                // For subsequent chunks, get the existing attachment's parent
                List<Attachment> existingAtts = [SELECT ParentId FROM Attachment WHERE Id = :attachmentId WITH USER_MODE LIMIT 1];
                if(!existingAtts.isEmpty()) {
                    parentDocumentId = existingAtts[0].ParentId;
                }
            }
            
            
            String modifiedFileName = fileName; // Default to original filename
            
            // Only modify filename for the first chunk to avoid duplication
            if((attachmentId == '' || attachmentId == null) && caseRecord != null){
                if(caseRecord.Subject_Type__c == 'Applicant'){
                    modifiedFileName = 'A'; 
                }else if(caseRecord.Subject_Type__c == 'Contractor'){
                    modifiedFileName = 'C'; 
                }
                if(caseRecord.DHS_Contact__r != null && caseRecord.DHS_Contact__r.SSN__c != null) {
                    modifiedFileName = modifiedFileName + caseRecord.DHS_Contact__r.SSN__c+'Att00_'+fileName;
                }
            }
            
            if(attachmentId == '' || attachmentId == null){
                Attachment att = new Attachment(
                    ParentId = parentDocumentId,
                    Body = fileBlob,
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
        } catch (Exception e) {
            throw new CustomException('Upload failed: ' + e.getMessage());
        }
    }
    
    // New method for handling large files with proper chunking
    
    
    // Custom exception class for upload errors
    /** @description Provides this DHS API member. */
    public class CustomException extends Exception {}
    @RemoteAction
    /**
     * @description Provides this DHS API member.
     * @param caseId Method parameter.
     * @param fileName Method parameter.
     * @return The requested result.
     */
    public static String processUploadedFiles(string caseId,string fileName) {
		caseId = String.valueOf(Id.valueOf(caseId.escapeHtml4()));
		fileName = fileName.escapeHtml4();
        DHS_Case__c caseRecord;
		List<DHS_Case__c> cases = [Select Subject_Type__c,Case_Number__c ,Case_Type__c, DHS_Contact__r.SSN__c from DHS_Case__c where Id=: caseId WITH USER_MODE ];
		if(!cases.isEMpty()){
			caseRecord = cases[0];
		}
        String modifiedFileName; // Default to original filename
            
            // Only modify filename for the first chunk to avoid duplication
            
		if(caseRecord.Subject_Type__c == 'Applicant'){
			modifiedFileName = 'A'; 
		}else if(caseRecord.Subject_Type__c == 'Contractor'){
			modifiedFileName = 'C'; 
		}
		if(caseRecord.DHS_Contact__r != null && caseRecord.DHS_Contact__r.SSN__c != null) {
			modifiedFileName = modifiedFileName + caseRecord.DHS_Contact__r.SSN__c+'Att00_'+fileName;
		}
        
		DHS_Document__c doc = New DHS_Document__c();
		doc.Added_By__c = [Select Id,Name from user where id=:userinfo.getuserid() ].Name;
		doc.DHS_Case__c = caseId;
		doc.Name__c = fileName;
        Database.insert(doc, AccessLevel.USER_MODE);
        return doc.Id;
    }
    
}
