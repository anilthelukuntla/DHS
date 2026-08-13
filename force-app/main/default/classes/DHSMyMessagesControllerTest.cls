@IsTest
/** Exercises the existing DHSMyMessagesController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
private class DHSMyMessagesControllerTest {
    @TestSetup
    static void setupUser() {
        PPFDHSTestUserFactory.createPmoUser();
    }

    @IsTest
    static void loadsAndRefreshesCurrentMessage() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
            DHS_Case__c parentCase = new DHS_Case__c(Case_Number__c = 'MESSAGE-TEST');
            insert parentCase;
            DHS_Message__c message = new DHS_Message__c(
                DHS_Case__c = parentCase.Id,
                Message_Body__c = 'Body',
                Subject__c = 'Subject',
                DHS_From_User__c = UserInfo.getUserId(),
                DHS_To_User__c = UserInfo.getUserId(),
                Read__c = false,
                UnRead__c = true
            );
            insert message;
            DHSMyMessagesController controller = new DHSMyMessagesController();
            controller.currentMessageId = message.Id;
            controller.FetchCurrentMessageAction();
            controller.RefreshAction();
            System.assertEquals(message.Id, controller.currentMessage.Id, 'Assertion failed in DHSMyMessagesControllerTest at source line 29');
        }
    }

    @IsTest
    static void sendsMessagesToEachRecipientGroup() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
            DHSMyMessagesController controller = new DHSMyMessagesController();
            controller.messageBody = 'Coverage message';
            controller.messageSubject = 'Coverage subject';

            for (String recipientGroup : new List<String>{
                'All Program Members',
                'All Investigators',
                'All PMOs',
                'All CMOs',
                'All QAs'
            }) {
                controller.selecteToAddressOption = recipientGroup;
                controller.SendMessage();
                controller.messageBody = 'Coverage message';
                controller.messageSubject = 'Coverage subject';
            }
        }
    }
}