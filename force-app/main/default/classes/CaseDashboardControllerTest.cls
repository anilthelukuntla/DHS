@isTest
public class CaseDashboardControllerTest {
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
     }
    testMethod private static void TestMethod1(){ 
        case__c c = [select id from Case__c limit 1];
          CaseDashboardController dashboardCtrl = new CaseDashboardController();   
        dashboardCtrl.subjectFirstNameSearchEntry = 'test';
        dashboardCtrl.subjectLastNameSearchEntry = 'investigator';
          dashboardCtrl.subjectSSNSearchEntry = '999-00-2222';
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
        Integer TotalNumberOfQACases = CaseDashboardController.TotalNumberOfQACases();
        Integer TotalNumberLeadsForCase = CaseDashboardController.TotalNumberLeadsForCase(c.id);
        PageReference CaseDashboardPage = Page.BICaseDashboard;
        Test.setCurrentPage(CaseDashboardPage);
        CaseDashboardPage.getParameters().put('showUnAssigned','true'); 
        CaseDashboardController dashboardCtrl2 = new CaseDashboardController();   
        CaseDashboardPage.getParameters().put('subjectFirstNameSearchEntry','test'); 
        CaseDashboardPage.getParameters().put('subjectLastNameSearchEntry','test'); 
        CaseDashboardPage.getParameters().put('caseNumberSearchEntry','test'); 
        CaseDashboardPage.getParameters().put('caseManifestSearchEntry','test'); 
        CaseDashboardPage.getParameters().put('caseAssigneeearchEntry','test'); 
        CaseDashboardPage.getParameters().put('caseTypeSearchEntry','test'); 
        CaseDashboardPage.getParameters().put('fromSubmissionDateSearchEntry',string.valueof(system.today())); 
        CaseDashboardPage.getParameters().put('toSubmissionDateSearchEntry',string.valueof(system.today())); 
        CaseDashboardController dashboardCtrl3 = new CaseDashboardController(); 
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
        CaseDashboardController dashboardCtrl4 = new CaseDashboardController();   
           
    }
     testMethod private static void TestAutoCreateLeads(){
        Auto_Lead_Generation_Template__c temp = new Auto_Lead_Generation_Template__c(Name__c='Test');
        insert temp;
        Auto_Lead_Generation_Setting__c setting = new Auto_Lead_Generation_Setting__c();
        setting.Auto_Lead_Generation_Template__c =temp.id;
        setting.Coverage_Type__c = 'Personal';
        setting.Item_number__c = 1;
        setting.Lead_Type__c = 'UnEmployment';
        insert setting;
        PageReference casedetailpage = Page.Bicasedetail;
        Test.setCurrentPage(casedetailpage);
        Case__c c = new Case__c();
        insert c;
       
    }
}