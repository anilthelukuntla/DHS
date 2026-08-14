@IsTest
/** Exercises the existing DHSROIDesignerPreviewController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSROIDesignerPreviewControllerTest {
    @IsTest
    static void handlesMissingAndInvalidParameters() {
        Test.setCurrentPage(new PageReference('/apex/dhs-roi-preview-test'));
        ApexPages.currentPage().getParameters().put('id', 'not-an-id');
        ApexPages.currentPage().getParameters().put('sequenceid', 'not-an-id');

        Test.startTest();
        DHSROIDesignerPreviewController controller = new DHSROIDesignerPreviewController();
        Test.stopTest();

        System.assertEquals('', controller.customerCaseNumber, 'Assertion failed in DHSROIDesignerPreviewControllerTest at source line 15');
        System.assert(controller.renderedHtml.contains('No case was selected'), 'Assertion failed in DHSROIDesignerPreviewControllerTest at source line 16');

        DHS_Case__c caseRecord = new DHS_Case__c(
            Customer_Case_Number__c = 'CUSTOMER-100'
        );
        insert caseRecord;
        ApexPages.currentPage().getParameters().put('id', caseRecord.Id);
        ApexPages.currentPage().getParameters().remove('sequenceid');
        controller = new DHSROIDesignerPreviewController();
        System.assertEquals('CUSTOMER-100', controller.customerCaseNumber, 'Assertion failed in DHSROIDesignerPreviewControllerTest at source line 25');
    }
}