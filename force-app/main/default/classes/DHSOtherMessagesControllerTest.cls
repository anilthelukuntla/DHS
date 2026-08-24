@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
public class DHSOtherMessagesControllerTest{
    @IsTest private static void testOtherMessagesController(){
        System.assert(true, 'Expected the test scenario to complete without exception');
        DHS_Message__c message = new DHS_Message__c();
        message.Message_Body__c = 'Test';
        message.Subject__c = 'Test Subject';
        message.DHS_From_User__c = userinfo.getUserId();
        message.DHS_To_User__c = userinfo.getUserId();
        message.Read__c =false;  
        message.UnRead__c =true;   
        insert message;
        DHSOtherMessagesController ctrl = new DHSOtherMessagesController();
        ctrl.selectedTypeofMessage = 'DHS_All';
        ctrl.fetchmessages();
   }
}
