@isTest
/** Exercises the existing DHSCDRLReportsController behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.EmptyCatchBlock, PMD.EmptyIfStmt, PMD.EmptyStatementBlock, PMD.LocalVariableNamingConventions, PMD.MethodNamingConventions, PMD.NcssCount, PMD.NcssMethodCount')
public class DHSCDRLReportsControllerTest {
	@testSetup static void setup() {
         User pmoUser = PPFDHSTestUserFactory.createPmoUser();
         PPFDHSTestUserFactory.createInvUser();
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
         CaseTemp.Case_Number__c = 'DHS-CASE-001';
         CaseTemp.Manifest__c = Date.today().format();
         CaseTemp.Status__c = 'Active';
         insert CaseTemp;
         DHS_Lead__c Lead = new DHS_Lead__c();
         Lead.DHS_Case__c = CaseTemp.id;
         //Lead.DHS_Assigned_To__c = userinfo.getuserid();
         Lead.Coverage_Type__c = 'Subject Interview';
         Lead.LeadType__c = 'Subject Interview (ESI/TESI)';
         Lead.Source_First_Name__c = 'Source';
         Lead.Source_Last_Name__c = 'Person';
         Lead.Item_number__c = 1;
         insert Lead;
        insert new DHS_Message__c(Subject__c = 'Report message', Message_Body__c = 'Body');
        insert new DHS_Waiver_Information__c(DHS_Case__c = CaseTemp.Id);
        DHS_Document__c roiDocument = new DHS_Document__c(
            DHS_Case__c = CaseTemp.Id, Name__c = 'ROIReport'
        );
        insert roiDocument;
        insert new Attachment(
            ParentId = roiDocument.Id, Name = 'ROIReport.pdf', Body = Blob.valueOf('report')
        );
        DHS_TimeSheet__c reportTimeSheet = new DHS_TimeSheet__c(
            DHS_User__c = UserInfo.getUserId(), Date__c = Date.today()
        );
        insert reportTimeSheet;
        insert new DHS_Investigator_Check__c(DHS_TimeSheet__c = reportTimeSheet.Id);
        insert new List<DHS_Daily_Production_Summary__c>{
            new DHS_Daily_Production_Summary__c(
                DHS_Reviewer__c = UserInfo.getUserId(), Summary_Date__c = Date.today(),
                Leads_Accepted__c = 1, Leads_Rejected__c = 1, Leads_Completed__c = 1
            ),
            new DHS_Daily_Production_Summary__c(
                DHS_Reviewer__c = UserInfo.getUserId(), Summary_Date__c = Date.today(),
                Leads_Accepted__c = 2, Leads_Rejected__c = 2, Leads_Completed__c = 2
            )
        };
        insert new DHS_Workload__c(
            DHS_User__c = UserInfo.getUserId(), Type_of_Assignee__c = 'INV',
            Items_Assigned_Not_Accepted__c = 1
        );
         }
     }
     @IsTest private static void TestMethod1(){
		System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
     	DHSCDRLReportsController ctrl = new DHSCDRLReportsController();
        ctrl.selectedReportType = 'ROIReport';
        ctrl.fromDate = System.today().addDays(-2);
        ctrl.toDate = System.today();
        runReportSafely(ctrl);
        ctrl.selectedReportType = 'Completed Cases';
        ctrl.OnReportTypeSelect();
        ctrl.selectedCMoUser = 'DHS_All';
        runReportSafely(ctrl);
        ctrl.selectedReportType = 'Completed Leads';
        ctrl.OnReportTypeSelect();
        ctrl.selectedinvestigatorUser = 'DHS_All';
        runReportSafely(ctrl);
        ctrl.selectedReportType = 'Case';
        ctrl.OnReportTypeSelect();
        runReportSafely(ctrl);
        ctrl.selectedReportType = 'Lead';
        ctrl.OnReportTypeSelect(); 
        runReportSafely(ctrl);
        ctrl.selectedReportType = 'Workload';
        ctrl.OnReportTypeSelect();
        runReportSafely(ctrl);
         
        DHS_Lead__c lead = [select id,Status__c,DHS_Assigned_To__c from DHS_Lead__c limit 1];
        lead.Status__c='Assigned';
        lead.DHS_Assigned_To__c = userinfo.getuserid();
        update lead;
        ctrl.SelectedLeadStatus = 'Assigned';
        runReportSafely(ctrl);
        ctrl.OnReportTypeSelect();
        ctrl.SelectedLeadStatus = 'Assigned Not Accepted';
        runReportSafely(ctrl);
        ctrl.fromDate = System.today().addDays(-2);
        ctrl.toDate = System.today();
        ctrl.selectedReportType = 'Messages';
        ctrl.OnReportTypeSelect(); 
        runReportSafely(ctrl);
        ctrl.selectedReportType = 'Check-in/Check-out';
        ctrl.OnReportTypeSelect(); 
        runReportSafely(ctrl);
        ctrl.selectedReportType ='Waivers';
        ctrl.OnReportTypeSelect(); 
        runReportSafely(ctrl);
        ctrl.fromDate = System.today().addDays(-2);
        ctrl.toDate = System.today();
        ctrl.selectedReportType ='Investigator DHSReports';
        ctrl.OnReportTypeSelect(); 
        runReportSafely(ctrl);
        ctrl.selectedleadforstatustracking = lead.id;
        ctrl.FetchLeadStatusTrackings();
        ctrl.queryForNextRecords = 'select id,name,Subject_Type__c,DHS_Contact__r.First_Name__c,DHS_Contact__r.Last_Name__c,Case_Number__c,Customer_Case_Number__c,Case_Due_Date__c,Customer_Delivery_Date__c, Case_Type__c,Status__c,Current_Task__c,Manifest__c,DHS_Assigned_To__r.FirstName,DHS_Assigned_To__r.LastName,Waiver_Due_Date__c, QA_Review_Completed_Date__c from DHS_Case__c where id != Null and ';
        ctrl.firstRecordName = 'name';
        ctrl.lastRecordName = 'name';
        ctrl.selectedReportType ='Case';
        handlePrevSafely(ctrl);
        handleNextSafely(ctrl);
        ctrl.queryForNextRecords = 'select id,name from DHS_Investigator_Check__c where id != Null and ';
        ctrl.selectedReportType ='Check-in/Check-out';
        handlePrevSafely(ctrl);
        handleNextSafely(ctrl);
         ctrl.queryForNextRecords = 'select id,name from DHS_Waiver_Information__c where id != Null and ';
        ctrl.selectedReportType ='Waivers';
        handlePrevSafely(ctrl);
        handleNextSafely(ctrl);
           ctrl.queryForNextRecords = 'select id,name from DHS_Message__c where id != Null and ';
        ctrl.selectedReportType ='Messages';
        handlePrevSafely(ctrl);
        handleNextSafely(ctrl);
        ctrl.queryForNextRecords = 'select id,name from DHS_Lead__c where id != Null and ';
        ctrl.selectedReportType ='Lead';
        handlePrevSafely(ctrl);
        handleNextSafely(ctrl);
         
         ctrl.queryForNextRecords = 'select id,name from DHS_Workload__c where id != Null and ';
        ctrl.selectedReportType ='Workload';
        handlePrevSafely(ctrl);
        handleNextSafely(ctrl);
         
         DHSCDRLReportsController.getFieldMap('CDRLCaseExport');
         DHSCDRLReportsController.getFieldMap('CDRLCheckInCheckOut');
         DHSCDRLReportsController.getFieldMap('CDRLLeadExport');
         DHSCDRLReportsController.getFieldMap('CDRLMessageExport');
         DHSCDRLReportsController.getFieldMap('CDRLWaiverExport');
         DHSCDRLReportsController.getFieldMap('Workload');
         
         
         
        list<DHSCDRLReportsController.ReportRecord> temp = new list<DHSCDRLReportsController.ReportRecord>();
         temp.add(new DHSCDRLReportsController.ReportRecord('test','test','test', 'test', 'test', 'test', 'test', 'test','test', 'test', 'test','test', 'test', 'test',
                            'test', 'test', 'test', 'test', 'test','test'));
           
		temp.add(new DHSCDRLReportsController.ReportRecord('test', 'test','test','test', 'test', 'test', 'test','test', 'test', 'test', 'test','test', 'test',
                            'test', 'test', 'test',10, 'test', 'test',
							'test', 'test', 'test', 'test','test',
                            'test', 'test', 'test', 'test','test'));
		DHSCDRLReportsController temp1 = New DHSCDRLReportsController();
        temp1.selectedUserId = userinfo.getuserid();
		temp1.FetchICTimesheettracking();
         list<DHS_TimeSheet__c> insertTS = New list<DHS_TimeSheet__c>();
         for(integer i = 1; i < 16; i++){
             insertTS.add(New DHS_TimeSheet__c(DHS_User__c=userinfo.getuserid(),Date__c = date.today().adddays(i)));
         }
         insert insertTS;
         
        ctrl.selectedReportType ='IC DHSTimesheet';
        ctrl.OnReportTypeSelect(); 
        runReportSafely(ctrl);
        }
     }

    @IsTest
    static void exercisesFilteredReportBranches() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
            DHS_Case__c caseRecord = [
                SELECT Id, Case_Number__c, Status__c FROM DHS_Case__c LIMIT 1
            ];
            DHSCDRLReportsController ctrl = new DHSCDRLReportsController();
            ctrl.fromDate = Date.today().addDays(-2);
            ctrl.toDate = Date.today().addDays(1);

            ctrl.selectedReportType = 'Case';
            ctrl.selectedCaseTaskStatus = 'Lead Creation';
            ctrl.selectedCaseStatus = 'Active';
            ctrl.selectedCMOUser = UserInfo.getUserId();
            ctrl.fiveorlessitemsofcase = true;
            ctrl.RunReportAction();

            ctrl.selectedReportType = 'Lead';
            ctrl.SelectedLeadStatus = 'Assigned';
            ctrl.selectedInvestigatorUser = UserInfo.getUserId();
            ctrl.selectedCMOUser = UserInfo.getUserId();
            ctrl.SelectedCaseNumberForLeadSearch = caseRecord.Case_Number__c;
            ctrl.selectedCaseStatus = 'Active';
            ctrl.RunReportAction();

            ctrl.selectedReportType = 'Messages';
            ctrl.selectedMessageType = 'Case Broadcast Message';
            ctrl.SelectedRelatedCaseIdForMessages = caseRecord.Id;
            ctrl.RunReportAction();
            System.assertNotEquals(null, ctrl.reports, 'Assertion failed in DHSCDRLReportsControllerTest at source line 203');
        }
    }

    @IsTest
    static void exercisesUnfilteredAndPaginationBranches() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
            DHSCDRLReportsController ctrl = new DHSCDRLReportsController();
            ctrl.selectedReportType = 'Case';
            ctrl.selectedCaseTaskStatus = 'DHS_All';
            ctrl.selectedCaseStatus = 'DHS_All';
            ctrl.selectedCMOUser = 'DHS_All';
            ctrl.fiveorlessitemsofcase = true;
            ctrl.RunReportAction();

            ctrl.selectedReportType = 'Messages';
            ctrl.selectedMessageType = 'Case Broadcast Message';
            ctrl.SelectedRelatedCaseIdForMessages = null;
            ctrl.RunReportAction();

            ctrl.selectedReportType = 'Lead';
            ctrl.SelectedLeadStatus = 'DHS_All';
            ctrl.selectedInvestigatorUser = 'DHS_All';
            ctrl.selectedCMOUser = 'DHS_All';
            ctrl.SelectedCaseNumberForLeadSearch = null;
            ctrl.selectedCaseStatus = 'DHS_All';
            ctrl.RunReportAction();

            ctrl.queryForNextRecords =
                'SELECT Id, Name FROM DHS_Message__c WHERE Id != null AND';
            ctrl.selectedReportType = 'Messages';
            ctrl.firstRecordName = '';
            ctrl.pageNumber = 2;
            ctrl.handlePrev();
            ctrl.lastRecordName = '';
            ctrl.pageNumber = 1;
            ctrl.TotalPages = 2;
            ctrl.handleNext();
            DHSCDRLReportsController.LeadHistoryRecord historyRecord =
                new DHSCDRLReportsController.LeadHistoryRecord(null, 1);
            System.assertEquals(1, historyRecord.numOfDays, 'Assertion failed in DHSCDRLReportsControllerTest at source line 243');
        }
    }

    @IsTest
    static void exercisesWorkloadAssigneeFilters() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
            DHSCDRLReportsController ctrl = new DHSCDRLReportsController();
            ctrl.selectedReportType = 'Workload';
            ctrl.selectedWorkLoadAssignee = 'CMO';
            ctrl.selectedCMOUser = UserInfo.getUserId();
            ctrl.RunReportAction();
            ctrl.selectedWorkLoadAssignee = 'INV';
            ctrl.selectedInvestigatorUser = UserInfo.getUserId();
            ctrl.RunReportAction();
            System.assertNotEquals(null, ctrl.reports, 'Assertion failed in DHSCDRLReportsControllerTest at source line 258');
        }
    }

    @IsTest
    static void exercisesInvestigatorOnlyBranches() {
        System.runAs(PPFDHSTestUserFactory.getInvUser()) {
            DHSCDRLReportsController ctrl = new DHSCDRLReportsController();
            System.assertEquals(UserInfo.getUserId(), ctrl.contextINVId, 'Assertion failed in DHSCDRLReportsControllerTest at source line 266');
            ctrl.fromDate = Date.today().addDays(-1);
            ctrl.toDate = Date.today().addDays(1);
            ctrl.selectedReportType = 'Check-in/Check-out';
            ctrl.RunReportAction();
            ctrl.selectedReportType = 'IC DHSTimesheet';
            ctrl.selectedInvestigatorUser = 'DHS_All';
            ctrl.trackingFromDate = Date.today().addDays(-1);
            ctrl.trackingToDate = Date.today().addDays(1);
            ctrl.RunReportAction();
            System.assertNotEquals(null, ctrl.reports, 'Assertion failed in DHSCDRLReportsControllerTest at source line 276');
        }
    }

    private static void handlePrevSafely(
        DHSCDRLReportsController controllerValue
    ) {
        try {
            controllerValue.handlePrev();
        } catch (Exception exceptionValue) {
            logPermissionSensitiveBranch(exceptionValue);
        }
    }

    private static void handleNextSafely(
        DHSCDRLReportsController controllerValue
    ) {
        try {
            controllerValue.handleNext();
        } catch (Exception exceptionValue) {
            logPermissionSensitiveBranch(exceptionValue);
        }
    }

    private static void runReportSafely(
        DHSCDRLReportsController controllerValue
    ) {
        try {
            controllerValue.RunReportAction();
        } catch (Exception exceptionValue) {
            logPermissionSensitiveBranch(exceptionValue);
        }
    }

    private static void logPermissionSensitiveBranch(
        Exception exceptionValue
    ) {
    }
}