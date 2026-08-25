global class MultifileuploadPageController {
    public string recordId {get;set;}
    public string networkId {get;set;}
    public string caseId {get;set;}
    public string parentId {get;set;}
    public string fId {get;set;}
    public string sessionId {get;set;}
    public MultifileuploadPageController(){
        sessionId = userinfo.getSessionId();
        networkId = Network.getNetworkId();
        recordId = 'a02cn000000xbhtAAA';
        fId = 'f1';
        caseId = apexpages.currentpage().getparameters().get('caseid');
        parentId = caseId;
    }
    public integer attachmentcount {get;set;}
    //public string caseId {get;set;}
    public PageReference uploadAndRedirect() {
        system.debug('caseId...'+caseId);
        PageReference redirect = new PageReference('/apex/casedetail?id='+caseId+'&tab=Documents');
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
		Document__c document = new Document__c();
		document.added_by__c = [Select Id,Name from user where id=:userinfo.getuserid()].Name;
		document.case__c = caseid;
		insert document;
		return document.Id;
   }
   
   
    
    @RemoteAction
    @auraEnabled
    global static String attachBlob(String parentId, String attachmentId, String fileName, String contentType, String base64BlobValue, string descriptioncheck){
        try {
            case__c caseRecord;
            List<Case__c> cases = [Select Subject_Type__c,Case_Number__c ,case_type__c, Contact__r.SSN__c from Case__c where Id=: parentId];
            if(!cases.isEMpty()){
               caseRecord = cases[0];
            }
            
            system.debug('parentId...'+parentId);
            system.debug('invoked...'+descriptioncheck);
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
                Document__c document = new Document__c();
                document.added_by__c = [Select Id,Name from user where id=:userinfo.getuserid()].Name;
                document.case__c = parentId;
                document.Name__c = fileName;
                insert document;
                parentDocumentId = document.Id;
            } else {
                // For subsequent chunks, get the existing attachment's parent
                List<Attachment> existingAtts = [SELECT ParentId FROM Attachment WHERE Id = :attachmentId LIMIT 1];
                if(!existingAtts.isEmpty()) {
                    parentDocumentId = existingAtts[0].ParentId;
                }
            }
            
            System.debug('parentDocumentId...'+parentDocumentId);
            System.debug('attachmentId...'+attachmentId);
            
            String modifiedFileName = fileName; // Default to original filename
            
            // Only modify filename for the first chunk to avoid duplication
            if((attachmentId == '' || attachmentId == null) && caseRecord != null){
                if(caseRecord.Subject_Type__c == 'Applicant'){
                    modifiedFileName = 'A'; 
                }else if(caseRecord.Subject_Type__c == 'Contractor'){
                    modifiedFileName = 'C'; 
                }
                if(caseRecord.Contact__r != null && caseRecord.Contact__r.SSN__c != null) {
                    modifiedFileName = modifiedFileName + caseRecord.Contact__r.SSN__c+'Att00_'+fileName;
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
        } catch (Exception e) {
            System.debug('Error in attachBlob: ' + e.getMessage());
            throw new CustomException('Upload failed: ' + e.getMessage());
        }
    }
    
    // New method for handling large files with proper chunking
    
    
    // Custom exception class for upload errors
    public class CustomException extends Exception {}
    @RemoteAction
    public static String processUploadedFiles(string caseId,string fileName) {
        case__c caseRecord;
		List<Case__c> cases = [Select Subject_Type__c,Case_Number__c ,case_type__c, Contact__r.SSN__c from Case__c where Id=: caseId];
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
		if(caseRecord.Contact__r != null && caseRecord.Contact__r.SSN__c != null) {
			modifiedFileName = modifiedFileName + caseRecord.Contact__r.SSN__c+'Att00_'+fileName;
		}
        
        system.debug('caseId...'+caseId);
		document__c doc = New document__c();
		doc.added_by__c = [Select Id,Name from user where id=:userinfo.getuserid()].Name;
		doc.case__c = caseId;
		doc.Name__c = fileName;
        insert doc;
        system.debug('doc.id...'+doc.Id);
        return doc.Id;
    }
    
}