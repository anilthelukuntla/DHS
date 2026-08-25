@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSForesiteFileUploadPageControllerTest {
    @IsTest
    static void savesAttachmentForCase() {
        DHS_Contact__c subject = new DHS_Contact__c(
            First_Name__c = 'DHS',
            Last_Name__c = 'File Test',
            SSN__c = '123-45-6789'
        );
        insert subject;
        DHS_Case__c caseRecord = new DHS_Case__c(
            Case_Number__c = 'UPLOAD-TEST',
            DHS_Contact__c = subject.Id,
            Subject_Type__c = 'Applicant'
        );
        insert caseRecord;
        Test.setCurrentPage(Page.DHSMultifileuploadPage);
        ApexPages.currentPage().getParameters().put('caseid', caseRecord.Id);
        Attachment upload = new Attachment(
            Body = Blob.valueOf('test'),
            Name = 'foresite-upload.txt'
        );

        DHSForesiteFileUploadPageController controller =
            new DHSForesiteFileUploadPageController(
                new ApexPages.StandardController(upload)
            );
        PageReference result = controller.saveAndRedirect();

        System.assertNotEquals(null, result, 'Expected the asserted condition to hold');
        System.assert(result.getUrl().contains(String.valueOf(caseRecord.Id)), 'Expected assertion condition to hold');
        DHS_Document__c document = [
            SELECT Id
            FROM DHS_Document__c
            WHERE DHS_Case__c = :caseRecord.Id
            LIMIT 1
        ];
        System.assertEquals(1, [
            SELECT COUNT()
            FROM Attachment
            WHERE ParentId = :document.Id
        ], 'Expected the asserted condition to hold');
    }
}