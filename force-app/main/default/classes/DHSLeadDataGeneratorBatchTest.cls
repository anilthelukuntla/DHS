@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexAssertionsShouldIncludeMessage')
private class DHSLeadDataGeneratorBatchTest {
    @IsTest
    static void generatesLeadDataForProvidedCase() {
        DHS_Contact__c subject = new DHS_Contact__c(
            First_Name__c = 'Generator', Last_Name__c = 'Subject',
            Email__c = 'generator.subject@example.com',
            Contact_Type__c = 'Subject'
        );
        insert subject;
        DHS_Case__c caseRecord = new DHS_Case__c(DHS_Contact__c = subject.Id);
        insert caseRecord;

        DHSLeadDataGeneratorBatch batch =
            new DHSLeadDataGeneratorBatch(71, caseRecord.Id);
        batch.start(null);
        batch.execute(null, new List<DHS_Lead__c>());
        batch.finish(null);

        System.assertEquals(
            1,
            [SELECT COUNT() FROM DHS_Lead__c WHERE DHS_Case__c = :caseRecord.Id]
        );
    }

    @IsTest
    static void retainsDefaultConstructorBehavior() {
        DHSLeadDataGeneratorBatch batch = new DHSLeadDataGeneratorBatch(null);
        batch.execute(null, new List<DHS_Lead__c>());
        System.assertEquals(0, [SELECT COUNT() FROM DHS_Lead__c]);
    }
}
