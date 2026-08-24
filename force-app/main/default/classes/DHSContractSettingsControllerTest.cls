@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSContractSettingsControllerTest {
    @IsTest
    static void loadsContractSettings() {
        DHSContractSettingsController controller =
            new DHSContractSettingsController();

        System.assertNotEquals(null, controller.contractSetting, 'Expected the asserted condition to hold');
    }
}
