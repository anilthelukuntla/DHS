@istest

@SuppressWarnings('PMD.AnnotationsNamingConventions,PMD.ApexUnitTestClassShouldHaveRunAs')
public class DHSLoginFlow_Controller_Test {

    @IsTest static void getdata()

    {

        DHSLoginFlow_Controller l = New DHSLoginFlow_Controller();

        l.createOTPrecord();

       

        List<DHS_OTP__c> otpRecord = [select id,OTP__c,DHS_User__c,Status__c,Expired__c from DHS_OTP__c where DHS_User__c =: UserInfo.getUserId() AND  Status__c = 'Generated' AND Expired__c = false];

                      system.assertEquals(1,otpRecord.size(), 'Expected the asserted condition to hold');

       

        DHSLoginFlow_Controller l1 = New DHSLoginFlow_Controller();

        l1.ErrorCount = 0 ;

        l1.OTPrecId = otpRecord[0].Id;

        l1.EnteredOTPfromUser = otpRecord[0].OTP__c;

        l1.VerifyOTP();

        l1.EnteredOTPfromUser ='234567';

        l1.VerifyOTP();

        l1.EnteredOTPfromUser ='234567';

        l1.VerifyOTP();

        l1.EnteredOTPfromUser ='345678';

        l1.VerifyOTP();

    }

}
