/** Controls the PPF/Foresite login and password-reset page. */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.ApexDoc, PMD.AvoidBooleanMethodParameters, PMD.AvoidDeeplyNestedIfStmts, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.MethodNamingConventions, PMD.PropertyNamingConventions, PMD.StdCyclomaticComplexity')
Public without sharing class ForeSiteLoginPageController{
    @TestVisible private static String testUserType;
    public string Username {get;set;}
    public string Password {get;set;}
    public boolean showloginpanel{get;set;}
    public string errorMessage {get;set;}
    public string newPassword {get;set;}
    public ForeSiteLoginPageController(){
        showloginpanel = true;
    }
    public pagereference doLogin(){
        errorMessage = null;
        List<User> u= [Select id,username,contact.onboarding__r.User_Profile__c
                       from user where username=:Username];
        string userType;
        if(!test.isRunningTest()){
            userType = u[0].contact.onboarding__r.User_Profile__c;   
        }else{
            userType = testUserType == null ? 'INV' : testUserType;
        }
        
        boolean isValid = true;
        if(u.isEmpty()){
            isValid = false;
            errorMessage = 'Your login attempt has failed. Invalid UserName.';   
            return Null;
        }
        String homePage;
       
        boolean isLoginFailed = false;
        if(isValid){
            if(userType == 'INV'){
                homePage = '/LeadDashboard';
            }else if(userType == 'PMO' || userType == 'CMO' || userType == 'QA'){
                 homePage = '/CaseDashboard';
            }else if(userType == 'Customer User'){
                homePage = '/CustomerInterface';
            }
            pagereference ref = site.login(Username,Password,homePage);
            if(ref == null){
                isLoginFailed=true;
                 for (ApexPages.Message m : ApexPages.getMessages()) {
                    if(errorMessage == null){
                        errorMessage = m.getSummary();
                    }else{
                        errorMessage = errorMessage +m.getSummary();
                    }
                } 
                return null;
            }else{
                return ref;
            }
        }else{
            return null;
        }
        
        
    }

    public void ForgotPasswordClickAction(){
        showloginpanel = false;
        errorMessage = '';
    }
    
    public void resetpassword(){
        try{
            errorMessage  = NULL;
            User u= [Select id,username from user where username=:Username];
            //System.resetPassword(u.id, true); 
            system.setPassword(u.id, newPassword);
            
            showloginpanel = true;
            newPassword = null;
            errorMessage = 'Password Reset succesful, Please Login.';
        }catch(Exception ex){
            errorMessage = ex.getmessage();
        }
    }
}