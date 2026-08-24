@IsTest
@SuppressWarnings('PMD.ApexAssertionsShouldIncludeMessage,PMD.ApexUnitTestClassShouldHaveAsserts,PMD.ApexUnitTestClassShouldHaveRunAs,PMD.NcssCount,PMD.UnusedLocalVariable')
public class DHSCaseDashboardControllerTest {
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
     }
    @IsTest private static void testMethod1(){ 
        DHS_Case__c c = [select id from DHS_Case__c limit 1];
          DHSCaseDashboardController dashboardCtrl = new DHSCaseDashboardController();   
        dashboardCtrl.subjectFirstNameSearchEntry = 'test';
        dashboardCtrl.subjectLastNameSearchEntry = 'investigator';
        dashboardCtrl.caseStatusSearchEntry = 'Completed';
        dashboardCtrl.fromSubmissionDateSearchEntry = system.today();
        dashboardCtrl.toSubmissionDateSearchEntry = system.today();
        dashboardCtrl.caseNumberSearchEntry = 'asdasd';
        dashboardCtrl.caseManifestSearchEntry = 'asdasd';
        dashboardCtrl.caseTypeSearchEntry = 'asdasd';
        dashboardCtrl.SearchAction();
        system.assertEquals(1,dashboardCtrl.casesSearched.size());
        dashboardCtrl.casesSearched[0].isSelected = true;
        //dashboardCtrl.casesSearched[1].isSelected = true;
        dashboardCtrl.selectedUserIdForAssignment = userinfo.getUserId();
        dashboardCtrl.AssignCasesAction();
        Integer totalNumberOfQACases = DHSCaseDashboardController.totalNumberOfQACases();
        Integer totalNumberLeadsForCase = DHSCaseDashboardController.totalNumberLeadsForCase(c.id);
        PageReference caseDashboardPage = Page.DHSCasedashboard;
        Test.setCurrentPage(caseDashboardPage);
        caseDashboardPage.getParameters().put('showUnAssigned','true'); 
        DHSCaseDashboardController dashboardCtrl2 = new DHSCaseDashboardController();   
        caseDashboardPage.getParameters().put('subjectFirstNameSearchEntry','test'); 
        caseDashboardPage.getParameters().put('subjectLastNameSearchEntry','test'); 
        caseDashboardPage.getParameters().put('caseNumberSearchEntry','test'); 
        caseDashboardPage.getParameters().put('caseManifestSearchEntry','test'); 
        caseDashboardPage.getParameters().put('caseAssigneeearchEntry','test'); 
        caseDashboardPage.getParameters().put('caseTypeSearchEntry','test'); 
        caseDashboardPage.getParameters().put('fromSubmissionDateSearchEntry',string.valueof(system.today())); 
        caseDashboardPage.getParameters().put('toSubmissionDateSearchEntry',string.valueof(system.today())); 
        DHSCaseDashboardController dashboardCtrl3 = new DHSCaseDashboardController(); 
        caseDashboardPage.getParameters().clear();
        caseDashboardPage.getParameters().put('showQACases','true');  
        caseDashboardPage.getParameters().put('subjectFirstNameSearchEntry','test'); 
        caseDashboardPage.getParameters().put('subjectLastNameSearchEntry','test'); 
        caseDashboardPage.getParameters().put('caseNumberSearchEntry','test'); 
        caseDashboardPage.getParameters().put('caseManifestSearchEntry','test'); 
        caseDashboardPage.getParameters().put('caseAssigneeearchEntry','test'); 
        caseDashboardPage.getParameters().put('caseTypeSearchEntry','test'); 
        caseDashboardPage.getParameters().put('fromSubmissionDateSearchEntry',string.valueof(system.today())); 
        caseDashboardPage.getParameters().put('toSubmissionDateSearchEntry',string.valueof(system.today())); 
        DHSCaseDashboardController dashboardCtrl4 = new DHSCaseDashboardController();   
           
    }
     @IsTest private static void testAutoCreateLeads(){
        DHS_Auto_Lead_Generation_Template__c temp = new DHS_Auto_Lead_Generation_Template__c(Name__c='Test');
        insert temp;
        DHS_Auto_Lead_Generation_Setting__c setting = new DHS_Auto_Lead_Generation_Setting__c();
        setting.DHS_Auto_Lead_Generation_Template__c =temp.id;
        setting.Coverage_Type__c = 'Personal';
        setting.Item_number__c = 1;
        setting.Lead_Type__c = 'UnEmployment';
        insert setting;
        PageReference casedetailpage = Page.DHSCasedetail;
        Test.setCurrentPage(casedetailpage);
        DHS_Case__c c = new DHS_Case__c();
        insert c;
       
    }
}
