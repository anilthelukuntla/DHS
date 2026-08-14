@isTest
/** Exercises the existing DHSSubjFileUploadAuthPageCtrl behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.MethodNamingConventions, PMD.LocalVariableNamingConventions, PMD.UnusedLocalVariable')
public class DHSSubjFileUploadAuthPageCtrlTest {
	  @IsTest private static void TestMethod1(){
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
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
         insert new DHS_Lead__c(
             DHS_Case__c = diaCase.Id,
             LeadType__c = 'Subject Interview (ESI/TESI)',
             Coverage_Type__c = 'Subject Interview',
             Item_Number__c = 1
         );
        
        PageReference DHSSubjectFileUploadAuthPage = Page.DHSSubjectFileUploadAuthPage;
        Test.setCurrentPage(DHSSubjectFileUploadAuthPage);
        DHSSubjectFileUploadAuthPage.getParameters().put('id',diaCase.id); 
        DHSSubjectFileUploadAuthPageController ctrl =new DHSSubjectFileUploadAuthPageController();
        ctrl.ssnUserInput = '0000';
        pagereference pref = ctrl.AuthMethod();
        System.assertEquals(false, ctrl.isAuthenticatedSuccess, 'Assertion failed in DHSSubjFileUploadAuthPageCtrlTest at source line 32');

        ctrl.ssnUserInput = '1123';
        PageReference redirectPage = ctrl.AuthMethod();
        System.assertEquals(true, ctrl.isAuthenticatedSuccess, 'Assertion failed in DHSSubjFileUploadAuthPageCtrlTest at source line 36');
        System.assertNotEquals(null, redirectPage, 'Assertion failed in DHSSubjFileUploadAuthPageCtrlTest at source line 37');
        System.assertEquals(1, [
            SELECT COUNT() FROM DHS_Document_Request__c
            WHERE DHS_Case__c = :diaCase.Id
        ], 'Assertion failed in DHSSubjFileUploadAuthPageCtrlTest at source line 38');
        }
      }
}