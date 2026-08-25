public class ApexUtil {
    
    //Method used to get fields from fieldsets defined in salesforce objects.
    //Sample Usage: List fieldSetMemberList =  Util.readFieldSet('FieldSetName','Work_Order__c');
    //Returns list<Schema.FieldSetMember>
    //We can access field ApIName, Label using getFieldPath(), getLabel() respectively
    public static List<Schema.FieldSetMember> readFieldSet(String fieldSetName, String ObjectName) {
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        return fieldSetObj.getFields();
    }
    
    //creates a map of all Record Type Names to Ids based upon a passed Object
    //Sample Usage: map<String, Id> incidentRecordTypes = buildMapOfRecordTypes('Incident__c');
    public static Map<String, Id> buildMapOfRecordTypes(String passedSobjectType) {
        Map<String, Id> returnMap = new Map<String, Id>(); 
        for (RecordType rt : [SELECT Id, Name FROM RecordType WHERE SobjectType = :passedSobjectType]) { 
            returnMap.put(rt.Name, rt.Id); 
        }
        return returnMap; 
    }
    
    //Method To Return Allfields of the object
    public static List<String> FetchFields(String ObjectName){
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = DescribeSObjectResultObj.fields.getMap();
        // Get all of the fields on the object
        List<String> fieldNames = new List<String>();
        fieldNames.addAll(fieldMap.keySet());
        return fieldNames;
    }
    
    //Return List of Pick list values for the given object and the picklist filed name
    public static List<String> getPickListValues(Sobject object_name, String field_name){
        List<String> pList = new List<String>();
        Schema.sObjectType sobject_type = object_name.getSObjectType(); 
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); 
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); 
        List<Schema.PicklistEntry> pick_list_values = field_map.get(field_name).getDescribe().getPickListValues(); 
        for (Schema.PicklistEntry ple : pick_list_values){
            pList.add(ple.getLabel());
        }  
        return pList;
    }
    
    public static String queryBuilder(String objectName, List<String> fields, List<String> filter){
        return queryBuilder(objectName,fields,filter,null);
    }
    
    public static String queryBuilder(String objectName, String fieldSetName, List<String> filter){
        String query = 'select ';
        List<String> fieldList = getFieldSetFields(objectName, fieldSetName);
        return queryBuilder(objectName,fieldList,filter);
    }
    
    public static String queryBuilder(String objectName, List<String> fields, List<String> filter,List<string> orderBy){
        String query = 'SELECT ';
        query += String.join(fields,',');
        query +=' FROM ' + objectName;
        if(filter!=null && filter.size()>0){
           query +=' WHERE ' + String.join(filter,' and '); 
        }
        if(orderBy!=null && orderBy.size()>0){
            query +=' ORDER BY ' + String.join(orderBy,','); 
        }
       return query;
    }
    
     public static List<String> getFieldSetFields(String object_name,String fsetName){
        List<Schema.FieldSetMember> fieldset  = getFieldSetFieldsObjs(object_name,fsetName);
        List<String> items = new List<String>();
        for(Schema.FieldSetMember f : fieldset) {
            items.add(f.getFieldPath());    
        }
        return items;
    }
    
    public static List<Schema.FieldSetMember> getFieldSetFieldsObjs(String object_name,String fsetName){
       return getObjectTypeDescribe(object_name).FieldSets.getMap().get(fsetName).getFields();
    }
    
    public static Schema.DescribeSObjectResult getObjectTypeDescribe(String object_name){
        Type t = Type.forName(object_name);
        return ((Sobject)t.newInstance()).getSObjectType().getDescribe();
    }
    
    public static Map<object,object> getSObjectFieldTypes(String objType) {
        map<object,object> fieldDataTypesMap = new map<object,object>();
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType objectSchema = schemaMap.get(objType);
        Map<String, Schema.SObjectField> fields = objectSchema.getDescribe().fields.getMap();
        Map<String, Object> result = new Map<String, Object>();
    
        for(String fieldName : fields.keySet()) {
            Schema.SObjectField field = fields.get(fieldName);
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            fieldDataTypesMap.put(fieldName, String.valueof(fieldDescribe.getType()));
        }
        
        return fieldDataTypesMap;
    } 
    
    public class Criteria {
       public String FieldName;
       public String Operator;
       public String FieldValue;
       public String FieldType;
       public Criteria(String f_name, string f_value,string f_operator) {
           FieldName = f_name;
           FieldValue = f_value;
           Operator = f_operator;
       }
       public Criteria(String f_name, string f_value,string f_operator,string f_type) {
           FieldName = f_name;
           FieldValue = f_value;
           Operator = f_operator;
           FieldType =  f_type;
       }
       public String getSOQLCriteria() {
           //Latest Change
           // Handle NULL separately
            if(FieldValue == null){
                return fieldName + ' ' + Operator + ' null';
            }
           if(FieldType != 'Date' && FieldType != 'Double' && FieldType != 'Integer'){
               return fieldName + ' '  + Operator + ' \'' + FieldValue + '\'';
           }else{
               return fieldName + ' '  + Operator  + FieldValue ;
           }
           
       }
    
       public boolean IsFieldValueGiven() {
           return FieldValue != null && FieldValue != '';
       }
    }
    
    public static String generateWhereQuery(List<Criteria> criterias) {
        List<String> and_conditions = new List<String>();
        for(Criteria single_criteria : criterias) {
            //if (single_criteria.IsFieldValueGiven()) {
                and_conditions.add(single_criteria.getSOQLCriteria());
            //}
        }
        return String.join(and_conditions, ' AND ');
    }
    
    public static List<String> getPickListValuesIntoList(String objectType, String selectedField){
        List<String> pickListValuesList = new List<String>();
        Schema.SObjectType convertToObj = Schema.getGlobalDescribe().get(objectType);
        Schema.DescribeSObjectResult res = convertToObj.getDescribe();
        Schema.DescribeFieldResult fieldResult = res.fields.getMap().get(selectedField).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }     
        return pickListValuesList;
    }
    
    public static Boolean runningInASandbox() {
        return [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }
	public static Map<String, Schema.SObjectField> getObjectFieldsDescribe(string ObjectName){
        Map <String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
		Schema.SObjectType sobjType = gd.get(ObjectName);
		Schema.DescribeSObjectResult r = sobjType.getDescribe();
		Map<String, Schema.SObjectField> MapofField = r.fields.getMap();
        return MapofField;
	}
    Public static List<Object> records;
    Public static List<Object> getAllRecByTooling(string objectName,List<string> fields, List<Map<string,Object>> conditions,Integer querylimit, String orderBy){
		records = New List<Object>();
        system.debug(toolingRecords(objectName,fields,conditions,querylimit,orderBy,false,null));
        system.debug(records.size());
        for(integer i = 0; i< records.size(); i++){
            system.debug(i);
        }
        return records;
    }
    
    public static List<Object> toolingRecords(string objectName,List<string> fields, List<Map<string,Object>> conditions,Integer querylimit, String orderBy,boolean haveNext, string NextURL){
        if(haveNext && NextURL != null){
            system.debug(NextURL);
            object recordObject = DIATooling.fetchNext(nextURL.replace('/services/data/v58.0/query', ''));
            Map<String, Object> mappedResponse = (Map<String, Object>)JSON.deserializeUntyped(string.valueOf(recordObject));
            records.AddAll((List<Object>)mappedResponse.get('records'));         
            string nxtURL = string.valueOf(mappedResponse.get('nextRecordsUrl'));
            if(string.isNotBlank(NxtURL)){
                toolingRecords(objectName,fields,conditions,querylimit,orderBy,true,NxtURL);
            }
        }else{
            object recordObject = DIATooling.fetchRecords(objectName,fields,conditions,querylimit,orderBy);
            system.debug(recordObject);
            Map<String, Object> mappedResponse = (Map<String, Object>)JSON.deserializeUntyped(string.valueOf(recordObject));
            records.AddAll((List<Object>)mappedResponse.get('records'));
            string nxtURL = string.valueOf(mappedResponse.get('nextRecordsUrl'));
            system.debug(NextURL);
            if(string.isNotBlank(NxtURL)){
                toolingRecords(objectName,fields,conditions,null,null,true,NxtURL);
            }
		}
        	return records;
    }
    public static datetime dt(date dt){
        integer day;
        integer month;
        integer year;
        datetime returnVal;
        day = dt.day();
        month = dt.month();
        year = dt.year();
        returnVal = datetime.Newinstance(day,month,year);
        return returnVal;
    }
    public static datetime dt(date dt,boolean isDate){
        integer day;
        integer month;
        integer year;
        datetime returnVal;
        day = dt.day();
        month = dt.month();
        year = dt.year();
        returnVal = datetime.Newinstance(day,month,year);
        return returnVal;
    }
}