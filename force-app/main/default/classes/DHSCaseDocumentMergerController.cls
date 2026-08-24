/** Provides PDF document data used by the DHS case document merger. */
@SuppressWarnings('PMD.ApexDoc,PMD.EmptyStatementBlock,PMD.ExcessiveParameterList')
public with sharing class DHSCaseDocumentMergerController {
    public class DocumentWrapper {
        @AuraEnabled public Id contentVersionId;
        @AuraEnabled public String title;
        @AuraEnabled public Integer sequence;
        @AuraEnabled public String addedBy;
        @AuraEnabled public String notes;

        public DocumentWrapper(Id versionId, String title, Integer sequence, String addedBy, String notes) {
            this.contentVersionId = versionId;
            this.title = title;
            this.sequence = sequence;
            this.addedBy = addedBy;
            this.notes = notes;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<DocumentWrapper> getDocumentsForCase(Id caseId) {
        List<DocumentWrapper> result = new List<DocumentWrapper>();

        // Get documents related to the case with their attachments
        List<DHS_Document__c> documents = [
            SELECT Id, Name__c, Added_By__c, Notes__c, 
                   (SELECT Id, Name, ContentType FROM Attachments WHERE Name LIKE '%.pdf' LIMIT 1)
            FROM DHS_Document__c 
            WHERE DHS_Case__c = :caseId
            WITH USER_MODE
            ORDER BY CreatedDate ASC
        ];

        // Create wrapper objects with sequence
        Integer sequence = 1;
        for (DHS_Document__c doc : documents) {
            if (doc.Attachments != null && !doc.Attachments.isEmpty()) {
                Attachment att = doc.Attachments[0];
                // Use attachment ID as the "ContentVersionId" for consistency
                result.add(new DocumentWrapper(
                    att.Id, 
                    doc.Name__c != null ? doc.Name__c : att.Name, 
                    sequence,
                    doc.Added_By__c,
                    doc.Notes__c
                ));
                sequence++;
            }
        }

        return result;
    }

    @AuraEnabled
    public static Map<Id, String> getBase64PDFs(List<Id> contentVersionIds) {
        Map<Id, String> base64Map = new Map<Id, String>();
        for (ContentVersion cv : [
            SELECT Id, VersionData
            FROM ContentVersion
            WHERE Id IN :contentVersionIds
         WITH USER_MODE ]) {
            base64Map.put(cv.Id, EncodingUtil.base64Encode(cv.VersionData));
        }
        return base64Map;
    }

    @AuraEnabled
    public static void updateDocumentSequence(Id caseId, List<DocumentWrapper> documents) {
        // This method can be used to save the sequence if needed
        // For now, we'll just return the documents in the order they were sent
    }

    @AuraEnabled
    public static Map<Id, String> getBase64PDFsFromAttachments(List<Id> attachmentIds) {
        Map<Id, String> attachmentToBase64 = new Map<Id, String>();

        if (attachmentIds == null || attachmentIds.isEmpty()) {
            return attachmentToBase64;
        }

        List<Attachment> attachments = [
            SELECT Id, Name, Body, ContentType
            FROM Attachment
            WHERE Id IN :attachmentIds
         WITH USER_MODE ];

        for (Attachment att : attachments) {
            if (att.Body != null && att.Name != null && att.Name.toLowerCase().endsWith('.pdf')) {
                String base64Data = EncodingUtil.base64Encode(att.Body);
                attachmentToBase64.put(att.Id, base64Data);
            }
        }

        return attachmentToBase64;
    }

    @AuraEnabled(cacheable=true)
    public static List<Id> getContentVersionIdsFromAttachments(List<Id> attachmentIds) {
        List<Id> ids = new List<Id>();
        if (attachmentIds != null) {
            ids.addAll(attachmentIds);
        }
        return ids;
    }

}
