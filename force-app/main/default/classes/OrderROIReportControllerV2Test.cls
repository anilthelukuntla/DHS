@isTest
public class OrderROIReportControllerV2Test {
    
    static testMethod void testFullCoverage() {
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

        PageReference result1 = controller.GenerateROIReport();
        System.assertNotEquals(null, result1);

        PageReference result2 = controller.GenerateNattachROIReport();
        System.assertNotEquals(null, result2);

        controller.currentsequenceid = null;
        controller.GenerateROIDraft();

        // Call future method directly
        Test.stopTest();
        OrderROIReportControllerV2.myFutureMethod(testCase.Id, controller.roiOrderId);
    }
}