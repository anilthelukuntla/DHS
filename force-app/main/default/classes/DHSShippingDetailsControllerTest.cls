@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
public class DHSShippingDetailsControllerTest {
    @IsTest private static void shippingDetailsControllerTest1(){
        DHS_Case__c c = new DHS_Case__c();
        DHS_PPF_Shipping_Information__c ppf = new DHS_PPF_Shipping_Information__c();
        ppf.Manifest_Number__c  = 'test';  
        
        
        User thisUser = [select Id from User where Id = :UserInfo.getUserId()];
        ID profileID = [
            SELECT Id FROM Profile WHERE Name = 'PPF - DHS INV Profile'
        ].Id;
        
        Account a1 = new Account(Name = 'Test Account', OwnerId=thisUser.Id );
        insert a1;
        
        Contact c1 = new Contact( AccountID = a1.id, FirstName = 'Test', LastName = 'User', 
        email = 'test-user@fakeemail.com' );
        insert c1; 
        
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
    
     @IsTest private static void shippingDetailsControllerTest2(){
        DHS_Case__c c = new DHS_Case__c();
        DHS_PPF_Shipping_Information__c ppf = new DHS_PPF_Shipping_Information__c();
        ppf.Manifest_Number__c  = 'test';  
        
        
        User thisUser = [select Id from User where Id = :UserInfo.getUserId()];
        ID profileID = [
            SELECT Id FROM Profile WHERE Name = 'PPF - DHS QA Profile'
        ].Id;
        
        Account a1 = new Account(Name = 'Test Account', OwnerId=thisUser.Id );
        insert a1;
        
        Contact c1 = new Contact( AccountID = a1.id, FirstName = 'Test', LastName = 'User', 
        email = 'test-user@fakeemail.com' );
        insert c1; 
        
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
