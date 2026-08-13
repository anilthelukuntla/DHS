@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest private class DHSBIManifestTest {
 @IsTest static void returnsNoDistribution(){System.assertEquals(null,DHSBIManifest.getDistributionPublicUrl(), 'Assertion failed in DHSBIManifestTest at source line 3');}
 @IsTest static void runsScheduledManifest(){
  insert new Account(Name='ISN');
  new DHSScheduleBIManifest().execute(null);
  System.assertEquals(1,[SELECT COUNT() FROM ContentVersion WHERE Title LIKE 'Manifest%'], 'Assertion failed in DHSBIManifestTest at source line 7');
 }
}