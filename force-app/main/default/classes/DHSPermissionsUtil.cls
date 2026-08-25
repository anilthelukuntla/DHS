/**
 * @description Retains the existing DHSPermissionsUtil integration and application behavior.
 */

public class DHSPermissionsUtil {
    /**
     * @description Provides this DHS API member.
     * @param userType Method parameter.
     * @return The requested result.
     */
    public static User_Permission__mdt getUserPermssions(string userType){
    	User_Permission__mdt userPermision = User_Permission__mdt.getInstance(userType.replaceAll(' ','_'));   
        return userPermision;
    }
}