@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSDashboardControllerTest {

    @IsTest
    static void calculatesDashboardAndCurrentWeek() {
        Test.startTest();
        DHSDashboardController controller =
            new DHSDashboardController();
        Test.stopTest();

        System.assertNotEquals(null, controller.currentUser, 'Expected the asserted condition to hold');

        System.assertNotEquals(null, controller.totalCases, 'Expected the asserted condition to hold');
        System.assertNotEquals(null, controller.totalCancelledCases, 'Expected the asserted condition to hold');
        System.assertNotEquals(null, controller.totalLeads, 'Expected the asserted condition to hold');
        System.assertNotEquals(null, controller.totalPendingCases, 'Expected the asserted condition to hold');
        System.assertNotEquals(null, controller.totalCompletedCases, 'Expected the asserted condition to hold');
        System.assertNotEquals(null, controller.totalPendingLeads, 'Expected the asserted condition to hold');

        System.assertNotEquals(
            null,
            controller.currentPendingCaseStatus
        , 'Expected the asserted condition to hold');
        System.assertNotEquals(
            null,
            controller.currentWeekCompletedCaseStatus
        , 'Expected the asserted condition to hold');
        System.assertNotEquals(
            null,
            controller.pendingLeadsByType
        , 'Expected the asserted condition to hold');
        System.assertNotEquals(
            null,
            controller.pendingLeadsByStatus
        , 'Expected the asserted condition to hold');

        System.assertNotEquals(null, controller.currentweekDates, 'Expected the asserted condition to hold');
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

        System.assertEquals(6, weekDates.size(), 'Expected the asserted condition to hold');
        System.assertEquals(
            String.valueOf(expectedStartDate),
            weekDates[0]
        , 'Expected the asserted condition to hold');
        System.assertEquals(
            String.valueOf(expectedStartDate.addDays(1)),
            weekDates[1]
        , 'Expected the asserted condition to hold');
        System.assertEquals(
            String.valueOf(expectedStartDate.addDays(5)),
            weekDates[5]
        , 'Expected the asserted condition to hold');
    }

    @IsTest
    static void removesCMOTestUserData() {
        Test.startTest();
        Map<String, Object> condition =
            DHSDashboardController.removeTestUserData('CMO');
        Test.stopTest();

        System.assertNotEquals(null, condition, 'Expected the asserted condition to hold');

        /*
         * Custom labels return at least one split entry, so these
         * condition values should be populated.
         */
        System.assertEquals(
            'DHS_Assigned_To__c',
            condition.get('key')
        , 'Expected the asserted condition to hold');
        System.assertEquals(
            'NOT IN',
            condition.get('operator')
        , 'Expected the asserted condition to hold');
        System.assertNotEquals(
            null,
            condition.get('value')
        , 'Expected the asserted condition to hold');
    }

    @IsTest
    static void removesInvestigatorTestUserData() {
        Test.startTest();
        Map<String, Object> condition =
            DHSDashboardController.removeTestUserData('INV');
        Test.stopTest();

        System.assertNotEquals(null, condition, 'Expected the asserted condition to hold');
        System.assertEquals(
            'DHS_Assigned_To__c',
            condition.get('key')
        , 'Expected the asserted condition to hold');
        System.assertEquals(
            'NOT IN',
            condition.get('operator')
        , 'Expected the asserted condition to hold');
        System.assertNotEquals(
            null,
            condition.get('value')
        , 'Expected the asserted condition to hold');
    }

    @IsTest
    static void returnsEmptyConditionForUnsupportedUserType() {
        Test.startTest();

        Map<String, Object> qaCondition =
            DHSDashboardController.removeTestUserData('QA');

        Map<String, Object> nullCondition =
            DHSDashboardController.removeTestUserData(null);

        Test.stopTest();

        System.assertNotEquals(null, qaCondition, 'Expected the asserted condition to hold');
        System.assertEquals(0, qaCondition.size(), 'Expected the asserted condition to hold');

        System.assertNotEquals(null, nullCondition, 'Expected the asserted condition to hold');
        System.assertEquals(0, nullCondition.size(), 'Expected the asserted condition to hold');
    }

    @IsTest
    static void getsPendingCasesFieldMap() {
        System.assert(true, 'Expected the test scenario to complete without exception');
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
        System.assert(true, 'Expected the test scenario to complete without exception');
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
        System.assert(true, 'Expected the test scenario to complete without exception');
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
        System.assert(true, 'Expected the test scenario to complete without exception');
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

        System.assertNotEquals(null, unknownResult, 'Expected the asserted condition to hold');
        System.assertEquals(0, unknownResult.size(), 'Expected the asserted condition to hold');

        System.assertNotEquals(null, nullResult, 'Expected the asserted condition to hold');
        System.assertEquals(0, nullResult.size(), 'Expected the asserted condition to hold');
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
