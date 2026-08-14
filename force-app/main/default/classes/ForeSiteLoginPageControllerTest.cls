@isTest
/** Exercises the existing ForeSiteLoginPageController behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.UnusedLocalVariable')
public class ForeSiteLoginPageControllerTest {
     @IsTest private static void testMethod1(){
         onboarding__c onboardingUser = new onboarding__c();
        onboardingUser.First_Name__c = 'test';
        onboardingUser.Last_Name__c = 'investigator';
        onboardingUser.Email__c = 'testinvestigator@test.com';
        onboardingUser.User_Profile__c = 'INV';
         insert onboardingUser;
        
         
         
         Account acc = new Account (
            Name = 'newAcc1'
            );  
            insert acc;
             Contact con = new Contact(accountid = acc.id, Onboarding__c = onboardingUser.id,firstname='test',lastname = 'investigator');
         insert con;
            Profile p = [select Id,name from Profile where Name ='Standard User' limit 1];
 
        
        User u = new User(Alias = 'standt', Email='standarduser4289@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser4289@testorg.com'
            );

        insert u;
        ForeSiteLoginPageController.testUserType = 'PMO';
        ForeSiteLoginPageController ctrl3 = new ForeSiteLoginPageController();
        pagereference pref = ctrl3.doLogin();
        ctrl3.ForgotPasswordClickAction();
        ctrl3.userName = 'standarduser4289@testorg.com';
        pagereference pref1 = ctrl3.doLogin();
        ctrl3.newPassword = 'StrongPassword!4289';
        ctrl3.resetpassword();
        System.assertEquals(true, ctrl3.showloginpanel, 'Assertion failed in ForeSiteLoginPageControllerTest at source line 39');
        System.assertEquals(null, ctrl3.newPassword, 'Assertion failed in ForeSiteLoginPageControllerTest at source line 40');
        System.assert(ctrl3.errorMessage.contains('Password Reset'), 'Assertion failed in ForeSiteLoginPageControllerTest at source line 41');
    
    }
     @IsTest private static void testMethod2(){
         onboarding__c onboardingUser = new onboarding__c();
        onboardingUser.First_Name__c = 'test';
        onboardingUser.Last_Name__c = 'investigator';
        onboardingUser.Email__c = 'testinvestigator@test.com';
        onboardingUser.User_Profile__c = 'PMO';
         insert onboardingUser;
        
         
         
         Account acc = new Account (
            Name = 'newAcc1'
            );  
            insert acc;
             Contact con = new Contact(accountid = acc.id, Onboarding__c = onboardingUser.id,firstname='test',lastname = 'investigator');
         insert con;
            Profile p = [select Id,name from Profile where Name ='Standard User' limit 1];
 
        
        User u = new User(Alias = 'standt', Email='standarduser4289@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser4289@testorg.com'
            );

        insert u;
        ForeSiteLoginPageController ctrl3 = new ForeSiteLoginPageController();
        pagereference pref = ctrl3.doLogin();
        ctrl3.ForgotPasswordClickAction();
        ctrl3.userName = 'standarduser4289@testorg.com';
        pagereference pref1 = ctrl3.doLogin();
        ForeSiteLoginPageController.testUserType = 'Customer User';
        ctrl3.doLogin();
        ctrl3.resetpassword();
    
    }
}