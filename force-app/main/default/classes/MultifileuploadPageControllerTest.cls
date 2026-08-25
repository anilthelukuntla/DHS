@isTest
public class MultifileuploadPageControllerTest {
    TestMethod static void method1(){
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
        PageReference casedetailpage = Page.multifileuploadpage;
        Test.setCurrentPage(casedetailpage);
        casedetailpage.getParameters().put('caseid',CaseTemp.id); 
        MultifileuploadPageController remp = new MultifileuploadPageController();
        
        MultifileuploadPageController temp1 = New MultifileuploadPageController();
        MultifileuploadPageController.attachmentcountmethod(CaseTemp.id);
        MultifileuploadPageController.attachmentnames(CaseTemp.id);
        string docId = MultifileuploadPageController.createDocumentRecord(CaseTemp.id);
        MultifileuploadPageController.attachBlob(CaseTemp.id,'','Test','csv','Test','');
        MultifileuploadPageController.processUploadedFiles(CaseTemp.id,'test.pdf');
    }
}