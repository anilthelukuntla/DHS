@isTest
public class ForeSiteLoginPageControllerTest {
     testMethod private static void testMethod1(){  
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
        ForeSiteLoginPageController ctrl3 = new ForeSiteLoginPageController();
        pagereference pref = ctrl3.doLogin();
        ctrl3.ForgotPasswordClickAction();
        ctrl3.userName = 'standarduser4289@testorg.com';
        pagereference pref1 = ctrl3.doLogin();
        ctrl3.resetpassword();
    
    }
     testMethod private static void testMethod2(){  
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
        ctrl3.resetpassword();
    
    }
}