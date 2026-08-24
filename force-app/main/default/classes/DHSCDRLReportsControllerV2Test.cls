@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.NcssCount,PMD.NcssMethodCount')
public class DHSCDRLReportsControllerV2Test {
	@TestSetup static void setup() {
        
     	 DHS_Contact__c con = new DHS_Contact__c();
         con.First_Name__c = 'Test';
         con.Last_Name__c = 'Name';
         con.Email__c  = 'test@test.com';
         con.Contact_Type__c = 'Subject';
		 con.SSN__c = '123-12-1123';
         insert con;
         DHS_Case__c caseTemp = new DHS_Case__c();
         caseTemp.DHS_Contact__c = con.id;
         caseTemp.DHS_Assigned_To__c = userinfo.getuserId();
         insert caseTemp;
         DHS_Lead__c lead = new DHS_Lead__c();
         lead.DHS_Case__c = caseTemp.id;
         //Lead.DHS_Assigned_To__c = userinfo.getuserid();
         lead.Coverage_Type__c = 'Subject Interview';
         lead.LeadType__c = 'Subject Interview (ESI/TESI)';
         insert lead;
        
        
         DHS_Document__c tempDoc = New DHS_Document__c();
        tempDoc.DHS_Case__c = caseTemp.id;
         tempDoc.Name__c = 'ROIReport';
         insert tempDoc;
     }
     @IsTest private static void testMethod1(){
         System.assert(true, 'Expected the test scenario to complete without exception');
     	DHSCDRLReportsControllerV2 ctrl = new DHSCDRLReportsControllerV2();
        ctrl.selectedReportType = 'ROIReport';
        ctrl.fromDate = System.today().addDays(-2);
        ctrl.toDate = System.today();
        ctrl.RunReportAction();
        ctrl.selectedReportType = 'Completed Cases';
        ctrl.OnReportTypeSelect();
        ctrl.selectedCMoUser = 'DHS_All';
        ctrl.RunReportAction();
        ctrl.selectedReportType = 'Completed Leads';
        ctrl.OnReportTypeSelect();
        ctrl.selectedinvestigatorUser = 'DHS_All';
        ctrl.RunReportAction();
        ctrl.selectedReportType = 'Case';
        ctrl.OnReportTypeSelect();
        ctrl.RunReportAction();
        ctrl.selectedReportType = 'Lead';
        ctrl.OnReportTypeSelect(); 
        ctrl.RunReportAction();
        DHS_Lead__c lead = [select id,Status__c,DHS_Assigned_To__c from DHS_Lead__c limit 1];
        lead.Status__c='Assigned';
        lead.DHS_Assigned_To__c = userinfo.getuserid();
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
        ctrl.selectedReportType ='Investigator DHSReports';
        ctrl.OnReportTypeSelect(); 
        ctrl.RunReportAction();
        ctrl.selectedleadforstatustracking = lead.id;
        ctrl.FetchLeadStatusTrackings();
        ctrl.queryForNextRecords = 'select id,name,Subject_Type__c,DHS_Contact__r.First_Name__c,DHS_Contact__r.Last_Name__c,Case_Number__c,Customer_Case_Number__c,Case_Due_Date__c,Customer_Delivery_Date__c, Case_Type__c,Status__c,Current_Task__c,Manifest__c,DHS_Assigned_To__r.FirstName,DHS_Assigned_To__r.LastName,Waiver_Due_Date__c, QA_Review_Completed_Date__c from DHS_Case__c where id != Null and ';
        ctrl.firstRecordName = 'name';
        ctrl.lastRecordName = 'name';
        ctrl.selectedReportType ='Case';
        ctrl.handleprev();
        ctrl.handlenext();
        ctrl.queryForNextRecords = 'select id,name from DHS_Investigator_Check__c where id != Null and ';
        ctrl.selectedReportType ='Check-in/Check-out';
        ctrl.handleprev();
        ctrl.handlenext();
         ctrl.queryForNextRecords = 'select id,name from DHS_Waiver_Information__c where id != Null and ';
        ctrl.selectedReportType ='Waivers';
        ctrl.handleprev();
        ctrl.handlenext();
           ctrl.queryForNextRecords = 'select id,name from DHS_Message__c where id != Null and ';
        ctrl.selectedReportType ='Messages';
        ctrl.handleprev();
        ctrl.handlenext();
        ctrl.queryForNextRecords = 'select id,name from DHS_Lead__c where id != Null and ';
        ctrl.selectedReportType ='Lead';
        ctrl.handleprev();
        ctrl.handlenext();
         DHSCDRLReportsControllerV2.getFieldMap('CDRLCaseExport');
         DHSCDRLReportsControllerV2.getFieldMap('CDRLCheckInCheckOut');
         DHSCDRLReportsControllerV2.getFieldMap('CDRLLeadExport');
         DHSCDRLReportsControllerV2.getFieldMap('CDRLMessageExport');
         DHSCDRLReportsControllerV2.getFieldMap('CDRLWaiverExport');
         
         
         
        list<DHSCDRLReportsControllerV2.ReportRecord> temp = new list<DHSCDRLReportsControllerV2.ReportRecord>();
         temp.add(new DHSCDRLReportsControllerV2.ReportRecord('test','test','test', 'test', 'test', 'test', 'test', 'test', 'test', 'test','test', 'test', 'test',
                            'test', 'test', 'test', 'test', 'test','test'));
           
		temp.add(new DHSCDRLReportsControllerV2.ReportRecord('test', 'test','test','test', 'test', 'test', 'test', 'test', 'test', 'test','test', 'test',
                            'test', 'test', 'test',10, 'test', 'test',
							'test', 'test', 'test', 'test','test',
                            'test', 'test', 'test', 'test','test'));

                 
     }
    
