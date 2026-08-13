@IsTest
/** Exercises the existing DHSPayrollSettingsController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSPayrollSettingsControllerTest {
    @IsTest
    static void loadsAndUpdatesSettings() {
        DHSPayrollSettingsController controller =
            new DHSPayrollSettingsController();

        controller.UpdatePayrollSettings();

        System.assertNotEquals(null, controller.payrollSettings, 'Assertion failed in DHSPayrollSettingsControllerTest at source line 12');
    }
}