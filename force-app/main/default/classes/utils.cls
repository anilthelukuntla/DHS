/** Retains the existing utils integration and application behavior. */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.ApexDoc, PMD.ApexSharingViolations, PMD.AvoidDeeplyNestedIfStmts, PMD.ClassNamingConventions, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.DebugsShouldUseLoggingLevel, PMD.StdCyclomaticComplexity')
public class utils {
    public static Map<String, Object> flatten(Map<String, Object> obj, String sep) {
        // Initialize with an empty roots list
        return flattenInternal(obj, new List<String>(), sep == null ? '.' : sep);
    }
    private static Map<String, Object> flattenInternal(Map<String, Object> obj, List<String> roots, String sep) {
        Map<String, Object> flattened = new Map<String, Object>();
        for (String key : obj.keySet()) {
            Object value = obj.get(key);
            // Handle null values explicitly
            if (value == null) {
                String flattenedKey = (roots.isEmpty() ? '' : String.join(roots, sep) + sep) + key;
                flattened.put(flattenedKey, null);
            } else if (value instanceof Map<String, Object>) {
                // Create a new list for roots
                List<String> newRoots = new List<String>(roots);
                newRoots.add(key);
                // Recursively flatten nested maps
                flattened.putAll(flattenInternal(
                    (Map<String, Object>)value,
                    newRoots,
                    sep
                ));
            } else {
                // Build the full key path for non-map values
                String flattenedKey = (roots.isEmpty() ? '' : String.join(roots, sep) + sep) + key;
                flattened.put(flattenedKey, value);
            }
        }
        return flattened;
    }
    public static List<Map<String, Object>> convertToMapList(List<SObject> records, List<String> fields) {
        List<Map<String, Object>> resultList = new List<Map<String, Object>>();
        
        for (SObject record : records) {
            Map<String, Object> recordMap = new Map<String, Object>();
            
            for (String field : fields) {
                if (field.contains('.')) {
                    // Handle relational fields
                    object fieldValue = getRelationalValue(record,field);
                    if(fieldValue != null){
                        if(fieldValue instanceof Date) {
                            List<string> dateVal = date.valueOf(fieldValue).tostring().substringBefore(' ').split('-');
                            fieldValue = dateVal.get(1)+'-'+dateVal.get(2)+'-'+dateVal.get(0);
                        }else if (fieldValue instanceof DateTime) {
                            DateTime dt = (DateTime)fieldValue;
                            fieldValue = dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                        }
                    }else{
                        fieldValue = '';
                    }
                    field = field.tolowercase();
                    recordMap.put(field, fieldValue);
                } else {
                    // Handle direct fields
                    object fieldValue = record.get(field);
                    if(fieldValue != null){
                        if(fieldValue instanceof Date) {
                            List<string> dateVal = date.valueOf(fieldValue).tostring().substringBefore(' ').split('-');
                            fieldValue = dateVal.get(1)+'-'+dateVal.get(2)+'-'+dateVal.get(0);
                        }else if (fieldValue instanceof DateTime) {
                            DateTime dt = (DateTime)fieldValue;
                            fieldValue = dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                        }
                    }else{
                        fieldValue = '';
                    }
                    field = field.tolowercase();
                    recordMap.put(field, fieldValue);
                }
            }	            
            resultList.add(recordMap);
        }
        
        return resultList;
    }
    public static object getRelationalValue(sObject record, string apiname){
        if(apiname.contains('.')){
            return record != null ? recursion(record,apiname) : null;
        }else{
            return record != null ? record.get(apiname) : null;
        }
    }
    static Object recursion(sObject record, string apiname){
        string parentApiName = apiname.substringBefore('.');
		sObject parentObject = (sobject)record.getSObject(parentApiName);
		string suffix = apiname.substringAfter('.');
        return getRelationalValue(parentObject,suffix);
    }
    @AuraEnabled
    public static List<Report_Export__c> getReportExport(string reportType,string currentSystem) {
        List<Report_Export__c> temps = [select id,Label__c	,Api_Name__c,Order__c,Report_Type__c,System__c from Report_Export__c 
                                       where System__c =: currentSystem and Report_Type__c =: reportType
                                       order by Order__c asc];
        
        return temps;
    }
    @AuraEnabled
    public static object saveReport(Map<string,string> revisedData){
        List<Report_Export__c> temps = [select id from Report_Export__c where id IN:revisedData.keyset()];
        for(Report_Export__c temp : temps){
            temp.Order__c = integer.valueOf(revisedData.get(temp.Id));
        }
        try{
            update temps;
            return true;
        }catch(exception e){
            return e;
        }
    }
    @AuraEnabled
    public static object updateReport(Map<string,string> info){
        List<Report_Export__c> temp = New List<Report_Export__c>();
        if(info.containsKey('id')){
			temp = [select id,label__c,api_name__c from Report_Export__c where id =: info.get('id')];
            temp[0].label__c = info.get('label');
        	temp[0].api_name__c = info.get('apiname');
            try{
                update temp[0];
                return true;
            }catch(exception e){
                return e;
            }
        }else{
			temp = [select id,order__c,Label__c,Api_Name__c,System__c,Report_Type__c from Report_Export__c where System__c =: info.get('currentsystem') and Report_Type__c =: info.get('objectname') order by order__c desc limit 1];
            integer order = 0;
            If(temp.size() > 0){
                order = integer.valueof(temp[0].Order__c);
				order = order+1;
            } 
            Report_Export__c re = New Report_Export__c();
            re.Label__c = info.get('label');
            re.Api_Name__c = info.get('apiname');
            re.Order__c = order;
            re.System__c = info.get('currentsystem');
            re.Report_Type__c = info.get('objectname');
            try{
                insert re;
                return true;
            }catch(exception e){
                return e;
            }
        }
    }
    @AuraEnabled
    public static List<Map<string,Object>> getFieldData(string objectName){
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
        Map<String, Schema.SObjectField> fieldsMap = sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();
		
        List<Map<string,Object>> getData = New List<Map<string,Object>>();
        // Loop through the fields and print their API names and labels
        for (String fieldName : fieldsMap.keySet()) {
            Map<string,Object> labelApiName = New Map<string,Object>();
            Schema.DescribeFieldResult fieldDescribe = fieldsMap.get(fieldName).getDescribe();
            String label = fieldDescribe.getLabel();
            labelApiName.put('label',label);
            labelApiName.put('apiname',fieldName);
            if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE){
                List<Schema.SObjectType> parentObjectName = fieldDescribe.getReferenceTo();
                if(parentObjectName.size() > 0){
                    labelApiName.put('isparent',parentObjectName[0].getDescribe().getName());
                }
            }else{
                labelApiName.put('isparent',null);
            }
            getData.add(labelApiName);
        }	
        	return getData;
    }
}