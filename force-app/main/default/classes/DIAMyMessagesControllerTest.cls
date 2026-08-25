@isTest
public class DIAMyMessagesControllerTest {
testMethod private static void TestMyMessagesController(){
         list<user> currentUsers = [Select Id, User_Type__c,system_access__c,profile.name from User where contactid != Null or profile.name = 'System Administrator'];
        for(user u:currentUsers){
        u.User_Type__c = 'PMO';
        u.system_access__c = 'DIA';
        }
        update currentUsers;
        DIA_Case__c c = new DIA_Case__c();
        c.case_number__c = 'test';
        c.assigned_to__c = userinfo.getuserid();
        insert c;
        DIA_Message__c message = new DIA_Message__c();
        message.Message_Body__c = 'Test';
        message.subject__c = 'Test Subject';
        message.From_User__c = userinfo.getUserId();
        message.to_user__c = userinfo.getUserId();
        message.read__c =false;  
        message.unread__c =true; 
        message.case__c = c.id;  
        insert message;
        DIAMyMessagesController mymessagesCtrl = new DIAMyMessagesController();
        mymessagesCtrl.currentMessageId = message.id;
        mymessagesCtrl.FetchCurrentMessageAction();
        mymessagesCtrl.messageBody = 'Test';
        mymessagesCtrl.messageSubject = 'Test';
        mymessagesCtrl.selecteToAddressOption = 'All Program Members';
        mymessagesCtrl.SendMessage();
        mymessagesCtrl.RefreshAction();
        mymessagesCtrl.selecteToAddressOption = 'All Investigators';
        mymessagesCtrl.SendMessage();
        mymessagesCtrl.selecteToAddressOption = 'All PMOs';
        mymessagesCtrl.SendMessage();
        mymessagesCtrl.selecteToAddressOption = 'All CMOs';
        mymessagesCtrl.SendMessage();
        mymessagesCtrl.selecteToAddressOption = 'All QAs';
        mymessagesCtrl.SendMessage();
    }
}