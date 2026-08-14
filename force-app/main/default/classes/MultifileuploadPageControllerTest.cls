@isTest
/** Exercises the existing MultifileuploadPageController behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.LocalVariableNamingConventions, PMD.UnusedLocalVariable')
public class MultifileuploadPageControllerTest {
    @IsTest static void method1(){
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
         CaseTemp.Subject_Type__c = 'Applicant';
         insert CaseTemp;
        PageReference casedetailpage = Page.multifileuploadpage;
        Test.setCurrentPage(casedetailpage);
        casedetailpage.getParameters().put('caseid',CaseTemp.id); 
        MultifileuploadPageController remp = new MultifileuploadPageController();
        
        MultifileuploadPageController temp1 = New MultifileuploadPageController();
        MultifileuploadPageController.attachmentcountmethod(CaseTemp.id);
        string docId = MultifileuploadPageController.createDocumentRecord(CaseTemp.id);
        String attachmentId = MultifileuploadPageController.attachBlob(
            CaseTemp.id, '', 'Test', 'csv', 'Test', 'f2'
        );
        MultifileuploadPageController.attachBlob(
            CaseTemp.id, attachmentId, 'Test', 'csv', 'VGVzdA==', 'f3'
        );
        MultifileuploadPageController.attachmentnames(docId);
        MultifileuploadPageController.processUploadedFiles(CaseTemp.id,'test.pdf');
        System.assertEquals(true, remp.uploadAndRedirect().getRedirect(), 'Assertion failed in MultifileuploadPageControllerTest at source line 34');
    }
}