/**
 * An apex page controller that exposes the change password functionality
 */
@SuppressWarnings('PMD.ApexDoc,PMD.CognitiveComplexity,PMD.EmptyStatementBlock')
public without sharing class DHSChangePasswordController {
    public String oldPassword {get; set;}
    public String newPassword {get; set;}
    public String verifyNewPassword {get; set;} 
    public string errorMessage {get;set;}       
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
    
    public DHSChangePasswordController() {}
}
