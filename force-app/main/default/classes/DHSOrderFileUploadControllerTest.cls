@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSOrderFileUploadControllerTest {
    @IsTest
    static void reportsNoAttachmentsForNullParent() {
        System.assertEquals(0,
            DHSOrderFileUploadController.attachmentcountmethod(null), 'Expected the asserted condition to hold');
        System.assertEquals('',
            DHSOrderFileUploadController.attachmentnames(null), 'Expected the asserted condition to hold');
    }
}