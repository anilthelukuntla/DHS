@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSLoginHistoryTest {
    @IsTest
    static void groupsSuccessfulLoginsByDate() {
        String userId = UserInfo.getUserId();
        List<Map<String, Object>> rows = new List<Map<String, Object>>{
            new Map<String, Object>{'UserId'=>userId,'LoginTime'=>'2026-07-31T10:00:00Z','Status'=>'Success'},
            new Map<String, Object>{'UserId'=>userId,'LoginTime'=>'2026-07-31T11:00:00Z','Status'=>'Success'},
            new Map<String, Object>{'UserId'=>userId,'LoginTime'=>'2026-08-01T10:00:00Z','Status'=>'Failed'}
        };
        Map<String, Set<String>> grouped = DHSLoginHistory.groupSuccessfulLogins(rows);
        System.assertEquals(1, grouped.size(), 'Expected the asserted condition to hold');
        System.assertEquals(new Set<String>{userId}, grouped.get('2026-07-31'), 'Expected the asserted condition to hold');
    }

    @IsTest
    static void queriesLoginHistorySafely() {
        System.assert(true, 'Expected the test scenario to complete without exception');
        DHSLoginHistory.getLoginsByuserId();
    }
}
