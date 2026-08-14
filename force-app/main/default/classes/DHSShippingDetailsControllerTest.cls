@isTest
/** Exercises the existing DHSShippingDetailsController behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.MethodNamingConventions, PMD.LocalVariableNamingConventions')
public class DHSShippingDetailsControllerTest {
    @IsTest private static void ShippingDetailsControllerTest1(){
        DHS_Case__c c = new DHS_Case__c();
        DHS_PPF_Shipping_Information__c ppf = new DHS_PPF_Shipping_Information__c();
        ppf.Manifest_Number__c  = 'test';  
        
        
        User thisUser = [select Id from User where Id = :UserInfo.getUserId()];
        ID ProfileID = [
            SELECT Id FROM Profile WHERE Name = 'PPF - DHS INV Profile'
        ].Id;
        
        Account A1 = new Account(Name = 'Test Account', OwnerId=thisUser.Id );
        insert A1;
        
        Contact C1 = new Contact( AccountID = A1.id, FirstName = 'Test', LastName = 'User', 
        email = 'test-user@fakeemail.com' );
        insert C1; 
        
        User u1 = new User( email='test-user@fakeemail.com', contactid = c1.id, profileid = profileID, 
                  UserName='test-user@fakeemail.com', alias='tuser1', CommunityNickName='tuser1', 
                  TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1', 
                  LanguageLocaleKey='en_US', FirstName = 'Test', LastName = 'User',User_Type__c='INV');
        insert u1;
        insert c;
        ppf.DHS_Case__c = c.Id;
        insert ppf;
       
        system.runAs(u1){
            DHSShippingDetailsController ctrl = new DHSShippingDetailsController();
            ctrl.selectedcaseidforshipping = c.id;
            ctrl.onselectofcase();
            ctrl.createppfshippinginformationaction();
        }
    }
    
     @IsTest private static void ShippingDetailsControllerTest2(){
        DHS_Case__c c = new DHS_Case__c();
        DHS_PPF_Shipping_Information__c ppf = new DHS_PPF_Shipping_Information__c();
        ppf.Manifest_Number__c  = 'test';  
        
        
        User thisUser = [select Id from User where Id = :UserInfo.getUserId()];
        ID ProfileID = [
            SELECT Id FROM Profile WHERE Name = 'PPF - DHS QA Profile'
        ].Id;
        
        Account A1 = new Account(Name = 'Test Account', OwnerId=thisUser.Id );
        insert A1;
        
        Contact C1 = new Contact( AccountID = A1.id, FirstName = 'Test', LastName = 'User', 
        email = 'test-user@fakeemail.com' );
        insert C1; 
        
        User u1 = new User( email='test-user@fakeemail.com', contactid = c1.id, profileid = profileID, 
                  UserName='test-user@fakeemail.com', alias='tuser1', CommunityNickName='tuser1', 
                  TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1', 
                  LanguageLocaleKey='en_US', FirstName = 'Test', LastName = 'User',User_Type__c='QA');
        insert u1;
        insert c;
        ppf.DHS_Case__c = c.Id;
        insert ppf;
       
        system.runAs(u1){
            DHSShippingDetailsController ctrl = new DHSShippingDetailsController();
            ctrl.selectedcaseidforshipping = c.id;
             ctrl.onselectofcase();
             ctrl.updateppfshippinginformationaction();
        }
    }
 }