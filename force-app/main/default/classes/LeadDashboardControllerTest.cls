@isTest
public class LeadDashboardControllerTest {
     @testSetup static void setup() {
         Contact__c con = new Contact__c();
         con.first_name__c = 'Test';
         
         con.last_name__c = 'Name';
         con.Email__c  = 'test@test.com';
         con.Contact_Type__c = 'Subject';
         con.ssn__c = '123-12-1123';
         insert con;
         Case__c CaseTemp = new Case__c();
         CaseTemp.contact__c = con.id;
         CaseTemp.Assigned_To__c = userinfo.getuserId();
         insert CaseTemp;
         Lead__c Lead = new Lead__c();
         Lead.case__c = CaseTemp.id;
         
         //Lead.Assigned_To__c = userinfo.getuserid();
         Lead.Coverage_Type__c = 'Subject Interview';
         Lead.LeadType__c = 'Subject Interview (ESI/TESI)';
         insert Lead;
         lead.Reason_for_Waiver__c = 'Subject not available';
         update lead;
     }
    testMethod private static void TestMethod1(){       
        PageReference LeadDashboardPage = Page.BILeadDashboard;
        Test.setCurrentPage(LeadDashboardPage);
        LeadDashboardController leadDashboardCtrl = new LeadDashboardController(); 
        LeadDashboardPage.getParameters().put('searchUnassigned','true');
        LeadDashboardController leaddashboardCtrl2 = new LeadDashboardController();
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
        LeadDashboardController leaddashboardCtrl3 = new LeadDashboardController(); 
        LeadDashboardPage.getParameters().clear();
        LeadDashboardPage.getParameters().put('searchmyavailableleads','true');  
        LeadDashboardController leaddashboardCtrl4 = new LeadDashboardController();
        LeadDashboardPage.getParameters().clear();
        LeadDashboardPage.getParameters().put('searchmyassigned','true');  
        LeadDashboardController leaddashboardCtrl5 = new LeadDashboardController();   
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
        LeadDashboardController leadDashboardCtrl = new LeadDashboardController(); 
        LeadDashboardPage.getParameters().put('searchUnassigned','true');
        LeadDashboardController leaddashboardCtrl2 = new LeadDashboardController();
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
        LeadDashboardController leaddashboardCtrl3 = new LeadDashboardController(); 
        LeadDashboardPage.getParameters().clear();
        LeadDashboardPage.getParameters().put('searchmyavailableleads','true');  
        LeadDashboardController leaddashboardCtrl4 = new LeadDashboardController();
        LeadDashboardPage.getParameters().clear();
        LeadDashboardPage.getParameters().put('searchmyassigned','true');  
        LeadDashboardController leaddashboardCtrl5 = new LeadDashboardController();   
        leadDashboardCtrl.searchUnassigned = true;
        leadDashboardCtrl.SearchAction();
        system.assertEquals(1,leadDashboardCtrl.leadsSearched.size());
        leadDashboardCtrl.selectedUserIdForAssignment = userinfo.getUserId();
        leadDashboardCtrl.leadsSearched[0].isSelected = true;
        leadDashboardCtrl.AssignLeadsAction();
        leadDashboardCtrl.UnAssignLeadsAction();
        leadDashboardCtrl.anticipatedCompletionDate = system.today();
        leadDashboardCtrl.updateACDDate();
        leadDashboardCtrl.handlePrev();
        leadDashboardCtrl.handleNext();
        List<id> ids = New List<id>();
        lead__c l = [select id from lead__c limit 1];
        ids.add(l.Id);
        LeadDashboardController.updateleadsunassignmethod(ids);
    }
}