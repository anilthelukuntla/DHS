@isTest
public class ISNBILoginPageControllerTest {
    @testSetup
    static void setup() {
        // Create test data for User and related objects
        Contact contact = new Contact(LastName = 'TestContact');
        insert contact;

        Onboarding__c onboarding = new Onboarding__c();
        insert onboarding;

        contact.Onboarding__r = onboarding;
        update contact;

        User user = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuserisncorp.123@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US',
            System_Access__c = 'Intel;DIA'
        );
        insert user;
    }

    @isTest
    static void testGetSystemAccess() {
        ISNBILoginPageController controller = new ISNBILoginPageController();
        List<SelectOption> options = controller.getSystemAccess();
    }

    @isTest
    static void testDoLoginSuccess() {
        ISNBILoginPageController controller = new ISNBILoginPageController();
        controller.Username = 'testuserisncorp.123@example.com';
        controller.Password = 'password';
        controller.systemaccessselected = 'Intel';

        Test.startTest();
        PageReference ref = controller.doLogin();
        Test.stopTest();

    }

    @isTest
    static void testDoLoginFailureInvalidUsername() {
        ISNBILoginPageController controller = new ISNBILoginPageController();
        controller.Username = 'invaliduser@example.com';
        controller.Password = 'password';
        controller.systemaccessselected = 'Intel';

        Test.startTest();
        PageReference ref = controller.doLogin();
        Test.stopTest();

    }

    @isTest
    static void testDoLoginFailureNoSystemAccess() {
        ISNBILoginPageController controller = new ISNBILoginPageController();
        controller.Username = 'testuserisncorp.123@example.com';
        controller.Password = 'password';
        controller.systemaccessselected = 'InvalidSystem';

        Test.startTest();
        PageReference ref = controller.doLogin();
        Test.stopTest();

    }

    @isTest
    static void testSendOTP() {
        ISNBILoginPageController controller = new ISNBILoginPageController();
        controller.Username = 'testuserisncorp.123@example.com';
        controller.enteredOTP = '123456';

        Test.startTest();
        controller.sendOTP();
        controller.verifyOTP();
        Test.stopTest();

    }


    @isTest
    static void testForgotPasswordClickAction() {
        ISNBILoginPageController controller = new ISNBILoginPageController();

        controller.ForgotPasswordClickAction();

    }

    @isTest
    static void testResetPassword() {
        ISNBILoginPageController controller = new ISNBILoginPageController();
        controller.Username = 'testuserisncorp.123@example.com';
        controller.newPassword = 'newpassword';

        Test.startTest();
        controller.resetpassword();
        Test.stopTest();

    }
    @isTest
    static void doLoginTest1(){
        ISNBILoginPageController controller = new ISNBILoginPageController();
        controller.sendOTP();
    }
}