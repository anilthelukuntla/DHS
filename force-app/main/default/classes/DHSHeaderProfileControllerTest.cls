@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSHeaderProfileControllerTest {
    @IsTest
    static void grantsDesignerAccessToAdministrator() {
        Test.startTest();
        DHSHeaderProfileController controller = new DHSHeaderProfileController();
        Test.stopTest();

        System.assertEquals(true, controller.canAccessDhsDesigner, 'Expected the asserted condition to hold');
    }
}