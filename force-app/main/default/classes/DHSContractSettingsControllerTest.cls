@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexAssertionsShouldIncludeMessage')
private class DHSContractSettingsControllerTest {
    @IsTest
    static void loadsContractSettings() {
        DHSContractSettingsController controller =
            new DHSContractSettingsController();

        System.assertNotEquals(null, controller.contractSetting);
    }
}
