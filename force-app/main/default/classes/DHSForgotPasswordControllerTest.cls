/**
 * An apex page controller that exposes the site forgot password functionality
 */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexUnitTestShouldNotUseSeeAllDataTrue,PMD.ApexAssertionsShouldIncludeMessage')
@IsTest public with sharing class DHSForgotPasswordControllerTest {
  	 @IsTest(SeeAllData=true) public static void testForgotPasswordController() {
    	// Instantiate a new controller with all parameters in the page
    	DHSForgotPasswordController controller = new DHSForgotPasswordController();
    	controller.username = 'test@salesforce.com';     	
    
    	System.assertEquals(controller.forgotPassword(),null);
    }
}
