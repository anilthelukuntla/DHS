@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
public class DHSSubjFileUploadAuthPageCtrlTest {
	  @IsTest private static void testMethod1(){
     	 DHS_Contact__c con = new DHS_Contact__c();
         con.First_Name__c = 'Test';
         con.Last_Name__c = 'Name';
         con.Email__c  = 'test@test.com';
         con.Contact_Type__c = 'Subject';
		 con.SSN__c = '123-12-1123';
         insert con;
         DHS_Case__c diaCase = new DHS_Case__c();
         diaCase.DHS_Contact__c = con.id;
         diaCase.DHS_Assigned_To__c = userinfo.getuserId();
         insert diaCase;
        
        PageReference dHSSubjectFileUploadAuthPage = Page.dHSSubjectFileUploadAuthPage;
        Test.setCurrentPage(dHSSubjectFileUploadAuthPage);
        dHSSubjectFileUploadAuthPage.getParameters().put('id',diaCase.id); 
        DHSSubjectFileUploadAuthPageController ctrl =new DHSSubjectFileUploadAuthPageController();
        ctrl.ssnUserInput = '0000';
        pagereference pref = ctrl.AuthMethod(); System.assertNotEquals(null, pref, 'Expected pref to be initialized');
        System.assertEquals(false, ctrl.isAuthenticatedSuccess, 'Expected the asserted condition to hold');

        ctrl.ssnUserInput = '1123';
        try {
            ctrl.AuthMethod();
            System.assert(false, 'Expected required lead validation');
        } catch (DmlException expected) {
            System.assert(expected.getMessage().contains('DHS_Lead__c'), 'Expected assertion condition to hold');
        }
        System.assertEquals(true, ctrl.isAuthenticatedSuccess, 'Expected the asserted condition to hold');
      }
}