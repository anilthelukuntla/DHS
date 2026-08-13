@IsTest
/** Exercises the existing DHSGenerateInvoiceRecordsBatch behavior. */
private class DHSGenerateInvoiceRecordsBatchTest {
    @TestSetup
    static void setupUser() {
        PPFDHSTestUserFactory.createPmoUser();
    }

    @IsTest
    static void handlesEmptyLeadScope() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
            DHSGenerateInvoiceRecordsBatch batch =
                new DHSGenerateInvoiceRecordsBatch();

            System.assertNotEquals(null, batch.start(null), 'Assertion failed in DHSGenerateInvoiceRecordsBatchTest at source line 15');
            batch.execute(null, new List<DHS_Lead__c>());
            batch.finish(null);

            System.assertEquals(0, [SELECT COUNT() FROM DHS_Invoice__c], 'Assertion failed in DHSGenerateInvoiceRecordsBatchTest at source line 19');
        }
    }
}