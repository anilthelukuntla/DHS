@isTest
public class DIACDRLReportsControllerTest {
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
        DIACDRLReportsController ctrl = new DIACDRLReportsController();
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
        dia_lead__C lead = [select id,status__C,Assigned_to__c from dia_lead__c limit 1];
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
        ctrl.queryForNextRecords = 'select id,name,Contact__r.First_Name__c,Contact__r.Last_Name__c,Case_Number__c,customer_case_number__c,Case_Due_Date__c,Customer_Delivery_Date__c, Case_Type__c,status__c,Current_Task__c,Manifest__c,Assigned_to__r.FirstName,Assigned_to__r.LastName,Waiver_Due_Date__c,Extension_Due_Date__c, QA_Review_Completed_Date__c from dia_case__c where id != Null and ';
        ctrl.firstRecordName = 'name';
        ctrl.lastRecordName = 'name';
        ctrl.selectedReportType ='Case';
        ctrl.handleprev();
        ctrl.handlenext();
        ctrl.queryForNextRecords = 'select id,name from DIA_Investigator_Check__c where id != Null and ';
        ctrl.selectedReportType ='Check-in/Check-out';
        ctrl.handleprev();
        ctrl.handlenext();
         ctrl.queryForNextRecords = 'select id,name from DIA_Waiver_Information__c where id != Null and ';
        ctrl.selectedReportType ='Waivers';
        ctrl.handleprev();
        ctrl.handlenext();
           ctrl.queryForNextRecords = 'select id,name from DIA_Message__c where id != Null and ';
        ctrl.selectedReportType ='Messages';
        ctrl.handleprev();
        ctrl.handlenext();
        ctrl.queryForNextRecords = 'select id,name,case__r.Extension_Due_Date__c from DIA_LEad__c where id != Null and ';
        ctrl.selectedReportType ='Lead';
        ctrl.handleprev();
        ctrl.handlenext();
         
         
         
        list<DIACDRLReportsController.ReportRecord> temp = new list<DIACDRLReportsController.ReportRecord>();
         temp.add(new DIACDRLReportsController.ReportRecord('test',null,null,null,system.today(),system.today(), null,null,null,null,
                                             null, null,null,system.today(),system.today(), null,null,null,null));
           
        temp.add(new DIACDRLReportsController.ReportRecord('test', 'test','test',system.today(),system.today(), system.today(), 'test', 'test', 'test', 'test', 'test','test', 'test',
                            'test', 'test', 'test',10, 'test', 'test',
                            'test', 'test', 'test', 'test','test',
                            system.today(), 'test', system.today(), 'test','test',100,90,system.now()));

                 
     }
}