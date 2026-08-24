@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSMessageTriggerTest {
    @IsTest
    static void removesOfficeMarkupOnInsertAndUpdate() {
        DHS_Message__c message = new DHS_Message__c(
            Message_Body__c = '<o:p>body</o:p>',
            Subject__c = 'Trigger test',
            DHS_From_User__c = UserInfo.getUserId(),
            DHS_To_User__c = UserInfo.getUserId()
        );
        insert message;
        message = [
            SELECT Message_Body__c FROM DHS_Message__c WHERE Id = :message.Id
        ];
        System.assertEquals('body', message.Message_Body__c, 'Expected the asserted condition to hold');
        message.Message_Body__c = '<o:p>updated</o:p>';
        update message;
        System.assertEquals('updated', [
            SELECT Message_Body__c FROM DHS_Message__c WHERE Id = :message.Id
        ].Message_Body__c, 'Expected the asserted condition to hold');
    }
}
