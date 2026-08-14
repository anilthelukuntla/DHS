@IsTest
/** Exercises the existing DHSExportRecordsController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSExportRecordsControllerTest {
    @IsTest
    static void startsExportBatch() {
        Test.startTest();
        Object result = DHSExportRecordsController.startBatch();
        Test.stopTest();

        System.assertEquals(null, result, 'Assertion failed in DHSExportRecordsControllerTest at source line 11');
    }

    @IsTest
    static void returnsExceptionWhenBatchCannotStart() {
        DHSExportRecordsController.forceFailure = true;

        Object result = DHSExportRecordsController.startBatch();

        System.assert(result instanceof Exception, 'Assertion failed in DHSExportRecordsControllerTest at source line 20');
        DHSExportRecordsController.forceFailure = false;
    }
}