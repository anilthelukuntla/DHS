@IsTest
/** Exercises the existing DHSCaseWizardController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSCaseWizardControllerTest {

    private static final String TEST_EMAIL =
        'wizard.subject@example.com';

    @TestSetup
    static void createAccessUser() {
        PPFDHSTestUserFactory.createPmoUser();
    }

    private static DHS_Contact__c createSubject(
        String firstName,
        String lastName,
        String email
    ) {
        DHS_Contact__c subject = new DHS_Contact__c(
            First_Name__c = firstName,
            Last_Name__c = lastName,
            Email__c = email,
            Phone__c = '2025550100',
            Mobile__c = '2025550199',
            State__c = 'MD',
            Contact_Type__c = 'Subject',
            SSN__c = '123-45-6789'
        );

        insert subject;
        return subject;
    }

    @IsTest
    static void constructorInitializesProperties() {
        Test.startTest();
        DHSCaseWizardController controller =
            new DHSCaseWizardController();
        Test.stopTest();

        System.assertNotEquals(
            null,
            controller.newSubject,
            'The new subject should be initialized.'
        );
        System.assertEquals(
            false,
            controller.showsubjectspanel,
            'The search panel should initially be hidden.'
        );
    }

    @IsTest
    static void createsNewSubjectAndCase() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        DHSCaseWizardController controller =
            new DHSCaseWizardController();

        controller.newSubject.First_Name__c = 'Wizard';
        controller.newSubject.Last_Name__c = 'Subject';
        controller.newSubject.Email__c = TEST_EMAIL;
        controller.newSubject.Phone__c = '2025550100';
        controller.newSubject.Mobile__c = '2025550199';
        controller.newSubject.State__c = 'MD';
        controller.newSubject.Contact_Type__c = 'Subject';
        controller.newSubject.SSN__c = '123-45-6789';

        Test.startTest();
        PageReference result = controller.CreateNewSubjectAction();
        Test.stopTest();

        System.assertNotEquals(
            null,
            result,
            'The method should return a redirect page.'
        );
        System.assertEquals(
            true,
            result.getRedirect(),
            'The page should be configured as a redirect.'
        );

        DHS_Contact__c createdSubject = [
            SELECT Id, First_Name__c, Last_Name__c, Email__c
            FROM DHS_Contact__c
            WHERE Email__c = :TEST_EMAIL
            LIMIT 1
        ];

        DHS_Case__c createdCase = [
            SELECT Id, DHS_Contact__c, Case_Number__c
            FROM DHS_Case__c
            WHERE DHS_Contact__c = :createdSubject.Id
            LIMIT 1
        ];

        System.assertEquals(
            createdSubject.Id,
            createdCase.DHS_Contact__c
        , 'Assertion failed in DHSCaseWizardControllerTest at source line 97');
        System.assertNotEquals(
            null,
            createdCase.Case_Number__c
        , 'Assertion failed in DHSCaseWizardControllerTest at source line 101');
        System.assertEquals(
            createdCase.Id,
            result.getParameters().get('id')
        , 'Assertion failed in DHSCaseWizardControllerTest at source line 105');
        }
    }

    @IsTest
    static void searchesSubjectUsingAllCriteria() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        DHS_Contact__c subject = createSubject(
            'Search',
            'Subject',
            'search.subject@example.com'
        );

        DHSCaseWizardController controller =
            new DHSCaseWizardController();

        controller.subjectFirstNameSearchEntry =
            subject.First_Name__c;
        controller.subjectLastNameSearchEntry =
            subject.Last_Name__c;
        controller.subjectEmailSearchEntry =
            subject.Email__c;

        Test.startTest();
        controller.SearchSubjectsAction();
        Test.stopTest();

        System.assertEquals(
            true,
            controller.showsubjectspanel
        , 'Assertion failed in DHSCaseWizardControllerTest at source line 135');
        System.assertNotEquals(
            null,
            controller.subjectsSearched
        , 'Assertion failed in DHSCaseWizardControllerTest at source line 139');
        System.assertEquals(
            1,
            controller.subjectsSearched.size()
        , 'Assertion failed in DHSCaseWizardControllerTest at source line 143');
        System.assertEquals(
            subject.Id,
            controller.subjectsSearched[0].subject.Id
        , 'Assertion failed in DHSCaseWizardControllerTest at source line 147');
        System.assertEquals(
            false,
            controller.subjectsSearched[0].isSelected
        , 'Assertion failed in DHSCaseWizardControllerTest at source line 151');
        }
    }

    @IsTest
    static void searchesSubjectUsingFirstNameOnly() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        DHS_Contact__c subject = createSubject(
            'FirstOnly',
            'Search',
            'first-only@example.com'
        );

        DHSCaseWizardController controller =
            new DHSCaseWizardController();

        controller.subjectFirstNameSearchEntry =
            subject.First_Name__c;

        Test.startTest();
        controller.SearchSubjectsAction();
        Test.stopTest();

        System.assertEquals(
            true,
            controller.showsubjectspanel
        , 'Assertion failed in DHSCaseWizardControllerTest at source line 177');
        System.assertEquals(
            1,
            controller.subjectsSearched.size()
        , 'Assertion failed in DHSCaseWizardControllerTest at source line 181');
        System.assertEquals(
            subject.Id,
            controller.subjectsSearched[0].subject.Id
        , 'Assertion failed in DHSCaseWizardControllerTest at source line 185');
        }
    }

    @IsTest
    static void createsCaseForSelectedSubject() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        DHS_Contact__c subject = createSubject(
            'Selected',
            'Subject',
            'selected.subject@example.com'
        );

        DHSCaseWizardController.SubjectRecord wrapper =
            new DHSCaseWizardController.SubjectRecord(subject);

        /*
         * Keep this assignment even before fixing the constructor,
         * because the current constructor always sets it to false.
         */
        wrapper.isSelected = true;

        DHSCaseWizardController controller =
            new DHSCaseWizardController();

        controller.subjectsSearched =
            new List<DHSCaseWizardController.SubjectRecord>{
                wrapper
            };

        Test.startTest();
        PageReference result = controller.CreateCaseAction();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Assertion failed in DHSCaseWizardControllerTest at source line 222');
        System.assertEquals(true, result.getRedirect(), 'Assertion failed in DHSCaseWizardControllerTest at source line 223');

        DHS_Case__c createdCase = [
            SELECT Id, DHS_Contact__c
            FROM DHS_Case__c
            WHERE DHS_Contact__c = :subject.Id
            LIMIT 1
        ];

        System.assertEquals(
            subject.Id,
            createdCase.DHS_Contact__c
        , 'Assertion failed in DHSCaseWizardControllerTest at source line 232');
        System.assertEquals(
            createdCase.Id,
            result.getParameters().get('id')
        , 'Assertion failed in DHSCaseWizardControllerTest at source line 236');
        }
    }

    @IsTest
    static void checkIfCaseExistsReturnsTrue() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        DHS_Contact__c subject = createSubject(
            'Existing',
            'Case',
            'existing.case@example.com'
        );

        DHS_Case__c caseRecord = new DHS_Case__c(
            DHS_Contact__c = subject.Id,
            Case_Number__c = 'EC-001MD'

            // Add Case_Queue_Status__c here if required:
            // Case_Queue_Status__c = 'Open'
        );
        insert caseRecord;

        Test.startTest();
        Boolean caseExists =
            DHSCaseWizardController.CheckIfCaseExists(
                subject.Id
            );
        Test.stopTest();

        System.assertEquals(
            true,
            caseExists,
            'An open case exists for the subject.'
        );
        }
    }

    @IsTest
    static void checkIfCaseExistsReturnsFalse() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        DHS_Contact__c subject = createSubject(
            'No',
            'Case',
            'no.case@example.com'
        );

        Test.startTest();
        Boolean caseExists =
            DHSCaseWizardController.CheckIfCaseExists(
                subject.Id
            );
        Test.stopTest();

        System.assertEquals(
            false,
            caseExists,
            'No case exists for the subject.'
        );
        }
    }

    @IsTest
    static void subjectRecordConstructorStoresValues() {
        DHS_Contact__c subject = new DHS_Contact__c(
            First_Name__c = 'Wrapper',
            Last_Name__c = 'Test'
        );

        Test.startTest();
        DHSCaseWizardController.SubjectRecord wrapper =
            new DHSCaseWizardController.SubjectRecord(subject);
        Test.stopTest();

        System.assertEquals(subject, wrapper.subject, 'Assertion failed in DHSCaseWizardControllerTest at source line 312');

        /*
         * Change this assertion to true after fixing the constructor:
         *
         * System.assertEquals(true, wrapper.isSelected);
         */
        System.assertEquals(false, wrapper.isSelected, 'Assertion failed in DHSCaseWizardControllerTest at source line 319');
    }
}