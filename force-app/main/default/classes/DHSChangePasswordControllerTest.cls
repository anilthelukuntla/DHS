/**
 * An apex page controller that exposes the change password functionality
 */
@SuppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue, PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest public with sharing class DHSChangePasswordControllerTest {
   	@IsTest(SeeAllData=true) public static void testChangePasswordController() {
        // Instantiate a new controller with all parameters in the page
        DHSChangePasswordController controller = new DHSChangePasswordController();
        controller.oldPassword = '123456';
        controller.newPassword = 'qwerty1';
        controller.verifyNewPassword = 'qwerty1';

        System.assertEquals(controller.changePassword(),null, 'Assertion failed in DHSChangePasswordControllerTest at source line 13');
    }
}