@isTest
/** Exercises the existing IntelModule behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.AvoidNonRestrictiveQueries, PMD.DebugsShouldUseLoggingLevel, PMD.LocalVariableNamingConventions, PMD.MethodNamingConventions, PMD.NcssCount, PMD.NcssMethodCount, PMD.UnusedLocalVariable')
public class IntelModuleTest {
      private static void legacyCaseNLeadFlow1(){ 
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
        //wizardController.SearchSubjectsAction();
        list<CaseWizardController.SubjectRecord> tempsubj = new list<CaseWizardController.SubjectRecord>();
        for(contact__c con: [select id,first_name__c,last_name__c,email__c from contact__c]){
            tempsubj.add(new CaseWizardController.SubjectRecord(con));
        }
        wizardController.subjectsSearched = tempsubj;
        //check if the subject is present in the system.
        system.assertEquals(1, wizardController.subjectsSearched.size(), 'Assertion failed in IntelModuleTest at source line 29');
        wizardController.subjectsSearched[0].isSelected = true;
        //create a case
        wizardController.CreateCaseAction();
        List<case__c> casesCreated = [Select Id,Case__c.Case_Discontinued__c,Contact__r.Email__c,contact__r.First_Name__c,contact__r.Last_Name__c from Case__c];
        //2 cases should be created using CreateCaseAction and CreateNewSubjectAction actions
        system.assertEquals(2,casesCreated.size(), 'Assertion failed in IntelModuleTest at source line 36');
        //CaseWizard Page Test ends...  
        //CaseDashboardController test starts...
        CaseDashboardController dashboardCtrl = new CaseDashboardController();   
        dashboardCtrl.subjectFirstNameSearchEntry = 'test';
        dashboardCtrl.subjectLastNameSearchEntry = 'investigator';
        dashboardCtrl.subjectSSNSearchEntry = '123123123';
        dashboardCtrl.caseStatusSearchEntry = 'QA and Review';
		dashboardCtrl.fromSubmissionDateSearchEntry = system.today();
        dashboardCtrl.toSubmissionDateSearchEntry = system.today();
        dashboardCtrl.caseNumberSearchEntry = 'Test-123';
        dashboardCtrl.caseManifestSearchEntry = date.today().tostring();
        dashboardCtrl.caseTypeSearchEntry = 'Tier 5';
        dashboardCtrl.SearchAction();
        dashboardCtrl.casesSearched[0].isSelected = true;
        
        dashboardCtrl.selectedUserIdForAssignment = userinfo.getUserId();
        case__c caseSample = [select id from case__c limit 1];
        dashboardCtrl.casesSearched[0].cs = caseSample;
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
        system.assertEquals(1,leadsCreated.size(), 'Assertion failed in IntelModuleTest at source line 117');
        casesCreated[0].Customer_Delivery_Date__c = system.today();
        casesCreated[0].contact__r.First_Name__c = 'Test';
        casesCreated[0].contact__r.Last_Name__c = 'Test';
        casesCreated[0].case_discontinued__c = true;
        update casesCreated[0];
        
        casedetailctrl.markleadcreationcompleteaction();
        casedetailctrl.AddCommentsAction();
        casedetailctrl.qareviewcompleteaction();
        casedetailctrl.regenerateroireportbuttonaction();
        casedetailctrl.leadIdToUpdate = leadscreated[0].id;
        casedetailctrl.itemnumbertoupdate = 4;
        casedetailctrl.updatelead();
        casedetailctrl.selectedUserIdForAssignment = userinfo.getuserId();
        casedetailctrl.caseRecord = casesCreated[0];
        
        casedetailctrl.updatecaseaction();
        
        //Case Detail Page Test ends...
        //LeadDashboardController test starts....
         Test.startTest(); 
        Lead__c lead = [Select Id,case__c, status__c, LeadType__c, Assigned_to__c, Lead_Accepted_or_Rejected__c from lead__c limit 1];
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
        LeadDashboardPage.getParameters().put('streetaddressSearchEntry','test');
        LeadDashboardPage.getParameters().put('seachqarejected','true');
        LeadDashboardPage.getParameters().put('searchUnassigned','false');
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
        system.assertEquals(1,leadDashboardCtrl.leadsSearched.size(), 'Assertion failed in IntelModuleTest at source line 169');
        //leadDashboardCtrl.leadsSearched[0].case__c = casesCreated[0].id;
        leadDashboardCtrl.selectedUserIdForAssignment = userinfo.getUserId();
        leadDashboardCtrl.leadsSearched[0].ld = lead;
        leadDashboardCtrl.leadsSearched[0].isSelected = true;
        leadDashboardCtrl.AssignLeadsAction();
        leadDashboardCtrl.UpdateACDLead();
        leadDashboardCtrl.leadsSearched[0].isSelected = true;
        Lead__c leads = [select id from lead__c limit 1];
        leadDashboardCtrl.leadsSearched[0].ld = leads;
        leadDashboardCtrl.UnAssignLeadsAction();
        message__c m = new message__c();
        m.case__c = caseSample.id;
        insert m;
        
        
        Test.stopTest();
    }
    private static void legacyCaseNLeadFlow(){ 
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
        //wizardController.SearchSubjectsAction();
        //check if the subject is present in the system.
        list<CaseWizardController.SubjectRecord> tempsubj = new list<CaseWizardController.SubjectRecord>();
        for(contact__c con: [select id,first_name__c,last_name__c,email__c from contact__c]){
            tempsubj.add(new CaseWizardController.SubjectRecord(con));
        }
        wizardController.subjectsSearched = tempsubj;
        system.assertEquals(1, wizardController.subjectsSearched.size(), 'Assertion failed in IntelModuleTest at source line 212');
        wizardController.subjectsSearched[0].isSelected = true;
        //create a case
        wizardController.CreateCaseAction();
        List<case__c> casesCreated = [Select Id,Case__c.Case_Discontinued__c,Contact__r.Email__c,contact__r.First_Name__c,contact__r.Last_Name__c from Case__c];
        //2 cases should be created using CreateCaseAction and CreateNewSubjectAction actions
        system.assertEquals(2,casesCreated.size(), 'Assertion failed in IntelModuleTest at source line 219');
        //CaseWizard Page Test ends...  
        //CaseDashboardController test starts...
        CaseDashboardController dashboardCtrl = new CaseDashboardController();   
        dashboardCtrl.subjectFirstNameSearchEntry = 'test';
        dashboardCtrl.subjectLastNameSearchEntry = 'investigator';
        dashboardCtrl.subjectSSNSearchEntry = '123123123';
        dashboardCtrl.caseStatusSearchEntry = 'QA and Review';
		dashboardCtrl.fromSubmissionDateSearchEntry = system.today();
        dashboardCtrl.toSubmissionDateSearchEntry = system.today();
        dashboardCtrl.caseNumberSearchEntry = 'Test-123';
        dashboardCtrl.caseManifestSearchEntry = date.today().tostring();
        dashboardCtrl.caseTypeSearchEntry = 'Tier 5';
        dashboardCtrl.SearchAction();
        dashboardCtrl.casesSearched[0].isSelected = true;
        dashboardCtrl.selectedUserIdForAssignment = userinfo.getUserId();
        case__c caseSample = [select id from case__c limit 1];
        dashboardCtrl.casesSearched[0].cs = caseSample;
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
        string query1='select id from message__c where id != Null ';
		casedetailctrl.queryForNextRecords = query1; 
        casedetailctrl.currentRecordCount = 10;
        casedetailctrl.lastRecordName = 'test';
        casedetailctrl.handleNext();
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
        system.assertEquals(1,leadsCreated.size(), 'Assertion failed in IntelModuleTest at source line 304');
        casesCreated[0].Customer_Delivery_Date__c = system.today();
        casesCreated[0].contact__r.First_Name__c = 'Test';
        casesCreated[0].contact__r.Last_Name__c = 'Test';
        casesCreated[0].case_discontinued__c = true;
        update casesCreated[0];
        
        casedetailctrl.markleadcreationcompleteaction();
        casedetailctrl.AddCommentsAction();
        casedetailctrl.qareviewcompleteaction();
        casedetailctrl.regenerateroireportbuttonaction();
        casedetailctrl.leadIdToUpdate = leadscreated[0].id;
        casedetailctrl.itemnumbertoupdate = 4;
        casedetailctrl.updatelead();
        casedetailctrl.selectedUserIdForAssignment = userinfo.getuserId();
        casedetailctrl.caseRecord = casesCreated[0];
        
        casedetailctrl.updatecaseaction();
        
        //Case Detail Page Test ends...
        //LeadDashboardController test starts....
         Test.startTest(); 
        Lead__c lead = [Select Id,case__c, status__c, LeadType__c, Assigned_to__c, Lead_Accepted_or_Rejected__c from lead__c limit 1];
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
        LeadDashboardPage.getParameters().put('streetaddressSearchEntry','test');
        LeadDashboardPage.getParameters().put('seachqarejected','true');
        LeadDashboardPage.getParameters().put('searchUnassigned','false');
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
        system.assertEquals(1,leadDashboardCtrl.leadsSearched.size(), 'Assertion failed in IntelModuleTest at source line 356');
        //leadDashboardCtrl.leadsSearched[0].case__c = casesCreated[0].id;
        leadDashboardCtrl.selectedUserIdForAssignment = userinfo.getUserId();
        leadDashboardCtrl.leadsSearched[0].ld = lead;
        leadDashboardCtrl.leadsSearched[0].isSelected = true;
        leadDashboardCtrl.AssignLeadsAction();
        leadDashboardCtrl.UpdateACDLead();
        leadDashboardCtrl.leadsSearched[0].isSelected = true;
        
        //leadDashboardCtrl.UnAssignLeadsAction();
        //leadDashboardCtrl.AssignLeadsAction();
        
        //LeadDashboardController test ends....
        //LeadDetailPageController test starts...
        insert new GeneralSettings__c(Name = 'TimeEntryDuringLeadConfirm', Value__c='SCA');
        PageReference leaddetailpage = Page.leaddetail;
        Test.setCurrentPage(leaddetailpage);
        Lead__c tempLead = [Select Id,case__c,name from Lead__c limit 1];
        //leaddetailpage.getParameters().put('id',leadDashboardCtrl.leadsSearched[0].ld.id);
        leaddetailpage.getParameters().put('id',tempLead.id);
       
        LeadDetailPageController leadDetailPageCtrl = new LeadDetailPageController();
         string query='select id from message__c where id != Null ';
		leadDetailPageCtrl.queryForNextRecords = query; 
        leadDetailPageCtrl.currentRecordCount = 10;
        leadDetailPageCtrl.lastRecordName = tempLead.name;
        leadDetailPageCtrl.handleNext();
        List<SelectOption> options = leadDetailPageCtrl.StandardisedIssueOptions;
        leadDetailPageCtrl.updateleadaction();
        leadDetailPageCtrl.hoursofleadcompletion = 02;
        leadDetailPageCtrl.minutesofleadcompletion = 30;
        leadDetailPageCtrl.isValidForRTAExtension = true;
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
        
       
         Test.stopTest();
        //ROIReportControllerV2 test starts...
        PageReference ROIReport = Page.ROIReport;
        Test.setCurrentPage(ROIReport);
        ROIReport.getParameters().put('id',casesCreated[0].id);
        ROIReportControllerV2 roictrl = new ROIReportControllerV2 ();
        //ROIReportControllerV2 test starts...
        Document_Request__c dr = new Document_Request__c();
        dr.Expiration_Date__c =system.today().adddays(1);
        dr.Status__c = 'Documents Requested';
        dr.Lead__c  = [select id from lead__c limit 1].id;
        dr.To_Address__c = 'test@test.com';
        insert dr;
        
        string encodedcaseId = EncodingUtil.base64Encode(blob.valueof(dr.id));
        PageReference SubjectDocumentsUpload = Page.SubjectDocumentsUpload;
        Test.setCurrentPage(SubjectDocumentsUpload);
        SubjectDocumentsUpload.getParameters().put('id',encodedcaseId);
        SubjectDocumentsUploadController sdcCtrl = new SubjectDocumentsUploadController();
        sdcCtrl.submitaction();
        
        dashboardCtrl.deleteCaseId = casesCreated[0].id;
        dashboardCtrl.DeleteCaseAction();
        
       
    }
    @IsTest private static void TestOnboarding(){
        Intel_Docusign_Templates__c idt = new Intel_Docusign_Templates__c ();
        idt.Name = 'ISN ICA PaperProof';
        idt.Template_Name__c = 'ISN ICA PaperProof';
        idt.Template_ID__c = '680382d1-8d7d-4b16-a94f-cdf6bd66785a';
        idt.Number_of_Signers__c = '2';
        idt.DocusignEmailMessage__c = 'ISN ICA PaperProof';
        idt.DocusignEmailSubject__c  = 'ISN ICA PaperProof';
        idt.DocusignExpireEnabled__c = 'true';
        idt.DocusignExpireAfter__c = '1';
        idt.DocusignExpireWarn__c = '1';
        idt.DocusignReminderEnabled__c = 'true';
        idt.DocusignReminderDelay__c = '1';
        idt.DocusignReminderFrequency__c = '1';
        Account acc = new Account(Name='ISN');
        insert acc;
        OnBoardingController onboardingCtrl = new OnBoardingController();
        onboarding__c onboardingUser = new onboarding__c();
        onboardingUser.First_Name__c = 'test';
        onboardingUser.Last_Name__c = 'investigator';
        onboardingUser.Email__c = 'testinvestigator@test.com';
        onboardingUser.Candidate_type__c = 'SCA';
        onboardingUser.User_Created__c = false;
        //insert onboardingUser;
        //System.debug('onboardingUser id in test class...'+onboardingUser.id);
        //CreateUserFromOnboardingBatch ctrl = new CreateUserFromOnboardingBatch(onboardingUser.id);
        //database.executeBatch(ctrl);
        //System.assertEquals(1, [Select Id from onboarding__c].size());
        onboardingCtrl.newuser.First_Name__c = 'test';
        onboardingCtrl.newuser.Last_Name__c = 'investigator';
        onboardingCtrl.newuser.Email__c = 'testinvestigator@test.com';
        onboardingCtrl.newuser.Candidate_type__c = 'SCA';
        onboardingCtrl.newuser.User_Created__c = false;
        onboardingCtrl.newuser.Send_Credentials_To_User__c = true;
        onboardingCtrl.CreateNewUser();
        List<Onboarding__c> onboardings = [Select id, first_name__c, last_name__c,Email__c from onboarding__c];
        onboardingCtrl.editOnboardingUserId = onboardings[0].id;
        onboardingCtrl.editOnboardingUser();
        onboardingCtrl.SendToDocusign();
        onboardingCtrl.SaveModifiedOnboardingUser();
        onboardingCtrl.deleteOnboardingUserId = onboardings[0].id;
        onboardingCtrl.DeleteOnboardingUser();
    }
    @IsTest private static void TesttimesheetsController(){
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
        ScheduleCreateTimesheetsBatch schedulableBatchCtrl = new ScheduleCreateTimesheetsBatch(); 
        schedulableBatchCtrl.execute(null);
        DateTime todaysDateTime = System.now();
        Integer currentDayOfMonth = todaysDateTime.day();
        Integer month = Date.Today().Month();
        Integer year = Date.Today().Year();
        Integer numberDays = Date.daysInMonth(year, month);
        Date startDate;
        Date endDate;
        if(currentDayOfMonth >= 1 && currentDayOfMonth <= 15){
            startDate = Date.newinstance(year, month, 1);
            endDate = Date.newinstance(year, month, 15);
        }
        if(currentDayOfMonth >= 16){
            startDate = Date.newinstance(year, month, 16);
            endDate = Date.newinstance(year, month, numberDays);
        }
        TimeSheet__c timeSheet = new TimeSheet__c();
        timeSheet.Period_From__c = startDate;
        timeSheet.Period_to__c = endDate;
        timeSheet.Date__c = Date.newinstance(year, month, todaysDateTime.day());
        timeSheet.Day_Name__c = DateTime.newInstance(year, month, todaysDateTime.day()).format('EEEE');
        timeSheet.User__c = userinfo.getuserid();
        insert timeSheet;
        TimesheetsController ctrl = new TimesheetsController();
        ctrl.addNewInvestigatorCheck();
        ctrl.addNewInvestigatorCheck();        
        ctrl.checkoutapexaction();
        ctrl.checkinapexaction();
        System.assertNotEquals(null, ctrl.timesheets, 'Assertion failed in IntelModuleTest at source line 516');
        }
    }
   
    @IsTest private static void TestPayrollSettingsController(){
        PayrollSettingsController payrollsettingsCtrl = new PayrollSettingsController();
        payrollsettingsCtrl.UpdatePayrollSettings();
        ContractSettingsController ctrl = new ContractSettingsController();
        
    }
    
    @IsTest private static void TestMyMessagesController(){
        Case__c c = new Case__c();
        c.case_number__c = 'test';
        c.assigned_to__c = userinfo.getuserid();
        insert c;
        Message__c message = new Message__c();
        message.Message_Body__c = 'Test';
        message.subject__c = 'Test Subject';
        message.From_User__c = userinfo.getUserId();
        message.to_user__c = userinfo.getUserId();
        message.read__c =false;  
        message.unread__c =true; 
        message.case__c = c.id;  
        insert message;
        MyMessagesController mymessagesCtrl = new MyMessagesController();
        mymessagesCtrl.currentMessageId = message.id;
        mymessagesCtrl.FetchCurrentMessageAction();
        mymessagesCtrl.messageBody = 'Test';
        mymessagesCtrl.messageSubject = 'Test';
        mymessagesCtrl.selecteToAddressOption = 'All Program Members';
        mymessagesCtrl.SendMessage();
        mymessagesCtrl.RefreshAction();
        mymessagesCtrl.selecteToAddressOption = 'All Investigators';
        mymessagesCtrl.SendMessage();
        mymessagesCtrl.selecteToAddressOption = 'All PMOs';
        mymessagesCtrl.SendMessage();
        mymessagesCtrl.selecteToAddressOption = 'All CMOs';
        mymessagesCtrl.SendMessage();
        mymessagesCtrl.selecteToAddressOption = 'All QAs';
        mymessagesCtrl.SendMessage();
    }
    
    @IsTest private static void TestMisc(){
        IntelHeaderController ctrl = new IntelHeaderController();
        user currentUser = [Select Id, User_Type__c from User where Id=:userinfo.getuserid()];
        currentUser.User_Type__c = 'CMO';
        update currentUser;
        IntelHeaderController ctrl2 = new IntelHeaderController();
        currentUser = [Select Id, User_Type__c from User where Id=:userinfo.getuserid()];
        currentUser.User_Type__c = 'QA';
        update currentUser;
        IntelHeaderController ctrl3 = new IntelHeaderController();
        currentUser = [Select Id, User_Type__c from User where Id=:userinfo.getuserid()];
        currentUser.User_Type__c = 'INV';
        update currentUser;
        IntelHeaderController ctrl5 = new IntelHeaderController();
        currentUser = [Select Id, User_Type__c from User where Id=:userinfo.getuserid()];
        currentUser.User_Type__c = 'PMO';
        update currentUser;
        IntelHeaderController ctrl4 = new IntelHeaderController();
        customer_order__c co = new customer_order__c(status__c = 'Uploaded'); insert co;
        customer_order__c co1 = new customer_order__c(status__c = 'Executed'); insert co1;        
        CustomerInterfaceController ciCtrl = new CustomerInterfaceController();
        
        onboarding__c onboardingUser = new onboarding__c();
        onboardingUser.First_Name__c = 'test';
        onboardingUser.Last_Name__c = 'investigator';
        onboardingUser.Email__c = 'testinvestigator@test.com';
        onboardingUser.Candidate_type__c = 'SCA';
        onboardingUser.User_Created__c = false;
        insert onboardingUser;
        
         Account acc = new Account(Name='ISN');
        insert acc;
        CreateUserFromOnboardingBatch CreateUserFromOnboardingBatchctrl = new CreateUserFromOnboardingBatch(onboardingUser.id);
        database.executeBatch(CreateUserFromOnboardingBatchctrl);
         PageReference IntelProfilePage = Page.IntelProfilePage;
        Test.setCurrentPage(IntelProfilePage);
        IntelProfilePage.getParameters().put('id',userinfo.getUserId());
        IntelProfilePageController ipc = new IntelProfilePageController();
        currentUser.Out_of_office__c = 'Vacation';
        ipc.updatefieldfisibility();
        
        ContentVersion content=new ContentVersion(); 
        content.Title='2022-02-11-12_46_39S_12313123123'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        //content.LinkedEntityId=sPayoff.id;
        content.origin = 'H';
        insert content;
        
        //List<Schema.FieldSetMember> temp = ApexUtil.readFieldSet('OnboardingUser','OnboardingUser__c');
        Map<String, Id> temp2 =  ApexUtil.buildMapOfRecordTypes('Lead__c');
        Map<String, Schema.SObjectType> globalDescMap=Schema.getGlobalDescribe();
        Schema.SObjectType targetType=globalDescMap.get('Lead__c');
        sObject sObj=targetType.newSObject();
        list<String> temp24 = apexutil.getPickListValues(sObj,'LeadType__c');
        //list<string> temp3 = apexutil.getFieldSetFields('OnboardingUser','OnboardingUser__c');
        Map<object,object> temp5 = apexutil.getSObjectFieldTypes('Lead__c');
        List<string> userFields = ApexUtil.FetchFields('User');
        List<String> userFilters = new List<String>();
        userFilters.add('id =: currentUserId');
        String userQuery = ApexUtil.queryBuilder('User', userFields, userFilters);
        String onboardingQuery = ApexUtil.queryBuilder('Onboarding__c', 'OnboardingUser', new list<string>{});
    }
    @IsTest private static void ShippingDetailsControllerTest(){
        Case__c c = new Case__c();
        insert c;
        PPF_Shipping_Information__c ppf = new PPF_Shipping_Information__c();
        ppf.Manifest_Number__c  = 'test';  
        ppf.case__c = c.id;  
        insert ppf;
        
        
        User thisUser = [select Id from User where Id = :UserInfo.getUserId()];
        ID ProfileID = [ Select id,UserType from Profile where name = 'Customer Community Investigator User'].id;
        
        Account A1 = new Account(Name = 'Test Account', OwnerId=thisUser.Id );
        insert A1;
        
        Contact C1 = new Contact( AccountID = A1.id, FirstName = 'Test', LastName = 'User', 
        email = 'test-user@fakeemail.com' );
        insert C1; 
        
        User u1 = new User( email='test-user@fakeemail.com', contactid = c1.id, profileid = profileID, 
                  UserName='test-user@fakeemail.com', alias='tuser1', CommunityNickName='tuser1', 
                  TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1', 
                  LanguageLocaleKey='en_US', FirstName = 'Test', LastName = 'User',User_Type__c='INV');
        insert u1;
       
        system.runAs(u1){
            ShippingDetailsController ctrl = new ShippingDetailsController();
            ctrl.selectedcaseidforshipping = c.id;
            ctrl.onselectofcase();
            ctrl.createppfshippinginformationaction();
        }
    }
    
     @IsTest private static void ShippingDetailsControllerTest2(){
        Case__c c = new Case__c();
        insert c;
        PPF_Shipping_Information__c ppf = new PPF_Shipping_Information__c();
        ppf.Manifest_Number__c  = 'test';  
        ppf.case__c = c.id;  
        insert ppf;
        
        
        User thisUser = [select Id from User where Id = :UserInfo.getUserId()];
        ID ProfileID = [ Select id,UserType from Profile where name = 'Customer Community Investigator User'].id;
        
        Account A1 = new Account(Name = 'Test Account', OwnerId=thisUser.Id );
        insert A1;
        
        Contact C1 = new Contact( AccountID = A1.id, FirstName = 'Test', LastName = 'User', 
        email = 'test-user@fakeemail.com' );
        insert C1; 
        
        User u1 = new User( email='test-user@fakeemail.com', contactid = c1.id, profileid = profileID, 
                  UserName='test-user@fakeemail.com', alias='tuser1', CommunityNickName='tuser1', 
                  TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1', 
                  LanguageLocaleKey='en_US', FirstName = 'Test', LastName = 'User',User_Type__c='QA');
        insert u1;
       
        system.runAs(u1){
            ShippingDetailsController ctrl = new ShippingDetailsController();
            ctrl.selectedcaseidforshipping = c.id;
             ctrl.onselectofcase();
             ctrl.updateppfshippinginformationaction();
        }
    }
    
    @IsTest private static void MyTrainingsControllerTest(){
        Training__c training = new Training__c();
        training.user__c = userinfo.getuserid();
        training.Training_Name__c = 'test';
        insert training;
        MyTrainingsController ctrl= new MyTrainingsController();
    
    }
    
    @IsTest private static void KnowledgeBaseControllerTest(){
        Knowledge_Base__c kb  = new Knowledge_Base__c();
        kb.name__c = 'test';
        insert kb;
        attachment att = new attachment();
        att.parentId = kb.id;
        att.name = 'test';
        att.body = blob.valueof('test');
        insert att;
        
        KnowledgeBaseController ctrl = new KnowledgeBaseController();
    
    }
    @IsTest private static void CaseTriggerTest(){
        Case__c c = new Case__c();
        insert c;
        c.case_type__c = 'Tier 5';
        c.service_days__c = '20';
        c.Scheduled_Date__c = system.today();
        update c;
        c.Scheduled_Date__c = system.today().addDays(10);
        update c;
        c.Scheduled_Date__c = system.today().addDays(15);
        update c;
        c.Scheduled_Date__c = system.today().addDays(18);
        update c;
        c.Scheduled_Date__c = system.today().addDays(22);
        update c;
        c.case_type__c = 'Tier 5';
        c.service_days__c = '40';
        c.Scheduled_Date__c = system.today();
        update c;
        c.Scheduled_Date__c = system.today().addDays(20);
        update c;
        c.Scheduled_Date__c = system.today().addDays(30);
        update c;
        c.Scheduled_Date__c = system.today().addDays(35);
        update c;
        c.Scheduled_Date__c = system.today().addDays(42);
        update c;
        c.case_type__c = 'Tier 5 Reinvestigation';
        c.service_days__c = '60';
        c.Scheduled_Date__c = system.today();
        update c;
        c.Scheduled_Date__c = system.today().addDays(35);
        update c;
        c.Scheduled_Date__c = system.today().addDays(45);
        update c;
        c.Scheduled_Date__c = system.today().addDays(57);
        update c;
        c.Scheduled_Date__c = system.today().addDays(62);
        update c;
        
        c.case_type__c = 'Triggered Investigation';
        c.service_days__c = '30';
        c.Scheduled_Date__c = system.today();
        update c;
        c.Scheduled_Date__c = system.today().addDays(15);
        update c;
        c.Scheduled_Date__c = system.today().addDays(23);
        update c;
        c.Scheduled_Date__c = system.today().addDays(27);
        update c;
        c.Scheduled_Date__c = system.today().addDays(32);
        update c;
    }
    
    @IsTest private static void CDRLReportsControllerTest(){
        Case__c c = new Case__c();
        c.case_number__c = 'test';
        insert c;
        lead__c lead = new lead__c();
        lead.case__c = c.id;
        lead.status__C = 'Assigned';
        insert lead;
        Document__c doc = new Document__c();
        doc.Case__c = c.id;
        
        insert doc;
        attachment att = new attachment();
        att.parentId = doc.id;
        att.name = 'ROIReport.pdf';
        att.body = blob.valueof('test');
        insert att;
        
        CDRLReportsController.getFieldMap('CDRLCaseExport');
        CDRLReportsController.getFieldMap('CDRLCheckInCheckOut');
        CDRLReportsController.getFieldMap('CDRLLeadExport');
        CDRLReportsController.getFieldMap('CDRLMessageExport');
        CDRLReportsController.getFieldMap('CDRLWaiverExport');
        CDRLReportsController ctrl = new CDRLReportsController();
        ctrl.selectedReportType = 'ROIReport';
        ctrl.fromDate = System.today().addDays(-2);
        ctrl.toDate = System.today();
        ctrl.RunReportAction();
        ctrl.selectedReportType = 'Completed Cases';
        ctrl.OnReportTypeSelect();
        ctrl.selectedCMoUser = 'All';
        ctrl.RunReportAction();
        ctrl.selectedReportType = 'Completed Leads';
        ctrl.OnReportTypeSelect();
        ctrl.handleNext();
        ctrl.handlePrev();
        ctrl.selectedinvestigatorUser = 'All';
        ctrl.RunReportAction();
        ctrl.selectedReportType = 'Case';
        ctrl.fiveorlessitemsofcase = false;
        ctrl.firstRecordName = c.Name;
        ctrl.queryForNextRecords = 'Select id from Case__c where ';
        ctrl.handleNext();
        ctrl.handlePrev();
        ctrl.OnReportTypeSelect();
        ctrl.RunReportAction();
        ctrl.selectedReportType = 'Lead';
        ctrl.selectedleadforstatustracking = lead.Id;
        ctrl.queryForNextRecords = 'Select id from Lead__c where ';
        ctrl.firstRecordName = lead.Name;
        ctrl.handleNext();
        ctrl.handlePrev();
        ctrl.FetchLeadStatusTrackings();
        ctrl.OnReportTypeSelect();
        lead.status__C='Assigned';
        lead.Assigned_to__c = userinfo.getuserid();
        update lead;
        List<lead__c> leads = new List<lead__C>();
        leads = [select id, status__C from lead__C ];
        ctrl.SelectedLeadStatus = 'Assigned';
        ctrl.RunReportAction();
        ctrl.OnReportTypeSelect();
        ctrl.SelectedLeadStatus = 'Assigned Not Accepted';
        ctrl.RunReportAction();
        ctrl.SelectedRelatedCaseIdForMessages = c.id;
        ctrl.selectedReportType = 'Messages';
        ctrl.queryForNextRecords = 'Select id from Message__c where ';
        ctrl.OnReportTypeSelect();
        ctrl.RunReportAction();
        ctrl.handleNext();
        ctrl.handlePrev();
        //ctrl.handlePrev();
        ctrl.selectedReportType = 'Check-in/Check-out';
        ctrl.RunReportAction();
        ctrl.queryForNextRecords = 'Select id from Investigator_Check__c where ';
        ctrl.handleNext();
        ctrl.handlePrev();
        //ctrl.handlePrev();
        ctrl.selectedReportType = 'Waivers';
        ctrl.RunReportAction();
        ctrl.queryForNextRecords = 'Select id from waiver_information__c where ';
        ctrl.handleNext();
        ctrl.handlePrev();
        //ctrl.handlePrev();
        ctrl.fromDate = System.today().addDays(-2);
        ctrl.toDate = System.today();
        ctrl.selectedReportType = 'Investigator Reports';
        ctrl.RunReportAction();
        //ctrl.handlePrev();
    }
    
    @IsTest private static void IntelAutoCompleteControllerTest1() {
        User u = [Select Id, Email, FirstName from User where Id =:UserInfo.getUserId()];
        Test.setCurrentPage(Page.IntelAutoCompleteJSON);
        ApexPages.currentPage().getParameters().put('q',u.FirstName);
        ApexPages.currentPage().getParameters().put('obj','User');
        ApexPages.currentPage().getParameters().put('label','FirstName');
        ApexPages.currentPage().getParameters().put('detail','Email');
        ApexPages.currentPage().getParameters().put('value','Id');
        IntelAutoCompleteController ctrl = new IntelAutoCompleteController();
        ctrl.getJSON();
    
      }
    
     @IsTest private static void IntelAutoCompleteControllerTest2() {
        User u = [Select Id, Email, FirstName,LastName from User where Id =:UserInfo.getUserId()];
        Test.setCurrentPage(Page.IntelAutoCompleteJSON);
        ApexPages.currentPage().getParameters().put('q',u.FirstName);
        ApexPages.currentPage().getParameters().put('obj','User');
        ApexPages.currentPage().getParameters().put('label','FirstName');
        ApexPages.currentPage().getParameters().put('detail','Email,LastName');
        ApexPages.currentPage().getParameters().put('value','Id');
        IntelAutoCompleteController ctrl = new IntelAutoCompleteController();
        ctrl.getJSON();
     }
     
     private static void legacyCaseNLeadMessages() {
         Account acc = new Account(Name='ISN');
         insert acc;
         Contact con = new Contact();
         con.FirstName = 'test';
         con.LastName = 'test';
         con.Email = 'test@test.com';
         insert con;
         case__c c = new case__c();
         c.assigned_to__c = userinfo.getuserid();
         c.case_number__c = 'test';
         insert c;
         try {
             MailUtilities.sendHTMLEmail(
                 new List<String> {'test@test.com'},
                 'test',
                 'test',
                 null,
                 'New Case Assigned',
                 c.id
             );
         } catch (EmailException exceptionValue) {
             System.assert(
                 exceptionValue.getMessage().contains('MAIL_PERMISSION'),
                 exceptionValue.getMessage()
             );
         }
         Lead__c l = new lead__c();
         l.case__c = c.id;
         l.assigned_to__c = userinfo.getuserid();
         insert l;
         l.Reason_for_Waiver__c = 'Subject not available';
         update l;
         l.Lead_Accepted_or_Rejected__c ='Rejected';
         update l;
         PageReference casedetailpage = Page.casedetail;
         Test.setCurrentPage(casedetailpage);
         casedetailpage.getParameters().put('id',c.id);
         casedetailcontroller ctrl = new casedetailcontroller();
         ctrl.SendMessage();
         ctrl.SendMessage('test', 'test', l.Id);
         //ctrl.downloadmanifestaction();
         insert new GeneralSettings__c(Name = 'TimeEntryDuringLeadConfirm', Value__c='SCA');
         PageReference leaddetailpage = Page.leaddetail;
         Test.setCurrentPage(leaddetailpage);
         leaddetailpage.getParameters().put('id',l.id);
         leaddetailpagecontroller leadctrl = new leaddetailpagecontroller();
         leadctrl.SendMessage();
         leadctrl.leadRecord = l;
         PageReference pref = leadctrl.applyforwaiveraction();
         leadctrl.rejectleadaction();
         leadctrl.reopenleadaction();
         leadctrl.deleteleadaction();
     }
     @IsTest private static void ForesiteFileUploadPageControllerTest(){
        Case__c c = new Case__c();
        c.case_number__c = 'test';
        insert c;
         PageReference ForesiteFileUploadPage = Page.ForesiteFileUploadPage;
         Test.setCurrentPage(ForesiteFileUploadPage);
         ForesiteFileUploadPage.getParameters().put('caseid',c.id);
         Attachment att = new Attachment();
         att.body = blob.valueOf('testing');
         att.Name = 'testing';
         ApexPages.StandardController sc = new ApexPages.StandardController(att);
         ForesiteFileUploadPageController ctrl = new ForesiteFileUploadPageController(sc);
         PageReference pref = ctrl.saveAndRedirect(); 
     }
     
     @IsTest private static void IntelDeliverablesControllerTest(){
        Case__c c = new Case__c();
        c.case_number__c = 'test';
        c.current_task__c = 'QA Review Completed';
        insert c;
           //Insert a document
        document__c doc = new document__c();
        doc.Case__c = c.id;
        doc.Name__c = 'ROIReport';
        insert doc;
        Attachment att = new Attachment();
        att.Body = Blob.valueOf('String1');
        att.ParentId = doc.id;
        att.name = 'testingdocument.pdf';
        insert att;
        IntelDeliverablesController ctrl = new IntelDeliverablesController();
        ctrl.selectedcaseOptions.add(new selectoption(c.id,c.case_number__c));
        ctrl.FetchCaseList();
        //ctrl.FetchAttachmentsList();
        //ctrl.downloadmanifestaction();
     } 
     
     @IsTest private static void LeadUploadPage(){
         Account acc = new Account(Name='ISN');
         insert acc;
         Contact con = new Contact();
         con.FirstName = 'test';
         con.LastName = 'test';
         con.Email = 'test@test.com';
         insert con;
         Case__c c = new Case__c();
         c.case_number__c = 'AG321IL';
         insert c;
         String leadData = 'Case Number,Case Name,Item_number__c,LeadType__c,Coverage_Type__c,Lead_Contact_Name__c,Lead_Contact_Address__c,Lead_Contact_City__c,Lead_Contact_State__c,Lead_Contact_Zip__c,Lead_Contact_Other_Information__c\nAG321IL,,9,Subject Interview (ESI/TESI),Subject Interview,John,45 South Street,Big Canyon,Texas,79848,United States';
         Blob fileData = blob.valueof(leadData);
         LeadsUploadPageController ctrl = new LeadsUploadPageController();
         ctrl.csvFileBody = fileData;
         ctrl.fileContentType = 'csv';
         PageReference pref = ctrl.StartBatchJob();
         ctrl.fileContentType = 'text/plain';
         ctrl.StartBatchJob();
         ctrl.fileContentType = null;
         ctrl.StartBatchJob();
         DataLoad_Activity__c activityRecord = [
             SELECT Id
             FROM DataLoad_Activity__c
             LIMIT 1
         ];
         LeadDataLoaderBatch parser = new LeadDataLoaderBatch(
             fileData,
             activityRecord
         );
         System.assertEquals(
             3,
             parser.splitString('One,"Two, with comma",Three').size()
         , 'Assertion failed in IntelModuleTest at source line 1004');
     }
    
}