/**
 * An apex page controller that exposes the site forgot password functionality
 */
@SuppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue, PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest public with sharing class DHSForgotPasswordControllerTest {
  	 @IsTest(SeeAllData=true) public static void testForgotPasswordController() {
    	// Instantiate a new controller with all parameters in the page
    	DHSForgotPasswordController controller = new DHSForgotPasswordController();
        controller.username = 'test@salesforce.com';

        System.assertEquals(controller.forgotPassword(),null, 'Assertion failed in DHSForgotPasswordControllerTest at source line 11');
    }
}