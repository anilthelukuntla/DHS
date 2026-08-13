@IsTest
/** Creates combined PPF/DHS users through the production onboarding flow. */
@SuppressWarnings('PMD.ApexDoc, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.AvoidNonRestrictiveQueries')
public class PPFDHSTestUserFactory {
    private static final String PMO_EMAIL = 'ppf.dhs.pmo.test@example.com';
    private static final String INV_EMAIL = 'ppf.dhs.inv.test@example.com';

    public static User createPmoUser() {
        insert new Account(Name = System.Label.IntelAccountName);

        Onboarding__c onboardingRecord = new Onboarding__c(
            First_Name__c = 'Combined',
            Last_Name__c = 'PMO',
            Email__c = PMO_EMAIL,
            User_Profile__c = 'PMO',
            Send_Credentials_To_User__c = false,
            System_Access__c = 'Intel;DHS',
            Status__c = 'New'
        );
        insert onboardingRecord;

        String uniqueValue = String.valueOf(DateTime.now().getTime());
        User pmoUser = new User(
            Alias = 'ppfdhpmo',
            Email = PMO_EMAIL,
            EmailEncodingKey = 'UTF-8',
            LastName = onboardingRecord.Last_Name__c,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/New_York',
            Username = 'ppf.dhs.pmo.' + uniqueValue + '@example.com',
            User_Type__c = onboardingRecord.User_Profile__c,
            System_Access__c = onboardingRecord.System_Access__c
        );

        System.runAs(new User(Id = UserInfo.getUserId())) {
            Database.UpsertResult[] upsertResults = Database.upsert(
                new List<User>{ pmoUser },
                false
            );
            OnboardingTriggerHandler.syncAccessGroupMemberships(
                new List<User>{ pmoUser },
                upsertResults
            );
            OnboardingTriggerHandler.syncPermissionSetGroupAssignments(
                new List<User>{ pmoUser },
                upsertResults
            );
            assignGroupComponentsDirectly(
                pmoUser.Id,
                new Set<String>{ 'PPF_DHS_PMO_PSG' }
            );
        }
        return pmoUser;
    }

    public static User getPmoUser() {
        return [
            SELECT Id, User_Type__c, System_Access__c
            FROM User
            WHERE Email = :PMO_EMAIL
            LIMIT 1
        ];
    }

    public static User createInvUser() {
        Onboarding__c onboardingRecord = new Onboarding__c(
            First_Name__c = 'Combined',
            Last_Name__c = 'INV',
            Email__c = INV_EMAIL,
            User_Profile__c = 'INV',
            Send_Credentials_To_User__c = false,
            System_Access__c = 'Intel;DHS',
            Status__c = 'New'
        );
        insert onboardingRecord;

        User invUser = new User(
            Alias = 'ppfdhinv',
            Email = INV_EMAIL,
            EmailEncodingKey = 'UTF-8',
            LastName = onboardingRecord.Last_Name__c,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/New_York',
            Username = 'ppf.dhs.inv.' + DateTime.now().getTime() + '@example.com',
            User_Type__c = onboardingRecord.User_Profile__c,
            System_Access__c = onboardingRecord.System_Access__c
        );
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Database.UpsertResult[] upsertResults = Database.upsert(
                new List<User>{ invUser }, false
            );
            OnboardingTriggerHandler.syncAccessGroupMemberships(
                new List<User>{ invUser }, upsertResults
            );
            OnboardingTriggerHandler.syncPermissionSetGroupAssignments(
                new List<User>{ invUser }, upsertResults
            );
            assignGroupComponentsDirectly(
                invUser.Id,
                new Set<String>{ 'PPF_DHS_INV_PSG' }
            );
        }
        return invUser;
    }

    public static User getInvUser() {
        return [
            SELECT Id, User_Type__c, System_Access__c
            FROM User WHERE Email = :INV_EMAIL LIMIT 1
        ];
    }

    private static void assignGroupComponentsDirectly(
        Id userId,
        Set<String> groupDeveloperNames
    ) {
        List<PermissionSetAssignment> assignments =
            new List<PermissionSetAssignment>();
        for (PermissionSetGroupComponent componentRecord : [
            SELECT PermissionSetId
            FROM PermissionSetGroupComponent
            WHERE PermissionSetGroup.DeveloperName IN :groupDeveloperNames
        ]) {
            assignments.add(new PermissionSetAssignment(
                AssigneeId = userId,
                PermissionSetId = componentRecord.PermissionSetId
            ));
        }
        Database.insert(assignments, false);
    }

    public static void grantCombinedPmoAccessToCurrentUser() {
        if ([SELECT COUNT() FROM Account] == 0) {
            insert new Account(Name = System.Label.IntelAccountName);
        }
        insert new Onboarding__c(
            First_Name__c = 'Current',
            Last_Name__c = 'PMO',
            Email__c = 'current.pmo.test@example.com',
            User_Profile__c = 'PMO',
            Send_Credentials_To_User__c = false,
            System_Access__c = 'Intel;DHS',
            Status__c = 'New'
        );

        List<PermissionSetAssignment> assignments =
            new List<PermissionSetAssignment>();
        for (PermissionSetGroup groupRecord : [
            SELECT Id
            FROM PermissionSetGroup
            WHERE DeveloperName IN (
                'PPF_DHS_PMO_PSG',
                'PPF_DHS_PMO_Delete_PSG'
            )
        ]) {
            assignments.add(new PermissionSetAssignment(
                AssigneeId = UserInfo.getUserId(),
                PermissionSetGroupId = groupRecord.Id
            ));
        }
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Database.insert(assignments, false);
            assignGroupComponentsDirectly(
                UserInfo.getUserId(),
                new Set<String>{ 'PPF_DHS_PMO_PSG' }
            );
        }
    }

    @IsTest
    static void provisionsCombinedPmoAccess() {
        User pmoUser = createPmoUser();
        Set<String> assignedGroups = new Set<String>();
        for (PermissionSetAssignment assignment : [
            SELECT PermissionSetGroup.DeveloperName
            FROM PermissionSetAssignment
            WHERE AssigneeId = :pmoUser.Id
            AND PermissionSetGroup.DeveloperName IN (
                'PPF_DHS_PMO_PSG',
                'PPF_DHS_PMO_Delete_PSG'
            )
        ]) {
            assignedGroups.add(
                assignment.PermissionSetGroup.DeveloperName
            );
        }
        System.assertEquals(
            new Set<String>{
                'PPF_DHS_PMO_PSG',
                'PPF_DHS_PMO_Delete_PSG'
            },
            assignedGroups,
            'The PMO user should receive both combined permission set groups.'
        );
    }
}