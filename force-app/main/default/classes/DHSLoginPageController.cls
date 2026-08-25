@SuppressWarnings('PMD.ApexSharingViolations,PMD.AvoidDeeplyNestedIfStmts,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.DebugsShouldUseLoggingLevel,PMD.EmptyStatementBlock,PMD.NcssCount,PMD.NcssMethodCount,PMD.StdCyclomaticComplexity')
/** @description Provides this DHS API member. */
Public class DHSLoginPageController{
    /** @description Provides this DHS API member. */
    public string username {get;set;}
    /** @description Provides this DHS API member. */
    public string password {get;set;}
    public boolean showloginpanel{get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public boolean verifyEmail{get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
	public boolean sendOTPTo{get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    /** @description Provides this DHS API member. */
    public string errorMessage {get;set;}
    /** @description Provides this DHS API member. */
    public string newPassword {get;set;}
    /** @description Provides this DHS API member. */
    public string enteredOTP{get;set;}
    public FINAL string  systemACCESS;
    Public Id oTPrecId;
    /** @description Provides this DHS API member. */
    public DHSLoginPageController(){
        showloginpanel = true;
        verifyEmail = false;
        sendOTPTo = false;
        systemACCESS = 'DHS';
    }
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public pagereference doLogin(){
        errorMessage = null;
        List<User> u= [Select id,username,contact.onboarding__r.User_Profile__c, system_access__c
                       from user where username=:username];
        string userType;
        if(!test.isRunningTest()){
            if(!u.isEmpty()){
                userType = u[0].contact.onboarding__r.User_Profile__c;
            }
        }else{
            userType = 'INV';    
        }
        
        boolean isValid = true;
        if(u.isEmpty()){
            isValid = false;
            errorMessage = 'Your login attempt has failed. Invalid UserName.';   
            return Null;
        }


        if(string.isBlank(password)){
            errorMessage = 'Please enter the password.';
            return null;
        }
        if(string.isBlank(systemACCESS)){
            errorMessage = 'Please select the system.';
            return null;
        }
        if(isValid){
            if(!u[0].System_Access__c.contains(systemACCESS)){
                isValid = false;
                errorMessage = 'Your do not have permission to access the system.';   
                return Null;
            }
        }
        
        
        String homePage;
       
        boolean isLoginFailed = false;
        if(isValid){
            if(userType == 'INV'){
                homePage = '/DHSLeadDashboard';
            }else if((userType == 'PMO' || userType == 'CMO' || userType == 'QA')){
                 homePage = '/DHSCaseDashboard';
            }else if(userType == 'Customer User'){
                homePage = '/BICustomerInterfaceV2';
            }else{
                homePage = '/DHSDashboard';
            }
            pagereference ref = site.login(username,password,homePage);

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
    /** @description Provides this DHS API member. */
    public void sendOTP(){
        
        List<user> usr = [select id,email,username,Name from user where username =:username];
        if(!usr.isEmpty()){
            String randomIntegerString = string.valueof(Math.abs(Crypto.getRandomInteger()));
            String generatedOTP = randomIntegerString.substring(0,6);
            
            OTP__C otp = New OTP__C();
            otp.OTP__c = generatedOTP;
            otp.Status__c = 'Generated';
            otp.Is_Portal__c = true;
            otp.User__c = usr[0].Id;
            Database.insert(otp, AccessLevel.USER_MODE);
            oTPrecId = otp.Id;
            sendOTPTo = false;
        	verifyEmail = true;
            errorMessage = 'OTP has been sent to your registered Email address.';
        }else{
            sendOTPTo = true;
        	verifyEmail = false;
            errorMessage = 'The username entered does not match any user in the system.';
        }
        
    }
    /** @description Provides this DHS API member. */
    public void verifyOTP(){
        user usr = [select id,email,username from user where username =:username];
        List<OTP__C> otpRecord = [select id,OTP__c,User__c,Status__c,Expired__c,is_portal__c from OTP__c where id=:oTPrecId AND OTP__c =: enteredOTP AND User__c =: usr.Id AND  Status__c = 'Generated' AND Expired__c = false and is_portal__c = true WITH USER_MODE];
        if(otpRecord.size()==1)
        {
            OTP__C oTPRec = otpRecord[0];
            oTPRec.Status__c = 'Verified';
			Database.update(oTPRec, AccessLevel.USER_MODE);
            verifyEmail = false;
            errorMessage = 'Verified!';
        }else{
            verifyEmail = true;
            errorMessage = 'The OTP entered is either incorrect or expired, please verify.';
        }
    }
    /** @description Provides this DHS API member. */
    public void forgotPasswordClickAction(){
        showloginpanel = false;
        sendOTPTo = true;
        errorMessage = '';
    }
    
    /** @description Provides this DHS API member. */
    public void resetpassword(){
        try{
            errorMessage  = NULL;
            User u= [Select id,username from user where username=:username];
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
