@isTest
public class CDRLReportsControllerV2Test {
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
        
        
         document__c tempDoc = New document__c();
        tempDoc.Case__c = CaseTemp.id;
         tempDoc.Name__c = 'ROIReport';
         insert tempDoc;
     }
     testMethod private static void TestMethod1(){
     	CDRLReportsControllerV2 ctrl = new CDRLReportsControllerV2();
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
         CDRLReportsControllerV2.getFieldMap('CDRLCaseExport');
         CDRLReportsControllerV2.getFieldMap('CDRLCheckInCheckOut');
         CDRLReportsControllerV2.getFieldMap('CDRLLeadExport');
         CDRLReportsControllerV2.getFieldMap('CDRLMessageExport');
         CDRLReportsControllerV2.getFieldMap('CDRLWaiverExport');
         
         
         
        list<CDRLReportsControllerV2.ReportRecord> temp = new list<CDRLReportsControllerV2.ReportRecord>();
         temp.add(new CDRLReportsControllerV2.ReportRecord('test','test','test', 'test', 'test', 'test', 'test', 'test', 'test', 'test','test', 'test', 'test',
                            'test', 'test', 'test', 'test', 'test','test'));
           
		temp.add(new CDRLReportsControllerV2.ReportRecord('test', 'test','test','test', 'test', 'test', 'test', 'test', 'test', 'test','test', 'test',
                            'test', 'test', 'test',10, 'test', 'test',
							'test', 'test', 'test', 'test','test',
                            'test', 'test', 'test', 'test','test'));

                 
     }
    
    @isTest
    static void testFlatten() {
        // Test with nested maps
        Map<String, Object> nestedMap = new Map<String, Object>{
            'key1' => 'value1',
            'key2' => new Map<String, Object>{
                'nestedKey1' => 'nestedValue1',
                'nestedKey2' => 'nestedValue2'
            }
        };
        Map<String, Object> result = utils.flatten(nestedMap, '.');
        System.assertEquals(3, result.size());
        System.assertEquals('value1', result.get('key1'));
        System.assertEquals('nestedValue1', result.get('key2.nestedKey1'));
        System.assertEquals('nestedValue2', result.get('key2.nestedKey2'));

        // Test with null values
        nestedMap.put('key3', null);
        result = utils.flatten(nestedMap, '.');
        System.assert(result.containsKey('key3'));
        System.assertEquals(null, result.get('key3'));
    }

    @isTest
    static void testConvertToMapList() {
        // Test with sample SObjects
        Account acc1 = new Account(Name = 'Test Account 1');
         Contact con = new Contact(LastName = 'Test Contact', AccountId = acc1.Id);
        insert con;
        Account acc2 = new Account(Name = 'Test Account 2');
        insert new List<Account>{acc1, acc2};

        List<SObject> records = [SELECT Id,createddate,account.createddate, Name FROM contact];
        List<String> fields = new List<String>{'createddate','account.createddate'};

        List<Map<String, Object>> result = utils.convertToMapList(records, fields);
    }

    @isTest
    static void testGetRelationalValue() {
        // Test with related SObjects
        Account acc = new Account(Name = 'Parent Account');
        insert acc;
        Contact con = new Contact(LastName = 'Test Contact', AccountId = acc.Id);
        insert con;

        Contact retrievedContact = [SELECT Id, Account.Name FROM Contact WHERE Id = :con.Id];
        Object result = utils.getRelationalValue(retrievedContact, 'Account.Name');
        System.assertEquals('Parent Account', result);
    }

    @isTest
    static void testGetReportExport() {
        // Test report export retrieval
        Report_Export__c report = new Report_Export__c(Label__c = 'Test Name', Api_Name__c = 'Name', Report_Type__c = 'Case__c', System__c = 'Intel', Order__c = 1);
        insert report;
        List<Report_Export__c> result = utils.getReportExport('Case__c', 'Intel');
    }

    @isTest
    static void testSaveReport() {
        // Test saving report order
        Report_Export__c report = new Report_Export__c(Label__c = 'Test Name', Api_Name__c = 'Name', Report_Type__c = 'Case__c', System__c = 'Intel', Order__c = 1.0);
        insert report;

        Map<String, String> updatedata = new Map<String, String>{'id' => report.Id,'label'=>'test label 1','apiname'=>'createddate','System__c'=>'Intel','Report_Type__c'=>'Case__c'};
		Map<String, String> createdata = new Map<String, String>{'label'=>'test label 1','apiname'=>'createddate'};

        Map<String, String> revisedData = new Map<String, String>{report.Id => '2'};
        Object result = utils.saveReport(revisedData);
		utils.updateReport(updatedata);
        utils.updateReport(createdata);
    }

    @isTest
    static void testGetFieldData() {
        // Test retrieving field data
        List<Map<String, Object>> result = utils.getFieldData('Account');
    }
    @isTest
    static void generateReportColumns(){
        generateReportColumn.createROIColumns();
        generateReportColumn.generateCDRLColumns();
    }
}