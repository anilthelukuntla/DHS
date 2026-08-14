@IsTest
/** Exercises the existing DHSContractSettingsController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSContractSettingsControllerTest {
    @IsTest
    static void loadsContractSettings() {
        DHSContractSettingsController controller =
            new DHSContractSettingsController();

        System.assertNotEquals(null, controller.contractSetting, 'Assertion failed in DHSContractSettingsControllerTest at source line 10');
    }
}