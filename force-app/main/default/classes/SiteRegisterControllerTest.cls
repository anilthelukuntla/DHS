/**
 * Class containing tests for SiteRegisterController
 */
@SuppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue, PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest public with sharing class SiteRegisterControllerTest {
    @IsTest(SeeAllData=true) static void testRegistration() {
        SiteRegisterController controller = new SiteRegisterController();
        controller.username = 'test@force.com';
        controller.email = 'test@force.com';
        controller.communityNickname = 'test';
        // registerUser will always return null when the page isn't accessed as a guest user
        System.assert(controller.registerUser() == null, 'Assertion failed in SiteRegisterControllerTest at source line 12');

        controller.password = 'abcd1234';
        controller.confirmPassword = 'abcd123';
        System.assert(controller.registerUser() == null, 'Assertion failed in SiteRegisterControllerTest at source line 16');

        SiteRegisterController.simulatedPortalUserId = UserInfo.getUserId();
        controller.password = null;
        controller.confirmPassword = null;
        System.assertEquals(
            System.Page.SiteRegisterConfirm.getUrl(),
            controller.registerUser().getUrl()
        , 'Assertion failed in SiteRegisterControllerTest at source line 21');
    }
}