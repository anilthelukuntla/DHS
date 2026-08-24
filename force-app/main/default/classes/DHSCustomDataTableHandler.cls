/**
 * @description Retains the existing DHSCustomDataTableHandler integration and application behavior.
 */
@SuppressWarnings('PMD.ApexSharingViolations,PMD.AvoidNonRestrictiveQueries,PMD.UnusedMethod')
public class DHSCustomDataTableHandler {
    /** @description Provides this DHS API member. */
    public List<map<string,object>> rows	{get;set;}
    /** @description Provides this DHS API member. */
    public static Map<string,map<string,object>> originalRows	{get;set;}
    /** @description Provides this DHS API member. */
    public static List<string> originalHeaders {get;set;}
    /** @description Provides this DHS API member. */
    public List<string> headers {get;set;}
    /** @description Provides this DHS API member. */
    public List<string> apinames {get;set;}
    /** @description Provides this DHS API member. */
    public DHSCustomDataTableHandler(){
        originalRows = New Map<string,map<string,object>>();
        originalHeaders = New List<string>();
        headers = New List<string>();
        rows = new List<map<string,object>>();
        apinames = New List<string>();
        headers.add('Id Value');
        headers.add('Name Value');
        apinames.add('id');
        apinames.add('name');
        list<contact> cons = [select id,name from contact WITH USER_MODE ];
        rows = DHSUtils.convertToMapList(cons,apinames);
        for(map<string,object> row : rows){
            originalRows.put(string.valueOf(row.get('id')),row);
        }
        originalHeaders.addAll(originalRows.keyset());
        rows = originalRows.values();
    }
    @RemoteAction
    /**
     * @description Provides this DHS API member.
     * @param rowId Method parameter.
     */
    public static void editField(string rowId) {
        map<string,object> row = originalRows.get(rowId);
        row.put('id','worked');
        originalRows.put((string)row.get('id'),row);
    }
}
