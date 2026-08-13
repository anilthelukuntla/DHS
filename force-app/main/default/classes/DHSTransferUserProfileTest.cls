@isTest
/** Exercises the existing DHSTransferUserProfile behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs')
public class DHSTransferUserProfileTest {
    @IsTest static void doTransfer(){
        Account accountRecord = new Account(Name = 'Transfer Account');
        insert accountRecord;
        Contact contactRecord = new Contact(
            AccountId = accountRecord.Id,
            LastName = 'Transfer'
        );
        insert contactRecord;
        Profile sourceProfile = [
            SELECT Id FROM Profile
            WHERE Name = :System.Label.DHS_from_profile
            LIMIT 1
        ];
        User portalUser = new User(
            Alias = 'trnsusr',
            CommunityNickname = 'transfer' + DateTime.now().getTime(),
            ContactId = contactRecord.Id,
            Email = 'transfer@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Transfer',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = sourceProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            Username = 'transfer.' + DateTime.now().getTime() + '@example.com'
        );
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert portalUser;
        }
        DHSTransferUserProfile.doTransfer();
        System.assertEquals(
            System.Label.DHS_to_profile,
            [SELECT Profile.Name FROM User WHERE Id = :portalUser.Id].Profile.Name
        , 'Assertion failed in DHSTransferUserProfileTest at source line 35');
    }
}