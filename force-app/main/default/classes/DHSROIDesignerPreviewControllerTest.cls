@IsTest
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

        System.assertEquals('', controller.customerCaseNumber, 'Expected the asserted condition to hold');
        System.assert(controller.renderedHtml.contains('No case was selected'), 'Expected assertion condition to hold');
    }
}
