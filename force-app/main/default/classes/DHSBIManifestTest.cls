@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest private class DHSBIManifestTest {
 @IsTest static void returnsNoDistribution(){System.assertEquals(null,DHSBIManifest.getDistributionPublicUrl(), 'Expected the asserted condition to hold');}
 @IsTest static void runsScheduledManifest(){
  insert new Account(Name='ISN');
  new DHSScheduleBIManifest().execute(null);
  System.assertEquals(1,[SELECT COUNT() FROM ContentVersion WHERE Title LIKE 'Manifest%'], 'Expected the asserted condition to hold');
 }
}
