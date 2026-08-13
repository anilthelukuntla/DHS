@IsTest
/** Exercises the existing DHSCaseMessageEditorController behavior. */
@SuppressWarnings('PMD.ExcessiveParameterList')
private class DHSCaseMessageEditorControllerTest {

    private static final String CMO_EMAIL = 'cmo.user@test.example';
    private static final String INV_EMAIL = 'inv.user@test.example';
    private static final String OTHER_INV_EMAIL = 'other.inv@test.example';
    private static final String QA_EMAIL = 'qa.user@test.example';

    @TestSetup
    static void setupUsers() {
        Id profileId = UserInfo.getProfileId();
        String uniqueValue = String.valueOf(DateTime.now().getTime());

        List<User> testUsers = new List<User>{
            createUser(
                profileId,
                'CMO',
                'CMO User',
                CMO_EMAIL,
                'cmo.' + uniqueValue + '@test.example'
            ),
            createUser(
                profileId,
                'INV',
                'Investigator',
                INV_EMAIL,
                'inv.' + uniqueValue + '@test.example'
            ),
            createUser(
                profileId,
                'INV',
                'Other Investigator',
                OTHER_INV_EMAIL,
                'other.inv.' + uniqueValue + '@test.example'
            ),
            createUser(
                profileId,
                'QA',
                'QA User',
                QA_EMAIL,
                'qa.' + uniqueValue + '@test.example'
            )
        };

        insert testUsers;
    }

    private static User createUser(
        Id profileId,
        String userType,
        String lastName,
        String email,
        String username
    ) {
        return new User(
            ProfileId = profileId,
            FirstName = 'Test',
            LastName = lastName,
            Email = email,
            Username = username,
            Alias = ('t' + userType).left(8),
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            User_Type__c = userType
        );
    }

    private static User getUser(String email) {
        return [
            SELECT Id, User_Type__c
            FROM User
            WHERE Email = :email
            LIMIT 1
        ];
    }

    private static DHS_Message__c createMessage(Id fromUserId) {
        DHS_Message__c messageRecord = new DHS_Message__c(
            Subject__c = 'Original subject',
            Message_Body__c = 'Original message body',
            DHS_From_User__c = fromUserId

            /*
             * Add other required fields used by your organization here.
             *
             * Example:
             * DHS_Case__c = caseRecordId
             */
        );

        insert messageRecord;
        return messageRecord;
    }

