/**
 * @description Determines whether the current DHS user can access the report designer.
 */
public with sharing class DHSHeaderProfileController {
    /**
     * @description Indicates whether the current user can open the DHS designer.
     */
    public Boolean canAccessDhsDesigner { get; private set; }

    /**
     * @description Loads the current user's DHS type and Salesforce profile.
     */
    public DHSHeaderProfileController() {
        canAccessDhsDesigner = false;
        List<User> users = [
            SELECT User_Type__c, Profile.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        if (!users.isEmpty()) {
            User currentUser = users[0];
            canAccessDhsDesigner = currentUser.User_Type__c == 'PMO' || currentUser.Profile.Name == 'System Administrator';
        }
    }
}