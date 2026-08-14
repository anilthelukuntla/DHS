@IsTest
/** Exercises the existing DHSDeliverablesController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSDeliverablesControllerTest {

    @TestSetup
    static void setupData() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
        insert new List<DHS_Case__c>{
            new DHS_Case__c(
                Case_Number__c = 'DELIVERABLE-001',
                Current_Task__c = 'QA Review Completed',
                DHS_Assigned_To__c = UserInfo.getUserId()
            ),
            new DHS_Case__c(
                Case_Number__c = 'DELIVERABLE-002',
                Current_Task__c = 'QA Review Completed',
                DHS_Assigned_To__c = UserInfo.getUserId()
            ),
            new DHS_Case__c(
                Case_Number__c = 'NOT-AVAILABLE-001',
                Current_Task__c = 'In Progress',
                DHS_Assigned_To__c = UserInfo.getUserId()
            )
        };
        }
    }

    @IsTest
    static void constructorLoadsCasesAndVersions() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        Test.startTest();
        DHSDeliverablesController controller =
            new DHSDeliverablesController();
        Test.stopTest();

        System.assertNotEquals(null, controller.caseOptions, 'Assertion failed in DHSDeliverablesControllerTest at source line 38');
        System.assertNotEquals(null, controller.selectedcaseOptions, 'Assertion failed in DHSDeliverablesControllerTest at source line 39');
        System.assertNotEquals(null, controller.versionOptions, 'Assertion failed in DHSDeliverablesControllerTest at source line 40');

        /*
         * One "--None--" option plus versions 1 through 20.
         */
        System.assertEquals(21, controller.versionOptions.size(), 'Assertion failed in DHSDeliverablesControllerTest at source line 45');
        System.assertEquals(
            '',
            controller.versionOptions[0].getValue()
        , 'Assertion failed in DHSDeliverablesControllerTest at source line 46');
        System.assertEquals(
            '--None--',
            controller.versionOptions[0].getLabel()
        , 'Assertion failed in DHSDeliverablesControllerTest at source line 50');
        System.assertEquals(
            '1',
            controller.versionOptions[1].getValue()
        , 'Assertion failed in DHSDeliverablesControllerTest at source line 54');
        System.assertEquals(
            '20',
            controller.versionOptions[20].getValue()
        , 'Assertion failed in DHSDeliverablesControllerTest at source line 58');

        Set<String> availableCaseNumbers = new Set<String>();

        for (SelectOption caseOption : controller.caseOptions) {
            availableCaseNumbers.add(caseOption.getLabel());
        }
        }
    }

    @IsTest
    static void fetchCaseListLoadsQACompletedCases() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        DHSDeliverablesController controller =
            new DHSDeliverablesController();

        /*
         * Clear the options because the constructor already calls
         * FetchCaseList().
         */
        controller.caseOptions.clear();

        Test.startTest();
        controller.FetchCaseList();
        Test.stopTest();


        Set<Id> returnedCaseIds = new Set<Id>();

        for (SelectOption caseOption : controller.caseOptions) {
            returnedCaseIds.add(
                (Id)caseOption.getValue()
            );
        }

        Map<Id, DHS_Case__c> expectedCases =
            new Map<Id, DHS_Case__c>([
                SELECT Id
                FROM DHS_Case__c
                WHERE Current_Task__c = 'QA Review Completed'
            ]);

        System.assertEquals(
            expectedCases.keySet(),
            returnedCaseIds
        , 'Assertion failed in DHSDeliverablesControllerTest at source line 103');
        }
    }

    @IsTest
    static void downloadsManifestForSelectedCases() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        List<DHS_Case__c> selectedCases = [
            SELECT Id, Case_Number__c
            FROM DHS_Case__c
            WHERE Current_Task__c = 'QA Review Completed'
            ORDER BY Case_Number__c
        ];

        DHSDeliverablesController controller =
            new DHSDeliverablesController();

        controller.selectedVersion = '3';
        controller.selectedcaseOptions =
            new List<SelectOption>();

        for (DHS_Case__c caseRecord : selectedCases) {
            controller.selectedcaseOptions.add(
                new SelectOption(
                    caseRecord.Id,
                    caseRecord.Case_Number__c
                )
            );
        }

        Test.startTest();
        controller.downloadmanifestaction();
        Test.stopTest();

        System.assertNotEquals(
            null,
            controller.manifestActionAttachmentId,
            'The generated attachment ID should be returned.'
        );

        DHS_Deliverable__c deliverable = [
            SELECT Id,
                   DHS_Requested_By__c,
                   Requested_Date_Time__c,
                   Case_List__c,
                   Version_Number__c
            FROM DHS_Deliverable__c
            WHERE Version_Number__c = '3'
            LIMIT 1
        ];

        System.assertEquals(
            UserInfo.getUserId(),
            deliverable.DHS_Requested_By__c
        , 'Assertion failed in DHSDeliverablesControllerTest at source line 157');
        System.assertNotEquals(
            null,
            deliverable.Requested_Date_Time__c
        , 'Assertion failed in DHSDeliverablesControllerTest at source line 161');
        System.assertEquals(
            '3',
            deliverable.Version_Number__c
        , 'Assertion failed in DHSDeliverablesControllerTest at source line 165');

        Attachment generatedAttachment = [
            SELECT Id, ParentId, Name, Body, ContentType
            FROM Attachment
            WHERE Id = :controller.manifestActionAttachmentId
        ];

        System.assertEquals(
            deliverable.Id,
            generatedAttachment.ParentId
        , 'Assertion failed in DHSDeliverablesControllerTest at source line 176');
        System.assertEquals(
            'application/xml',
            generatedAttachment.ContentType
        , 'Assertion failed in DHSDeliverablesControllerTest at source line 180');
        System.assert(
            generatedAttachment.Name.startsWith(
                'isn_manifest_'
            )
        , 'Assertion failed in DHSDeliverablesControllerTest at source line 184');
        System.assert(
            generatedAttachment.Name.endsWith('.xml')
        , 'Assertion failed in DHSDeliverablesControllerTest at source line 189');
        System.assert(
            generatedAttachment.Body.size() > 0
        , 'Assertion failed in DHSDeliverablesControllerTest at source line 192');
        }
    }
}