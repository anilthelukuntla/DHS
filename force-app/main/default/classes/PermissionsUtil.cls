/** Resolves the custom-metadata permissions configured for a user type. */
@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
public class PermissionsUtil {
    public static User_Permission__mdt GetUserPermssions(string userType){
    	User_Permission__mdt userPermision = User_Permission__mdt.getInstance(userType.replaceAll(' ','_'));   
        return userPermision;
    }
}