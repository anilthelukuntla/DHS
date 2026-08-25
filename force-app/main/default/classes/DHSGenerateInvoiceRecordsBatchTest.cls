@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSGenerateInvoiceRecordsBatchTest {
    @IsTest
    static void handlesEmptyLeadScope() {
        DHSGenerateInvoiceRecordsBatch batch =
            new DHSGenerateInvoiceRecordsBatch();

        System.assertNotEquals(null, batch.start(null), 'Expected the asserted condition to hold');
        batch.execute(null, new List<DHS_Lead__c>());
        batch.finish(null);

        System.assertEquals(0, [SELECT COUNT() FROM DHS_Invoice__c], 'Expected the asserted condition to hold');
    }
}