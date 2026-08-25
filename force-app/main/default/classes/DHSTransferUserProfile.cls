/**
 * @description Retains the existing DHSTransferUserProfile integration and application behavior.
 */
@SuppressWarnings('PMD.ApexSharingViolations')
public class DHSTransferUserProfile {
    /** @description Provides this DHS API member. */
    public static void doTransfer(){
        string fromProfileName = string.valueOf(system.label.DHS_from_profile);
        string toProfileName = string.valueOf(system.label.DHS_to_profile);
        profile toProfile = [select id from profile where name =: toProfileName order by createddate desc limit 1];
        list<user> users = [select id,profileId from user where profile.Name =: fromProfileName ];
        list<user> updateUsers = New list<user>();
        for(user usr : users){
            usr.profileId = toProfile.Id;
            updateUsers.add(usr);
        }
        	Database.update(updateUsers, AccessLevel.USER_MODE);
    }
}