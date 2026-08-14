@IsTest
/** Exercises the existing DHSDashboardController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexUnitTestClassShouldHaveAsserts')
private class DHSDashboardControllerTest {

    @IsTest
    static void calculatesDashboardAndCurrentWeek() {
        DHS_Case__c pendingCase = new DHS_Case__c(
            Current_Task__c = 'Investigations Review'
        );
        insert pendingCase;
        insert new List<DHS_Lead__c>{
            new DHS_Lead__c(
                DHS_Case__c = pendingCase.Id,
                Status__c = 'Unassigned',
                LeadType__c = 'Subject Interview (ESI/TESI)'
            ),
            new DHS_Lead__c(
                DHS_Case__c = pendingCase.Id,
                Status__c = 'Unassigned',
                LeadType__c = 'Subject Interview (ESI/TESI)'
            )
        };
        Test.startTest();
        DHSDashboardController controller =
            new DHSDashboardController();
        Test.stopTest();

        System.assertNotEquals(null, controller.currentUser, 'Assertion failed in DHSDashboardControllerTest at source line 29');

        System.assertNotEquals(null, controller.totalCases, 'Assertion failed in DHSDashboardControllerTest at source line 31');
        System.assertNotEquals(null, controller.totalCancelledCases, 'Assertion failed in DHSDashboardControllerTest at source line 32');
        System.assertNotEquals(null, controller.totalLeads, 'Assertion failed in DHSDashboardControllerTest at source line 33');
        System.assertNotEquals(null, controller.totalPendingCases, 'Assertion failed in DHSDashboardControllerTest at source line 34');
        System.assertNotEquals(null, controller.totalCompletedCases, 'Assertion failed in DHSDashboardControllerTest at source line 35');
        System.assertNotEquals(null, controller.totalPendingLeads, 'Assertion failed in DHSDashboardControllerTest at source line 36');

        System.assertNotEquals(
            null,
            controller.currentPendingCaseStatus
        , 'Assertion failed in DHSDashboardControllerTest at source line 38');
        System.assertNotEquals(
            null,
            controller.currentWeekCompletedCaseStatus
        , 'Assertion failed in DHSDashboardControllerTest at source line 42');
        System.assertNotEquals(
            null,
            controller.pendingLeadsByType
        , 'Assertion failed in DHSDashboardControllerTest at source line 46');
        System.assertNotEquals(
            null,
            controller.pendingLeadsByStatus
        , 'Assertion failed in DHSDashboardControllerTest at source line 50');

        System.assertNotEquals(null, controller.currentweekDates, 'Assertion failed in DHSDashboardControllerTest at source line 55');
        System.assertEquals(
            6,
            controller.currentweekDates.size(),
            'The controller currently returns Monday through Saturday.'
        );
    }

    @IsTest
    static void getsCurrentWeekDates() {
        DHSDashboardController controller =
            new DHSDashboardController();

        Date expectedStartDate = Date.today().toStartOfWeek();

        Test.startTest();
        List<String> weekDates =
            controller.getCurrentWeekDates();
        Test.stopTest();

        System.assertEquals(6, weekDates.size(), 'Assertion failed in DHSDashboardControllerTest at source line 75');
        System.assertEquals(
            String.valueOf(expectedStartDate),
            weekDates[0]
        , 'Assertion failed in DHSDashboardControllerTest at source line 76');
        System.assertEquals(
            String.valueOf(expectedStartDate.addDays(1)),
            weekDates[1]
        , 'Assertion failed in DHSDashboardControllerTest at source line 80');
        System.assertEquals(
            String.valueOf(expectedStartDate.addDays(5)),
            weekDates[5]
        , 'Assertion failed in DHSDashboardControllerTest at source line 84');
    }

    @IsTest
    static void removesCMOTestUserData() {
        Test.startTest();
        Map<String, Object> condition =
            DHSDashboardController.removeTestUserData('CMO');
        Test.stopTest();

        System.assertNotEquals(null, condition, 'Assertion failed in DHSDashboardControllerTest at source line 97');

        /*
         * Custom labels return at least one split entry, so these
         * condition values should be populated.
         */
        System.assertEquals(
            'DHS_Assigned_To__c',
            condition.get('key')
        , 'Assertion failed in DHSDashboardControllerTest at source line 103');
        System.assertEquals(
            'NOT IN',
            condition.get('operator')
        , 'Assertion failed in DHSDashboardControllerTest at source line 107');
        System.assertNotEquals(
            null,
            condition.get('value')
        , 'Assertion failed in DHSDashboardControllerTest at source line 111');
    }

    @IsTest
    static void removesInvestigatorTestUserData() {
        Test.startTest();
        Map<String, Object> condition =
            DHSDashboardController.removeTestUserData('INV');
        Test.stopTest();

        System.assertNotEquals(null, condition, 'Assertion failed in DHSDashboardControllerTest at source line 124');
        System.assertEquals(
            'DHS_Assigned_To__c',
            condition.get('key')
        , 'Assertion failed in DHSDashboardControllerTest at source line 125');
        System.assertEquals(
            'NOT IN',
            condition.get('operator')
        , 'Assertion failed in DHSDashboardControllerTest at source line 129');
        System.assertNotEquals(
            null,
            condition.get('value')
        , 'Assertion failed in DHSDashboardControllerTest at source line 133');
    }

    @IsTest
    static void returnsEmptyConditionForUnsupportedUserType() {
        Test.startTest();

        Map<String, Object> qaCondition =
            DHSDashboardController.removeTestUserData('QA');

        Map<String, Object> nullCondition =
            DHSDashboardController.removeTestUserData(null);

        Test.stopTest();

        System.assertNotEquals(null, qaCondition, 'Assertion failed in DHSDashboardControllerTest at source line 151');
        System.assertEquals(0, qaCondition.size(), 'Assertion failed in DHSDashboardControllerTest at source line 152');

        System.assertNotEquals(null, nullCondition, 'Assertion failed in DHSDashboardControllerTest at source line 154');
        System.assertEquals(0, nullCondition.size(), 'Assertion failed in DHSDashboardControllerTest at source line 155');
    }

    @IsTest
    static void getsPendingCasesFieldMap() {
        Test.startTest();
        List<Map<String, Object>> fieldMap =
            DHSDashboardController.getFieldMap(
                'pendingCasesByStatus'
            );
        Test.stopTest();

        verifyFieldMap(fieldMap);
    }

    @IsTest
    static void getsPendingLeadsByStatusFieldMap() {
        Test.startTest();
        List<Map<String, Object>> fieldMap =
            DHSDashboardController.getFieldMap(
                'PendingLeadsByStatus'
            );
        Test.stopTest();

        verifyFieldMap(fieldMap);
    }

    @IsTest
    static void getsPendingLeadsByTypeFieldMap() {
        Test.startTest();
        List<Map<String, Object>> fieldMap =
            DHSDashboardController.getFieldMap(
                'PendingLeadsByType'
            );
        Test.stopTest();

        verifyFieldMap(fieldMap);
    }

    @IsTest
    static void getsCompletedCasesFieldMap() {
        Test.startTest();
        List<Map<String, Object>> fieldMap =
            DHSDashboardController.getFieldMap(
                'CasesCompletedThisWeek'
            );
        Test.stopTest();

        verifyFieldMap(fieldMap);
    }

    @IsTest
    static void returnsEmptyFieldMapForUnsupportedReport() {
        Test.startTest();

        List<Map<String, Object>> unknownResult =
            DHSDashboardController.getFieldMap(
                'UnsupportedReport'
            );

        List<Map<String, Object>> nullResult =
            DHSDashboardController.getFieldMap(null);

        Test.stopTest();

        System.assertNotEquals(null, unknownResult, 'Assertion failed in DHSDashboardControllerTest at source line 220');
        System.assertEquals(0, unknownResult.size(), 'Assertion failed in DHSDashboardControllerTest at source line 221');

        System.assertNotEquals(null, nullResult, 'Assertion failed in DHSDashboardControllerTest at source line 223');
        System.assertEquals(0, nullResult.size(), 'Assertion failed in DHSDashboardControllerTest at source line 224');
    }

    private static void verifyFieldMap(
        List<Map<String, Object>> fieldMap
    ) {
        System.assertNotEquals(
            null,
            fieldMap,
            'The method must always return a list.'
        );

        /*
         * Metadata may differ between environments. Only validate
         * individual entries when metadata records are available.
         */
        for (Map<String, Object> fieldEntry : fieldMap) {
            System.assert(
                fieldEntry.containsKey('label'),
                'Each entry should contain a label.'
            );
            System.assert(
                fieldEntry.containsKey('apiname'),
                'Each entry should contain an API name.'
            );
        }
    }
}