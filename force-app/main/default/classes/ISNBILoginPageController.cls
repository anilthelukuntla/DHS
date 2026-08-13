/** Controls PPF/BI portal login, OTP verification, and password reset. */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.ApexDoc, PMD.AvoidBooleanMethodParameters, PMD.AvoidDeeplyNestedIfStmts, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.FieldNamingConventions, PMD.MethodNamingConventions, PMD.NcssCount, PMD.NcssMethodCount, PMD.PropertyNamingConventions, PMD.StdCyclomaticComplexity')
Public without sharing class ISNBILoginPageController{
    @TestVisible private static String testUserType;
    public string Username {get;set;}
    public string Password {get;set;}
    public boolean showloginpanel{get;set;}
    public boolean verifyEmail{get;set;}
	public boolean sendOTPTo{get;set;}
    public string errorMessage {get;set;}
    public string newPassword {get;set;}
    public string enteredOTP{get;set;}
    public string systemaccessselected {get;set;}
    Public Id OTPrecId; // NOPMD - legacy structure retained to preserve behavior
    public ISNBILoginPageController(){
        showloginpanel = true;
        verifyEmail = false;
        sendOTPTo = false;
    }
    
    public List<SelectOption> getsystemAccess() {
            List<SelectOption> options = new List<SelectOption>();
        	options.add(new SelectOption('','--None--'));
            options.add(new SelectOption('Intel','PPF'));
            options.add(new SelectOption('DIA','BI'));

            return options;
        }
    public pagereference doLogin(){
        errorMessage = null;
        List<User> u= [Select id,username,contact.onboarding__r.User_Profile__c, system_access__c
                       from user where username=:Username];
        string userType;
        if(!test.isRunningTest()){
            if(!u.isEmpty()){
                userType = u[0].contact.onboarding__r.User_Profile__c;
            }
        }else{
            userType = testUserType == null ? 'INV' : testUserType;
        }
        
        boolean isValid = true;
        if(u.isEmpty()){
            isValid = false;
            errorMessage = 'Your login attempt has failed. Invalid UserName.';   
            return Null;
        }
        if(string.isBlank(Password)){
            errorMessage = 'Please enter the password.';
            return null;
        }
        if(string.isBlank(systemaccessselected)){
            errorMessage = 'Please select the system.';
            return null;
        }
        if(isValid){
            if(!u[0].System_Access__c.contains(systemaccessselected)){
                isValid = false;
                errorMessage = 'Your do not have permission to access the system.';   
                return Null;
            }
        }
        
        
        String homePage;
       
        boolean isLoginFailed = false;
        if(isValid){
            if(userType == 'INV' && systemaccessselected == 'DIA'){
                homePage = '/BILeadDashboard';
            }else if((userType == 'PMO' || userType == 'CMO' || userType == 'QA')&& systemaccessselected == 'DIA'){
                 homePage = '/BICaseDashboard';
            }else if(userType == 'Customer User' && systemaccessselected == 'DIA'){
                homePage = '/BICustomerInterfaceV2';
            }else{
                homePage = '/BIDashboard';
            }
            if(userType == 'INV' && systemaccessselected == 'Intel'){
                homePage = '/LeadDashboard';
            }else if((userType == 'PMO' || userType == 'CMO' || userType == 'QA')&& systemaccessselected == 'Intel'){
                homePage = '/CaseDashboard';
            }else if(userType == 'Customer User' && systemaccessselected == 'Intel'){
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
    public void sendOTP(){
        
        List<user> usr = [select id,email,username,Name from user where username =:Username];
        if(!usr.isEmpty()){
            String randomIntegerString = string.valueof(Math.abs(Crypto.getRandomInteger()));
            String generatedOtp = randomIntegerString.substring(0,6);
            
            OTP__C otp = New OTP__C();
            otp.OTP__c = generatedOtp;
            otp.Status__c = 'Generated';
            otp.Is_Portal__c = true;
            otp.User__c = usr[0].Id;
            insert otp;
            OTPrecId = otp.Id;
            sendOTPTo = false;
        	verifyEmail = true;
            errorMessage = 'OTP has been sent to your registered Email address.';
        }else{
            sendOTPTo = true;
        	verifyEmail = false;
            errorMessage = 'The username entered does not match any user in the system.';
        }
        
    }
    public void verifyOTP(){
        user usr = [select id,email,username from user where username =:Username];
        List<OTP__C> otpRecord = [select id,OTP__c,User__c,Status__c,Expired__c,is_portal__c from OTP__c where id=:OTPrecId AND OTP__c =: enteredOTP AND User__c =: usr.Id AND  Status__c = 'Generated' AND Expired__c = false and is_portal__c = true];
        if(otpRecord.size()==1)
        {
            OTP__C otpRecordToVerify = otpRecord[0];
            otpRecordToVerify.Status__c = 'Verified';
			update otpRecordToVerify;
            verifyEmail = false;
            errorMessage = 'Verified!';
        }else{
            verifyEmail = true;
            errorMessage = 'The OTP entered is either incorrect or expired, please verify.';
        }
    }
    public void ForgotPasswordClickAction(){
        showloginpanel = false;
        sendOTPTo = true;
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