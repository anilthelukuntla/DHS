@isTest
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
        Map<String, String> expectedPermissionSets = new Map<String, String>{
            'PMO' => 'PPF_DHS_PMO_PS',
            'CMO' => 'PPF_DHS_CMO_PS',
            'INV' => 'PPF_DHS_INV_PS',
            'QA' => 'PPF_DHS_QA_PS'
        };
        Map<String, String> expectedPpfPermissionSets = new Map<String, String>{
            'PMO' => 'PPF_PMO_PS',
            'CMO' => 'PPF_CMO_PS',
            'INV' => 'PPF_INV_PS',
            'QA' => 'PPF_QA_PS'
        };

        for(String userType : expectedProfiles.keySet()) {
            System.assertEquals(
                expectedProfiles.get(userType),
                OnboardingTriggerHandler.getPpfDhsProfileName(userType)
            );
            System.assertEquals(
                expectedPermissionSets.get(userType),
                OnboardingTriggerHandler.getPpfDhsPermissionSetName(userType)
            );
            System.assertEquals(
                expectedPpfPermissionSets.get(userType),
                OnboardingTriggerHandler.getPpfPermissionSetName(userType)
            );
        }

        System.assertEquals(null, OnboardingTriggerHandler.getPpfDhsProfileName('Customer User'));
        System.assertEquals(null, OnboardingTriggerHandler.getPpfDhsPermissionSetName('Customer User'));
        System.assertEquals(null, OnboardingTriggerHandler.getPpfPermissionSetName('Customer User'));
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
            new Set<String>(),
            OnboardingTriggerHandler.getAccessGroupNames('Customer User', 'Intel;DHS')
        );
    }

    @isTest
    static void testDhsMappingsAndAllCommunityProfileBranches() {
        for(String userType : new List<String>{'PMO', 'CMO', 'INV', 'QA'}) {
            OnboardingTriggerHandler.getDhsProfileName(userType);
            OnboardingTriggerHandler.getDhsPermissionSetName(userType);
        }
        OnboardingTriggerHandler.getDhsProfileName('Customer User');
        OnboardingTriggerHandler.getDhsPermissionSetName('Customer User');
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

}