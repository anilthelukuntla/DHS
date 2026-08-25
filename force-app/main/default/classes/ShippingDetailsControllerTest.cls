@isTest
public class ShippingDetailsControllerTest {
    testMethod private static void ShippingDetailsControllerTest1(){
        Case__c c = new Case__c();
        insert c;
        PPF_Shipping_Information__c ppf = new PPF_Shipping_Information__c();
        ppf.Manifest_Number__c  = 'test';  
        ppf.case__c = c.id;  
        insert ppf;
        
        
        User thisUser = [select Id from User where Id = :UserInfo.getUserId()];
        ID ProfileID = [ Select id,UserType from Profile where name = 'Customer Community Investigator User'].id;
        
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
       
        system.runAs(u1){
            ShippingDetailsController ctrl = new ShippingDetailsController();
            ctrl.selectedcaseidforshipping = c.id;
            ctrl.onselectofcase();
            ctrl.createppfshippinginformationaction();
        }
    }
    
     testMethod private static void ShippingDetailsControllerTest2(){
        Case__c c = new Case__c();
        insert c;
        PPF_Shipping_Information__c ppf = new PPF_Shipping_Information__c();
        ppf.Manifest_Number__c  = 'test';  
        ppf.case__c = c.id;  
        insert ppf;
        
        
        User thisUser = [select Id from User where Id = :UserInfo.getUserId()];
        ID ProfileID = [ Select id,UserType from Profile where name = 'Customer Community Investigator User'].id;
        
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
       
        system.runAs(u1){
            ShippingDetailsController ctrl = new ShippingDetailsController();
            ctrl.selectedcaseidforshipping = c.id;
             ctrl.onselectofcase();
             ctrl.updateppfshippinginformationaction();
        }
    }
 }