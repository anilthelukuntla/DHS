@isTest
/** Exercises the existing OrderROIReportControllerV2 behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.NcssCount')
public class OrderROIReportControllerV2Test {
    
    @IsTest static void testFullCoverage() {
        // Setup test data
        Contact__c testContact = new Contact__c(
            First_Name__c = 'Test',
            Last_Name__c = 'Contact',
            Email__c= 'test@example.com',
            Address__c = '123 Street',
            City__c = 'Testville',
            State__c = 'TS',
            Zip__c = '12345',
            SSN__c = '123-45-6789'
        );
        insert testContact;

        Case__c testCase = new Case__c(
            Contact__c = testContact.Id,
            Subject_Type__c = 'Applicant'
        );
        insert testCase;

        // Leads
        List<Lead__c> leads = new List<Lead__c>();
        for (Integer i = 1; i <= 3; i++) {
            leads.add(new Lead__c(
                Case__c = testCase.Id,
                LeadType__c = 'Residence (RESI)',
                Coverage_Type__c = (i / 2 != 1) ? 'Personal' : 'Other',
                Item_Number__c = i
            ));
        }
        leads.add(new Lead__c( // No-subheader type
            Case__c = testCase.Id,
            LeadType__c = 'Subject Interview (ESI/TESI)',
            Coverage_Type__c = 'Other',
            Item_Number__c = 4
        ));
        insert leads;

        // Simulate ApexPages parameters
        Test.setCurrentPageReference(new PageReference('/apex/YourPageName')); // Replace with actual page
        ApexPages.currentPage().getParameters().put('id', testCase.Id);
        ApexPages.currentPage().getParameters().put('type', 'TestType');

        Test.startTest();
        OrderROIReportControllerV2 controller = new OrderROIReportControllerV2();

        // Simulate lead numbers/subheaders for report generation
        Integer leadNum = 1;
        for (OrderROIReportControllerV2.AllLeads ld : controller.leadRecordss) {
            if (!ld.issubheader) {
                ld.leadNumber = leadNum++;
            } else {
                ld.subheaderNumber = '1';
            }
        }
        controller.updateLeads();
        controller.reloadLeads();
        leadNum = 1;
        for (OrderROIReportControllerV2.AllLeads leadWrapper :
            controller.leadRecordss) {
            if (!leadWrapper.issubheader) {
                leadWrapper.leadNumber = leadNum++;
            } else {
                leadWrapper.subheaderNumber = '1';
            }
        }
        controller.leadRecordss[0].headerTitle = true;
        controller.leadRecords = new List<OrderROIReportControllerV2.LeadRecord>{
            new OrderROIReportControllerV2.LeadRecord(leads[0], 1),
            new OrderROIReportControllerV2.LeadRecord(leads[1], 2)
        };

        PageReference result1 = controller.GenerateROIReport();
        System.assertNotEquals(null, result1, 'Assertion failed in OrderROIReportControllerV2Test at source line 79');

        PageReference result2 = controller.GenerateNattachROIReport();
        System.assertNotEquals(null, result2, 'Assertion failed in OrderROIReportControllerV2Test at source line 82');

        controller.currentsequenceid = null;
        controller.GenerateROIDraft();
        controller.GenerateROIDraft();
        System.assertNotEquals(null, controller.backToReport(), 'Assertion failed in OrderROIReportControllerV2Test at source line 87');

        ApexPages.currentPage().getParameters().put(
            'sequenceid', controller.currentsequenceid
        );
        OrderROIReportControllerV2 previewController =
            new OrderROIReportControllerV2();
        System.assertEquals(true, previewController.showPreview, 'Assertion failed in OrderROIReportControllerV2Test at source line 94');

        // Call future method directly
        Test.stopTest();
        System.assertNotEquals(null, controller.leadRecordss, 'Assertion failed in OrderROIReportControllerV2Test at source line 98');
    }
}