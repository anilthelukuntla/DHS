@isTest
/** Exercises the existing DHSLeadDashboardController behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.LocalVariableNamingConventions, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.MethodNamingConventions')
public class DHSLeadDashboardControllerTest {
     @testSetup static void setup() {
         User pmoUser = PPFDHSTestUserFactory.createPmoUser();
         System.runAs(pmoUser) {
         DHS_Contact__c con = new DHS_Contact__c();
         con.First_Name__c = 'Test';
         
         con.Last_Name__c = 'Name';
         con.Email__c  = 'test@test.com';
         con.Contact_Type__c = 'Subject';
         con.SSN__c = '123-12-1123';
         insert con;
         DHS_Case__c CaseTemp = new DHS_Case__c();
         CaseTemp.DHS_Contact__c = con.id;
         CaseTemp.DHS_Assigned_To__c = userinfo.getuserId();
         insert CaseTemp;
         DHS_Lead__c Lead = new DHS_Lead__c();
         Lead.DHS_Case__c = CaseTemp.id;
         
         Lead.DHS_Assigned_To__c = userinfo.getuserid();
         Lead.Coverage_Type__c = 'Subject Interview';
         Lead.LeadType__c = 'Subject Interview (ESI/TESI)';
         insert Lead;
         lead.Reason_for_Waiver__c = 'Subject not available';
         update lead;
         insert new DHS_Daily_Production_Summary__c(
             DHS_Reviewer__c = UserInfo.getUserId(),
             Leads_Accepted__c = 0,
             Leads_Rejected__c = 0
         );
         }
     }
    @IsTest private static void testConstructorSearchParameters(){
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        PageReference LeadDashboardPage = Page.DHSLeaddashboard;
        Test.setCurrentPage(LeadDashboardPage);
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
        DHSLeadDashboardController leadDashboardCtrl = new DHSLeadDashboardController();
        System.assertNotEquals(null, leadDashboardCtrl.leadsSearched, 'Assertion failed in DHSLeadDashboardControllerTest at source line 51');
        }
    }

    @IsTest private static void testSearchAndAssignment(){
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        Test.setCurrentPage(Page.DHSLeaddashboard);
        DHSLeadDashboardController leadDashboardCtrl = new DHSLeadDashboardController();
        leadDashboardCtrl.searchUnassigned = true;
        leadDashboardCtrl.SearchAction();
        system.assertEquals(1,leadDashboardCtrl.leadsSearched.size(), 'Assertion failed in DHSLeadDashboardControllerTest at source line 61');
        leadDashboardCtrl.selectedUserIdForAssignment = userinfo.getUserId();
        leadDashboardCtrl.leadsSearched[0].isSelected = true;
        leadDashboardCtrl.AssignLeadsAction();
        }
    }

    @IsTest private static void testLeadActions(){
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        Test.setCurrentPage(Page.DHSLeaddashboard);
        DHSLeadDashboardController leadDashboardCtrl = new DHSLeadDashboardController();
        leadDashboardCtrl.searchUnassigned = true;
        leadDashboardCtrl.SearchAction();
        System.assertEquals(1, leadDashboardCtrl.leadsSearched.size(), 'Assertion failed in DHSLeadDashboardControllerTest at source line 74');
        leadDashboardCtrl.leadsSearched[0].isSelected = true;
        leadDashboardCtrl.leadIdToUpdate = leadDashboardCtrl.leadsSearched[0].ld.Id;
        leadDashboardCtrl.acdDateToUpdate = 'invalid-date';
        leadDashboardCtrl.UpdateACDLead();
        System.assertNotEquals(null, leadDashboardCtrl.errorMessage, 'Assertion failed in DHSLeadDashboardControllerTest at source line 79');
        leadDashboardCtrl.onstatechange();
        leadDashboardCtrl.searchUnassigned = false;
        leadDashboardCtrl.seachqarejected = true;
        leadDashboardCtrl.SearchAction();
        leadDashboardCtrl.UnAssignLeadsAction();
        }
    }

    @IsTest private static void testUpdateAndPagination(){
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        Test.setCurrentPage(Page.DHSLeaddashboard);
        DHSLeadDashboardController leadDashboardCtrl = new DHSLeadDashboardController();
        leadDashboardCtrl.searchUnassigned = true;
        leadDashboardCtrl.SearchAction();
        system.assertEquals(1,leadDashboardCtrl.leadsSearched.size(), 'Assertion failed in DHSLeadDashboardControllerTest at source line 94');
        leadDashboardCtrl.leadsSearched[0].isSelected = true;
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

    @IsTest private static void testNavigationConstructorModes(){
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        PageReference dashboardPage = Page.DHSLeaddashboard;
        Test.setCurrentPage(dashboardPage);
        dashboardPage.getParameters().put('searchmyavailableleads', 'true');
        DHSLeadDashboardController availableController = new DHSLeadDashboardController();
        System.assertNotEquals(null, availableController.leadsSearched, 'Assertion failed in DHSLeadDashboardControllerTest at source line 113');
        dashboardPage.getParameters().clear();
        dashboardPage.getParameters().put('searchmyAssigned', 'true');
        DHSLeadDashboardController assignedController = new DHSLeadDashboardController();
        System.assertNotEquals(null, assignedController.leadsSearched, 'Assertion failed in DHSLeadDashboardControllerTest at source line 117');
        }
    }

    @IsTest private static void testAdditionalSearchModes(){
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        Test.setCurrentPage(Page.DHSLeaddashboard);
        DHSLeadDashboardController leadDashboardCtrl = new DHSLeadDashboardController();
        leadDashboardCtrl.searchQARejected = true;
        leadDashboardCtrl.SearchAction();
        leadDashboardCtrl.searchQARejected = false;
        leadDashboardCtrl.searchmydiscontinued = true;
        leadDashboardCtrl.SearchAction();
        leadDashboardCtrl.searchmydiscontinued = false;
        leadDashboardCtrl.seachqarejected = true;
        leadDashboardCtrl.SearchAction();
        System.assertNotEquals(null, leadDashboardCtrl.leadsSearched, 'Assertion failed in DHSLeadDashboardControllerTest at source line 133');
        }
    }

    @IsTest private static void testAcceptAction(){
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        Test.setCurrentPage(Page.DHSLeaddashboard);
        DHSLeadDashboardController leadDashboardCtrl = new DHSLeadDashboardController();
        leadDashboardCtrl.searchUnassigned = true;
        leadDashboardCtrl.SearchAction();
        leadDashboardCtrl.leadIdToAccept = leadDashboardCtrl.leadsSearched[0].ld.Id;
        leadDashboardCtrl.acceptaction();
        System.assertEquals(0, leadDashboardCtrl.leadsSearched.size(), 'Assertion failed in DHSLeadDashboardControllerTest at source line 145');
        }
    }

    @IsTest private static void testRejectAction(){
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        Test.setCurrentPage(Page.DHSLeaddashboard);
        DHSLeadDashboardController leadDashboardCtrl = new DHSLeadDashboardController();
        leadDashboardCtrl.searchUnassigned = true;
        leadDashboardCtrl.SearchAction();
        leadDashboardCtrl.leadIdToReject = leadDashboardCtrl.leadsSearched[0].ld.Id;
        leadDashboardCtrl.rejectaction();
        System.assertEquals(0, leadDashboardCtrl.leadsSearched.size(), 'Assertion failed in DHSLeadDashboardControllerTest at source line 157');
        }
    }
}