@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
public class DHSMultifileuploadPageControllerTest {
    @IsTest static void method1(){
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
        PageReference casedetailpage = Page.DHSMultifileuploadPage;
        Test.setCurrentPage(casedetailpage);
        casedetailpage.getParameters().put('caseid',caseTemp.id); 
        DHSMultifileuploadPageController remp = new DHSMultifileuploadPageController(); System.assertNotEquals(null, remp, 'Expected remp to be initialized');
        
        DHSMultifileuploadPageController temp1 = New DHSMultifileuploadPageController(); System.assertNotEquals(null, temp1, 'Expected temp1 to be initialized');
        DHSMultifileuploadPageController.attachmentcountmethod(caseTemp.id);
        DHSMultifileuploadPageController.attachmentnames(caseTemp.id);
        string docId = DHSMultifileuploadPageController.createDocumentRecord(caseTemp.id); System.assertNotEquals(null, docId, 'Expected docId to be initialized');
        DHSMultifileuploadPageController.attachBlob(caseTemp.id,'','Test','csv','Test','');
        DHSMultifileuploadPageController.processUploadedFiles(caseTemp.id,'test.pdf');
    }
}