@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSSubjectFileUploadPageControllerTest {
    @IsTest
    static void readsCaseIdFromPageParameter() {
        Test.setCurrentPage(new PageReference('/apex/dhs-subject-upload-test'));
        ApexPages.currentPage().getParameters().put('caseid', UserInfo.getUserId());

        DHSSubjectFileUploadPageController pageController =
            new DHSSubjectFileUploadPageController();

        System.assertEquals(UserInfo.getUserId(), pageController.caseId, 'Expected the asserted condition to hold');
        System.assertEquals(pageController.caseId, pageController.caseRecordIDforDocUpload, 'Expected the asserted condition to hold');
    }

    @IsTest
    static void acceptsAStandardController() {
        Attachment upload = new Attachment(
            Name = 'subject.txt',
            Body = Blob.valueOf('test'),
            ParentId = UserInfo.getUserId()
        );
        ApexPages.StandardController standardController =
            new ApexPages.StandardController(upload);

        DHSSubjectFileUploadPageController pageController =
            new DHSSubjectFileUploadPageController(standardController);

        System.assertNotEquals(null, pageController, 'Expected the asserted condition to hold');
    }

    @IsTest
    static void savesUploadedFileAsCaseDocument() {
        DHS_Contact__c subject = new DHS_Contact__c(
            First_Name__c = 'DHS',
            Last_Name__c = 'Upload Test',
            Email__c = 'dhs-upload-test@example.com',
            Contact_Type__c = 'Subject'
        );
        insert subject;
        DHS_Case__c caseRecord = new DHS_Case__c(
            DHS_Contact__c = subject.Id,
            Subject_Type__c = 'Applicant'
        );
        insert caseRecord;
        Attachment upload = new Attachment(
            Name = 'subject-document.txt',
            Body = Blob.valueOf('test')
        );
        ApexPages.StandardController standardController =
            new ApexPages.StandardController(upload);
        DHSSubjectFileUploadPageController pageController =
            new DHSSubjectFileUploadPageController(standardController);
        pageController.caseId = caseRecord.Id;

        Test.startTest();
        PageReference result = pageController.saveAndRedirect();
        Test.stopTest();

        DHS_Document__c document = [
            SELECT Id, DHS_Case__c, Name__c
            FROM DHS_Document__c
            WHERE DHS_Case__c = :caseRecord.Id
            LIMIT 1
        ];
        System.assertEquals(null, result, 'Expected the asserted condition to hold');
        System.assertEquals('subject-document.txt', document.Name__c, 'Expected the asserted condition to hold');
        System.assertEquals(1, [
            SELECT COUNT()
            FROM Attachment
            WHERE ParentId = :document.Id
            AND Name = 'subject-document.txt'
        ], 'Expected the asserted condition to hold');
    }
}
