@isTest
public class OnBoardingControllerTest {

    @testSetup
    static void setupData() {

        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User u = new User(
            FirstName = 'Test',
            LastName = 'Admin',
            Alias = 'tadm',
            Email = 'testadmin@test.com',
            Username = 'testadmin' + System.currentTimeMillis() + '@test.com',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert u;

        List<Onboarding__c> onboardingList = new List<Onboarding__c>();

        for(Integer i = 0; i < 3; i++) {
            onboardingList.add(new Onboarding__c(
                First_Name__c = 'First' + i,
                Last_Name__c = 'Last' + i,
                Email__c = 'user' + i + '@test.com',
                Candidate_type__c = 'SCA',
                User_Created__c = false,
                Send_Credentials_To_User__c = true,
                Paychex_ID__c = '100' + i,
                Status__c = 'Active',
                System_Access__c = 'Intel'
            ));
        }

        insert onboardingList;
    }

    @isTest
    static void testOnboardingControllerMethods() {

        User runUser = [SELECT Id FROM User WHERE Email = 'testadmin@test.com' LIMIT 1];

        System.runAs(runUser) {

            Test.startTest();

            OnBoardingController onboardingCtrl = new OnBoardingController();

            // getItems coverage
            onboardingCtrl.getItems();

            // fetchOnboardingUsers coverage
            onboardingCtrl.fetchOnboardingUsers();

            // CreateNewUser coverage
            onboardingCtrl.newUser = new Onboarding__c(
                First_Name__c = 'New',
                Last_Name__c = 'User',
                Email__c = 'newuser@test.com',
                Candidate_type__c = 'SCA',
                User_Created__c = false,
                Send_Credentials_To_User__c = true,
                System_Access__c = 'Intel'
            );

            onboardingCtrl.UserSystemAccess = 'Intel';
            onboardingCtrl.CreateNewUser();

            // Duplicate username branch
            onboardingCtrl.newUser = new Onboarding__c(
                First_Name__c = 'Dup',
                Last_Name__c = 'User',
                Email__c = 'newuser@test.com'
            );

            onboardingCtrl.CreateNewUser();

            List<Onboarding__c> onboardings = [
                SELECT Id,
                       First_Name__c,
                       Last_Name__c,
                       Email__c,
                       System_Access__c,
                       Status__c
                FROM Onboarding__c
                LIMIT 2
            ];

            // Edit onboarding user
            onboardingCtrl.editOnboardingUserId = onboardings[0].Id;
            onboardingCtrl.editOnboardingUser();

            // Save modified onboarding user
            onboardingCtrl.editOnboardingUser.First_Name__c = 'Updated';
            onboardingCtrl.UserSystemAccess1 = 'Intel';
            onboardingCtrl.SaveModifiedOnboardingUser();

            // Bulk update coverage
            onboardingCtrl.bulkUpdatePayload =
                '[{"Id":"' + onboardings[0].Id + '","Paychex_ID__c":"99999"},' +
                '{"Id":"' + onboardings[1].Id + '","Status__c":"Inactive"}]';

            onboardingCtrl.SaveMainScreenUpdates();

            // Delete onboarding user
            onboardingCtrl.deleteOnboardingUserId = onboardings[0].Id;
            onboardingCtrl.DeleteOnboardingUser();

            // SendToDocusign coverage
            onboardingCtrl.editOnboardingUser = onboardings[1];
            onboardingCtrl.SendToDocusign();

            // addTemplate direct coverage
            DocuSignAPI.Recipient rec1 = new DocuSignAPI.Recipient();
            rec1.ID = 1;
            rec1.RoleName = 'Signer 1';

            DocuSignAPI.Recipient rec2 = new DocuSignAPI.Recipient();
            rec2.ID = 2;
            rec2.RoleName = 'Signer 2';

            onboardingCtrl.addTemplate('Template123', rec1, rec2);

            // getAllUsernames coverage
            OnBoardingController.getAllUsernames();

            Test.stopTest();
        }
    }

    @isTest
    static void testConvertBulkEditBranches() {

        Test.startTest();

        OnBoardingController ctrl = new OnBoardingController();

        List<Onboarding__c> onboardings = [
            SELECT Id
            FROM Onboarding__c
            LIMIT 1
        ];

        ctrl.bulkUpdatePayload =
            '[{' +
            '"Id":"' + onboardings[0].Id + '",' +
            '"User_Created__c":"true",' +
            '"Paychex_ID__c":"55555"' +
            '}]';

        ctrl.SaveMainScreenUpdates();

        Test.stopTest();
    }
}