@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts,PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexUnitTestMethodShouldHaveIsTestAnnotation')
public class DHSOnBoardingControllerTest {
    TestMethod static void testOnboard(){
        OnBoarding__c existingOnboarding = new OnBoarding__c(
            First_Name__c = 'Existing',
            Last_Name__c = 'Onboarding',
            Email__c = 'existing.onboarding@example.com',
            Candidate_type__c = 'SCA',
            User_Created__c = false,
            System_Access__c = 'Intel'
        );
        insert existingOnboarding;

        DHSOnBoardingController onboardingCtrl = new DHSOnBoardingController();
        onboardingCtrl.bulkUpdatePayload = JSON.serialize(
            new List<Map<String, Object>>{
                new Map<String, Object>{
                    'Id' => existingOnboarding.Id,
                    'Paychex_ID__c' => '123231'
                }
            }
        );
        onboardingCtrl.getItems();
        onboardingCtrl.SaveMainScreenUpdates();
        OnBoarding__c onboardingUser = new OnBoarding__c();
        onboardingUser.First_Name__c = 'test';
        onboardingUser.Last_Name__c = 'investigator';
        onboardingUser.Email__c = 'testinvestigator@test.com';
        onboardingUser.Candidate_type__c = 'SCA';
        onboardingUser.User_Created__c = false;
        onboardingCtrl.newuser.First_Name__c = 'test';
        onboardingCtrl.newuser.Last_Name__c = 'investigator';
        onboardingCtrl.newuser.Email__c = 'testinvestigator@test.com';
        onboardingCtrl.newuser.Candidate_type__c = 'SCA';
        onboardingCtrl.newuser.User_Created__c = false;
        onboardingCtrl.newuser.Send_Credentials_To_User__c = true;
        onboardingCtrl.CreateNewUser();
        List<OnBoarding__c> onboardings = [Select id, First_Name__c, Last_Name__c,Email__c from OnBoarding__c];
        onboardingCtrl.editOnboardingUserId = onboardings[0].id;
        onboardingCtrl.editOnboardingUser();
        onboardingCtrl.SendToDocusign();
        onboardingCtrl.SaveModifiedOnboardingUser();
        onboardingCtrl.deleteOnboardingUserId = onboardings[0].id;
        onboardingCtrl.DeleteOnboardingUser();
    }
}
