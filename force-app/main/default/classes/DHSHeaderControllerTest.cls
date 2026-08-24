@IsTest

private class DHSHeaderControllerTest {

    private static final String TEST_ALIAS = 'dhsadmin';

    @TestSetup
    static void setupData() {
        Profile systemAdministratorProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator'
            LIMIT 1
        ];

        String uniqueValue =
            String.valueOf(Datetime.now().getTime());

        User systemAdministrator = new User(
            FirstName = 'DHS',
            LastName = 'System Administrator',
            Email = 'dhs.admin.' + uniqueValue + '@example.com',
            Username =
                'dhs.admin.' + uniqueValue + '@example.com',
            Alias = TEST_ALIAS,
            ProfileId = systemAdministratorProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            User_Type__c = 'PMO'
        );

        insert systemAdministrator;

        List<PermissionSet> packageAdminPermissionSets = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'DHS_Package_System_Admin_Access'
            LIMIT 1
        ];

        if (!packageAdminPermissionSets.isEmpty()) {
            insert new PermissionSetAssignment(
                AssigneeId = systemAdministrator.Id,
                PermissionSetId = packageAdminPermissionSets[0].Id
            );
        }
    }

    @IsTest
    static void testControllerInitializationAsSystemAdministrator() {
        User adminUser = getSystemAdministrator();

        System.runAs(adminUser) {
            Test.startTest();
            DHSHeaderController controller =
                new DHSHeaderController();
            Test.stopTest();

            System.assertEquals(
                adminUser.Id,
                controller.currentUser.Id
            , 'Expected the asserted condition to hold');

            System.assertEquals(
                'PMO',
                controller.currentUser.User_Type__c
            , 'Expected the asserted condition to hold');

            System.assertEquals(true, controller.isPMOUser, 'Expected the asserted condition to hold');
            System.assertNotEquals(true, controller.isCMOUser, 'Expected the asserted condition to hold');
            System.assertNotEquals(true, controller.isINVUser, 'Expected the asserted condition to hold');
            System.assertNotEquals(true, controller.isQAUser, 'Expected the asserted condition to hold');
            System.assertNotEquals(true, controller.isSecurityUser, 'Expected the asserted condition to hold');
            System.assertNotEquals(true, controller.isCustomerUser, 'Expected the asserted condition to hold');

            List<String> allowedUserTypes =
                System.Label.DHS_Access_To_Lead_Upload.split(',');

            System.assertEquals(
                allowedUserTypes.contains('PMO'),
                controller.hasAccessToLeadUpload
            , 'Expected the asserted condition to hold');

            System.assertEquals(
                0,
                controller.unreadmessagecountforotherpages
            , 'Expected the asserted condition to hold');
        }
    }

    @IsTest
    static void testFetchMessagesAsSystemAdministrator() {
        User adminUser = getSystemAdministrator();

        System.runAs(adminUser) {
            DHSHeaderController controller =
                new DHSHeaderController();

            Test.startTest();
            controller.FetchMessages();
            Test.stopTest();

            System.assertEquals(
                0,
                controller.unreadmessagecountforotherpages,
                'The administrator should have no unread test messages'
            );
        }
    }

    @IsTest
    static void testUpdateLogoutTime() {
        User adminUser = getSystemAdministrator();

        System.runAs(adminUser) {
            DHS_TimeSheet__c timesheet =
                createTimesheet(adminUser.Id, 0);

            Test.startTest();
            DHSHeaderController.updateLogoutTime();
            Test.stopTest();

            DHS_TimeSheet__c updatedTimesheet = [
                SELECT Id, Login_Time__c, Logout_Time__c
                FROM DHS_TimeSheet__c
                WHERE Id = :timesheet.Id
            ];

            System.assertNotEquals(
                null,
                updatedTimesheet.Logout_Time__c
            , 'Expected the asserted condition to hold');
        }
    }

    @IsTest
    static void testUpdateLogoutTimeWithoutTimesheet() {
        User adminUser = getSystemAdministrator();

        System.runAs(adminUser) {
            Test.startTest();
            DHSHeaderController.updateLogoutTime();
            Test.stopTest();

            Integer timesheetCount = [
                SELECT COUNT()
                FROM DHS_TimeSheet__c
                WHERE DHS_User__c = :adminUser.Id
                AND Date__c = :Date.today()
            ];

            System.assertEquals(
                0,
                timesheetCount,
                'The method should not create a new timesheet'
            );
        }
    }

    @IsTest
    static void testUpdateIdleTime() {
        User adminUser = getSystemAdministrator();

        System.runAs(adminUser) {
            DHS_TimeSheet__c timesheet =
                createTimesheet(adminUser.Id, 5);

            Test.startTest();
            DHSHeaderController.updateIdleTime(10);
            Test.stopTest();

            DHS_TimeSheet__c updatedTimesheet = [
                SELECT Id, Idle_Minutes__c, Last_Active_Time__c
                FROM DHS_TimeSheet__c
                WHERE Id = :timesheet.Id
            ];

            System.assertEquals(
                15,
                updatedTimesheet.Idle_Minutes__c,
                'Ten minutes should be added to the existing value'
            );

            System.assertNotEquals(
                null,
                updatedTimesheet.Last_Active_Time__c
            , 'Expected the asserted condition to hold');
        }
    }

    @IsTest
    static void testUpdateIdleTimeWhenCurrentValueIsNull() {
        User adminUser = getSystemAdministrator();

        System.runAs(adminUser) {
            DHS_TimeSheet__c timesheet =
                createTimesheet(adminUser.Id, null);

            Test.startTest();
            DHSHeaderController.updateIdleTime(7);
            Test.stopTest();

            DHS_TimeSheet__c updatedTimesheet = [
                SELECT Id, Idle_Minutes__c, Last_Active_Time__c
                FROM DHS_TimeSheet__c
                WHERE Id = :timesheet.Id
            ];

            System.assertEquals(
                7,
                updatedTimesheet.Idle_Minutes__c
            , 'Expected the asserted condition to hold');

            System.assertNotEquals(
                null,
                updatedTimesheet.Last_Active_Time__c
            , 'Expected the asserted condition to hold');
        }
    }

    @IsTest
    static void testUpdateIdleTimeWithInvalidInputs() {
        User adminUser = getSystemAdministrator();

        System.runAs(adminUser) {
            DHS_TimeSheet__c timesheet =
                createTimesheet(adminUser.Id, 5);

            Test.startTest();
            DHSHeaderController.updateIdleTime(null);
            DHSHeaderController.updateIdleTime(0);
            DHSHeaderController.updateIdleTime(-10);
            Test.stopTest();

            DHS_TimeSheet__c unchangedTimesheet = [
                SELECT Idle_Minutes__c
                FROM DHS_TimeSheet__c
                WHERE Id = :timesheet.Id
            ];

            System.assertEquals(
                5,
                unchangedTimesheet.Idle_Minutes__c,
                'Invalid values should not update idle minutes'
            );
        }
    }

    @IsTest
    static void testUpdateIdleTimeWithoutTimesheet() {
        User adminUser = getSystemAdministrator();

        System.runAs(adminUser) {
            Test.startTest();
            DHSHeaderController.updateIdleTime(10);
            Test.stopTest();

            Integer timesheetCount = [
                SELECT COUNT()
                FROM DHS_TimeSheet__c
                WHERE DHS_User__c = :adminUser.Id
                AND Date__c = :Date.today()
            ];

            System.assertEquals(
                0,
                timesheetCount,
                'The method should not create a new timesheet'
            );
        }
    }

    private static User getSystemAdministrator() {
        return [
            SELECT Id, Profile.Name, User_Type__c
            FROM User
            WHERE Alias = :TEST_ALIAS
            AND Profile.Name = 'System Administrator'
            LIMIT 1
        ];
    }

    private static DHS_TimeSheet__c createTimesheet(
        Id userId,
        Decimal idleMinutes
    ) {
        DHS_TimeSheet__c timesheet = new DHS_TimeSheet__c(
            DHS_User__c = userId,
            Date__c = Date.today(),
            Login_Time__c = System.now().addHours(-1),
            Idle_Minutes__c = idleMinutes
        );

        insert timesheet;
        return timesheet;
    }
}
