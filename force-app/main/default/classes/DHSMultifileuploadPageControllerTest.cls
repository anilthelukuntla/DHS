@isTest
/** Exercises the existing DHSMultifileuploadPageController behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.LocalVariableNamingConventions, PMD.UnusedLocalVariable')
public class DHSMultifileuploadPageControllerTest {
    @IsTest static void method1(){
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
         CaseTemp.Subject_Type__c = 'Applicant';
         insert CaseTemp;
        PageReference casedetailpage = Page.DHSMultifileuploadPage;
        Test.setCurrentPage(casedetailpage);
        casedetailpage.getParameters().put('caseid',CaseTemp.id); 
        DHSMultifileuploadPageController remp = new DHSMultifileuploadPageController();
        
        DHSMultifileuploadPageController temp1 = New DHSMultifileuploadPageController();
        DHSMultifileuploadPageController.attachmentcountmethod(CaseTemp.id);
        string docId = DHSMultifileuploadPageController.createDocumentRecord(CaseTemp.id);
        String attachmentId = DHSMultifileuploadPageController.attachBlob(
            CaseTemp.id, '', 'Test', 'csv', 'Test', 'f2'
        );
        DHSMultifileuploadPageController.attachBlob(
            CaseTemp.id, attachmentId, 'Test', 'csv', 'VGVzdA==', 'f3'
        );
        DHSMultifileuploadPageController.attachmentnames(docId);
        DHSMultifileuploadPageController.processUploadedFiles(CaseTemp.id,'test.pdf');
        System.assertEquals(true, remp.uploadAndRedirect().getRedirect(), 'Assertion failed in DHSMultifileuploadPageControllerTest at source line 34');
    }
}