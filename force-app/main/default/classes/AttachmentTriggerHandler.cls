Public class AttachmentTriggerHandler{
   /* public static void CreditReportToCase(List<Attachment> attachments){
        Schema.DescribeSObjectResult creditChecker = creditchecker__Credit_Report__c.sObjectType.getDescribe();
         String creditCheckerPrefix = creditChecker.getKeyPrefix(); 
         list<string> attachmentIdsForCreditReportToConsider = new list<string>();
         list<document__c> documentsToCreate = new list<document__c>();
         list<string> creditReportIds = new list<string>();
             for(Attachment att: attachments){
                 if(String.valueof(att.parentId).substring(0,3) == creditCheckerPrefix){
                     attachmentIdsForCreditReportToConsider.add(att.id);
                     creditReportIds.add(att.parentId);
                 }
                 
             }
             if(!attachmentIdsForCreditReportToConsider.isEmpty()){
                 map<string, creditchecker__Credit_Report__c> creditReportMap = new map<string, creditchecker__Credit_Report__c>([Select Id, Case__c from creditchecker__Credit_Report__c WHERE Id in:creditReportIds]);
                 for(Attachment att: attachments){
                     if(attachmentIdsForCreditReportToConsider.contains(att.id)){
                         if(creditReportMap.get(att.parentId).case__c != Null){
                             Document__c doc = new Document__c();
                             doc.Name__c = 'Credit Report';
                             doc.Added_By__c = 'Credit Report';
                             doc.case__c = creditReportMap.get(att.parentId).case__c;
                             insert doc;
                             Attachment newFile = att.clone();
                             newFile.ParentId = doc.id;
                             insert newFile;
                        }
                     }
                 }
             }
    }*/
    public static void ConvertAttachmentToFile(List<Attachment> attachments){
        list<string> attachmentIds = new list<string>();
        for(attachment attach: attachments){
            attachmentIds.add(attach.id);
            //Insert ContentVersion
            ContentVersion cVersion = new ContentVersion();
            cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
            cVersion.PathOnClient = attach.Name;//File name with extention
            cVersion.Origin = 'H';//C-Content Origin. H-Chatter Origin.
            cVersion.OwnerId = userinfo.getuserid();//Owner of the file
            cVersion.Title = attach.Name;//Name of the file
            cVersion.VersionData = attach.Body;//File content
            Insert cVersion;
             
            //After saved the Content Verison, get the ContentDocumentId
            Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;
             
            //Insert ContentDocumentLink
            ContentDocumentLink cDocLink = new ContentDocumentLink();
            cDocLink.ContentDocumentId = conDocument;//Add ContentDocumentId
            cDocLink.LinkedEntityId = attach.ParentId;//Add attachment parentId
            cDocLink.ShareType = 'V';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
            cDocLink.Visibility = 'AllUsers';//AllUsers, InternalUsers, SharedUsers
            Insert cDocLink;   
            
        }
        delete [select id from attachment where id in:attachmentIds];
    }

}