/**
 * An apex page controller that takes the user to the right start page based on credentials or lack thereof
 */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest public with sharing class CommunitiesSelfRegConfirmControllerTest {
    @IsTest public static void testCommunitiesSelfRegConfirmController() {
        // Instantiate a new controller with all parameters in the page
        CommunitiesSelfRegConfirmController controller = new CommunitiesSelfRegConfirmController();
        Assert.isNotNull(controller, 'The Visualforce controller should be constructed.');
        Assert.isTrue(controller.confirmationPageReady, 'The confirmation page should be ready.');
    }
}