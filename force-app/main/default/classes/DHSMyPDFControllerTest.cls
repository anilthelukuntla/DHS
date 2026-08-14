@IsTest
/** Exercises the existing DHSMyPDFController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSMyPDFControllerTest {
    @IsTest
    static void setsDownloadHeader() {
        Test.setCurrentPage(new PageReference('/apex/dhs-pdf-test'));

        Test.startTest();
        new DHSMyPDFController();
        Test.stopTest();

        System.assertEquals(
            'attachment; filename=CustomReport.pdf',
            ApexPages.currentPage().getHeaders().get('Content-Disposition')
        , 'Assertion failed in DHSMyPDFControllerTest at source line 13');
    }
}