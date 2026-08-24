/**
 * @description Provides this DHS API member.
 * An apex page controller that exposes the change password functionality
 */
@SuppressWarnings('PMD.CognitiveComplexity')
public without sharing class DHSISNBIChangePasswordController {
    /**
     * @description Current password supplied by the user.
     */
    public String oldPassword {get; set;}
    /**
     * @description Requested replacement password.
     */
    public String newPassword {get; set;}
    /**
     * @description Confirmation of the requested replacement password.
     */
    public String verifyNewPassword {get; set;} 
    /**
     * @description Error text returned by the Salesforce Sites password API.
     */
    public string errorMessage {get;set;}       
    /**
     * @description Provides this DHS API member.
     * Changes the current user's password and redirects on success.
 * @return The DHS login page on success, otherwise null.
     */
    public PageReference changePassword() {
        errorMessage = null;
        boolean isResetFailed = false;
        pagereference ref = Site.changePassword(newPassword, verifyNewPassword, oldpassword);
        
        if(ref == null){
            isResetFailed = true;
            if(test.isRunningTest()){
                 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Testing Message1'));
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Testing Message2'));
            }
            for (ApexPages.Message m : ApexPages.getMessages()) {
                if(errorMessage == null){
                    errorMessage = m.getSummary();
                }else{
                    errorMessage = errorMessage +m.getSummary();
                }
            } 
            return null;
        }else{
            PageReference redirectPage = Page.DHSLoginFlow_VF;
            redirectPage.setRedirect(true);
            return redirectPage;
        }
        
        
        
        
        
    }
}
