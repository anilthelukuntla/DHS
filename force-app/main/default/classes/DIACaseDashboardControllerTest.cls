@isTest
public class DIACaseDashboardControllerTest {
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
        dia_case__c c = [select id from dia_Case__c limit 1];
          DIACaseDashboardController dashboardCtrl = new DIACaseDashboardController();   
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
        Integer TotalNumberOfQACases = DIACaseDashboardController.TotalNumberOfQACases();
        Integer TotalNumberLeadsForCase = DIACaseDashboardController.TotalNumberLeadsForCase(c.id);
        PageReference CaseDashboardPage = Page.BICaseDashboard;
        Test.setCurrentPage(CaseDashboardPage);
        CaseDashboardPage.getParameters().put('showUnAssigned','true'); 
        DIACaseDashboardController dashboardCtrl2 = new DIACaseDashboardController();   
        CaseDashboardPage.getParameters().put('subjectFirstNameSearchEntry','test'); 
        CaseDashboardPage.getParameters().put('subjectLastNameSearchEntry','test'); 
        CaseDashboardPage.getParameters().put('caseNumberSearchEntry','test'); 
        CaseDashboardPage.getParameters().put('caseManifestSearchEntry','test'); 
        CaseDashboardPage.getParameters().put('caseAssigneeearchEntry','test'); 
        CaseDashboardPage.getParameters().put('caseTypeSearchEntry','test'); 
        CaseDashboardPage.getParameters().put('fromSubmissionDateSearchEntry',string.valueof(system.today())); 
        CaseDashboardPage.getParameters().put('toSubmissionDateSearchEntry',string.valueof(system.today())); 
        DIACaseDashboardController dashboardCtrl3 = new DIACaseDashboardController(); 
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
        DIACaseDashboardController dashboardCtrl4 = new DIACaseDashboardController();   
           
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
        DIA_Case__c c = new DIA_Case__c();
        insert c;
        casedetailpage.getParameters().put('id',c.id); 
        DIACaseDetailController ctrl = new DIACaseDetailController();
        ctrl.selectedLeadTemplateId = temp.id;
        ctrl.autocreateleads();
    }
}