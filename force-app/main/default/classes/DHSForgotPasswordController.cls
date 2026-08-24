/**
 * @description Provides this DHS API member.
 * An apex page controller that exposes the site forgot password functionality
 */
public with sharing class DHSForgotPasswordController {
    /**
     * @description Username whose password should be reset.
     */
    public String username {get; set;}   
	
	/**
	 * @description Provides this DHS API member.
	 * Requests a password reset and redirects when Salesforce accepts it.
 * @return The confirmation page on success, otherwise null.
	 */
  	public PageReference forgotPassword() {
  		boolean success = Site.forgotPassword(username);
  		PageReference pr = Page.ForgotPasswordConfirm;
  		pr.setRedirect(true);
  		
  		if (success) {  			
  			return pr;
  		}
  		return null;
  	}
}
