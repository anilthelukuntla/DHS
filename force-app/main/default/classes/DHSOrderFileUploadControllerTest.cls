@IsTest
/** Exercises the existing DHSOrderFileUploadController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSOrderFileUploadControllerTest {
    @IsTest
    static void reportsNoAttachmentsForNullParent() {
        System.assertEquals(0,
            DHSOrderFileUploadController.attachmentcountmethod(null), 'Assertion failed in DHSOrderFileUploadControllerTest at source line 7');
        System.assertEquals('',
            DHSOrderFileUploadController.attachmentnames(null), 'Assertion failed in DHSOrderFileUploadControllerTest at source line 9');
    }
}