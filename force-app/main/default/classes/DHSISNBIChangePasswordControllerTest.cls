/**
 * An apex page controller that exposes the change password functionality
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts,PMD.ApexUnitTestClassShouldHaveRunAs')
public class DHSISNBIChangePasswordControllerTest {
      static @IsTest void testChangePasswordController() {
        // Instantiate a new controller with all parameters in the page
        DHSISNBIChangePasswordController controller = new DHSISNBIChangePasswordController();
        controller.oldPassword = '123456';
        controller.newPassword = 'qwerty1'; 
        controller.verifyNewPassword = 'qwerty1';                
        controller.changePassword();                          
    }    
}
