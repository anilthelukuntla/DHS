@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts,PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexAssertionsShouldIncludeMessage')
private class DHSLeadsUploadPageControllerTest {
    @IsTest
    static void rejectsMissingAndInvalidFiles() {
        DHSLeadsUploadPageController controller = new DHSLeadsUploadPageController();
        controller.StartBatchJob();
        System.assert(controller.errorMessage.contains('upload the file'));
        controller.fileContentType = 'text/plain';
        controller.StartBatchJob();
        System.assert(controller.errorMessage.contains('valid file type'));
    }

    @IsTest
    static void submitsValidCsvFile() {
        DHSLeadsUploadPageController.skipBatchExecution = true;
        DHSLeadsUploadPageController controller =
            new DHSLeadsUploadPageController();
        controller.fileContentType = 'text/csv';
        controller.csvFileBody = Blob.valueOf('First_Name__c,Last_Name__c\nTest,Lead');

        PageReference result = controller.StartBatchJob();

        System.assertEquals(null, result);
        System.assertEquals(null, controller.errorMessage);
        System.assertNotEquals(null, controller.batchId);
        System.assert(controller.successMessage.contains('submitted successfully'));
        System.assertEquals(
            1,
            [SELECT COUNT() FROM DHS_DataLoad_Activity__c]
        );
    }

    @IsTest
    static void processesValidCsvFileThroughBatch() {
        insert new Contact(
            FirstName = 'Batch',
            LastName = 'Contact',
            Email = 'batch-contact@example.com'
        );
        insert new DHS_Case__c(
            Case_Number__c = 'AG321IL'
        );

        String csv =
            'Case Number,Case Name,Item_number__c,LeadType__c,Coverage_Type__c,' +
            'Lead_Contact_Name__c,Lead_Contact_Address__c,Lead_Contact_City__c,' +
            'Lead_Contact_State__c,Lead_Contact_Zip__c,' +
            'Lead_Contact_Other_Information__c\n' +
            'AG321IL,,9,Subject Interview (ESI/TESI),Subject Interview,' +
            'John,45 South Street,Big Canyon,Texas,79848,United States';

        DHSLeadsUploadPageController controller =
            new DHSLeadsUploadPageController();
        controller.csvFileBody = Blob.valueOf(csv);
        controller.fileContentType = 'csv';

        Test.startTest();
        controller.StartBatchJob();
        Test.stopTest();
    }
}
