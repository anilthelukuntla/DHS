/**
* @File Name : DHSCaseDocumentController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 5, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 5, 2025 |   | Initial Version
**/

public with sharing class DHSCaseDocumentController {
    /**
     * Links uploaded content documents to a DHS case.
     * @param caseId DHS case record ID
     * @param documentIds content document IDs to link
     */
    @AuraEnabled
    public static void saveDocs(Id caseId, List<Id> documentIds) {
        // NOTE: Standard lightning-file-upload already links documents to Case
        // This is only for additional processing if business requires
        
        // Create ContentDocumentLink to associate uploaded documents with the Case
        List<ContentDocumentLink> docLinks = new List<ContentDocumentLink>();

        for (Id documentId : documentIds) {
            ContentDocumentLink docLink = new ContentDocumentLink(
                ContentDocumentId = documentId, 
                LinkedEntityId = caseId, 
                ShareType = 'V'  // 'V' means Viewer - adjust based on your sharing needs
            );
            docLinks.add(docLink);
        }

        // Insert the ContentDocumentLink records
        if (!docLinks.isEmpty()) {
            insert as user docLinks;
        }
    }
}