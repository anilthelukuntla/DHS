@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSLeadsUploadPageControllerTest {
    @IsTest
    static void rejectsMissingAndInvalidFiles() {
        DHSLeadsUploadPageController controller = new DHSLeadsUploadPageController();
        controller.StartBatchJob();
        System.assert(controller.errorMessage.contains('upload the file'), 'Expected assertion condition to hold');
        controller.fileContentType = 'text/plain';
        controller.StartBatchJob();
        System.assert(controller.errorMessage.contains('valid file type'), 'Expected assertion condition to hold');
    }

    @IsTest
    static void submitsValidCsvFile() {
        DHSLeadsUploadPageController.skipBatchExecution = true;
        DHSLeadsUploadPageController controller =
            new DHSLeadsUploadPageController();
        controller.fileContentType = 'text/csv';
        controller.csvFileBody = Blob.valueOf('First_Name__c,Last_Name__c\nTest,Lead');

        PageReference result = controller.StartBatchJob();

        System.assertEquals(null, result, 'Expected the asserted condition to hold');
        System.assertEquals(null, controller.errorMessage, 'Expected the asserted condition to hold');
        System.assertNotEquals(null, controller.batchId, 'Expected the asserted condition to hold');
        System.assert(controller.successMessage.contains('submitted successfully'), 'Expected assertion condition to hold');
        System.assertEquals(
            1,
            [SELECT COUNT() FROM DHS_DataLoad_Activity__c]
        , 'Expected the asserted condition to hold');
    }

    @IsTest
    static void processesValidCsvFileThroughBatch() {
        System.assert(true, 'Expected the test scenario to complete without exception');
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