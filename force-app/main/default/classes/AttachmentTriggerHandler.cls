/** @description Converts legacy attachments into Salesforce Files. */
public with sharing class AttachmentTriggerHandler{
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
    /**
     * @description Converts attachments to ContentVersion and ContentDocumentLink records in bulk.
     * @param attachments attachments to convert
     */
    public static void convertAttachmentToFile(List<Attachment> attachments){
        if (attachments.isEmpty()) {
            return;
        }
        if (!ContentVersion.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isCreateable()
            || !ContentDocumentLink.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isCreateable()
            || !Attachment.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isDeletable()) {
            throw new SecurityException('Insufficient access to convert attachments to files.');
        }

        List<ContentVersion> contentVersions = new List<ContentVersion>();
        Map<Id, Attachment> attachmentById = new Map<Id, Attachment>();
        for (Attachment currentAttachment : attachments) {
            attachmentById.put(currentAttachment.Id, currentAttachment);
            contentVersions.add(new ContentVersion(
                ContentLocation = 'S',
                PathOnClient = currentAttachment.Name,
                Origin = 'H',
                OwnerId = UserInfo.getUserId(),
                Title = currentAttachment.Name,
                VersionData = currentAttachment.Body,
                FirstPublishLocationId = currentAttachment.ParentId
            ));
        }

        insert contentVersions;
        delete attachmentById.values();
    }

}
