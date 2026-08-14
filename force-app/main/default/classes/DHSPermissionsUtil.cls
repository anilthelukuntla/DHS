/** Retains the existing DHSPermissionsUtil integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
public class DHSPermissionsUtil {
    public static User_Permission__mdt GetUserPermssions(string userType){
    	User_Permission__mdt userPermision = User_Permission__mdt.getInstance(userType.replaceAll(' ','_'));   
        return userPermision;
    }
}