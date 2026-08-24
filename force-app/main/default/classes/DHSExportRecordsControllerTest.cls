@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexAssertionsShouldIncludeMessage')
private class DHSExportRecordsControllerTest {
    @IsTest
    static void startsExportBatch() {
        Test.startTest();
        Object result = DHSExportRecordsController.startBatch();
        Test.stopTest();

        System.assertEquals(null, result);
    }

    @IsTest
    static void returnsExceptionWhenBatchCannotStart() {
        DHSExportRecordsController.forceFailure = true;

        Object result = DHSExportRecordsController.startBatch();

        System.assert(result instanceof Exception);
        DHSExportRecordsController.forceFailure = false;
    }
}
