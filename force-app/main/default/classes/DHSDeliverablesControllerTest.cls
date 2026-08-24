@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexAssertionsShouldIncludeMessage')
private class DHSDeliverablesControllerTest {

    @TestSetup
    static void setupData() {
        insert new List<DHS_Case__c>{
            new DHS_Case__c(
                Case_Number__c = 'DELIVERABLE-001',
                Current_Task__c = 'QA Review Completed'
            ),
            new DHS_Case__c(
                Case_Number__c = 'DELIVERABLE-002',
                Current_Task__c = 'QA Review Completed'
            ),
            new DHS_Case__c(
                Case_Number__c = 'NOT-AVAILABLE-001',
                Current_Task__c = 'In Progress'
            )
        };
    }

    @IsTest
    static void constructorLoadsCasesAndVersions() {
        Test.startTest();
        DHSDeliverablesController controller =
            new DHSDeliverablesController();
        Test.stopTest();

        System.assertNotEquals(null, controller.caseOptions);
        System.assertNotEquals(null, controller.selectedcaseOptions);
        System.assertNotEquals(null, controller.versionOptions);

        /*
         * One "--None--" option plus versions 1 through 20.
         */
        System.assertEquals(21, controller.versionOptions.size());
        System.assertEquals(
            '',
            controller.versionOptions[0].getValue()
        );
        System.assertEquals(
            '--None--',
            controller.versionOptions[0].getLabel()
        );
        System.assertEquals(
            '1',
            controller.versionOptions[1].getValue()
        );
        System.assertEquals(
            '20',
            controller.versionOptions[20].getValue()
        );

        Set<String> availableCaseNumbers = new Set<String>();

        for (SelectOption caseOption : controller.caseOptions) {
            availableCaseNumbers.add(caseOption.getLabel());
        }
    }

    @IsTest
    static void fetchCaseListLoadsQACompletedCases() {
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
        );
    }

    @IsTest
    static void downloadsManifestForSelectedCases() {
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
        );
        System.assertNotEquals(
            null,
            deliverable.Requested_Date_Time__c
        );
        System.assertEquals(
            '3',
            deliverable.Version_Number__c
        );

        Attachment generatedAttachment = [
            SELECT Id, ParentId, Name, Body, ContentType
            FROM Attachment
            WHERE Id = :controller.manifestActionAttachmentId
        ];

        System.assertEquals(
            deliverable.Id,
            generatedAttachment.ParentId
        );
        System.assertEquals(
            'application/xml',
            generatedAttachment.ContentType
        );
        System.assert(
            generatedAttachment.Name.startsWith(
                'isn_manifest_'
            )
        );
        System.assert(
            generatedAttachment.Name.endsWith('.xml')
        );
        System.assert(
            generatedAttachment.Body.size() > 0
        );
    }
}
