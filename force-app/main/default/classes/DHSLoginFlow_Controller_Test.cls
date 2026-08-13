@istest

/** Exercises the existing DHSLoginFlow_Controller_ behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.LocalVariableNamingConventions')
public class DHSLoginFlow_Controller_Test {

    @IsTest static void getdata()

    {

        DHSLoginFlow_Controller L = New DHSLoginFlow_Controller();

        L.createOTPrecord();

       

        List<DHS_OTP__c> otpRecord = [select id,OTP__c,DHS_User__c,Status__c,Expired__c from DHS_OTP__c where DHS_User__c =: UserInfo.getUserId() AND  Status__c = 'Generated' AND Expired__c = false];

                      system.assertEquals(1,otpRecord.size(), 'Assertion failed in DHSLoginFlow_Controller_Test at source line 19');

       

        DHSLoginFlow_Controller L1 = New DHSLoginFlow_Controller();

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