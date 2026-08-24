@IsTest
@SuppressWarnings('PMD.ApexAssertionsShouldIncludeMessage,PMD.ApexUnitTestClassShouldHaveRunAs,PMD.UnusedLocalVariable')
public class DHSLeadDashboardControllerTest {
     @TestSetup static void setup() {
         DHS_Contact__c con = new DHS_Contact__c();
         con.First_Name__c = 'Test';
         
         con.Last_Name__c = 'Name';
         con.Email__c  = 'test@test.com';
         con.Contact_Type__c = 'Subject';
         con.SSN__c = '123-12-1123';
         insert con;
         DHS_Case__c caseTemp = new DHS_Case__c();
         caseTemp.DHS_Contact__c = con.id;
         caseTemp.DHS_Assigned_To__c = userinfo.getuserId();
         insert caseTemp;
         DHS_Lead__c lead = new DHS_Lead__c();
         lead.DHS_Case__c = caseTemp.id;
         
         //Lead.DHS_Assigned_To__c = userinfo.getuserid();
         lead.Coverage_Type__c = 'Subject Interview';
         lead.LeadType__c = 'Subject Interview (ESI/TESI)';
         insert lead;
         lead.Reason_for_Waiver__c = 'Subject not available';
         update lead;
     }
    @IsTest private static void testMethod1(){       
        PageReference leadDashboardPage = Page.DHSLeaddashboard;
        Test.setCurrentPage(leadDashboardPage);
        DHSLeadDashboardController leadDashboardCtrl = new DHSLeadDashboardController(); 
        leadDashboardPage.getParameters().put('searchUnassigned','true');
        DHSLeadDashboardController leaddashboardCtrl2 = new DHSLeadDashboardController();
        leadDashboardPage.getParameters().clear();
        leadDashboardPage.getParameters().put('searchUnassigned','false'); 
        leadDashboardPage.getParameters().put('ZipSearchEntry','test'); 
        leadDashboardPage.getParameters().put('stateSearchEntry','test'); 
        leadDashboardPage.getParameters().put('citySearchEntry','test'); 
        leadDashboardPage.getParameters().put('subjectLastNameSearchEntry','test'); 
        leadDashboardPage.getParameters().put('manifestSearchEntry','test'); 
        leadDashboardPage.getParameters().put('subjectFirstNameSearchEntry','test'); 
        leadDashboardPage.getParameters().put('caseNumberSearchEntry','test'); 
        leadDashboardPage.getParameters().put('leadStatusSearchEntry','test'); 
        leadDashboardPage.getParameters().put('leadTypeSearchEntry','test'); 
        DHSLeadDashboardController leaddashboardCtrl3 = new DHSLeadDashboardController(); 
        leadDashboardPage.getParameters().clear();
        leadDashboardPage.getParameters().put('searchmyavailableleads','true');  
        DHSLeadDashboardController leaddashboardCtrl4 = new DHSLeadDashboardController();
        leadDashboardPage.getParameters().clear();
        leadDashboardPage.getParameters().put('searchmyassigned','true');  
        DHSLeadDashboardController leaddashboardCtrl5 = new DHSLeadDashboardController();   
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
    @IsTest private static void testMethod2(){       
        PageReference leadDashboardPage = Page.DHSLeaddashboard;
        Test.setCurrentPage(leadDashboardPage);
        DHSLeadDashboardController leadDashboardCtrl = new DHSLeadDashboardController(); 
        leadDashboardPage.getParameters().put('searchUnassigned','true');
        DHSLeadDashboardController leaddashboardCtrl2 = new DHSLeadDashboardController();
        leadDashboardPage.getParameters().clear();
        leadDashboardPage.getParameters().put('searchUnassigned','false'); 
        leadDashboardPage.getParameters().put('ZipSearchEntry','test'); 
        leadDashboardPage.getParameters().put('stateSearchEntry','test'); 
        leadDashboardPage.getParameters().put('citySearchEntry','test'); 
        leadDashboardPage.getParameters().put('subjectLastNameSearchEntry','test'); 
        leadDashboardPage.getParameters().put('manifestSearchEntry','test'); 
        leadDashboardPage.getParameters().put('subjectFirstNameSearchEntry','test'); 
        leadDashboardPage.getParameters().put('caseNumberSearchEntry','test'); 
        leadDashboardPage.getParameters().put('leadStatusSearchEntry','test'); 
        leadDashboardPage.getParameters().put('leadTypeSearchEntry','test'); 
        DHSLeadDashboardController leaddashboardCtrl3 = new DHSLeadDashboardController(); 
        leadDashboardPage.getParameters().clear();
        leadDashboardPage.getParameters().put('searchmyavailableleads','true');  
        DHSLeadDashboardController leaddashboardCtrl4 = new DHSLeadDashboardController();
        leadDashboardPage.getParameters().clear();
        leadDashboardPage.getParameters().put('searchmyassigned','true');  
        DHSLeadDashboardController leaddashboardCtrl5 = new DHSLeadDashboardController();   
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
        DHS_Lead__c l = [select id from DHS_Lead__c limit 1];
        ids.add(l.Id);
        DHSLeadDashboardController.updateleadsunassignmethod(ids);
    }
}
