/**
 * An apex page controller that exposes the change password functionality
 */
@isTest
public class IntelChangePasswordControllerTest {
      static testMethod void testChangePasswordController() {
        // Instantiate a new controller with all parameters in the page
        IntelChangePasswordController controller = new IntelChangePasswordController();
        controller.oldPassword = '123456';
        controller.newPassword = 'qwerty1'; 
        controller.verifyNewPassword = 'qwerty1';                
        controller.changePassword();                          
    }    
}