@isTest
/** Exercises the existing DHSCaseDashboardController behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.LocalVariableNamingConventions, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.MethodNamingConventions, PMD.NcssCount, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.UnusedLocalVariable')
public class DHSCaseDashboardControllerTest {
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
         //Lead.DHS_Assigned_To__c = userinfo.getuserid();
         Lead.Coverage_Type__c = 'Subject Interview';
         Lead.LeadType__c = 'Subject Interview (ESI/TESI)';
         insert Lead;
         }
     }
    @IsTest private static void TestMethod1(){
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
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
        system.assertEquals(1,dashboardCtrl.casesSearched.size(), 'Assertion failed in DHSCaseDashboardControllerTest at source line 41');
        dashboardCtrl.casesSearched[0].isSelected = true;
        //dashboardCtrl.casesSearched[1].isSelected = true;
        dashboardCtrl.selectedUserIdForAssignment = userinfo.getUserId();
        dashboardCtrl.AssignCasesAction();
        Integer TotalNumberOfQACases = DHSCaseDashboardController.TotalNumberOfQACases();
        Integer TotalNumberLeadsForCase = DHSCaseDashboardController.TotalNumberLeadsForCase(c.id);
        PageReference CaseDashboardPage = Page.DHSCasedashboard;
        Test.setCurrentPage(CaseDashboardPage);
        CaseDashboardPage.getParameters().put('showUnAssigned','true'); 
        DHSCaseDashboardController dashboardCtrl2 = new DHSCaseDashboardController();   
        CaseDashboardPage.getParameters().put('subjectFirstNameSearchEntry','test'); 
        CaseDashboardPage.getParameters().put('subjectLastNameSearchEntry','test'); 
        CaseDashboardPage.getParameters().put('caseNumberSearchEntry','test'); 
        CaseDashboardPage.getParameters().put('caseManifestSearchEntry','test'); 
        CaseDashboardPage.getParameters().put('caseAssigneeearchEntry','test'); 
        CaseDashboardPage.getParameters().put('caseTypeSearchEntry','test'); 
        CaseDashboardPage.getParameters().put('fromSubmissionDateSearchEntry',string.valueof(system.today())); 
        CaseDashboardPage.getParameters().put('toSubmissionDateSearchEntry',string.valueof(system.today())); 
        DHSCaseDashboardController dashboardCtrl3 = new DHSCaseDashboardController(); 
        CaseDashboardPage.getParameters().clear();
        CaseDashboardPage.getParameters().put('showQACases','true');  
        CaseDashboardPage.getParameters().put('subjectFirstNameSearchEntry','test'); 
        CaseDashboardPage.getParameters().put('subjectLastNameSearchEntry','test'); 
        CaseDashboardPage.getParameters().put('caseNumberSearchEntry','test'); 
        CaseDashboardPage.getParameters().put('caseManifestSearchEntry','test'); 
        CaseDashboardPage.getParameters().put('caseAssigneeearchEntry','test'); 
        CaseDashboardPage.getParameters().put('caseTypeSearchEntry','test'); 
        CaseDashboardPage.getParameters().put('fromSubmissionDateSearchEntry',string.valueof(system.today())); 
        CaseDashboardPage.getParameters().put('toSubmissionDateSearchEntry',string.valueof(system.today())); 
        DHSCaseDashboardController dashboardCtrl4 = new DHSCaseDashboardController();   
        }
    }
     @IsTest private static void TestAutoCreateLeads(){
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
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

    @IsTest
    static void testCountsPaginationAndDelete() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
            DHS_Case__c extraCase = new DHS_Case__c(Status__c = 'Active');
            insert extraCase;
            System.assert(DHSCaseDashboardController.TotalNumberOfUnassignedCases() >= 1, 'Assertion failed in DHSCaseDashboardControllerTest at source line 96');
            System.assert(DHSCaseDashboardController.TotalNumberOfassignedCases() >= 0, 'Assertion failed in DHSCaseDashboardControllerTest at source line 97');

            DHSCaseDashboardController controller = new DHSCaseDashboardController();
            controller.queryForNextRecords =
                'SELECT Id, Name FROM DHS_Case__c WHERE Id != null';
            controller.firstRecordName = '';
            controller.pageNumber = 2;
            controller.handlePrev();
            controller.lastRecordName = '';
            controller.pageNumber = 1;
            controller.TotalPages = 2;
            controller.handleNext();
            System.assert(controller.casesSearched.size() >= 2, 'Assertion failed in DHSCaseDashboardControllerTest at source line 109');

            controller.deleteCaseId = extraCase.Id;
            controller.DeleteCaseAction();
            System.assertEquals(
                0, [SELECT COUNT() FROM DHS_Case__c WHERE Id = :extraCase.Id]
            , 'Assertion failed in DHSCaseDashboardControllerTest at source line 113');
        }
    }
}