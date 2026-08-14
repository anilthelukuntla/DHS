@IsTest
/** Exercises the existing DHSHeaderProfileController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSHeaderProfileControllerTest {
    @IsTest
    static void grantsDesignerAccessToAdministrator() {
        Test.startTest();
        DHSHeaderProfileController controller = new DHSHeaderProfileController();
        Test.stopTest();

        System.assertEquals(true, controller.canAccessDhsDesigner, 'Assertion failed in DHSHeaderProfileControllerTest at source line 11');
    }
}