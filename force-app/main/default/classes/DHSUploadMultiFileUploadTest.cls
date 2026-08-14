@IsTest
/** Exercises the DHS multi-file upload entry points. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSUploadMultiFileUploadTest {
    @IsTest
    static void uploads() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
            DHS_Contact__c contactRecord = new DHS_Contact__c(
                First_Name__c = 'Test', Last_Name__c = 'Subject',
                Email__c = 'upload@test.com', Contact_Type__c = 'Subject',
                SSN__c = '123-45-6789'
            );
            insert contactRecord;
            DHS_Case__c caseRecord = new DHS_Case__c(
                DHS_Contact__c = contactRecord.Id,
                DHS_Assigned_To__c = UserInfo.getUserId()
            );
            insert caseRecord;
            Test.setCurrentPage(new PageReference('/apex/upload'));
            ApexPages.currentPage().getParameters().put(
                'caseid', caseRecord.Id
            );
            System.assertEquals(
                caseRecord.Id,
                new DHSUploadMultiFileUpload().caseId
            , 'Assertion failed in DHSUploadMultiFileUploadTest at source line 24');
            String documentId = DHSUploadMultiFileUpload.processUploadedFiles(
                caseRecord.Id, 'file.pdf'
            );
            System.assertNotEquals(null, documentId, 'Assertion failed in DHSUploadMultiFileUploadTest at source line 31');
        }
    }
}