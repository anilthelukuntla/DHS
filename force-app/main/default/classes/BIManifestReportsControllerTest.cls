@isTest
public class BIManifestReportsControllerTest {
	TestMethod static void BIManifestReportsTest(){
        account acc = New account(name = 'ISN');
        insert acc;
        
        string fileName = 'Manifest from ';
        ContentVersion objCV = new ContentVersion();
        objCV.Title = fileName;
            objCV.PathOnClient = fileName+'.CSV';
        objCV.VersionData = blob.valueOf('{}');
            insert objCV;
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: objCV.Id].ContentDocumentId;
            cdl.LinkedEntityId = [Select Id from Account Where Name='ISN'].id;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            insert cdl;
        
        dia_contact__c diacon = new dia_contact__c();
        diacon.First_Name__c = 'Test';
        diacon.Last_Name__c = 'User';
        diacon.SSN__c = '12312-3123';
        insert diacon;
        
        dia_case__c cs = New dia_case__c();
        cs.Contact__c = diacon.Id;
        cs.case_number__c = 'Test12345';
        cs.Case_Completed_Date__c = system.today();
        cs.Coverage_Period_Begin_Date__c = system.today();
        cs.Closure_Type__c = 'Completed T5';
        cs.ISP_requested_Extension__c = 'No';
        cs.ISP_requested_Waiver__c = 'No';
        cs.SF_86_Certification_Date__c = system.today();
        cs.Case_Queue_Status__c = 'Completed';
        insert cs;
        Test.startTest();
        BIManifestReportsController sp = New BIManifestReportsController();
        sp.fromDate = system.today();
        sp.toDate = system.today();
        sp.formatDate(system.today());
        sp.createContentVersion('Waiver Request','Test');
        sp.generateCustomDateRangeManifest();
        sp.regenerateManifest();
        sp.generateCustomDateRangeOppSummary();
        sp.generateCustomDateRangeExtensionRequest();
        sp.generateCustomDateRangeWaiverRequest();
        Test.stopTest();
    }
}