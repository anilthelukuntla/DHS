@istest

public class LoginFlow_Controller_Test {

    TestMethod static void getdata()

    {

        LoginFlow_Controller L = New LoginFlow_Controller();

        L.createOTPrecord();

       

        List<OTP__C> otpRecord = [select id,OTP__c,User__c,Status__c,Expired__c from OTP__c where User__c =: UserInfo.getUserId() AND  Status__c = 'Generated' AND Expired__c = false];

                      system.assertEquals(1,otpRecord.size());

       

        LoginFlow_Controller L1 = New LoginFlow_Controller();

        L1.ErrorCount = 0 ;

        L1.OTPrecId = otpRecord[0].Id;

        L1.EnteredOTPfromUser = otpRecord[0].OTP__c;

        L1.VerifyOTP();

        L1.EnteredOTPfromUser ='234567';

        L1.VerifyOTP();

        L1.EnteredOTPfromUser ='234567';

        L1.VerifyOTP();

        L1.EnteredOTPfromUser ='345678';

        L1.VerifyOTP();

    }

}