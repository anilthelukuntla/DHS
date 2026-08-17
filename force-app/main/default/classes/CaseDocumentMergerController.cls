/** Provides PDF document data used by the case document merger. */
@SuppressWarnings('PMD.EmptyStatementBlock, PMD.EmptyCatchBlock, PMD.EmptyIfStmt')
public with sharing class CaseDocumentMergerController {
    /** Serializable document metadata returned to the client. */
    @SuppressWarnings('PMD.FieldNamingConventions, PMD.EmptyStatementBlock, PMD.EmptyCatchBlock, PMD.EmptyIfStmt')
    public class DocumentWrapper {
        /** Content version or legacy attachment ID. */
        @AuraEnabled public Id ContentVersionId;
        /** Display title. */
        @AuraEnabled public String Title;
        /** Merge sequence. */
        @AuraEnabled public Integer Sequence;
        /** User or process that added the document. */
        @AuraEnabled public String AddedBy;
        /** Document notes. */
        @AuraEnabled public String Notes;

        /**
         * Creates document metadata for the merger UI.
         * @param versionId content version or attachment ID
         * @param title display title
         * @param sequence merge sequence
         * @param addedBy user or process that added the document
         * @param notes document notes
         */
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public DocumentWrapper(Id versionId, String title, Integer sequence, String addedBy, String notes) {
            this.ContentVersionId = versionId;
            this.Title = title;
            this.Sequence = sequence;
            this.AddedBy = addedBy;
            this.Notes = notes;
        }
    }

    /**
     * Returns PDF attachment metadata for a case.
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

    /**
     * Returns Base64-encoded content versions.
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
     * Logs the client-selected document order; persistence is not currently implemented.
     * @param caseId case record ID
     * @param documents ordered document metadata
     */
    @AuraEnabled
    public static void updateDocumentSequence(Id caseId, List<DocumentWrapper> documents) {
        // This method can be used to save the sequence if needed
        // For now, we'll just return the documents in the order they were sent
    }

    /**
     * Returns Base64-encoded legacy PDF attachments.
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