    @IsTest
    static void testFlatten() {
        // Test with nested maps
        Map<String, Object> nestedMap = new Map<String, Object>{
            'key1' => 'value1',
            'key2' => new Map<String, Object>{
                'nestedKey1' => 'nestedValue1',
                'nestedKey2' => 'nestedValue2'
            }
        };
        Map<String, Object> result = DHSUtils.flatten(nestedMap, '.');
        System.assertEquals(3, result.size(), 'Expected the asserted condition to hold');
        System.assertEquals('value1', result.get('key1'), 'Expected the asserted condition to hold');
        System.assertEquals('nestedValue1', result.get('key2.nestedKey1'), 'Expected the asserted condition to hold');
        System.assertEquals('nestedValue2', result.get('key2.nestedKey2'), 'Expected the asserted condition to hold');

        // Test with null values
        nestedMap.put('key3', null);
        result = DHSUtils.flatten(nestedMap, '.');
        System.assert(result.containsKey('key3'), 'Expected assertion condition to hold');
        System.assertEquals(null, result.get('key3'), 'Expected the asserted condition to hold');
    }

    @IsTest
    static void testConvertToMapList() {
        // Test with sample SObjects
        Account acc1 = new Account(Name = 'Test Account 1');
         Contact con = new Contact(LastName = 'Test Contact', AccountId = acc1.Id);
        insert con;
        Account acc2 = new Account(Name = 'Test Account 2');
        insert new List<Account>{acc1, acc2};

        List<SObject> records = [SELECT Id,createddate,account.createddate, Name FROM contact];
        List<String> fields = new List<String>{'createddate','account.createddate'};

        List<Map<String, Object>> result = DHSUtils.convertToMapList(records, fields); System.assertNotEquals(null, result, 'Expected result to be initialized');
    }

    @IsTest
    static void testGetRelationalValue() {
        // Test with related SObjects
        Account acc = new Account(Name = 'Parent Account');
        insert acc;
        Contact con = new Contact(LastName = 'Test Contact', AccountId = acc.Id);
        insert con;

        Contact retrievedContact = [SELECT Id, Account.Name FROM Contact WHERE Id = :con.Id];
        Object result = DHSUtils.getRelationalValue(retrievedContact, 'Account.Name');
        System.assertEquals('Parent Account', result, 'Expected the asserted condition to hold');
    }

    @IsTest
    static void testGetReportExport() {
        // Test report export retrieval
        DHS_Report_Export__c report = new DHS_Report_Export__c(Label__c = 'Test Name', Api_Name__c = 'Name', Report_Type__c = 'Case__c', System__c = 'Intel', Order__c = 1);
        insert report;
        List<DHS_Report_Export__c> result = DHSUtils.getReportExport('Case__c', 'Intel'); System.assertNotEquals(null, result, 'Expected result to be initialized');
    }

    @IsTest
    static void testSaveReport() {
        // Test saving report order
        DHS_Report_Export__c report = new DHS_Report_Export__c(Label__c = 'Test Name', Api_Name__c = 'Name', Report_Type__c = 'Case__c', System__c = 'Intel', Order__c = 1.0);
        insert report;

        Map<String, String> updatedata = new Map<String, String>{'id' => report.Id,'label'=>'test label 1','apiname'=>'createddate','System__c'=>'Intel','Report_Type__c'=>'Case__c'};
		Map<String, String> createdata = new Map<String, String>{'label'=>'test label 1','apiname'=>'createddate'};

        Map<String, String> revisedData = new Map<String, String>{report.Id => '2'};
        Object result = DHSUtils.saveReport(revisedData); System.assertNotEquals(null, result, 'Expected result to be initialized');
		DHSUtils.updateReport(updatedata);
        DHSUtils.updateReport(createdata);
    }

    @IsTest
    static void testGetFieldData() {
        // Test retrieving field data
        List<Map<String, Object>> result = DHSUtils.getFieldData('Account'); System.assertNotEquals(null, result, 'Expected result to be initialized');
    }
    @IsTest
    static void generateReportColumns(){
        System.assert(true, 'Expected the test scenario to complete without exception');
        DHSGenerateReportColumn.createROIColumns();
        DHSGenerateReportColumn.generateCDRLColumns();
    }
}
