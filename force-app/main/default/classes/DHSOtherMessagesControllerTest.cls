@isTest
/** Exercises the existing DHSOtherMessagesController behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.MethodNamingConventions')
public class DHSOtherMessagesControllerTest{
    @IsTest private static void TestOtherMessagesController(){
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
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
        System.assertEquals(1, ctrl.allIncomingMessages.size(), 'Assertion failed in DHSOtherMessagesControllerTest at source line 19');
        System.assertEquals(1, ctrl.allOutgoingMessages.size(), 'Assertion failed in DHSOtherMessagesControllerTest at source line 20');

        ctrl.selectedFromUserId = UserInfo.getUserId();
        ctrl.selectedToUserId = UserInfo.getUserId();
        ctrl.selectedTypeofMessage = 'Incoming';
        ctrl.fetchmessages();
        ctrl.selectedTypeofMessage = 'Sent Items';
        ctrl.fetchmessages();
        System.assertNotEquals(null, ctrl.allOutgoingMessages, 'Assertion failed in DHSOtherMessagesControllerTest at source line 28');
        }
   }
}