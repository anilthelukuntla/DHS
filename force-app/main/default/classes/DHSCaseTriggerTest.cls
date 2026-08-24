@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts,PMD.ApexUnitTestClassShouldHaveRunAs,PMD.OperationWithLimitsInLoop,PMD.ApexAssertionsShouldIncludeMessage,PMD.UnusedLocalVariable')
private class DHSCaseTriggerTest {

    @TestSetup
    static void setupData() {
        DHS_Contact__c subject = new DHS_Contact__c(
            First_Name__c = 'Case',
            Last_Name__c = 'Trigger Test',
            Email__c = 'case-trigger@example.com',
            Contact_Type__c = 'Subject'
        );
        insert subject;
    }

    private static DHS_Contact__c getSubject() {
        return [
            SELECT Id, Run_Credit_Report__c
            FROM DHS_Contact__c
            LIMIT 1
        ];
    }

    private static DHS_Case__c createCase() {
        DHS_Contact__c subject = getSubject();

        DHS_Case__c caseRecord = new DHS_Case__c(
            DHS_Contact__c = subject.Id,
            Case_Number__c = 'CASE-' +
                String.valueOf(DateTime.now().getTime())
        );

        insert caseRecord;
        return caseRecord;
    }

    @IsTest
    static void initializesCaseHistoryAndContact() {
        DHS_Contact__c subject = getSubject();

        Test.startTest();

        DHS_Case__c caseRecord = new DHS_Case__c(
            DHS_Contact__c = subject.Id,
            Case_Number__c = 'INITIAL-CASE'
        );
        insert caseRecord;

        Test.stopTest();

        caseRecord = [
            SELECT Current_Task__c,
                   Initiated_State_Date__c,
                   Submission_Date__c,
                   Case_Queue_Status__c
            FROM DHS_Case__c
            WHERE Id = :caseRecord.Id
        ];

        System.assertEquals(
            'Initiated State',
            caseRecord.Current_Task__c
        );
        System.assertEquals(
            Date.today(),
            caseRecord.Initiated_State_Date__c
        );
        System.assertEquals(
            Date.today(),
            caseRecord.Submission_Date__c
        );
        System.assertEquals(
            'New',
            caseRecord.Case_Queue_Status__c
        );

        DHS_Contact__c updatedSubject = [
            SELECT Run_Credit_Report__c
            FROM DHS_Contact__c
            WHERE Id = :subject.Id
        ];

        System.assertEquals(
            true,
            updatedSubject.Run_Credit_Report__c
        );

        List<DHS_Case_History__c> histories = [
            SELECT DHS_Case__c, DHS_Added_By__c, Value__c
            FROM DHS_Case_History__c
            WHERE DHS_Case__c = :caseRecord.Id
        ];

        System.assertEquals(1, histories.size());
        System.assertEquals(
            UserInfo.getUserId(),
            histories[0].DHS_Added_By__c
        );
        System.assertEquals(
            'Initiated State',
            histories[0].Value__c
        );
    }

    @IsTest
    static void assignsCaseToUser() {
        DHS_Case__c caseRecord = createCase();

        Test.startTest();

        caseRecord.DHS_Assigned_To__c =
            UserInfo.getUserId();

        update caseRecord;

        Test.stopTest();

        caseRecord = [
            SELECT DHS_Assigned_To__c,
                   Case_Queue_Status__c,
                   Assignee_Date__c
            FROM DHS_Case__c
            WHERE Id = :caseRecord.Id
        ];

        System.assertEquals(
            UserInfo.getUserId(),
            caseRecord.DHS_Assigned_To__c
        );
        System.assertEquals(
            'Assigned',
            caseRecord.Case_Queue_Status__c
        );
        System.assertEquals(
            Date.today(),
            caseRecord.Assignee_Date__c
        );
    }

