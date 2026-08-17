/** @description Provides PDF document data used by the case document merger. */
public with sharing class CaseDocumentMergerController {
    /** @description Serializable document metadata returned to the client. */
    public class DocumentWrapper {
        /** @description Content version or legacy attachment ID. */
        @AuraEnabled public Id contentVersionId;
        /** @description Display title. */
        @AuraEnabled public String title;
        /** @description Merge sequence. */
        @AuraEnabled public Integer sequence;
        /** @description User or process that added the document. */
        @AuraEnabled public String addedBy;
        /** @description Document notes. */
        @AuraEnabled public String notes;

        /**
         * @description Creates document metadata with an initial sequence.
         * @param sequenceValue merge sequence
         */
        public DocumentWrapper(Integer sequenceValue) {
            sequence = sequenceValue;
        }

        /**
         * @description Creates document metadata from an attachment and its parent document.
         * @param attachmentRecord source PDF attachment
         * @param documentRecord parent document metadata
         * @param sequenceValue merge sequence
         */
        public DocumentWrapper(
            Attachment attachmentRecord,
            Document__c documentRecord,
            Integer sequenceValue
        ) {
            contentVersionId = attachmentRecord.Id;
            title = documentRecord.Name__c != null ? documentRecord.Name__c : attachmentRecord.Name;
            sequence = sequenceValue;
            addedBy = documentRecord.Added_By__c;
            notes = documentRecord.Notes__c;
        }
    }

    /**
     * @description Returns PDF attachment metadata for a case.
     * @param caseId case record ID
     * @return ordered document metadata
     */
    @AuraEnabled(cacheable=true)
    public static List<DocumentWrapper> getDocumentsForCase(Id caseId) {
        List<DocumentWrapper> result = new List<DocumentWrapper>();

        // Get documents related to the case with their attachments
        List<Document__c> documents = [
            SELECT Id, Name__c, Added_By__c, Notes__c, 
                   (SELECT Id, Name, ContentType FROM Attachments WHERE Name LIKE '%.pdf' LIMIT 1)
            FROM Document__c 
            WHERE Case__c = :caseId
            WITH USER_MODE
            ORDER BY CreatedDate ASC
        ];

        // Create wrapper objects with sequence
        Integer sequence = 1;
        for (Document__c doc : documents) {
            if (doc.Attachments != null && !doc.Attachments.isEmpty()) {
                Attachment att = doc.Attachments[0];
                // Use attachment ID as the "ContentVersionId" for consistency
                result.add(new DocumentWrapper(att, doc, sequence));
                sequence++;
            }
        }

        return result;
    }

    /**
     * @description Returns Base64-encoded content versions.
     * @param contentVersionIds content version IDs
     * @return Base64 data keyed by content version ID
     */
    @AuraEnabled
    public static Map<Id, String> getBase64PDFs(List<Id> contentVersionIds) {
        Map<Id, String> base64Map = new Map<Id, String>();
        for (ContentVersion cv : [
            SELECT Id, VersionData
            FROM ContentVersion
            WHERE Id IN :contentVersionIds
            WITH USER_MODE
        ]) {
            base64Map.put(cv.Id, EncodingUtil.base64Encode(cv.VersionData));
        }
        return base64Map;
    }

    /**
     * @description Normalizes the client-selected document order.
     * @param caseId case record ID
     * @param documents ordered document metadata
     */
    @AuraEnabled
    public static void updateDocumentSequence(Id caseId, List<DocumentWrapper> documents) {
        if (caseId == null || documents == null) {
            return;
        }
        for (Integer index = 0; index < documents.size(); index++) {
            documents[index].sequence = index + 1;
        }
    }

    /**
     * @description Returns Base64-encoded legacy PDF attachments.
     * @param attachmentIds attachment IDs
     * @return Base64 data keyed by attachment ID
     */
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
            WITH USER_MODE
        ];

        for (Attachment att : attachments) {
            if (att.Body != null && att.Name != null && att.Name.toLowerCase().endsWith('.pdf')) {
                String base64Data = EncodingUtil.base64Encode(att.Body);
                attachmentToBase64.put(att.Id, base64Data);
            }
        }

        return attachmentToBase64;
    }

}
