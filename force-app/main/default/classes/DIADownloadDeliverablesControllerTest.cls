@isTest
public class DIADownloadDeliverablesControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create a test Contact
        dia_Contact__c testContact = new dia_Contact__c(
            First_Name__c = 'Test',
            Last_Name__c = 'User',
            Email__c = 'testuser@example.com'
        );
        insert testContact;
        
        // Create a test Case
        DIA_Case__c testCase = new DIA_Case__c(
            Case_Number__c = 'CASE12345',
            Contact__c = testContact.Id,
            Case_Due_Date__c = Date.today().addDays(10)
        );
        insert testCase;

        // Create a test Document
        DIA_Document__c testDocument = new DIA_Document__c(
            Case__c = testCase.Id,
            Name__c = 'Test Document'
        );
        insert testDocument;


        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test Content Doc',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test Data'),
            FirstPublishLocationId = UserInfo.getUserId()
        );
        insert testContentVersion;

        
        ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: testContentVersion.Id].ContentDocumentId;
            cdl.LinkedEntityId = testDocument.Id;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            insert cdl;
    }

    @isTest
    static void testSearchAction() {
        Test.startTest();
        
        // Instantiate the Controller
        DIADownloadDeliverablesController controller = new DIADownloadDeliverablesController();
        controller.caseNumberToSearch = 'CASE12345';
        
        // Call the search method
        controller.SearchAction();
        
        // Validate results
        System.assertNotEquals(controller.caseRecord, null, 'Case should be found');
        System.assert(controller.showTable, 'Table should be shown when case is found');
        System.assert(controller.errorMessage == null, 'Error message should not be set');
        
        Test.stopTest();
    }

    @isTest
    static void testFetchCaseInformation_NoResults() {
        Test.startTest();
        
        // Instantiate the Controller
        DIADownloadDeliverablesController controller = new DIADownloadDeliverablesController();
        controller.FetchCaseInformation('INVALID_CASE');
        
        // Validate results
        System.assert(controller.caseRecord == null, 'No case should be found for invalid input');
        System.assertEquals(controller.errorMessage, 'No records found for the search criteria', 'Error message should be set');
        
        Test.stopTest();
    }

    @isTest
    static void testFetchDocumentInformation() {
        // Fetch the test case created in @testSetup
        DIA_Case__c testCase = [SELECT Id, Case_Number__c,Case_Due_Date__c FROM DIA_Case__c LIMIT 1];

        Test.startTest();
        
        // Instantiate the Controller
        DIADownloadDeliverablesController controller = new DIADownloadDeliverablesController();
        controller.FetchDocumentInformation(testCase.Id, testCase);
        
        // Validate results
        System.assertNotEquals(controller.downloadDocuments, null, 'Download documents should not be null');
        System.assert(controller.downloadDocuments.size() > 0, 'There should be at least one document');
        System.assertEquals(controller.downloadDocuments[0].caseNumber, testCase.Case_Number__c, 'Case number should match');
        
        Test.stopTest();
    }
}