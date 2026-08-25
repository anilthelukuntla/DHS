@IsTest
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

            System.assertEquals(null, result, 'Expected the asserted condition to hold');
            System.assertEquals(false, controller.hasError, 'Expected the asserted condition to hold');
            System.assertEquals('', controller.errorMessage, 'Expected the asserted condition to hold');
            System.assertEquals(true, controller.isCMOOrPMO, 'Expected the asserted condition to hold');
            System.assertEquals(false, controller.isInvestigator, 'Expected the asserted condition to hold');

            DHS_Message__c updatedMessage = [
                SELECT Subject__c, Message_Body__c
                FROM DHS_Message__c
                WHERE Id = :messageRecord.Id
            ];

            System.assertEquals(
                'Subject edited by CMO',
                updatedMessage.Subject__c
            , 'Expected the asserted condition to hold');
            System.assertEquals(
                'Body edited by CMO',
                updatedMessage.Message_Body__c
            , 'Expected the asserted condition to hold');
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

            System.assertEquals(false, controller.hasError, 'Expected the asserted condition to hold');
            System.assertEquals(true, controller.isInvestigator, 'Expected the asserted condition to hold');
            System.assertEquals(false, controller.isCMOOrPMO, 'Expected the asserted condition to hold');

            DHS_Message__c updatedMessage = [
                SELECT Subject__c, Message_Body__c
                FROM DHS_Message__c
                WHERE Id = :messageRecord.Id
            ];

            System.assertEquals(
                'Investigator edited subject',
                updatedMessage.Subject__c
            , 'Expected the asserted condition to hold');
            System.assertEquals(
                'Investigator edited body',
                updatedMessage.Message_Body__c
            , 'Expected the asserted condition to hold');
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

            System.assertEquals(true, controller.hasError, 'Expected the asserted condition to hold');
            System.assertEquals(
                'You do not have permission to edit this message.',
                controller.errorMessage
            , 'Expected the asserted condition to hold');

            DHS_Message__c unchangedMessage = [
                SELECT Subject__c, Message_Body__c
                FROM DHS_Message__c
                WHERE Id = :messageRecord.Id
            ];

            System.assertEquals(
                'Original subject',
                unchangedMessage.Subject__c
            , 'Expected the asserted condition to hold');
            System.assertEquals(
                'Original message body',
                unchangedMessage.Message_Body__c
            , 'Expected the asserted condition to hold');
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

            System.assertEquals(true, controller.hasError, 'Expected the asserted condition to hold');
            System.assertEquals(
                'You do not have permission to edit this message.',
                controller.errorMessage
            , 'Expected the asserted condition to hold');
            System.assertEquals(false, controller.isCMOOrPMO, 'Expected the asserted condition to hold');
            System.assertEquals(false, controller.isInvestigator, 'Expected the asserted condition to hold');
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

            System.assertEquals(true, canDelete, 'Expected the asserted condition to hold');
            System.assertEquals(
                0,
                [
                    SELECT COUNT()
                    FROM DHS_Message__c
                    WHERE Id = :messageRecord.Id
                ]
            , 'Expected the asserted condition to hold');
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

            System.assertEquals(false, canDelete, 'Expected the asserted condition to hold');
            System.assertEquals(true, exceptionThrown, 'Expected the asserted condition to hold');
            System.assertEquals(
                1,
                [
                    SELECT COUNT()
                    FROM DHS_Message__c
                    WHERE Id = :messageRecord.Id
                ]
            , 'Expected the asserted condition to hold');
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

            System.assertEquals(true, controller.hasError, 'Expected the asserted condition to hold');
            System.assert(
                controller.errorMessage.startsWith('Error saving message:')
            , 'Expected assertion condition to hold');
        }
    }
}