    @IsTest
    static void cmoCanEditAnyMessage() {
        User cmoUser = getUser(CMO_EMAIL);
        User investigator = getUser(INV_EMAIL);

        System.runAs(cmoUser) {
            DHS_Message__c messageRecord = createMessage(investigator.Id);

            DHSCaseMessageEditorController controller =
                new DHSCaseMessageEditorController();

            controller.messageId = messageRecord.Id;
            controller.editedSubject = 'Subject edited by CMO';
            controller.editedBody = 'Body edited by CMO';

            Test.startTest();
            PageReference result = controller.saveMessage();
            Test.stopTest();

            System.assertEquals(null, result, 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 118');
            System.assertEquals(false, controller.hasError, 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 119');
            System.assertEquals('', controller.errorMessage, 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 120');
            System.assertEquals(true, controller.isCMOOrPMO, 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 121');
            System.assertEquals(false, controller.isInvestigator, 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 122');

            DHS_Message__c updatedMessage = [
                SELECT Subject__c, Message_Body__c
                FROM DHS_Message__c
                WHERE Id = :messageRecord.Id
            ];

            System.assertEquals(
                'Subject edited by CMO',
                updatedMessage.Subject__c
            , 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 130');
            System.assertEquals(
                'Body edited by CMO',
                updatedMessage.Message_Body__c
            , 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 134');
        }
    }

    @IsTest
    static void investigatorCanEditOwnMessage() {
        User investigator = getUser(INV_EMAIL);

        System.runAs(investigator) {
            DHS_Message__c messageRecord = createMessage(investigator.Id);

            DHSCaseMessageEditorController controller =
                new DHSCaseMessageEditorController();

            controller.messageId = messageRecord.Id;
            controller.editedSubject = 'Investigator edited subject';
            controller.editedBody = 'Investigator edited body';

            Test.startTest();
            controller.saveMessage();
            Test.stopTest();

            System.assertEquals(false, controller.hasError, 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 159');
            System.assertEquals(true, controller.isInvestigator, 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 160');
            System.assertEquals(false, controller.isCMOOrPMO, 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 161');

            DHS_Message__c updatedMessage = [
                SELECT Subject__c, Message_Body__c
                FROM DHS_Message__c
                WHERE Id = :messageRecord.Id
            ];

            System.assertEquals(
                'Investigator edited subject',
                updatedMessage.Subject__c
            , 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 169');
            System.assertEquals(
                'Investigator edited body',
                updatedMessage.Message_Body__c
            , 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 173');
        }
    }

    @IsTest
    static void investigatorCannotEditAnotherUsersMessage() {
        User investigator = getUser(INV_EMAIL);
        User otherInvestigator = getUser(OTHER_INV_EMAIL);

        System.runAs(investigator) {
            DHS_Message__c messageRecord =
                createMessage(otherInvestigator.Id);

            DHSCaseMessageEditorController controller =
                new DHSCaseMessageEditorController();

            controller.messageId = messageRecord.Id;
            controller.editedSubject = 'Unauthorized subject';
            controller.editedBody = 'Unauthorized body';

            Test.startTest();
            controller.saveMessage();
            Test.stopTest();

            System.assertEquals(true, controller.hasError, 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 200');
            System.assertEquals(
                'You do not have permission to edit this message.',
                controller.errorMessage
            , 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 201');

            DHS_Message__c unchangedMessage = [
                SELECT Subject__c, Message_Body__c
                FROM DHS_Message__c
                WHERE Id = :messageRecord.Id
            ];

            System.assertEquals(
                'Original subject',
                unchangedMessage.Subject__c
            , 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 212');
            System.assertEquals(
                'Original message body',
                unchangedMessage.Message_Body__c
            , 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 216');
        }
    }

    @IsTest
    static void otherUserTypeCannotEditMessage() {
        User qaUser = getUser(QA_EMAIL);
        User investigator = getUser(INV_EMAIL);

        System.runAs(qaUser) {
            DHS_Message__c messageRecord = createMessage(investigator.Id);

            DHSCaseMessageEditorController controller =
                new DHSCaseMessageEditorController();

            controller.messageId = messageRecord.Id;
            controller.editedSubject = 'QA edited subject';
            controller.editedBody = 'QA edited body';

            Test.startTest();
            controller.saveMessage();
            Test.stopTest();

            System.assertEquals(true, controller.hasError, 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 242');
            System.assertEquals(
                'You do not have permission to edit this message.',
                controller.errorMessage
            , 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 243');
            System.assertEquals(false, controller.isCMOOrPMO, 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 247');
            System.assertEquals(false, controller.isInvestigator, 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 248');
        }
    }

    @IsTest
    static void cmoCanDeleteMessage() {
        User cmoUser = getUser(CMO_EMAIL);
        User investigator = getUser(INV_EMAIL);

        System.runAs(cmoUser) {
            DHS_Message__c messageRecord = createMessage(investigator.Id);

            Test.startTest();
            Boolean canDelete =
                DHSCaseMessageEditorController.canDeleteMessage(
                    messageRecord.Id
                );

            DHSCaseMessageEditorController.deleteMessage(messageRecord.Id);
            Test.stopTest();

            System.assertEquals(true, canDelete, 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 269');
            System.assertEquals(
                0,
                [
                    SELECT COUNT()
                    FROM DHS_Message__c
                    WHERE Id = :messageRecord.Id
                ]
            , 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 270');
        }
    }

    @IsTest
    static void investigatorCannotDeleteMessage() {
        User investigator = getUser(INV_EMAIL);

        System.runAs(investigator) {
            DHS_Message__c messageRecord = createMessage(investigator.Id);

            Test.startTest();

            Boolean canDelete =
                DHSCaseMessageEditorController.canDeleteMessage(
                    messageRecord.Id
                );

            Boolean exceptionThrown = false;

            try {
                DHSCaseMessageEditorController.deleteMessage(
                    messageRecord.Id
                );
            } catch (AuraHandledException e) {
                exceptionThrown = true;
            }

            Test.stopTest();

            System.assertEquals(false, canDelete, 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 307');
            System.assertEquals(true, exceptionThrown, 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 308');
            System.assertEquals(
                1,
                [
                    SELECT COUNT()
                    FROM DHS_Message__c
                    WHERE Id = :messageRecord.Id
                ]
            , 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 309');
        }
    }

    @IsTest
    static void saveMessageHandlesInvalidMessageId() {
        User cmoUser = getUser(CMO_EMAIL);

        System.runAs(cmoUser) {
            DHSCaseMessageEditorController controller =
                new DHSCaseMessageEditorController();

            controller.messageId = null;
            controller.editedSubject = 'Edited subject';
            controller.editedBody = 'Edited body';

            Test.startTest();
            controller.saveMessage();
            Test.stopTest();

            System.assertEquals(true, controller.hasError, 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 336');
            System.assert(
                controller.errorMessage.startsWith('Error saving message:')
            , 'Assertion failed in DHSCaseMessageEditorControllerTest at source line 337');
        }
    }
}