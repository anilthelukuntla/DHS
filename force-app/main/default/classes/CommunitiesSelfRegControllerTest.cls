/**
 * An apex page controller that supports self registration of users in communities that allow self registration
 */
@SuppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue, PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest public with sharing class CommunitiesSelfRegControllerTest {
    @IsTest(SeeAllData=true)
    public static void testCommunitiesSelfRegController() {
        CommunitiesSelfRegController controller = new CommunitiesSelfRegController();
        controller.firstName = 'FirstName';
        controller.lastName = 'LastName';
        controller.email = 'test@force.com';
        controller.communityNickname = 'test';

        // registerUser will always return null when the page isn't accessed as a guest user
        System.assert(controller.registerUser() == null, 'Assertion failed in CommunitiesSelfRegControllerTest at source line 15');

        controller.password = 'abcd1234';
        controller.confirmPassword = 'abcd123';
        System.assert(controller.registerUser() == null, 'Assertion failed in CommunitiesSelfRegControllerTest at source line 19');

        CommunitiesSelfRegController.simulateSuccessfulRegistration = true;
        Test.setCurrentPage(Page.CommunitiesSelfReg);
        CommunitiesSelfRegController successfulController =
            new CommunitiesSelfRegController();
        successfulController.email = 'success@example.com';
        successfulController.lastName = 'Success';
        PageReference confirmation = successfulController.registerUser();
        System.assertEquals(true, confirmation.getRedirect(), 'Assertion failed in CommunitiesSelfRegControllerTest at source line 28');

        successfulController.password = 'abcd1234';
        successfulController.confirmPassword = 'abcd1234';
        successfulController.registerUser();
    }
}