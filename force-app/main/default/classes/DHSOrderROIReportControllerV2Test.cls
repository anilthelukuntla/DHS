@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
public class DHSOrderROIReportControllerV2Test {
    
    static @IsTest void testFullCoverage() {
        // Setup test data
        DHS_Contact__c testContact = new DHS_Contact__c(
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

        DHS_Case__c testCase = new DHS_Case__c(
            DHS_Contact__c = testContact.Id,
            Subject_Type__c = 'Applicant'
        );
        insert testCase;

        // Leads
        List<DHS_Lead__c> leads = new List<DHS_Lead__c>();
        for (Integer i = 1; i <= 3; i++) {
            leads.add(new DHS_Lead__c(
                DHS_Case__c = testCase.Id,
                LeadType__c = 'Residence (RESI)',
                Coverage_Type__c = (i / 2 != 1) ? 'Personal' : 'Other',
                Item_number__c = i
            ));
        }
        leads.add(new DHS_Lead__c( // No-subheader type
            DHS_Case__c = testCase.Id,
            LeadType__c = 'Subject Interview (ESI/TESI)',
            Coverage_Type__c = 'Other',
            Item_number__c = 4
        ));
        insert leads;

        // Simulate ApexPages parameters
        Test.setCurrentPageReference(new PageReference('/apex/DHSOrderROIReportV2')); // Replace with actual page
        ApexPages.currentPage().getParameters().put('id', testCase.Id);
        ApexPages.currentPage().getParameters().put('type', 'TestType');

        Test.startTest();
        DHSOrderROIReportControllerV2 controller = new DHSOrderROIReportControllerV2();

        // Simulate lead numbers/subheaders for report generation
        Integer leadNum = 1;
        for (DHSOrderROIReportControllerV2.AllLeads ld : controller.leadRecordss) {
            if (!ld.issubheader) {
                ld.leadNumber = leadNum++;
            } else {
                ld.subheaderNumber = '1';
            }
        }

        PageReference result1 = controller.GenerateROIReport();
        System.assertNotEquals(null, result1, 'Expected the asserted condition to hold');

        PageReference result2 = controller.GenerateNattachROIReport();
        System.assertNotEquals(null, result2, 'Expected the asserted condition to hold');

        controller.currentsequenceid = null;
        controller.GenerateROIDraft();

        // Call future method directly
        Test.stopTest();
        DHSOrderROIReportControllerV2.myFutureMethod(testCase.Id, controller.roiOrderId);
    }
}