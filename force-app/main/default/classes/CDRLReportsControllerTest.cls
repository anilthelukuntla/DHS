@isTest
public class CDRLReportsControllerTest {
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
        database.executeBatch(New WorkloadBatch(),100);
     }
     testMethod private static void TestMethod1(){
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
        ctrl.firstRecordName = 'name';
        ctrl.lastRecordName = 'name';
        ctrl.selectedReportType ='Case';
        ctrl.handleprev();
        ctrl.handlenext();
        ctrl.queryForNextRecords = 'select id,name from Investigator_Check__c where id != Null and ';
        ctrl.selectedReportType ='Check-in/Check-out';
        ctrl.handleprev();
        ctrl.handlenext();
         ctrl.queryForNextRecords = 'select id,name from Waiver_Information__c where id != Null and ';
        ctrl.selectedReportType ='Waivers';
        ctrl.handleprev();
        ctrl.handlenext();
           ctrl.queryForNextRecords = 'select id,name from Message__c where id != Null and ';
        ctrl.selectedReportType ='Messages';
        ctrl.handleprev();
        ctrl.handlenext();
        ctrl.queryForNextRecords = 'select id,name from LEad__c where id != Null and ';
        ctrl.selectedReportType ='Lead';
        ctrl.handleprev();
        ctrl.handlenext();
         
         ctrl.queryForNextRecords = 'select id,name from workload__c where id != Null and ';
        ctrl.selectedReportType ='Workload';
        ctrl.handleprev();
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
     }
}