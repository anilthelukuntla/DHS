@IsTest
/** Exercises the existing DHSLeadsUploadPageController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexUnitTestClassShouldHaveAsserts')
private class DHSLeadsUploadPageControllerTest {
    @IsTest
    static void rejectsMissingAndInvalidFiles() {
        DHSLeadsUploadPageController controller = new DHSLeadsUploadPageController();
        controller.StartBatchJob();
        System.assert(controller.errorMessage.contains('upload the file'), 'Assertion failed in DHSLeadsUploadPageControllerTest at source line 9');
        controller.fileContentType = 'text/plain';
        controller.StartBatchJob();
        System.assert(controller.errorMessage.contains('valid file type'), 'Assertion failed in DHSLeadsUploadPageControllerTest at source line 12');
    }

    @IsTest
    static void submitsValidCsvFile() {
        DHSLeadsUploadPageController.skipBatchExecution = true;
        DHSLeadsUploadPageController controller =
            new DHSLeadsUploadPageController();
        controller.fileContentType = 'text/csv';
        controller.csvFileBody = Blob.valueOf('First_Name__c,Last_Name__c\nTest,Lead');

        PageReference result = controller.StartBatchJob();

        System.assertEquals(null, result, 'Assertion failed in DHSLeadsUploadPageControllerTest at source line 25');
        System.assertEquals(null, controller.errorMessage, 'Assertion failed in DHSLeadsUploadPageControllerTest at source line 26');
        System.assertNotEquals(null, controller.batchId, 'Assertion failed in DHSLeadsUploadPageControllerTest at source line 27');
        System.assert(controller.successMessage.contains('submitted successfully'), 'Assertion failed in DHSLeadsUploadPageControllerTest at source line 28');
        System.assertEquals(
            1,
            [SELECT COUNT() FROM DHS_DataLoad_Activity__c]
        , 'Assertion failed in DHSLeadsUploadPageControllerTest at source line 29');
    }

    @IsTest
    static void processesValidCsvFileThroughBatch() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
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
        DHS_DataLoad_Activity__c activityRecord = [
            SELECT Id
            FROM DHS_DataLoad_Activity__c
            LIMIT 1
        ];
        DHSLeadDataLoaderBatch parser = new DHSLeadDataLoaderBatch(
            Blob.valueOf(csv),
            activityRecord
        );
        System.assertEquals(
            3,
            parser.splitString('One,"Two, with comma",Three').size()
        , 'Assertion failed in DHSLeadsUploadPageControllerTest at source line 73');
        System.assertEquals(1, [SELECT COUNT() FROM DHS_Lead__c], 'Assertion failed in DHSLeadsUploadPageControllerTest at source line 77');
        }
    }
}