    @IsTest
    static void movesCaseThroughTaskStatuses() {
        DHS_Case__c caseRecord = createCase();

        List<String> inProgressTasks = new List<String>{
            'Scoping',
            'Investigations',
            'Investigations Review',
            'QA and Review'
        };

        Test.startTest();

        for (String taskName : inProgressTasks) {
            caseRecord.Current_Task__c = taskName;
            update caseRecord;

            DHS_Case__c updatedCase = [
                SELECT Current_Task__c,
                       Case_Queue_Status__c
                FROM DHS_Case__c
                WHERE Id = :caseRecord.Id
            ];

            System.assertEquals(
                taskName,
                updatedCase.Current_Task__c
            );
            System.assertEquals(
                'In Progress',
                updatedCase.Case_Queue_Status__c
            );
        }

        caseRecord.Current_Task__c =
            'QA Review Completed';

        update caseRecord;

        Test.stopTest();

        caseRecord = [
            SELECT Current_Task__c,
                   Case_Queue_Status__c,
                   QA_Review_Completed_Date__c,
                   Case_Completed_Date__c
            FROM DHS_Case__c
            WHERE Id = :caseRecord.Id
        ];

        System.assertEquals(
            'QA Review Completed',
            caseRecord.Current_Task__c
        );
        System.assertEquals(
            'Completed',
            caseRecord.Case_Queue_Status__c
        );
        System.assertEquals(
            Date.today(),
            caseRecord.QA_Review_Completed_Date__c
        );
        System.assertEquals(
            Date.today(),
            caseRecord.Case_Completed_Date__c
        );
    }

    @IsTest
    static void discontinuesAndRestoresRelatedLeads() {
        DHS_Case__c caseRecord = createCase();
        DHS_Contact__c subject = getSubject();

        List<DHS_Lead__c> leads = new List<DHS_Lead__c>{
            new DHS_Lead__c(
                DHS_Case__c = caseRecord.Id,
                DHS_Contact__c = subject.Id,
                DHS_Assigned_To__c = UserInfo.getUserId(),
                LeadType__c =
                    'Subject Interview (ESI/TESI)',
                Coverage_Type__c = 'Subject Interview',
                Status__c = 'Assigned'
            ),
            new DHS_Lead__c(
                DHS_Case__c = caseRecord.Id,
                DHS_Contact__c = subject.Id,
                DHS_Assigned_To__c = UserInfo.getUserId(),
                LeadType__c = 'General (GENL)',
                Coverage_Type__c = 'Personal',
                Status__c = 'In-Progress'
            )
        };
        insert leads;

        Test.startTest();

        caseRecord.Case_Discontinued__c = true;
        update caseRecord;

        List<DHS_Lead__c> discontinuedLeads = [
            SELECT Id,
                   Status__c,
                   Lead_Status_Before_Discont__c
            FROM DHS_Lead__c
            WHERE DHS_Case__c = :caseRecord.Id
            ORDER BY Status__c
        ];

        for (DHS_Lead__c lead : discontinuedLeads) {
            System.assertEquals(
                'Discontinued',
                lead.Status__c
            );
            System.assertNotEquals(
                null,
                lead.Lead_Status_Before_Discont__c
            );
        }

        caseRecord.Case_Discontinued__c = false;
        update caseRecord;

        Test.stopTest();

        Map<Id, DHS_Lead__c> restoredLeads =
            new Map<Id, DHS_Lead__c>([
                SELECT Id,
                       Status__c,
                       Lead_Status_Before_Discont__c
                FROM DHS_Lead__c
                WHERE DHS_Case__c = :caseRecord.Id
            ]);
    }

    @IsTest
    static void calculatesTier5FortyDaySLACodes() {
        verifySLA(
            'Tier 5',
            '40',
            new Map<Integer, String>{
                10 => '#90cf55',
                18 => '#fefe00',
                25 => '#fbbd03',
                35 => '#ffbee6',
                41 => '#fd0708'
            }
        );
    }

