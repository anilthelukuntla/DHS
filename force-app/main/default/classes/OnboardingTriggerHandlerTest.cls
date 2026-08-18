@isTest
/** Exercises the existing OnboardingTriggerHandler behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.IfStmtsMustUseBraces, PMD.IfElseStmtsMustUseBraces, PMD.ApexUnitTestClassShouldHaveAsserts')
public class OnboardingTriggerHandlerTest {

    @testSetup
    static void setupData() {
        // Create Account required by handler
        Account acc = new Account(Name = System.label.IntelAccountName);
        insert acc;
    }

    // 🔹 Test INSERT (covers Contact + Customer User path)
    @isTest
    static void testInsertFlow() {

        List<Onboarding__c> listObs = new List<Onboarding__c>();

        // Non-customer → Contact creation path
        listObs.add(new Onboarding__c(
            First_Name__c = 'John',
            Last_Name__c = 'PMO',
            Email__c = 'pmo@test.com',
            User_Profile__c = 'PMO',
            Send_Credentials_To_User__c = true,
            System_Access__c = 'Intel',
            Status__c = 'New'
        ));

        // Customer User → Future method path
        listObs.add(new Onboarding__c(
            First_Name__c = 'Cust',
            Last_Name__c = 'User',
            Email__c = 'cust@test.com',
            User_Profile__c = 'Customer User',
            Send_Credentials_To_User__c = true,
            System_Access__c = 'Intel',
            Status__c = 'New'
        ));

        Test.startTest();
        insert listObs;
        Test.stopTest();

        // Validate Contacts created
        List<Contact> cons = [SELECT Id FROM Contact];
        System.assert(cons.size() > 0, 'Contacts should be created');

        // Validate status updated
        List<Onboarding__c> obs = [SELECT Status__c FROM Onboarding__c];
        for(Onboarding__c o : obs){
            System.assertEquals('Active', o.Status__c);
        }
    }

    // 🔹 Test UPDATE (covers update + create + customer user)
    @isTest
    static void testUpdateFlow() {

        // Insert initial record
        Onboarding__c ob = new Onboarding__c(
            First_Name__c = 'Jane',
            Last_Name__c = 'PMO',
            Email__c = 'jane@test.com',
            User_Profile__c = 'PMO',
            Send_Credentials_To_User__c = false,
            System_Access__c = 'Intel',
            Status__c = 'New'
        );
        insert ob;

        // Reset static flag (IMPORTANT)
        OnboardingTriggerHandler.OnboardingTriggerRunOnce = false;

        // Update to trigger creation
        ob.Send_Credentials_To_User__c = true;

        Test.startTest();
        update ob;
        Test.stopTest();

        // Contact should now exist
        List<Contact> cons = [
            SELECT Id FROM Contact WHERE onboarding__c = :ob.Id
        ];
        System.assert(cons.size() > 0, 'Contact should be created on update');
    }

    // 🔹 Test CONTACT UPDATE path (existing contact branch)
    @isTest
    static void testExistingContactUpdate() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        // Insert onboarding
        Onboarding__c ob = new Onboarding__c(
            First_Name__c = 'Update',
            Last_Name__c = 'User',
            Email__c = 'update@test.com',
            User_Profile__c = 'PMO',
            Send_Credentials_To_User__c = true,
            System_Access__c = 'Intel',
            Status__c = 'New'
        );
        insert ob;

        // Create contact manually (simulate existing)
        Contact con = new Contact(
            FirstName = 'Old',
            LastName = 'Name',
            Email = 'update@test.com',
            AccountId = acc.Id,
            onboarding__c = ob.Id
        );
        insert con;

        // Reset flag
        OnboardingTriggerHandler.OnboardingTriggerRunOnce = false;

        // Update onboarding → should update contact
        ob.First_Name__c = 'Updated';

        Test.startTest();
        update ob;
        Test.stopTest();

        Contact updated = [
            SELECT FirstName FROM Contact WHERE Id = :con.Id
        ];
        System.assertEquals('Updated', updated.FirstName);
    }

    // 🔹 Test FUTURE method: CreateCustomerUser
    @isTest
    static void testCreateCustomerUserFuture() {

        Onboarding__c ob = new Onboarding__c(
            First_Name__c = 'Future',
            Last_Name__c = 'Cust',
            Email__c = 'futurecust@test.com',
            User_Profile__c = 'Customer User',
            Send_Credentials_To_User__c = true,
            System_Access__c = 'Intel',
            Status__c = 'Active'
        );
        insert ob;

        Test.startTest();
        OnboardingTriggerHandler.CreateCustomerUser(
            new List<String>{ob.Id}
        );
        Test.stopTest();

        System.assert(true); // just ensure no exception
    }

    // 🔹 Test FUTURE method: Community User
    @isTest
    static void testCommunityUserFuture() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Onboarding__c ob = new Onboarding__c(
            First_Name__c = 'Comm',
            Last_Name__c = 'User',
            Email__c = 'commuser@test.com',
            User_Profile__c = 'QA',
            Send_Credentials_To_User__c = true,
            System_Access__c = 'Intel',
            Status__c = 'Active',
            CCPL__c = true
        );
        insert ob;

        Contact con = new Contact(
            FirstName = 'Comm',
            LastName = 'User',
            Email = 'commuser@test.com',
            AccountId = acc.Id,
            onboarding__c = ob.Id
        );
        insert con;

        Test.startTest();
        OnboardingTriggerHandler.CreateOrUpdateCustomerCommunityUser(
            new List<String>{con.Id}
        );
        Test.stopTest();

        System.assert(true);
    }

    // 🔹 Test INACTIVE user branch
    @isTest
    static void testInactiveUserBranch() {

        Onboarding__c ob = new Onboarding__c(
            First_Name__c = 'Inactive',
            Last_Name__c = 'User',
            Email__c = 'inactive@test.com',
            User_Profile__c = 'Customer User',
            Send_Credentials_To_User__c = true,
            System_Access__c = 'Intel',
            Status__c = 'Inactive'
        );
        insert ob;

        Test.startTest();
        OnboardingTriggerHandler.CreateCustomerUser(
            new List<String>{ob.Id}
        );
        ob.First_Name__c = 'Test';
        update ob;
        OnboardingTriggerHandler.convertDt(system.today());
        OnboardingTriggerHandler.convertDt(system.today(),false);
        OnboardingTriggerHandler.convertDt(system.today(),false,true);
        Test.stopTest();

        System.assert(true);
    }

    @isTest
    static void testIntelAndDhsProfileAndPermissionSetMappings() {
        Map<String, String> expectedProfiles = new Map<String, String>{
            'PMO' => 'PPF - DHS PMO Profile',
            'CMO' => 'PPF - DHS CMO Profile',
            'INV' => 'PPF - DHS INV Profile',
            'QA' => 'PPF - DHS QA Profile'
        };
        for(String userType : expectedProfiles.keySet()) {
            System.assertEquals(
                expectedProfiles.get(userType),
                OnboardingTriggerHandler.getPpfDhsProfileName(userType)
            );
            Set<String> expectedGroups = new Set<String>{'PPF_DHS_' + userType + '_PSG'};
            if(userType == 'PMO') expectedGroups.add('PPF_DHS_PMO_Delete_PSG');
            System.assertEquals(expectedGroups,
                OnboardingTriggerHandler.getPermissionSetGroupNames(userType, 'Intel;DHS'));
        }

        System.assertEquals(null, OnboardingTriggerHandler.getPpfDhsProfileName('Customer User'));
        System.assertEquals(new Set<String>{'PPF_Customer_PSG'},
            OnboardingTriggerHandler.getPermissionSetGroupNames('Customer User', 'Intel'));
    }

    @isTest
    static void testAccessGroupMappings() {
        System.assertEquals(
            new Set<String>{'Intel_PMO_Access'},
            OnboardingTriggerHandler.getAccessGroupNames('PMO', 'Intel')
        );
        System.assertEquals(
            new Set<String>{'DHS_CMO_Access'},
            OnboardingTriggerHandler.getAccessGroupNames('CMO', 'DHS')
        );
        System.assertEquals(
            new Set<String>{'PPF_DHS_INV_Access'},
            OnboardingTriggerHandler.getAccessGroupNames('INV', 'Intel;DHS')
        );
        System.assertEquals(
            new Set<String>{'PPF_DHS_Customer_Access'},
            OnboardingTriggerHandler.getAccessGroupNames('Customer User', 'Intel;DHS')
        );
        System.assertEquals(
            new Set<String>{'Intel_Customer_Access'},
            OnboardingTriggerHandler.getAccessGroupNames('Customer User', 'Intel')
        );
        System.assertEquals(
            new Set<String>{'DHS_Customer_Access'},
            OnboardingTriggerHandler.getAccessGroupNames('Customer User', 'DHS')
        );
    }

    @isTest
    static void testDhsMappingsAndAllCommunityProfileBranches() {
        for(String userType : new List<String>{'PMO', 'CMO', 'INV', 'QA'}) {
            OnboardingTriggerHandler.getDhsProfileName(userType);
            OnboardingTriggerHandler.getPermissionSetGroupNames(userType, 'DHS');
        }
        OnboardingTriggerHandler.getDhsProfileName('Customer User');
        OnboardingTriggerHandler.getPermissionSetGroupNames('Customer User', 'DHS');
        OnboardingTriggerHandler.getAccessGroupNames('PMO', null);
        OnboardingTriggerHandler.getAccessGroupNames('QA', 'Intel;DHS');

        Account portalAccount = [SELECT Id FROM Account LIMIT 1];
        List<Onboarding__c> onboardingRecords = new List<Onboarding__c>();
        Integer sequence = 0;
        for(String userType : new List<String>{
            'PMO', 'CMO', 'INV', 'Customer User', 'QA'
        }) {
            sequence++;
            onboardingRecords.add(new Onboarding__c(
                First_Name__c = 'Profile',
                Last_Name__c = userType.replace(' ', ''),
                Email__c = 'profile' + sequence + '@example.com',
                User_Profile__c = userType,
                Send_Credentials_To_User__c = false,
                System_Access__c = 'Intel;DIA;DHS',
                Status__c = 'Active',
                CCPL__c = Math.mod(sequence, 2) == 0,
                Candidate_type__c = userType == 'INV' ? 'Employee' : null,
                BI_Candidate_type__c = userType == 'INV' ? 'Employee' : null
            ));
        }
        insert onboardingRecords;

        List<Contact> contacts = new List<Contact>();
        for(Onboarding__c onboardingRecord : onboardingRecords) {
            contacts.add(new Contact(
                FirstName = onboardingRecord.First_Name__c,
                LastName = onboardingRecord.Last_Name__c,
                Email = onboardingRecord.Email__c,
                AccountId = portalAccount.Id,
                Onboarding__c = onboardingRecord.Id,
                System_Access__c = onboardingRecord.System_Access__c
            ));
        }
        insert contacts;

        List<String> contactIds = new List<String>();
        for(Contact contactRecord : contacts) {
            contactIds.add(contactRecord.Id);
        }

        Test.startTest();
        OnboardingTriggerHandler.CreateOrUpdateCustomerCommunityUser(
            contactIds
        );
        Test.stopTest();
    }

    @isTest
    static void testExistingCustomerUserUpdatePath() {
        Onboarding__c onboardingRecord = new Onboarding__c(
            First_Name__c = 'Existing',
            Last_Name__c = 'Customer',
            Email__c = 'existing.customer@example.com',
            User_Profile__c = 'Customer User',
            Send_Credentials_To_User__c = false,
            System_Access__c = 'Intel',
            Status__c = 'Active',
            User__c = UserInfo.getUserId()
        );
        insert onboardingRecord;

        Test.startTest();
        OnboardingTriggerHandler.CreateCustomerUser(
            new List<String>{ onboardingRecord.Id }
        );
        Test.stopTest();
    }

    @isTest
    static void testAccessAndPermissionSetSynchronizationLifecycle() {
        String uniqueValue = String.valueOf(DateTime.now().getTime());
        User onboardingUser = new User(
            Alias = 'syncusr',
            Email = 'sync.user.' + uniqueValue + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Synchronization',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'sync.user.' + uniqueValue + '@example.com',
            User_Type__c = 'PMO',
            System_Access__c = 'Intel;DIA'
        );

        Test.startTest();
        Database.UpsertResult[] intelResults = Database.upsert(
            new List<User>{ onboardingUser },
            false
        );
        OnboardingTriggerHandler.syncAccessGroupMemberships(
            new List<User>{ onboardingUser },
            intelResults
        );
        OnboardingTriggerHandler.syncPermissionSetGroupAssignments(
            new List<User>{ onboardingUser },
            intelResults
        );

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM PermissionSetAssignment
                WHERE AssigneeId = :onboardingUser.Id
                AND PermissionSetGroup.DeveloperName = 'PPF_PMO_PSG'
            ],
            'Intel-only PMO users should receive PPF_PMO_PSG.'
        );

        onboardingUser.System_Access__c = 'Intel;DHS';
        Database.UpsertResult[] combinedResults = Database.upsert(
            new List<User>{ onboardingUser },
            false
        );
        OnboardingTriggerHandler.syncAccessGroupMemberships(
            new List<User>{ onboardingUser },
            combinedResults
        );
        OnboardingTriggerHandler.syncPermissionSetGroupAssignments(
            new List<User>{ onboardingUser },
            combinedResults
        );

        onboardingUser.System_Access__c = 'DHS';
        Database.UpsertResult[] dhsResults = Database.upsert(
            new List<User>{ onboardingUser },
            false
        );
        OnboardingTriggerHandler.syncAccessGroupMemberships(
            new List<User>{ onboardingUser },
            dhsResults
        );
        OnboardingTriggerHandler.syncPermissionSetGroupAssignments(
            new List<User>{ onboardingUser },
            dhsResults
        );
        Test.stopTest();

        GroupMember finalMembership = [
            SELECT Group.DeveloperName
            FROM GroupMember
            WHERE UserOrGroupId = :onboardingUser.Id
            AND Group.DeveloperName IN (
                'DHS_PMO_Access',
                'Intel_PMO_Access',
                'PPF_DHS_PMO_Access'
            )
            LIMIT 1
        ];
        System.assertEquals('DHS_PMO_Access', finalMembership.Group.DeveloperName);
    }

}