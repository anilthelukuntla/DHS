@IsTest
/** Verifies conversion of legacy attachments into Salesforce Files. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class AttachmentTriggerHandlerTest {
    @IsTest
    static void convertsAttachmentAndHandlesEmptyInput() {
        Account parentRecord = new Account(Name = 'Attachment conversion test');
        insert parentRecord;
        Attachment attachmentRecord = new Attachment(
            ParentId = parentRecord.Id,
            Name = 'evidence.txt',
            Body = Blob.valueOf('evidence')
        );
        insert attachmentRecord;
        attachmentRecord = [
            SELECT Id, ParentId, Name, Body
            FROM Attachment WHERE Id = :attachmentRecord.Id
        ];

        Test.startTest();
        AttachmentTriggerHandler.convertAttachmentToFile(
            new List<Attachment>{ attachmentRecord }
        );
        AttachmentTriggerHandler.convertAttachmentToFile(new List<Attachment>());
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Attachment WHERE Id = :attachmentRecord.Id]
        , 'Assertion failed in AttachmentTriggerHandlerTest at source line 27');
        System.assertEquals(
            1,
            [SELECT COUNT() FROM ContentDocumentLink
             WHERE LinkedEntityId = :parentRecord.Id]
        , 'Assertion failed in AttachmentTriggerHandlerTest at source line 31');
    }
}