@isTest
public class DIAHeaderControllerTest {
    @testSetup static void setup() {
        
         DIA_Contact__c con = new DIA_Contact__c();
         con.first_name__c = 'Test';
         con.last_name__c = 'Name';
         con.Email__c  = 'test@test.com';
         con.Contact_Type__c = 'Subject';
         con.ssn__c = '123-12-1123';
         insert con;
         DIA_Case__c diaCase = new DIA_Case__c();
         diaCase.contact__c = con.id;
         diaCase.Assigned_To__c = userinfo.getuserId();
         insert diaCase;
         DIA_Lead__c diaLead = new DIA_Lead__c();
         diaLead.case__c = diaCase.id;
         //diaLead.Assigned_To__c = userinfo.getuserid();
         diaLead.Coverage_Type__c = 'Subject Interview';
         diaLead.LeadType__c = 'Subject Interview (ESI/TESI)';
         insert diaLead;
     }
     testMethod private static void TestMethod1(){
       DIAHeaderController  ctrl = new DIAHeaderController ();
        user currentUser = [Select Id, User_Type__c from User where Id=:userinfo.getuserid()];
        currentUser.User_Type__c = 'CMO';
        update currentUser;
        DIAHeaderController  ctrl2 = new DIAHeaderController ();
        currentUser = [Select Id, User_Type__c from User where Id=:userinfo.getuserid()];
        currentUser.User_Type__c = 'QA';
        update currentUser;
        DIAHeaderController  ctrl3 = new DIAHeaderController ();
        currentUser = [Select Id, User_Type__c from User where Id=:userinfo.getuserid()];
        currentUser.User_Type__c = 'INV';
        update currentUser;
        DIAHeaderController  ctrl5 = new DIAHeaderController ();
        currentUser = [Select Id, User_Type__c from User where Id=:userinfo.getuserid()];
        currentUser.User_Type__c = 'PMO';
        update currentUser;
        DIAHeaderController  ctrl4 = new DIAHeaderController ();
                 
     }
}