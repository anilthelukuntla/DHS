@IsTest
/** Exercises failed password changes without modifying a real user password. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class ISNBIChangePasswordControllerTest {
    @IsTest
    static void reportsSitePasswordFailure() {
        ISNBIChangePasswordController controller =
            new ISNBIChangePasswordController();
        controller.oldPassword = 'invalid-current-password';
        controller.newPassword = 'Replacement123!';
        controller.verifyNewPassword = 'Replacement123!';

        PageReference result = controller.changePassword();

        System.assertEquals(null, result, 'Assertion failed in ISNBIChangePasswordControllerTest at source line 15');
        System.assertNotEquals(null, controller.errorMessage, 'Assertion failed in ISNBIChangePasswordControllerTest at source line 16');
        System.assert(controller.errorMessage.contains('Testing Message1'), 'Assertion failed in ISNBIChangePasswordControllerTest at source line 17');
    }
}