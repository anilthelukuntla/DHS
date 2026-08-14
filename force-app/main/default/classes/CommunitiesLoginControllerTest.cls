/**
 * An apex page controller that exposes the site login functionality
 */
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.ApexUnitTestShouldNotUseSeeAllDataTrue, PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest global with sharing class CommunitiesLoginControllerTest {
    @IsTest(SeeAllData=true)
    global static void testCommunitiesLoginController () {
     	CommunitiesLoginController controller = new CommunitiesLoginController();
        System.assertEquals(null, controller.forwardToAuthPage(), 'Assertion failed in CommunitiesLoginControllerTest at source line 9');
    }
}