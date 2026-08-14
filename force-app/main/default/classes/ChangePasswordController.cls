/**
 * An apex page controller that exposes the change password functionality
 */
public with sharing class ChangePasswordController {
    /** Current password entered by the user. */
    public String oldPassword {get; set;}
    /** Requested new password. */
    public String newPassword {get; set;}
    /** Confirmation of the requested new password. */
    public String verifyNewPassword {get; set;}        
    
    /**
     * Changes the current site user's password.
     * @return the page selected by Salesforce Sites after the password change
     */
    public PageReference changePassword() {
        return Site.changePassword(newPassword, verifyNewPassword, oldpassword);    
    }     
}