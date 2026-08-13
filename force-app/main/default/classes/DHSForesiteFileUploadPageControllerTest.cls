@IsTest
/** Exercises the existing DHSForesiteFileUploadPageController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSForesiteFileUploadPageControllerTest {
    @IsTest
    static void savesAttachmentForCase() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
        DHS_Contact__c subject = new DHS_Contact__c(
            First_Name__c = 'DHS',
            Last_Name__c = 'File Test',
            SSN__c = '123-45-6789', Contact_Type__c = 'Subject'
        );
        insert subject;
        DHS_Case__c caseRecord = new DHS_Case__c(
            Case_Number__c = 'UPLOAD-TEST',
            DHS_Contact__c = subject.Id,
            Subject_Type__c = 'Applicant',
            DHS_Assigned_To__c = UserInfo.getUserId()
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

        System.assertNotEquals(null, result, 'Assertion failed in DHSForesiteFileUploadPageControllerTest at source line 35');
        System.assert(result.getUrl().contains(String.valueOf(caseRecord.Id)), 'Assertion failed in DHSForesiteFileUploadPageControllerTest at source line 36');
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
        ], 'Assertion failed in DHSForesiteFileUploadPageControllerTest at source line 43');
        }
    }
}