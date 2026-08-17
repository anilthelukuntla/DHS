/**
 * @description Shared helpers for schema describes, field sets, and query fragments.
 */
public with sharing class ApexUtil {
    
    //Method used to get fields from fieldsets defined in salesforce objects.
    //Sample Usage: List fieldSetMemberList =  Util.readFieldSet('FieldSetName','Work_Order__c');
    //Returns list<Schema.FieldSetMember>
    //We can access field ApIName, Label using getFieldPath(), getLabel() respectively
    /**
     * @description Returns the members of a field set on the requested object.
     * @param fieldSetName field set API name
     * @param objectName object API name
     * @return configured field set members
     */
    public static List<Schema.FieldSetMember> readFieldSet(String fieldSetName, String objectName) {
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType sObjectTypeObj = globalDescribeMap.get(objectName);
        Schema.DescribeSObjectResult describeSObjectResultObj = sObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = describeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        return fieldSetObj.getFields();
    }
    
    //creates a map of all Record Type Names to Ids based upon a passed Object
    //Sample Usage: map<String, Id> incidentRecordTypes = buildMapOfRecordTypes('Incident__c');
    /**
     * @description Returns record type IDs keyed by record type name for an sObject type.
     * @param passedSobjectType object API name
     * @return record type IDs keyed by name
     */
    public static Map<String, Id> buildMapOfRecordTypes(String passedSobjectType) {
        Map<String, Id> returnMap = new Map<String, Id>(); 
        for (RecordType rt : [SELECT Id, Name FROM RecordType WHERE SobjectType = :passedSobjectType WITH USER_MODE]) { 
            returnMap.put(rt.Name, rt.Id); 
        }
        return returnMap; 
    }
    
    //Method To Return Allfields of the object
    /**
     * @description Returns all field API names for an object.
     * @param objectName object API name
     * @return field API names
     */
    public static List<String> fetchFields(String objectName){
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType sObjectTypeObj = globalDescribeMap.get(objectName);
        Schema.DescribeSObjectResult describeSObjectResultObj = sObjectTypeObj.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = describeSObjectResultObj.fields.getMap();
        // Get all of the fields on the object
        List<String> fieldNames = new List<String>();
        fieldNames.addAll(fieldMap.keySet());
        return fieldNames;
    }
    
    //Return List of Pick list values for the given object and the picklist filed name
    /**
     * @description Returns the labels of the picklist values for the requested field.
     * @param objectName record providing the object type
     * @param fieldName field API name
     * @return picklist labels
     */
    public static List<String> getPickListValues(Sobject objectName, String fieldName){
        List<String> pList = new List<String>();
        Schema.sObjectType sObjectType = objectName.getSObjectType(); 
        Schema.DescribeSObjectResult sObjectDescribe = sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED);
        Map<String, Schema.SObjectField> fieldMap = sObjectDescribe.fields.getMap(); 
        List<Schema.PicklistEntry> pickListValues = fieldMap.get(fieldName).getDescribe().getPickListValues(); 
        for (Schema.PicklistEntry ple : pickListValues){
            pList.add(ple.getLabel());
        }  
        return pList;
    }
    
    /**
     * @description Builds a query from explicit fields and filter fragments.
     * @param objectName object API name
     * @param fields fields to select
     * @param filter filter fragments
     * @return generated SOQL
     */
    public static String queryBuilder(String objectName, List<String> fields, List<String> filter){
        String query = 'SELECT ' + String.join(fields, ',') + ' FROM ' + objectName;
        if (filter != null && !filter.isEmpty()) {
            query += ' WHERE ' + String.join(filter, ' and ');
        }
        return query;
    }
    
    /**
     * @description Builds a query using the members of a field set.
     * @param objectName object API name
     * @param fieldSetName field set API name
     * @param filter filter fragments
     * @return generated SOQL
     */
    public static String queryBuilder(String objectName, String fieldSetName, List<String> filter){
        List<String> fieldList = getFieldSetFields(objectName, fieldSetName);
        return queryBuilder(objectName,fieldList,filter);
    }
    
    /**
     * @description Returns the field paths configured in a field set.
     * @param objectName object API name
     * @param fsetName field set API name
     * @return configured field paths
     */
     public static List<String> getFieldSetFields(String objectName,String fsetName){
        List<Schema.FieldSetMember> fieldset  = getFieldSetFieldsObjs(objectName,fsetName);
        List<String> items = new List<String>();
        for(Schema.FieldSetMember f : fieldset) {
            items.add(f.getFieldPath());    
        }
        return items;
    }
    
    /**
     * @description Returns the members configured in a field set.
     * @param objectName object API name
     * @param fsetName field set API name
     * @return configured field set members
     */
    public static List<Schema.FieldSetMember> getFieldSetFieldsObjs(String objectName,String fsetName){
       return getObjectTypeDescribe(objectName).FieldSets.getMap().get(fsetName).getFields();
    }
    
    /**
     * @description Returns describe information for an object API name.
     * @param objectName object API name
     * @return object describe result
     */
    public static Schema.DescribeSObjectResult getObjectTypeDescribe(String objectName){
        Type t = Type.forName(objectName);
        return ((Sobject)t.newInstance()).getSObjectType().getDescribe();
    }
    
    /**
     * @description Returns field data types keyed by field API name.
     * @param objType object API name
     * @return field types keyed by field API name
     */
    public static Map<object,object> getSObjectFieldTypes(String objType) {
        map<object,object> fieldDataTypesMap = new map<object,object>();
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType objectSchema = schemaMap.get(objType);
        Map<String, Schema.SObjectField> fields = objectSchema.getDescribe().fields.getMap();
        new Map<String, Object>();
    
        for(String fieldName : fields.keySet()) {
            Schema.SObjectField field = fields.get(fieldName);
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            fieldDataTypesMap.put(fieldName, String.valueof(fieldDescribe.getType()));
        }
        
        return fieldDataTypesMap;
    } 
    
    /** @description Represents a single SOQL filter criterion. */
    public class Criteria {
       public String fieldName;
       public String operator;
       public String fieldValue;
       public String fieldType;
       /**
        * @description Creates an untyped filter criterion.
        * @param fieldNameValue field API name
        * @param fieldValueValue comparison value
        * @param fieldOperator comparison operator
        */
       public Criteria(String fieldNameValue, string fieldValueValue,string fieldOperator) {
           fieldName = fieldNameValue;
           fieldValue = fieldValueValue;
           operator = fieldOperator;
       }
       /**
        * @description Sets the field data type used when rendering the criterion.
        * @param fieldTypeValue field data type
        * @return this criterion
        */
       public Criteria withFieldType(String fieldTypeValue) {
           fieldType = fieldTypeValue;
           return this;
       }
       /**
        * @description Returns the SOQL representation of this criterion.
        * @return SOQL criterion fragment
        */
       public String getSOQLCriteria() {
           //Latest Change
           // Handle NULL separately
            if(fieldValue == null){
                return fieldName + ' ' + operator + ' null';
            }
           if(fieldType != 'Date' && fieldType != 'Double' && fieldType != 'Integer'){
               return fieldName + ' '  + operator + ' \'' + String.escapeSingleQuotes(fieldValue) + '\'';
           }else{
               return fieldName + ' '  + operator  + fieldValue ;
           }
           
       }
    
       /**
        * @description Indicates whether this criterion has a nonblank value.
        * @return true when a value is present
        */
       public boolean isFieldValueGiven() {
           return fieldValue != null && fieldValue != '';
       }
    }
    
    /**
     * @description Joins criteria into an AND-delimited WHERE fragment.
     * @param criterias criteria to join
     * @return generated WHERE fragment
     */
    public static String generateWhereQuery(List<Criteria> criterias) {
        List<String> andConditions = new List<String>();
        for(Criteria singleCriteria : criterias) {
            //if (single_criteria.IsFieldValueGiven()) {
                andConditions.add(singleCriteria.getSOQLCriteria());
            //}
        }
        return String.join(andConditions, ' AND ');
    }
    
    /**
     * @description Returns picklist labels for a field identified by object and field API names.
     * @param objectType object API name
     * @param selectedField field API name
     * @return picklist labels
     */
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
    
    /**
     * @description Indicates whether the current organization is a sandbox.
     * @return true in a sandbox organization
     */
    public static Boolean runningInASandbox() {
        return [SELECT Id, IsSandbox FROM Organization WITH USER_MODE LIMIT 1].IsSandbox;
    }
    /**
     * @description Returns describe fields keyed by field API name.
     * @param objectName object API name
     * @return fields keyed by field API name
     */
	public static Map<String, Schema.SObjectField> getObjectFieldsDescribe(string objectName){
        Map <String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
		Schema.SObjectType sobjType = gd.get(objectName);
		Schema.DescribeSObjectResult r = sobjType.getDescribe();
		Map<String, Schema.SObjectField> mapOfField = r.fields.getMap();
        return mapOfField;
	}
    /**
     * @description Converts a date into a datetime using the legacy conversion behavior.
     * @param dt date to convert
     * @return converted datetime
     */
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
}
