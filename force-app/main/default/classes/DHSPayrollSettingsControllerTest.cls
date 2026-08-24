@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexAssertionsShouldIncludeMessage')
private class DHSPayrollSettingsControllerTest {
    @IsTest
    static void loadsAndUpdatesSettings() {
        DHSPayrollSettingsController controller =
            new DHSPayrollSettingsController();

        controller.UpdatePayrollSettings();

        System.assertNotEquals(null, controller.payrollSettings);
    }
}
