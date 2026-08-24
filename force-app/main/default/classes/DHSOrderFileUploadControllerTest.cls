@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexAssertionsShouldIncludeMessage')
private class DHSOrderFileUploadControllerTest {
    @IsTest
    static void reportsNoAttachmentsForNullParent() {
        System.assertEquals(0,
            DHSOrderFileUploadController.attachmentcountmethod(null));
        System.assertEquals('',
            DHSOrderFileUploadController.attachmentnames(null));
    }
}
