@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class CaseWizardControllerTest {
    @IsTest
    static void searchesAndCreatesCases() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
            Contact__c subject = new Contact__c(
                First_Name__c = 'Wizard',
                Last_Name__c = 'Subject',
                Email__c = 'wizard.subject@example.com'
            );
            insert subject;

            CaseWizardController controller = new CaseWizardController();
            controller.subjectFirstNameSearchEntry = 'Wizard';
            controller.subjectLastNameSearchEntry = 'Subject';
            controller.subjectEmailSearchEntry = 'wizard.subject@example.com';
            controller.SearchSubjectsAction();
            Assert.areEqual(1, controller.subjectsSearched.size(), 'Assertion failed in CaseWizardControllerTest at source line 20');
            Assert.isTrue(controller.showsubjectspanel, 'Assertion failed in CaseWizardControllerTest at source line 21');
            controller.subjectsSearched[0].isSelected = true;
            PageReference result = controller.CreateCaseAction();
            Assert.isTrue(result.getRedirect(), 'Assertion failed in CaseWizardControllerTest at source line 24');
            Assert.isTrue(CaseWizardController.CheckIfCaseExists(subject.Id), 'Assertion failed in CaseWizardControllerTest at source line 25');
        }
    }

    @IsTest
    static void createsNewSubjectAndCase() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
            CaseWizardController controller = new CaseWizardController();
            controller.newSubject = new Contact__c(
                First_Name__c = 'New',
                Last_Name__c = 'Subject'
            );
            PageReference result = controller.CreateNewSubjectAction();
            Assert.isTrue(result.getRedirect(), 'Assertion failed in CaseWizardControllerTest at source line 39');
            Assert.isNotNull(result.getParameters().get('id'), 'Assertion failed in CaseWizardControllerTest at source line 40');
        }
    }
}