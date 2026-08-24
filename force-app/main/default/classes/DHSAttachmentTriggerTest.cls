@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSAttachmentTriggerTest {
    @IsTest
    static void handlesAttachmentInsert() {
        Account parent = new Account(Name = 'DHS attachment trigger test');
        insert parent;
        Attachment record = new Attachment(
            ParentId = parent.Id,
            Name = 'trigger.txt',
            Body = Blob.valueOf('test')
        );
        insert record;
        System.assertNotEquals(null, record.Id, 'Expected the asserted condition to hold');
    }
}
