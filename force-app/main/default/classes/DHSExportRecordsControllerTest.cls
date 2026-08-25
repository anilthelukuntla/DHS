@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSExportRecordsControllerTest {
    @IsTest
    static void startsExportBatch() {
        Test.startTest();
        Object result = DHSExportRecordsController.startBatch();
        Test.stopTest();

        System.assertEquals(null, result, 'Expected the asserted condition to hold');
    }

    @IsTest
    static void returnsExceptionWhenBatchCannotStart() {
        DHSExportRecordsController.forceFailure = true;

        Object result = DHSExportRecordsController.startBatch();

        System.assert(result instanceof Exception, 'Expected assertion condition to hold');
        DHSExportRecordsController.forceFailure = false;
    }
}