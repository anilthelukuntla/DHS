@isTest
public class DIAOnBoardingControllerTest {
	testmethod private static void onboardingTest(){
        Account acc = new Account(name='ISN');
        insert acc;
        DIAOnBoardingController onboardingCtrl = new DIAOnBoardingController();
        
        //System.debug('onboardingUser id in test class...'+onboardingUser.id);
        //CreateUserFromOnboardingBatch ctrl = new CreateUserFromOnboardingBatch(onboardingUser.id);
        //database.executeBatch(ctrl);
        //System.assertEquals(1, [Select Id from onboarding__c].size());
        onboardingCtrl.newuser.First_Name__c = 'test';
        onboardingCtrl.newuser.Last_Name__c = 'investigator';
        onboardingCtrl.newuser.Email__c = 'testinvestigator@test.com';
        onboardingCtrl.newuser.Candidate_type__c = 'SCA';
        onboardingCtrl.newuser.User_Created__c = false;
        onboardingCtrl.newuser.Send_Credentials_To_User__c = true;
        onboardingCtrl.newuser.status__c = 'Active';
        onboardingCtrl.newuser.system_Access__C = 'DIA';
        onboardingCtrl.newuser.user_profile__c = 'PMO';
        onboardingCtrl.CreateNewUser();
        List<onboarding__c> onboardings = [Select id, first_name__c, last_name__c,Email__c from onboarding__c];
        OnboardingTriggerHandler.OnboardingTriggerRunOnce = false;
        onboardings[0].system_access__c = 'DIA;Intel';
        update onboardings[0];
        OnboardingTriggerHandler.OnboardingTriggerRunOnce = false;
        onboardings[0].Send_Credentials_To_User__c = false;
        update onboardings[0];
        onboardingCtrl.editOnboardingUserId = onboardings[0].id;
        onboardingCtrl.editOnboardingUser();
        onboardingCtrl.SendToDocusign();
        onboardingCtrl.SaveModifiedOnboardingUser();
        onboardingCtrl.deleteOnboardingUserId = onboardings[0].id;
        onboardingCtrl.DeleteOnboardingUser();
    }
      testmethod private static void onboardingTest2(){
        Account acc = new Account(name='ISN');
        insert acc;
        DIAOnBoardingController onboardingCtrl = new DIAOnBoardingController();
        onboarding__c onboardingUser = new onboarding__c();
        onboardingUser.First_Name__c = 'test';
        onboardingUser.Last_Name__c = 'investigator';
        onboardingUser.Email__c = 'testinvestigator@test.com';
        onboardingUser.Candidate_type__c = 'SCA';
        onboardingUser.User_Created__c = false;
        
        //insert onboardingUser;
        //System.debug('onboardingUser id in test class...'+onboardingUser.id);
        //CreateUserFromOnboardingBatch ctrl = new CreateUserFromOnboardingBatch(onboardingUser.id);
        //database.executeBatch(ctrl);
        //System.assertEquals(1, [Select Id from onboarding__c].size());
        onboardingCtrl.newuser.First_Name__c = 'test';
        onboardingCtrl.newuser.Last_Name__c = 'investigator';
        onboardingCtrl.newuser.Email__c = 'testinvestigatoraSaaSASDASDASD@test.com';
        onboardingCtrl.newuser.Candidate_type__c = 'SCA';
        onboardingCtrl.newuser.User_Created__c = false;
        onboardingCtrl.newuser.Send_Credentials_To_User__c = false;
        onboardingCtrl.newuser.status__c = 'Active';
        onboardingCtrl.newuser.system_Access__C = 'DIA';
        onboardingCtrl.newuser.user_profile__c = 'PMO';
        onboardingCtrl.CreateNewUser();
        List<onboarding__c> onboardings = [Select id, first_name__c, last_name__c,Email__c from onboarding__c];
        OnboardingTriggerHandler.OnboardingTriggerRunOnce = false;
        onboardings[0].Send_Credentials_To_User__c = true;
        update onboardings[0];
        onboardingCtrl.editOnboardingUserId = onboardings[0].id;
        onboardingCtrl.editOnboardingUser();
        onboardingCtrl.SendToDocusign();
        onboardingCtrl.SaveModifiedOnboardingUser();
        onboardingCtrl.deleteOnboardingUserId = onboardings[0].id;
        onboardingCtrl.DeleteOnboardingUser();
    }
    
