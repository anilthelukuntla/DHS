@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSPayrollSettingsControllerTest {
    @IsTest
    static void loadsAndUpdatesSettings() {
        DHSPayrollSettingsController controller =
            new DHSPayrollSettingsController();

        controller.UpdatePayrollSettings();

        System.assertNotEquals(null, controller.payrollSettings, 'Expected the asserted condition to hold');
    }
}