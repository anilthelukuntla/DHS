/**
 * @description Retains the existing DHSLoginHistory integration and application behavior.
 */
@SuppressWarnings('PMD.ApexSharingViolations,PMD.UnusedMethod')
public class DHSLoginHistory {
    /** @description Provides this DHS API member. */
    public static void getLoginsByuserId() {
        List<Map<String, Object>> loginRows = new List<Map<String, Object>>();
        for (SObject loginRecord : Database.query(
            'SELECT UserId, LoginTime, Status FROM LoginHistory'
        )) {
            loginRows.add((Map<String, Object>) JSON.deserializeUntyped(
                JSON.serialize(loginRecord)
            ));
        }
        groupSuccessfulLogins(loginRows);
    }

    @TestVisible
    private static Map<String, Set<String>> groupSuccessfulLogins(
        List<Map<String, Object>> loginRows
    ) {
        Map<String, Set<String>> dateWithUserIds =
            new Map<String, Set<String>>();
        for (Map<String, Object> row : loginRows) {
            if (String.valueOf(row.get('Status')) != 'Success') {
                continue;
            }
            String loginDate = String.valueOf(row.get('LoginTime')).substringBefore('T');
            if (!dateWithUserIds.containsKey(loginDate)) {
                dateWithUserIds.put(loginDate, new Set<String>());
            }
            dateWithUserIds.get(loginDate).add(String.valueOf(row.get('UserId')));
        }
        return dateWithUserIds;
    }
}
