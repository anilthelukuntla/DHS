@IsTest
/** Exercises the existing DHSSubjectDocumentsUploadController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSSubjectDocumentsUploadControllerTest {
    @IsTest
    static void loadsAndSubmitsDocumentRequest() {
        DHS_Case__c parentCase = new DHS_Case__c();
        insert parentCase;
        DHS_Lead__c lead = new DHS_Lead__c(DHS_Case__c = parentCase.Id);
        insert lead;
        DHS_Document_Request__c request = new DHS_Document_Request__c(
            DHS_Lead__c = lead.Id,
            To_Address__c = 'subject-documents@example.com',
            Status__c = 'Documents Requested'
        );
        insert request;
        Test.setCurrentPage(new PageReference('/apex/dhs-subject-documents-test'));
        ApexPages.currentPage().getParameters().put(
            'id', EncodingUtil.base64Encode(Blob.valueOf(request.Id)));
        DHSSubjectDocumentsUploadController controller =
            new DHSSubjectDocumentsUploadController();
        controller.submitaction();
        System.assertEquals('Documents Received', controller.documentRequest.Status__c, 'Assertion failed in DHSSubjectDocumentsUploadControllerTest at source line 23');

        Attachment uploadedFile = new Attachment(
            ParentId = request.Id,
            Name = 'identity.txt',
            Body = Blob.valueOf('test document')
        );
        insert uploadedFile;
        controller.deleteAttachmentId = uploadedFile.Id;
        controller.DeleteAttachment();
        controller.documentRequest.Subject_Comments__c = 'Verified';
        controller.autosaveaction();

        System.assertEquals(0, [SELECT COUNT() FROM Attachment WHERE Id = :uploadedFile.Id], 'Assertion failed in DHSSubjectDocumentsUploadControllerTest at source line 36');
    }
}