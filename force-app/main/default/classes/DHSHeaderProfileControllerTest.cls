@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexAssertionsShouldIncludeMessage')
private class DHSHeaderProfileControllerTest {
    @IsTest
    static void grantsDesignerAccessToAdministrator() {
        Test.startTest();
        DHSHeaderProfileController controller = new DHSHeaderProfileController();
        Test.stopTest();

        System.assertEquals(true, controller.canAccessDhsDesigner);
    }
}
