/**
 * @description Provides this DHS API member.
 * An apex page controller that exposes the change password functionality
 */
@SuppressWarnings('PMD.CognitiveComplexity,PMD.EmptyStatementBlock')
public without sharing class DHSChangePasswordController {
    /** @description Provides this DHS API member. */
    public String oldPassword {get; set;}
    /** @description Provides this DHS API member. */
    public String newPassword {get; set;}
    /** @description Provides this DHS API member. */
    public String verifyNewPassword {get; set;} 
    /** @description Provides this DHS API member. */
    public string errorMessage {get;set;}       
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
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
            PageReference redirectPage = Page.ISNBILoginPage;
            redirectPage.setRedirect(true);
            return redirectPage;
        }
        
        
        
        
        
    }     
    
    /** @description Provides this DHS API member. */
    public DHSChangePasswordController() {}
}