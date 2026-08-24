@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSROIReportControllerV2Test {
    @IsTest
    static void buildsVersionTwoReportWithoutLeads() {
        DHS_Case__c parentCase = new DHS_Case__c(Case_Number__c = 'ROI-V2-TEST');
        insert parentCase;
        Test.setCurrentPage(Page.DHSROIReport);
        ApexPages.currentPage().getParameters().put('id', parentCase.Id);
        DHSROIReportControllerV2 controller = new DHSROIReportControllerV2();
        System.assertEquals(parentCase.Id, controller.caseRecord.Id, 'Expected the asserted condition to hold');
        System.assertEquals(0, controller.totalLeads, 'Expected the asserted condition to hold');
    }
}
