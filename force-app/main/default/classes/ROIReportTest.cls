@isTest
public class ROIReportTest {
    testMethod private static void OrderROIReportControllerTest(){ 
        //CaseWizard Page Test Starts...        
        Account acc = new Account(name='ISN');
        insert acc;
        CaseWizardController wizardController = new CaseWizardController();
        //To create new subject
        wizardController.newSubject.First_Name__c = 'test';
        wizardController.newSubject.Last_Name__c = 'investigator';
        wizardController.newSubject.Phone__c = '8197277272';
        wizardController.newSubject.State__c = 'CA';
        wizardController.newSubject.Email__c = 'test.investigator@test.com';
        
        pagereference pref = wizardController.CreateNewSubjectAction();
        //To search for existing subject
        wizardController.subjectFirstNameSearchEntry = 'test';
        wizardController.subjectLastNameSearchEntry = 'investigator';
        wizardController.subjectEmailSearchEntry = 'test.investigator@test.com';
        wizardController.SearchSubjectsAction();
        //check if the subject is present in the system.
        system.assertEquals(1, wizardController.subjectsSearched.size());
        wizardController.subjectsSearched[0].isSelected = true;
        //create a case
        wizardController.CreateCaseAction();
        List<case__c> casesCreated = [Select Id from Case__c];
        //2 cases should be created using CreateCaseAction and CreateNewSubjectAction actions
        system.assertEquals(2,casesCreated.size());
        //CaseWizard Page Test ends...  
        //CaseDashboardController test starts...
        CaseDashboardController dashboardCtrl = new CaseDashboardController();   
        dashboardCtrl.subjectFirstNameSearchEntry = 'test';
        dashboardCtrl.subjectLastNameSearchEntry = 'investigator';
        dashboardCtrl.SearchAction();
        system.assertEquals(2,dashboardCtrl.casesSearched.size());
        dashboardCtrl.casesSearched[0].isSelected = true;
        dashboardCtrl.casesSearched[1].isSelected = true;
        dashboardCtrl.selectedUserIdForAssignment = userinfo.getUserId();
        dashboardCtrl.AssignCasesAction();
        Integer TotalNumberOfQACases = CaseDashboardController.TotalNumberOfQACases();
        Integer TotalNumberLeadsForCase = CaseDashboardController.TotalNumberLeadsForCase(casesCreated[0].id);
        PageReference CaseDashboardPage = Page.CaseDashboard;
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
        //CaseDashboardController test ends...  
        //Case Detail Page Test Starts...
        PageReference casedetailpage = Page.casedetail;
        Test.setCurrentPage(casedetailpage);
        casedetailpage.getParameters().put('id',casesCreated[0].id); 
        casesCreated[0].case_number__c = '1234';
        update casesCreated[0];
        
        
        //Insert a document
        document__c doc = new document__c();
        doc.Case__c = casesCreated[0].id;
        doc.Name__c = 'testingdocument.pdf';
        insert doc;
        Attachment att = new Attachment();
        att.Body = Blob.valueOf('String1');
        att.ParentId = doc.id;
        att.name = 'testingdocument.pdf';
        insert att;
        DownloadDeliverablesController ddctrl = new DownloadDeliverablesController();
        ddctrl.caseNumberToSearch = '1234';
        ddctrl.searchaction();
        CaseDetailController casedetailctrl = new CaseDetailController();
        casesCreated[0].subject_type__c = 'Applicant';
        casedetailctrl.SetPPFContactInfo();
        casesCreated[0].subject_type__c = 'Contractor';
        casedetailctrl.SetPPFContactInfo();
        //create new lead
        casedetailctrl.newLead.LeadType__c = 'Subject Interview (ESI/TESI)';
        casedetailctrl.newLead.Method__c = 'Telephonic';
        casedetailctrl.newLead.Coverage_Type__c = 'Personal';
        casedetailctrl.CreateLeadAction();
        List<Lead__c> leadsCreated = [Select Id from Lead__c];
        //Lead creation check
        system.assertEquals(1,leadsCreated.size());
        casedetailctrl.markleadcreationcompleteaction();
        casedetailctrl.AddCommentsAction();
        casedetailctrl.qareviewcompleteaction();
        casedetailctrl.regenerateroireportbuttonaction();
        casedetailctrl.leadIdToUpdate = leadscreated[0].id;
        casedetailctrl.itemnumbertoupdate = 4;
        casedetailctrl.updatelead();
        casedetailctrl.updatecaseaction();
        
        //Case Detail Page Test ends...
        //LeadDashboardController test starts....
         Test.startTest(); 
        Lead__c lead = [Select Id, status__c, LeadType__c, Assigned_to__c, Lead_Accepted_or_Rejected__c from lead__c limit 1];
        System.debug('lead...'+lead);
        PageReference LeadDashboardPage = Page.LeadDashboard;
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
        //leadDashboardCtrl.leadsSearched[0].isSelected = true;
        leadDashboardCtrl.UnAssignLeadsAction();
        
        //LeadDashboardController test ends....
        //LeadDetailPageController test starts...
        insert new GeneralSettings__c(Name = 'TimeEntryDuringLeadConfirm', Value__c='SCA');
        PageReference leaddetailpage = Page.leaddetail;
        Test.setCurrentPage(leaddetailpage);
        Lead__c tempLead = [Select Id from Lead__c];
        //leaddetailpage.getParameters().put('id',leadDashboardCtrl.leadsSearched[0].ld.id);
        leaddetailpage.getParameters().put('id',tempLead.id);
       
        LeadDetailPageController leadDetailPageCtrl = new LeadDetailPageController();
        leadDetailPageCtrl.updateleadaction();
        leadDetailPageCtrl.completeleadaction();
        leadDetailPageCtrl.selfassignaction();
        pagereference temp = leadDetailPageCtrl.reviewcompletedaction();
        leadDetailPageCtrl.createdocumentrequestaction();
        leadDetailPageCtrl.rejectleadaction();
        
        Test.setCurrentPage(LeadDashboardPage);
        //leadDashboardCtrl.leadIdToAccept = leadDashboardCtrl.leadsSearched[0].ld.id;
        leadDashboardCtrl.leadIdToAccept = tempLead.id;
        leadDashboardCtrl.acceptaction();
        Contact__C con = new contact__c();
        con.First_Name__c = 'test';
        con.Last_Name__c = 'investigator';
        con.Email__c = 'test.investigator@test.com';
        insert con;
        case__c c = new case__c(contact__c = con.id);
        insert c;
        Lead__c l = new Lead__c();
        l.Case__c = c.id;
        insert l;
        leadDashboardCtrl.leadIdToReject = l.id;
        leadDashboardCtrl.rejectaction();
        leadDashboardCtrl.onstatechange();
        //LeadDetailPageController test ends...
        
        PageReference ROIReport = Page.OrderROIReport;
        Test.setCurrentPage(ROIReport);
        ROIReport.getParameters().put('id',casesCreated[0].id);
        OrderROIReportController oCtrl = new OrderROIReportController();
        oCtrl.GenerateROIReport();
        oCtrl.GenerateNattachROIReport();
        ROI_Report_Order__c roiOrder = new ROI_Report_Order__c();
        roiOrder.case__c = casesCreated[0].id;
        roiOrder.ROI_Report_Order__c ='1,2,3';
        insert roiOrder;
        //ROIReportController test starts...
        PageReference ROIReport2 = Page.ROIReportV2;
        Test.setCurrentPage(ROIReport2);
        ROIReport2.getParameters().put('id',casesCreated[0].id);
        ROIReport2.getParameters().put('sequenceid',roiOrder.id);
        ROIReportControllerV2 roictrl = new ROIReportControllerV2 ();
       
    }
    
}