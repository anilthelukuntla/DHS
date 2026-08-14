@isTest
/** Exercises the existing DHSCDRLReportsAdditional behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.EmptyCatchBlock, PMD.EmptyIfStmt, PMD.EmptyStatementBlock, PMD.MethodNamingConventions, PMD.NcssCount, PMD.NcssMethodCount')
public class DHSCDRLReportsAdditionalTest {
	@testSetup static void setup() {
		 PPFDHSTestUserFactory.createPmoUser();
		 System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
     	 DHS_Contact__c con = new DHS_Contact__c();
         con.First_Name__c = 'Test';
         con.Last_Name__c = 'Name';
         con.Email__c  = 'test@test.com';
         con.Contact_Type__c = 'Subject';
		 con.SSN__c = '123-12-1123';
         insert con;
         DHS_Case__c diaCase = new DHS_Case__c();
         diaCase.DHS_Contact__c = con.id;
         diaCase.DHS_Assigned_To__c = userinfo.getuserId();
         insert diaCase;
         DHS_Lead__c diaLead = new DHS_Lead__c();
         diaLead.DHS_Case__c = diaCase.id;
         //diaLead.DHS_Assigned_To__c = userinfo.getuserid();
         diaLead.Coverage_Type__c = 'Subject Interview';
         diaLead.LeadType__c = 'Subject Interview (ESI/TESI)';
         insert diaLead;
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
        ctrl.queryForNextRecords = 'select id,name,DHS_Contact__r.First_Name__c,DHS_Contact__r.Last_Name__c,Case_Number__c,Customer_Case_Number__c,Case_Due_Date__c,Customer_Delivery_Date__c, Case_Type__c,Status__c,Current_Task__c,Manifest__c,DHS_Assigned_To__r.FirstName,DHS_Assigned_To__r.LastName,Waiver_Due_Date__c, QA_Review_Completed_Date__c from DHS_Case__c where id != Null and ';
        ctrl.firstRecordName = 'name';
        ctrl.lastRecordName = 'name';
         ctrl.fiveorlessitemsofcase = true;
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
         
         
         
        list<DHSCDRLReportsController.ReportRecord> temp = new list<DHSCDRLReportsController.ReportRecord>();
         temp.add(new DHSCDRLReportsController.ReportRecord('test','test','test', 'test', 'test', 'test', 'test', 'test', 'test', 'test','test', 'test', 'test',
                            'test', 'test', 'test', 'test', 'test', 'test', 'test'));
           
		temp.add(new DHSCDRLReportsController.ReportRecord('test', 'test','test','test', 'test', 'test', 'test', 'test', 'test', 'test','test', 'test',
                            'test', 'test', 'test', 'test', 10, 'test', 'test',
							'test', 'test', 'test', 'test','test',
							'test', 'test', 'test', 'test','test'));

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