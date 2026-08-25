@isTest
public class DIALeadDashboardControllerTest {
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
        PageReference LeadDashboardPage = Page.BILeadDashboard;
        Test.setCurrentPage(LeadDashboardPage);
        DIALeadDashboardController leadDashboardCtrl = new DIALeadDashboardController(); 
        LeadDashboardPage.getParameters().put('searchUnassigned','true');
        DIALeadDashboardController leaddashboardCtrl2 = new DIALeadDashboardController();
        LeadDashboardPage.getParameters().clear();
        LeadDashboardPage.getParameters().put('searchUnassigned','false'); 
        LeadDashboardPage.getParameters().put('ZipSearchEntry','test'); 
        LeadDashboardPage.getParameters().put('stateSearchEntry','test'); 
        LeadDashboardPage.getParameters().put('citySearchEntry','test'); 
        LeadDashboardPage.getParameters().put('subjectLastNameSearchEntry','test'); 
        LeadDashboardPage.getParameters().put('manifestSearchEntry','test'); 
        LeadDashboardPage.getParameters().put('subjectFirstNameSearchEntry','test'); 
        LeadDashboardPage.getParameters().put('caseNumberSearchEntry','test'); 
        LeadDashboardPage.getParameters().put('leadStatusSearchEntry','test'); 
        LeadDashboardPage.getParameters().put('leadTypeSearchEntry','test'); 
        DIALeadDashboardController leaddashboardCtrl3 = new DIALeadDashboardController(); 
        LeadDashboardPage.getParameters().clear();
        LeadDashboardPage.getParameters().put('searchmyavailableleads','true');  
        DIALeadDashboardController leaddashboardCtrl4 = new DIALeadDashboardController();
        LeadDashboardPage.getParameters().clear();
        LeadDashboardPage.getParameters().put('searchmyassigned','true');  
        DIALeadDashboardController leaddashboardCtrl5 = new DIALeadDashboardController();   
        leadDashboardCtrl.searchUnassigned = true;
        leadDashboardCtrl.SearchAction();
        system.assertEquals(1,leadDashboardCtrl.leadsSearched.size());
        leadDashboardCtrl.selectedUserIdForAssignment = userinfo.getUserId();
        leadDashboardCtrl.leadsSearched[0].isSelected = true;
        leadDashboardCtrl.AssignLeadsAction();
        leadDashboardCtrl.UpdateACDLead();
        leadDashboardCtrl.onstatechange();
        leadDashboardCtrl.searchUnassigned = false;
        leadDashboardCtrl.seachqarejected = true;
        leadDashboardCtrl.SearchAction();
        leadDashboardCtrl.leadIdToAccept = leadDashboardCtrl.leadsSearched[0].ld.id;
        leadDashboardCtrl.acceptaction();
        leadDashboardCtrl.rejectaction();
        //leadDashboardCtrl.leadsSearched[0].isSelected = true;
        leadDashboardCtrl.UnAssignLeadsAction();
        //leadDashboardCtrl.updateleadsunassignmethod(new list<string>{leadDashboardCtrl.leadsSearched[0].ld.id});
    }
    testMethod private static void TestMethod2(){       
        PageReference LeadDashboardPage = Page.BILeadDashboard;
        Test.setCurrentPage(LeadDashboardPage);
        DIALeadDashboardController leadDashboardCtrl = new DIALeadDashboardController(); 
        LeadDashboardPage.getParameters().put('searchUnassigned','true');
        DIALeadDashboardController leaddashboardCtrl2 = new DIALeadDashboardController();
        LeadDashboardPage.getParameters().clear();
        LeadDashboardPage.getParameters().put('searchUnassigned','false'); 
        LeadDashboardPage.getParameters().put('ZipSearchEntry','test'); 
        LeadDashboardPage.getParameters().put('stateSearchEntry','test'); 
        LeadDashboardPage.getParameters().put('citySearchEntry','test'); 
        LeadDashboardPage.getParameters().put('subjectLastNameSearchEntry','test'); 
        LeadDashboardPage.getParameters().put('manifestSearchEntry','test'); 
        LeadDashboardPage.getParameters().put('subjectFirstNameSearchEntry','test'); 
        LeadDashboardPage.getParameters().put('caseNumberSearchEntry','test'); 
        LeadDashboardPage.getParameters().put('leadStatusSearchEntry','test'); 
        LeadDashboardPage.getParameters().put('leadTypeSearchEntry','test'); 
        DIALeadDashboardController leaddashboardCtrl3 = new DIALeadDashboardController(); 
        LeadDashboardPage.getParameters().clear();
        LeadDashboardPage.getParameters().put('searchmyavailableleads','true');  
        DIALeadDashboardController leaddashboardCtrl4 = new DIALeadDashboardController();
        LeadDashboardPage.getParameters().clear();
        LeadDashboardPage.getParameters().put('searchmyassigned','true');  
        DIALeadDashboardController leaddashboardCtrl5 = new DIALeadDashboardController();   
        leadDashboardCtrl.searchUnassigned = true;
        leadDashboardCtrl.SearchAction();
        system.assertEquals(1,leadDashboardCtrl.leadsSearched.size());
        leadDashboardCtrl.selectedUserIdForAssignment = userinfo.getUserId();
        leadDashboardCtrl.leadsSearched[0].isSelected = true;
        leadDashboardCtrl.AssignLeadsAction();
        leadDashboardCtrl.UnAssignLeadsAction();
    }
}