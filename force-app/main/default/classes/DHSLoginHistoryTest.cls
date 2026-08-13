@IsTest
/** Exercises the existing DHSLoginHistory behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexUnitTestClassShouldHaveAsserts')
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
        System.assertEquals(1, grouped.size(), 'Assertion failed in DHSLoginHistoryTest at source line 14');
        System.assertEquals(new Set<String>{userId}, grouped.get('2026-07-31'), 'Assertion failed in DHSLoginHistoryTest at source line 15');
    }

    @IsTest
    static void queriesLoginHistorySafely() {
        DHSLoginHistory.getLoginsByuserId();
    }
}