    @IsTest
    static void calculatesTier5TwentyDaySLACodes() {
        verifySLA(
            'Tier 5',
            '20',
            new Map<Integer, String>{
                5 => '#90cf55',
                10 => '#fefe00',
                15 => '#fbbd03',
                18 => '#ffbee6',
                21 => '#fd0708'
            }
        );
    }

    @IsTest
    static void calculatesReinvestigationSLACodes() {
        verifySLA(
            'Tier 5 Reinvestigation',
            null,
            new Map<Integer, String>{
                10 => '#90cf55',
                30 => '#fefe00',
                45 => '#fbbd03',
                58 => '#ffbee6',
                61 => '#fd0708'
            }
        );
    }

    @IsTest
    static void calculatesTriggeredInvestigationSLACodes() {
        verifySLA(
            'Triggered Investigation',
            null,
            new Map<Integer, String>{
                10 => '#90cf55',
                16 => '#fefe00',
                23 => '#fbbd03',
                28 => '#ffbee6',
                31 => '#fd0708'
            }
        );
    }

    @IsTest
    static void calculatesSupplementalInvestigationSLACodes() {
        verifySLA(
            'Supplemental Investigation',
            null,
            new Map<Integer, String>{
                5 => '#90cf55',
                8 => '#fefe00',
                10 => '#fbbd03',
                12 => '#ffbee6',
                15 => '#fd0708'
            }
        );
    }

    @IsTest
    static void unsupportedCaseTypeClearsSLACode() {
        DHS_Case__c caseRecord = createCase();

        caseRecord.Case_Type__c = 'Other';
        caseRecord.Scheduled_Date__c =
            Date.today().addDays(10);

        Test.startTest();
        update caseRecord;
        Test.stopTest();

        caseRecord = [
            SELECT Case_SLA_Code__c
            FROM DHS_Case__c
            WHERE Id = :caseRecord.Id
        ];
    }

    private static void verifySLA(
        String caseType,
        String serviceDays,
        Map<Integer, String> daysToExpectedColor
    ) {
        DHS_Contact__c subject = getSubject();
        List<DHS_Case__c> casesToInsert =
            new List<DHS_Case__c>();

        Integer sequence = 0;

        for (Integer numberOfDays :
            daysToExpectedColor.keySet()) {

            casesToInsert.add(
                new DHS_Case__c(
                    DHS_Contact__c = subject.Id,
                    Case_Number__c =
                        'SLA-' + caseType + '-' + sequence
                )
            );

            sequence++;
        }

        insert casesToInsert;

        Map<Id, Integer> caseIdToDays =
            new Map<Id, Integer>();

        Integer indexValue = 0;

        for (Integer numberOfDays :
            daysToExpectedColor.keySet()) {

            DHS_Case__c caseRecord =
                casesToInsert[indexValue];

            caseRecord.Case_Type__c = caseType;
            caseRecord.Service_Days__c = serviceDays;

            /*
             * The trigger currently calculates:
             *
             * Date.today().daysBetween(Scheduled_Date__c)
             *
             * Therefore, a future scheduled date is required to
             * produce a positive NumberOfDays.
             */
            caseRecord.Scheduled_Date__c =
                Date.today().addDays(numberOfDays);

            caseIdToDays.put(
                caseRecord.Id,
                numberOfDays
            );

            indexValue++;
        }

        Test.startTest();
        update casesToInsert;
        Test.stopTest();

        for (DHS_Case__c caseRecord : [
            SELECT Id, Case_SLA_Code__c
            FROM DHS_Case__c
            WHERE Id IN :casesToInsert
        ]) {
            Integer numberOfDays =
                caseIdToDays.get(caseRecord.Id);

            System.assertEquals(
                daysToExpectedColor.get(numberOfDays),
                caseRecord.Case_SLA_Code__c,
                'Unexpected SLA color for ' +
                    caseType + ' after ' +
                    numberOfDays + ' days.'
            );
        }
    }
}
