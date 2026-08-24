@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts,PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexUnitTestMethodShouldHaveIsTestAnnotation,PMD.UnusedLocalVariable')
public class DHSMultifileuploadPageControllerTest {
    TestMethod static void method1(){
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
        DHSMultifileuploadPageController remp = new DHSMultifileuploadPageController();
        
        DHSMultifileuploadPageController temp1 = New DHSMultifileuploadPageController();
        DHSMultifileuploadPageController.attachmentcountmethod(caseTemp.id);
        DHSMultifileuploadPageController.attachmentnames(caseTemp.id);
        string docId = DHSMultifileuploadPageController.createDocumentRecord(caseTemp.id);
        DHSMultifileuploadPageController.attachBlob(caseTemp.id,'','Test','csv','Test','');
        DHSMultifileuploadPageController.processUploadedFiles(caseTemp.id,'test.pdf');
    }
}
