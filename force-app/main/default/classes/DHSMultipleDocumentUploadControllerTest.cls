@IsTest
/** Exercises the existing DHSMultipleDocumentUploadController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSMultipleDocumentUploadControllerTest {
    @IsTest
    static void createsDocumentAndReportsAttachments() {
        DHS_Contact__c subject = new DHS_Contact__c(
            First_Name__c = 'Upload',
            Last_Name__c = 'Subject',
            SSN__c = '123-45-6789'
        );
        insert subject;
        DHS_Case__c parentCase = new DHS_Case__c(
            DHS_Contact__c = subject.Id,
            Subject_Type__c = 'Applicant'
        );
        insert parentCase;
        String documentId =
            DHSMultipleDocumentUploadController.createDocumentRecord(parentCase.Id);
        System.assertEquals(0,
            DHSMultipleDocumentUploadController.attachmentcountmethod(documentId), 'Assertion failed in DHSMultipleDocumentUploadControllerTest at source line 20');
        System.assertEquals('',
            DHSMultipleDocumentUploadController.attachmentnames(documentId), 'Assertion failed in DHSMultipleDocumentUploadControllerTest at source line 22');
        DHSMultipleDocumentUploadController controller =
            new DHSMultipleDocumentUploadController();
        controller.caseId = parentCase.Id;
        System.assert(controller.uploadAndRedirect().getUrl().contains(parentCase.Id), 'Assertion failed in DHSMultipleDocumentUploadControllerTest at source line 27');

        String attachmentId = DHSMultipleDocumentUploadController.attachBlob(
            parentCase.Id, null, 'identity.pdf', 'application/pdf',
            EncodingUtil.base64Encode(Blob.valueOf('first')), 'f2'
        );
        System.assertNotEquals(null, attachmentId, 'Assertion failed in DHSMultipleDocumentUploadControllerTest at source line 33');
        System.assertEquals(0,
            DHSMultipleDocumentUploadController.attachmentcountmethod(
                [SELECT ParentId FROM Attachment WHERE Id = :attachmentId].ParentId), 'Assertion failed in DHSMultipleDocumentUploadControllerTest at source line 34');
        System.assert(
            DHSMultipleDocumentUploadController.attachmentnames(
                [SELECT ParentId FROM Attachment WHERE Id = :attachmentId].ParentId
            ).contains('identity.pdf'), 'Assertion failed in DHSMultipleDocumentUploadControllerTest at source line 37');

        DHSMultipleDocumentUploadController.attachBlob(
            parentCase.Id, attachmentId, 'identity.pdf', 'application/pdf',
            EncodingUtil.base64Encode(Blob.valueOf('second')), 'f3'
        );
    }
}