    testmethod private static void onboardingTest3(){
        Account acc = new Account(name='ISN');
        insert acc;
        DIAOnBoardingController onboardingCtrl = new DIAOnBoardingController();
        onboarding__c onboardingUser = new onboarding__c();
        onboardingUser.First_Name__c = 'test';
        onboardingUser.Last_Name__c = 'investigator';
        onboardingUser.Email__c = 'testinvestigator@test.com';
        onboardingUser.Candidate_type__c = 'SCA';
        onboardingUser.user_profile__c = 'Customer User';
        onboardingUser.User_Created__c = false;
        
        onboardingCtrl.newuser.First_Name__c = 'test';
        onboardingCtrl.newuser.Last_Name__c = 'investigator';
        onboardingCtrl.newuser.Email__c = 'testinvestigator@test.com';
        onboardingCtrl.newuser.Candidate_type__c = 'SCA';
        onboardingCtrl.newuser.User_Created__c = false;
        onboardingCtrl.newuser.Send_Credentials_To_User__c = true;
        onboardingCtrl.newuser.status__c = 'Active';
        onboardingCtrl.newuser.system_Access__C = 'DIA';
        onboardingCtrl.newuser.user_profile__c = 'Customer User';
        onboardingCtrl.CreateNewUser();
        List<onboarding__c> onboardings = [Select id, first_name__c, last_name__c,Email__c from onboarding__c];
        OnboardingTriggerHandler.OnboardingTriggerRunOnce = false;
        onboardings[0].system_access__c = 'DIA;Intel';
        update onboardings[0];
        OnboardingTriggerHandler.OnboardingTriggerRunOnce = false;
        onboardings[0].Send_Credentials_To_User__c = false;
        update onboardings[0];
        onboardingCtrl.editOnboardingUserId = onboardings[0].id;
        onboardingCtrl.editOnboardingUser();
        onboardingCtrl.SendToDocusign();
        onboardingCtrl.SaveModifiedOnboardingUser();
        onboardingCtrl.deleteOnboardingUserId = onboardings[0].id;
        onboardingCtrl.DeleteOnboardingUser();
    }
    @isTest
    static void testCreateCustomerUser() {
        // Setup test data
        List<Profile> profiles = [SELECT Id, Name FROM Profile WHERE Name IN ('DIA Agency User') LIMIT 1];
        Profile testProfile = profiles.isEmpty() ? null : profiles[0];

        // Create Onboarding test data
        onboarding__c onboarding1 = new onboarding__c(
            First_Name__c = 'Test',
            Last_Name__c = 'User1',
            email__c = 'testuser1@example.com',
            User_Profile__c = 'Customer User',
            status__c = 'Active',
            system_Access__c = 'Intel'
        );

        onboarding__c onboarding2 = new onboarding__c(
            First_Name__c = 'Test',
            Last_Name__c = 'User2',
            email__c = 'testuser2@example.com',
            User_Profile__c = 'Customer User',
            status__c = 'Inactive',
            system_Access__c = 'DIA'
        );

        insert new List<onboarding__c>{ onboarding1, onboarding2 };

        // Test method execution
        Test.startTest();
        OnboardingTriggerHandler.CreateCustomerUser(new List<String>{ onboarding1.Id, onboarding2.Id });
        Test.stopTest();

    }
    
    @isTest
    static void testOnInsertAction() {
        List<Onboarding__c> onboardingUsers = new List<Onboarding__c>{
            new Onboarding__c(First_name__c = 'John', Last_name__c = 'Doe', Email__c = 'john.doe@example.com', Send_Credentials_To_User__c = true, User_Profile__c = 'Customer User', system_Access__c = 'Intel')
        };
        insert onboardingUsers;
        Test.startTest();
        OnboardingTriggerHandler.OnInsertAction(onboardingUsers);
        Test.stopTest();
        
    }
    
    @isTest
    static void testOnUpdateAction() {
        List<Onboarding__c> onboardingUsers = new List<Onboarding__c>{
            new Onboarding__c(First_name__c = 'Jane', Last_name__c = 'Doe', Email__c = 'jane.doe@example.com', Send_Credentials_To_User__c = true, User_Profile__c = 'Customer User', system_Access__c = 'DIA')
        };
        insert onboardingUsers;
        
        Map<Id, Onboarding__c> oldOnboardingUsersMap = new Map<Id, Onboarding__c>(onboardingUsers);
        
        for (Onboarding__c user : onboardingUsers) {
            user.Send_Credentials_To_User__c = false;
        }
        update onboardingUsers;
        
        Test.startTest();
        OnboardingTriggerHandler.OnUpdateAction(onboardingUsers, oldOnboardingUsersMap);
        Test.stopTest();
        
    }
    
    @isTest
    static void testCreateCustomerUser1() {
        List<Onboarding__c> onboardingUsers = new List<Onboarding__c>{
            new Onboarding__c(First_name__c = 'Alice', Last_name__c = 'Smith', Email__c = 'alice.smith@example.com', User_Profile__c = 'Customer User', system_Access__c = 'Intel', Status__c = 'Inactive')
        };
        insert onboardingUsers;
        
        Test.startTest();
        OnboardingTriggerHandler.CreateCustomerUser(new List<String>{onboardingUsers[0].Id});
        Test.stopTest();
        
    }
}