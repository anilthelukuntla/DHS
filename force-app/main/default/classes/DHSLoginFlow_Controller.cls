/**
 * @description Controls the DHS login-flow one-time-password challenge.
 */
@SuppressWarnings('PMD.UnusedMethod')
public without sharing class DHSLoginFlow_Controller {
    /** @description Provides this DHS API member. */
    Public user userData                {get;set;}
    /** @description Provides this DHS API member. */
    Public Id oTPrecId                  {get;set;}
    /** @description Provides this DHS API member. */
    Public String enteredOTPfromUser    {get;set;}
    /** @description Provides this DHS API member. */
    Public integer errorCount           {get;set;}
    /** @description Provides this DHS API member. */
    Public String message               {get;set;}
    /** @description Provides this DHS API member. */
    Public String errorMessage          {get;set;}
    
    /**
     * @description This constructor is helps to get the context user's details
     */
    Public DHSLoginFlow_Controller()
    {
        userData = [select id,Name,Email from user where id =: Userinfo.getUserId() ];
    }
    /**
     * @description This method creates the New OTP record which contails the OTP when ever the user try to login.
 * @return  `Public pagereference`
     */
    Public pagereference createOTPrecord()
    {
        errorCount =0;
        String randomIntegerString = string.valueof(Math.abs(Crypto.getRandomInteger()));
        String generatedOtp = randomIntegerString.substring(0,6);
        
        DHS_OTP__c otp = new DHS_OTP__c();
        otp.OTP__c = generatedOtp;
        otp.Status__c = 'Generated';
        otp.DHS_User__c = UserInfo.getUserId();
        Database.insert(otp, AccessLevel.USER_MODE);
        //database.insert(otp,false,AccessLevel.USER_MODE);
        oTPrecId = otp.Id;
        return null;
    }
    /**
     * @description This method verifies the OTP whenever the user enters the latest, Not expired (Expires after 5minutes of Generating OTP), and correct OTP  then the OTP record status updates to Verified and navigates to the Home page, 
     * otherwise if the user enters the incorrect OTP more than 3 times then automatically user forced to logout.
 * @return  `Public pagereference`
     */
    Public pagereference verifyOTP()
    {
        List<DHS_OTP__c> otpRecord = [select id,OTP__c,DHS_User__c,Status__c,Expired__c from DHS_OTP__c where id=:oTPrecId AND OTP__c = : enteredOTPfromUser AND DHS_User__c =: UserInfo.getUserId() AND  Status__c = 'Generated' AND Expired__c = false WITH USER_MODE ];
        
        if(otpRecord.size()==1)
        {
            DHS_OTP__c otpRecordToVerify = otpRecord[0];
            otpRecordToVerify.Status__c = 'Verified';
			Database.update(otpRecordToVerify, AccessLevel.USER_MODE);
            //database.update(OTPRec,false,AccessLevel.USER_MODE);
            return Auth.SessionManagement.finishLoginFlow();
        }
        else
        {
            if(errorCount ==2)
            {
                PageReference p = new PageReference('/secur/logout.jsp');
                p.setRedirect(true);
                return p;
            }
            else
            {
                message = 'The OTP entered is either incorrect or expired, please verify.';
                errorCount ++;
                errorMessage =  'You have made '+errorCount+' invalid attempts out of 3 attempts.';
                return null;
            }
        }
    }
}
