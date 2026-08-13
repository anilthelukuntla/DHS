@IsTest
/** Exercises the PPF subject-document upload lifecycle. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class SubjectDocumentsUploadControllerTest {
    @IsTest
    static void loadsSubmitsDeletesAndAutosavesRequest() {
        Case__c caseRecord = new Case__c();
        insert caseRecord;
        Lead__c leadRecord = new Lead__c(
            Case__c = caseRecord.Id,
            LeadType__c = 'Subject Interview (ESI/TESI)',
            Coverage_Type__c = 'Subject Interview'
        );
        insert leadRecord;
        Document_Request__c requestRecord = new Document_Request__c(
            Lead__c = leadRecord.Id,
            To_Address__c = 'subject-documents@example.com',
            Status__c = 'Documents Requested'
        );
        insert requestRecord;
        Test.setCurrentPage(new PageReference('/apex/subject-documents-test'));
        ApexPages.currentPage().getParameters().put(
            'id', EncodingUtil.base64Encode(Blob.valueOf(requestRecord.Id))
        );
        SubjectDocumentsUploadController controller =
            new SubjectDocumentsUploadController();
        controller.submitaction();

        Attachment uploadedFile = new Attachment(
            ParentId = requestRecord.Id,
            Name = 'identity.txt',
            Body = Blob.valueOf('test document')
        );
        insert uploadedFile;
        controller.deleteAttachmentId = uploadedFile.Id;
        controller.DeleteAttachment();
        controller.documentRequest.Subject_Comments__c = 'Verified';
        controller.autosaveaction();

        System.assertEquals('Documents Received', controller.documentRequest.Status__c, 'Assertion failed in SubjectDocumentsUploadControllerTest at source line 40');
        System.assertEquals(0, [SELECT COUNT() FROM Attachment WHERE Id = :uploadedFile.Id], 'Assertion failed in SubjectDocumentsUploadControllerTest at source line 41');
    }
}