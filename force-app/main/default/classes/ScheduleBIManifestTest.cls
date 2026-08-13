@IsTest
/** Verifies the scheduled manifest delegates to the manifest generator. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class ScheduleBIManifestTest {
    @IsTest
    static void runsScheduledManifest() {
        insert new Account(Name = 'ISN');

        new ScheduleBIManifest().execute(null);

        System.assertEquals(
            1,
            [SELECT COUNT() FROM ContentVersion WHERE Title LIKE 'Manifest%']
        , 'Assertion failed in ScheduleBIManifestTest at source line 11');
    }
}