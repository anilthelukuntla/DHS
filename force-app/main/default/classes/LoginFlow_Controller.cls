/** Controls the PPF login-flow one-time-password challenge. */
@SuppressWarnings('PMD.ApexDoc, PMD.PropertyNamingConventions, PMD.ApexCRUDViolation, PMD.MethodNamingConventions')
public without sharing class LoginFlow_Controller {
    Public user UserData                {get;set;}
    Public Id OTPrecId                  {get;set;}
    Public String EnteredOTPfromUser    {get;set;}
    Public integer ErrorCount           {get;set;}
    Public String Message               {get;set;}
    Public String ErrorMessage          {get;set;}
    
    /**
     * @description This constructor is helps to get the oontext user's details
     * @return  `Object`
     */
    Public LoginFlow_Controller()
    {
        UserData = [select id,Name,Email from user where id =: Userinfo.getUserId()];
    }
    /**
     * @description This method creates the New OTP record which contails the OTP when ever the user try to login.
     * @return  `Public pagereference`
     */
    Public pagereference createOTPrecord()
    {
        ErrorCount =0;
        String randomIntegerString = string.valueof(Math.abs(Crypto.getRandomInteger()));
        String generatedOtp = randomIntegerString.substring(0,6);
        
        OTP__C otp = New OTP__C();
        otp.OTP__c = generatedOtp;
        otp.Status__c = 'Generated';
        otp.User__c = UserInfo.getUserId();
        insert otp;
        OTPrecId = otp.Id;
        return null;
    }
    /**
     * @description This method verifies the OTP whenever the user enters the latest, Not expired (Expires after 5minutes of Generating OTP), and correct OTP  then the OTP record status updates to Verified and navigates to the Home page, 
     * otherwise if the user enters the incorrect OTP more than 3 times then automatically user forced to logout.
     * @return  `Public pagereference`
     */
    Public pagereference VerifyOTP()
    {
        List<OTP__C> otpRecord = [select id,OTP__c,User__c,Status__c,Expired__c from OTP__c where id=:OTPrecId AND OTP__c =: EnteredOTPfromUser AND User__c =: UserInfo.getUserId() AND  Status__c = 'Generated' AND Expired__c = false];
        
        if(otpRecord.size()==1)
        {
            OTP__C otpRecordToVerify = otpRecord[0];
            otpRecordToVerify.Status__c = 'Verified';
            update otpRecordToVerify;
            return Auth.SessionManagement.finishLoginFlow();
        }
        else
        {
            if(ErrorCount ==2)
            {
                PageReference p = new PageReference('/secur/logout.jsp');
                p.setRedirect(true);
                return p;
            }
            else
            {
                Message = 'The OTP entered is either incorrect or expired, please verify.';
                ErrorCount ++;
                ErrorMessage =  'You have made '+ErrorCount+' invalid attempts out of 3 attempts.';
                return null;
            }
            
        }
    }
}