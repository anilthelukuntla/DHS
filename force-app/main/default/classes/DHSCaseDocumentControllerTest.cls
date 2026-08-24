@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSCaseDocumentControllerTest {
    @IsTest
    static void saveDocsLinksEveryDocument() {
        Account linkedRecord = new Account(Name = 'DHS document test');
        insert linkedRecord;
        ContentVersion version = new ContentVersion(
            Title = 'DHS case test document',
            PathOnClient = 'dhs-case-test.txt',
            VersionData = Blob.valueOf('test')
        );
        insert version;
        Id documentId = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :version.Id
        ].ContentDocumentId;

        Test.startTest();
        DHSCaseDocumentController.saveDocs(linkedRecord.Id, new List<Id>{ documentId });
        DHSCaseDocumentController.saveDocs(linkedRecord.Id, new List<Id>());
        Test.stopTest();

        System.assertEquals(1, [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :documentId
            AND LinkedEntityId = :linkedRecord.Id
        ], 'Expected the asserted condition to hold');
    }
}
