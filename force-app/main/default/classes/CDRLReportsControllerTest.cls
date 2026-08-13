@isTest
/** Exercises the existing CDRLReportsController behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.LocalVariableNamingConventions, PMD.MethodNamingConventions, PMD.NcssCount, PMD.NcssMethodCount')
public class CDRLReportsControllerTest {
	@testSetup static void setup() {
         User pmoUser = PPFDHSTestUserFactory.createPmoUser();
         PPFDHSTestUserFactory.createInvUser();
         System.runAs(pmoUser) {
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
         CaseTemp.Case_Number__c = 'CASE-001';
         CaseTemp.Manifest__c = Date.today().format();
         CaseTemp.Status__c = 'Active';
         insert CaseTemp;
         Lead__c Lead = new Lead__c();
         Lead.case__c = CaseTemp.id;
         //Lead.Assigned_To__c = userinfo.getuserid();
         Lead.Coverage_Type__c = 'Subject Interview';
         Lead.LeadType__c = 'Subject Interview (ESI/TESI)';
         Lead.Source_First_Name__c = 'Source';
         Lead.Source_Last_Name__c = 'Person';
         Lead.Item_Number__c = 1;
         insert Lead;
        insert new List<Lead__c>{
            new Lead__c(
                Case__c = CaseTemp.Id, Assigned_To__c = UserInfo.getUserId(),
                LeadType__c = 'Employment (EMPL)', Coverage_Type__c = 'Record',
                Item_Number__c = 2, Employment_Contact_Method__c = 'Email'
            ),
            new Lead__c(
                Case__c = CaseTemp.Id, Assigned_To__c = UserInfo.getUserId(),
                LeadType__c = 'General (GENL)', Coverage_Type__c = 'Personal',
                Item_Number__c = 3, Personal_Contact_Method__c = 'Telephone'
            ),
            new Lead__c(
                Case__c = CaseTemp.Id, Assigned_To__c = UserInfo.getUserId(),
                LeadType__c = 'General (GENL)', Coverage_Type__c = 'Record',
                Item_Number__c = 4, Contact_Method__c = 'Email'
            )
        };
        insert new Message__c(Subject__c = 'Report message', Message_Body__c = 'Body');
        insert new Waiver_Information__c(Case__c = CaseTemp.Id);
        Document__c roiDocument = new Document__c(Case__c = CaseTemp.Id, Name__c = 'ROIReport');
        insert roiDocument;
        insert new Attachment(
            ParentId = roiDocument.Id, Name = 'ROIReport.pdf', Body = Blob.valueOf('report')
        );
        TimeSheet__c reportTimeSheet = new TimeSheet__c(
            User__c = UserInfo.getUserId(), Date__c = Date.today()
        );
        insert reportTimeSheet;
        insert new Investigator_Check__c(TimeSheet__c = reportTimeSheet.Id);
        insert new List<Daily_Production_Summary__c>{
            new Daily_Production_Summary__c(
                Reviewer__c = UserInfo.getUserId(), Summary_Date__c = Date.today(),
                Leads_Accepted__c = 1, Leads_Rejected__c = 1, Leads_Completed__c = 1
            ),
            new Daily_Production_Summary__c(
                Reviewer__c = UserInfo.getUserId(), Summary_Date__c = Date.today(),
                Leads_Accepted__c = 2, Leads_Rejected__c = 2, Leads_Completed__c = 2
            )
        };
        insert new Workload__c(
            User__c = UserInfo.getUserId(), Type_of_Assignee__c = 'INV',
            Items_Assigned_Not_Accepted__c = 1
        );
         }
     }
     @IsTest private static void TestMethod1(){
		System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
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
        ctrl.selectedinvestigatorUser = 'All';
        ctrl.RunReportAction();
        ctrl.selectedReportType = 'Case';
        ctrl.OnReportTypeSelect();
        ctrl.RunReportAction();
        ctrl.selectedReportType = 'Lead';
        ctrl.OnReportTypeSelect(); 
        ctrl.RunReportAction();
        ctrl.selectedReportType = 'Workload';
        ctrl.OnReportTypeSelect();
        ctrl.RunReportAction();
         
        lead__C lead = [select id,status__C,Assigned_to__c from lead__c limit 1];
        lead.status__C='Assigned';
        lead.Assigned_to__c = userinfo.getuserid();
        update lead;
        ctrl.SelectedLeadStatus = 'Assigned';
        ctrl.RunReportAction();
        ctrl.OnReportTypeSelect();
        ctrl.SelectedLeadStatus = 'Assigned Not Accepted';
        ctrl.RunReportAction();
        ctrl.fromDate = System.today().addDays(-2);
        ctrl.toDate = System.today();
        ctrl.selectedReportType = 'Messages';
        ctrl.OnReportTypeSelect(); 
        ctrl.RunReportAction();
        ctrl.selectedReportType = 'Check-in/Check-out';
        ctrl.OnReportTypeSelect(); 
        ctrl.RunReportAction();
        ctrl.selectedReportType ='Waivers';
        ctrl.OnReportTypeSelect(); 
        ctrl.RunReportAction();
        ctrl.fromDate = System.today().addDays(-2);
        ctrl.toDate = System.today();
        ctrl.selectedReportType ='Investigator Reports';
        ctrl.OnReportTypeSelect(); 
        ctrl.RunReportAction();
        ctrl.selectedleadforstatustracking = lead.id;
        ctrl.FetchLeadStatusTrackings();
        ctrl.queryForNextRecords = 'select id,name,Subject_Type__c,Contact__r.First_Name__c,Contact__r.Last_Name__c,Case_Number__c,customer_case_number__c,Case_Due_Date__c,Customer_Delivery_Date__c, Case_Type__c,status__c,Current_Task__c,Manifest__c,Assigned_to__r.FirstName,Assigned_to__r.LastName,Waiver_Due_Date__c, QA_Review_Completed_Date__c from case__c where id != Null and ';
        ctrl.firstRecordName = '';
        ctrl.lastRecordName = 'name';
        ctrl.selectedReportType ='Case';
        ctrl.handleprev();
        ctrl.lastRecordName = '';
        ctrl.handlenext();
        ctrl.queryForNextRecords = 'select id,name from Investigator_Check__c where id != Null and ';
        ctrl.selectedReportType ='Check-in/Check-out';
        ctrl.firstRecordName = '';
        ctrl.handleprev();
        ctrl.lastRecordName = '';
        ctrl.handlenext();
         ctrl.queryForNextRecords = 'select id,name from Waiver_Information__c where id != Null and ';
        ctrl.selectedReportType ='Waivers';
        ctrl.firstRecordName = '';
        ctrl.handleprev();
        ctrl.lastRecordName = '';
        ctrl.handlenext();
           ctrl.queryForNextRecords = 'select id,name from Message__c where id != Null and ';
        ctrl.selectedReportType ='Messages';
        ctrl.firstRecordName = '';
        ctrl.handleprev();
        ctrl.lastRecordName = '';
        ctrl.handlenext();
        ctrl.queryForNextRecords = 'select id,name from LEad__c where id != Null and ';
        ctrl.selectedReportType ='Lead';
        ctrl.firstRecordName = '';
        ctrl.handleprev();
        ctrl.lastRecordName = '';
        ctrl.handlenext();
         
         ctrl.queryForNextRecords = 'select id,name from workload__c where id != Null and ';
        ctrl.selectedReportType ='Workload';
         ctrl.firstRecordName = '';
         ctrl.handleprev();
         ctrl.lastRecordName = '';
         ctrl.handlenext();
         
         CDRLReportsController.getFieldMap('CDRLCaseExport');
         CDRLReportsController.getFieldMap('CDRLCheckInCheckOut');
         CDRLReportsController.getFieldMap('CDRLLeadExport');
         CDRLReportsController.getFieldMap('CDRLMessageExport');
         CDRLReportsController.getFieldMap('CDRLWaiverExport');
         CDRLReportsController.getFieldMap('Workload');
         
         
         
        list<CDRLReportsController.ReportRecord> temp = new list<CDRLReportsController.ReportRecord>();
         temp.add(new CDRLReportsController.ReportRecord('test','test','test', 'test', 'test', 'test', 'test', 'test','test', 'test', 'test','test', 'test', 'test',
                            'test', 'test', 'test', 'test', 'test','test'));
           
		temp.add(new CDRLReportsController.ReportRecord('test', 'test','test','test', 'test', 'test', 'test','test', 'test', 'test', 'test','test', 'test',
                            'test', 'test', 'test',10, 'test', 'test',
							'test', 'test', 'test', 'test','test',
                            'test', 'test', 'test', 'test','test'));
		CDRLReportsController temp1 = New CDRLReportsController();
        temp1.selectedUserId = userinfo.getuserid();
		temp1.FetchICTimesheettracking();
         list<timesheet__c> insertTS = New list<timesheet__c>();
         for(integer i = 1; i < 16; i++){
             insertTS.add(New timesheet__c(user__c=userinfo.getuserid(),date__c = date.today().adddays(i)));
         }
         insert insertTS;
         
        ctrl.selectedReportType ='IC Timesheet';
        ctrl.OnReportTypeSelect(); 
        ctrl.RunReportAction();
        ctrl.firstRecordName = '';
        ctrl.lastRecordName = '';
        ctrl.handleprev();
        ctrl.lastRecordName = '';
        ctrl.handlenext();

        new CDRLReportsController.ReportRecord([SELECT Id FROM Message__c LIMIT 1]);
        new CDRLReportsController.ReportRecord([SELECT Id FROM Investigator_Check__c LIMIT 1]);
        new CDRLReportsController.ReportRecord([SELECT Id FROM Waiver_Information__c LIMIT 1]);
        new CDRLReportsController.ReportRecord([SELECT Id FROM TimeSheet__c LIMIT 1]);
        new CDRLReportsController.ReportRecord([SELECT Id FROM Workload__c LIMIT 1]);
        }
     }

    @IsTest
    static void exercisesFilteredReportBranches() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
            Case__c caseRecord = [SELECT Id, Case_Number__c, Status__c FROM Case__c LIMIT 1];
            CDRLReportsController ctrl = new CDRLReportsController();
            ctrl.fromDate = Date.today().addDays(-2);
            ctrl.toDate = Date.today().addDays(1);

            ctrl.selectedReportType = 'Case';
            ctrl.selectedCaseTaskStatus = 'Lead Creation';
            ctrl.selectedCaseStatus = 'Active';
            ctrl.selectedCMOUser = UserInfo.getUserId();
            ctrl.fiveorlessitemsofcase = true;
            ctrl.RunReportAction();
            System.assertNotEquals(null, ctrl.reports, 'Assertion failed in CDRLReportsControllerTest at source line 225');

            ctrl.selectedReportType = 'Lead';
            ctrl.SelectedLeadStatus = 'Assigned';
            ctrl.selectedInvestigatorUser = UserInfo.getUserId();
            ctrl.selectedCMOUser = UserInfo.getUserId();
            ctrl.SelectedCaseNumberForLeadSearch = caseRecord.Case_Number__c;
            ctrl.selectedCaseStatus = 'Active';
            ctrl.RunReportAction();
            System.assertNotEquals(null, ctrl.reports, 'Assertion failed in CDRLReportsControllerTest at source line 234');

            ctrl.selectedReportType = 'Messages';
            ctrl.selectedMessageType = 'Case Broadcast Message';
            ctrl.SelectedRelatedCaseIdForMessages = caseRecord.Id;
            ctrl.RunReportAction();
            System.assertNotEquals(null, ctrl.reports, 'Assertion failed in CDRLReportsControllerTest at source line 240');
        }
    }

    @IsTest
    static void exercisesUnfilteredAndPaginationBranches() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
            CDRLReportsController ctrl = new CDRLReportsController();
            ctrl.fromDate = null;
            ctrl.toDate = null;
            ctrl.selectedReportType = 'Case';
            ctrl.selectedCaseTaskStatus = 'All';
            ctrl.selectedCaseStatus = 'All';
            ctrl.selectedCMOUser = 'All';
            ctrl.fiveorlessitemsofcase = true;
            ctrl.RunReportAction();

            ctrl.selectedReportType = 'Messages';
            ctrl.selectedMessageType = 'Case Broadcast Message';
            ctrl.SelectedRelatedCaseIdForMessages = null;
            ctrl.fromDate = null;
            ctrl.toDate = null;
            ctrl.RunReportAction();

            ctrl.selectedReportType = 'Lead';
            ctrl.SelectedLeadStatus = 'All';
            ctrl.selectedInvestigatorUser = 'All';
            ctrl.selectedCMOUser = 'All';
            ctrl.SelectedCaseNumberForLeadSearch = null;
            ctrl.selectedCaseStatus = 'All';
            ctrl.RunReportAction();

            ctrl.queryForNextRecords = 'SELECT Id, Name FROM Message__c WHERE Id != null AND';
            ctrl.selectedReportType = 'Messages';
            ctrl.firstRecordName = '';
            ctrl.pageNumber = 2;
            ctrl.handlePrev();
            ctrl.lastRecordName = '';
            ctrl.pageNumber = 1;
            ctrl.TotalPages = 2;
            ctrl.handleNext();
            CDRLReportsController.LeadHistoryRecord historyRecord =
                new CDRLReportsController.LeadHistoryRecord(null, 1);
            System.assertEquals(1, historyRecord.numOfDays, 'Assertion failed in CDRLReportsControllerTest at source line 283');
            System.assertNotEquals(null, ctrl.reports, 'Assertion failed in CDRLReportsControllerTest at source line 284');
        }
    }

    @IsTest
    static void exercisesWorkloadAssigneeFilters() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
            CDRLReportsController ctrl = new CDRLReportsController();
            ctrl.selectedReportType = 'Workload';
            ctrl.selectedWorkLoadAssignee = 'CMO';
            ctrl.selectedCMOUser = UserInfo.getUserId();
            ctrl.RunReportAction();
            ctrl.selectedWorkLoadAssignee = 'INV';
            ctrl.selectedInvestigatorUser = UserInfo.getUserId();
            ctrl.RunReportAction();
            System.assertNotEquals(null, ctrl.reports, 'Assertion failed in CDRLReportsControllerTest at source line 299');
        }
    }

    @IsTest
    static void exercisesInvestigatorOnlyBranches() {
        System.runAs(PPFDHSTestUserFactory.getInvUser()) {
            CDRLReportsController ctrl = new CDRLReportsController();
            System.assertEquals(UserInfo.getUserId(), ctrl.contextINVId, 'Assertion failed in CDRLReportsControllerTest at source line 307');
            ctrl.fromDate = Date.today().addDays(-1);
            ctrl.toDate = Date.today().addDays(1);
            ctrl.selectedReportType = 'Check-in/Check-out';
            ctrl.RunReportAction();
            ctrl.selectedReportType = 'IC Timesheet';
            ctrl.selectedInvestigatorUser = 'All';
            ctrl.trackingFromDate = Date.today().addDays(-1);
            ctrl.trackingToDate = Date.today().addDays(1);
            ctrl.RunReportAction();
            System.assertNotEquals(null, ctrl.reports, 'Assertion failed in CDRLReportsControllerTest at source line 317');
        }
    }
}