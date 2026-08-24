@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexAssertionsShouldIncludeMessage')
private class DHSGenerateInvoiceRecordsBatchTest {
    @IsTest
    static void handlesEmptyLeadScope() {
        DHSGenerateInvoiceRecordsBatch batch =
            new DHSGenerateInvoiceRecordsBatch();

        System.assertNotEquals(null, batch.start(null));
        batch.execute(null, new List<DHS_Lead__c>());
        batch.finish(null);

        System.assertEquals(0, [SELECT COUNT() FROM DHS_Invoice__c]);
    }
}
