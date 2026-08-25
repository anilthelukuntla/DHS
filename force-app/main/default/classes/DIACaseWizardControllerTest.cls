@isTest
public class DIACaseWizardControllerTest {
	testMethod private static void TestCaseNLeadFlow(){ 
        //CaseWizard Page Test Starts...        
        Account acc = new Account(name='ISN');
        insert acc;
        DIACaseWizardController wizardController = new DIACaseWizardController();
        //To create new subject
        wizardController.newSubject.First_Name__c = 'test';
        wizardController.newSubject.Last_Name__c = 'investigator';
        wizardController.newSubject.Phone__c = '8197277272';
        wizardController.newSubject.State__c = 'CA';
        wizardController.newSubject.Email__c = 'test.investigator@test.com';
        
        pagereference pref = wizardController.CreateNewSubjectAction();
        //To search for existing subject
        wizardController.subjectFirstNameSearchEntry = 'test';
        wizardController.subjectLastNameSearchEntry = 'investigator';
        wizardController.subjectEmailSearchEntry = 'test.investigator@test.com';
      
       
        wizardController.SearchSubjectsAction();
        //check if the subject is present in the system.
        //system.assertEquals(1, wizardController.subjectsSearched.size());
        //wizardController.subjectsSearched[0].isSelected = true;
        //create a case
        wizardController.CreateCaseAction();
        list<dia_contact__c> con = new list<dia_contact__c>();
        con = [select id from dia_contact__c];
        if(!con.isEmpty()){
        	DIACaseWizardController.CheckIfCaseExists(con[0].id);    
        }else{
        	DIACaseWizardController.CheckIfCaseExists(acc.id);        
        }
        
    }
}