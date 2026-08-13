@isTest
/** Exercises the existing OtherMessagesController behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.MethodNamingConventions')
public class OtherMessagesControllerTest{
    @IsTest private static void TestOtherMessagesController(){
        Message__c message = new Message__c();
        message.Message_Body__c = 'Test';
        message.subject__c = 'Test Subject';
        message.From_User__c = userinfo.getUserId();
        message.to_user__c = userinfo.getUserId();
        message.read__c =false;  
        message.unread__c =true;   
        insert message;
        OtherMessagesController ctrl = new OtherMessagesController();
        ctrl.selectedTypeofMessage = 'All';
        ctrl.fetchmessages();
   }
}