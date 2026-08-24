/** Retains the existing DHSApexUtil integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc,PMD.ApexSharingViolations,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.EagerlyLoadedDescribeSObjectResult,PMD.EmptyStatementBlock,PMD.ExcessiveParameterList,PMD.FieldDeclarationsShouldBeAtStart')
public class DHSApexUtil {
    
    //Method used to get fields from fieldsets defined in salesforce objects.
    //Sample Usage: List fieldSetMemberList =  Util.readFieldSet('FieldSetName','Work_Order__c');
    //Returns list<Schema.FieldSetMember>
    //We can access field ApIName, Label using getFieldPath(), getLabel() respectively
    public static List<Schema.FieldSetMember> readFieldSet(String fieldSetName, String objectName) {
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType sObjectTypeObj = globalDescribeMap.get(objectName);
        Schema.DescribeSObjectResult describeSObjectResultObj = sObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = describeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        return fieldSetObj.getFields();
    }
    
    //creates a map of all Record Type Names to Ids based upon a passed Object
    //Sample Usage: map<String, Id> incidentRecordTypes = buildMapOfRecordTypes('Incident__c');
    public static Map<String, Id> buildMapOfRecordTypes(String passedSobjectType) {
        Map<String, Id> returnMap = new Map<String, Id>(); 
        for (RecordType rt : [SELECT Id, Name FROM RecordType WHERE SobjectType = :passedSobjectType WITH USER_MODE ]) { 
            returnMap.put(rt.Name, rt.Id); 
        }
        return returnMap; 
    }
    
    //Method To Return Allfields of the object
    public static List<String> fetchFields(String objectName){
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType sObjectTypeObj = globalDescribeMap.get(objectName);
        Schema.DescribeSObjectResult describeSObjectResultObj = sObjectTypeObj.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = describeSObjectResultObj.fields.getMap();
        // Get all of the fields on the object
        List<String> fieldNames = new List<String>();
        for (String fieldName : fieldMap.keySet()) {
            if (fieldMap.get(fieldName).getDescribe().isAccessible()) {
                fieldNames.add(fieldName);
            }
        }
        return fieldNames;
    }
    
    //Return List of Pick list values for the given object and the picklist filed name
    public static List<String> getPickListValues(Sobject objectName, String fieldName){
        List<String> pList = new List<String>();
        Schema.sObjectType sobjectType = objectName.getSObjectType(); 
        Schema.DescribeSObjectResult sobjectDescribe = sobjectType.getDescribe(); 
        Map<String, Schema.SObjectField> fieldMap = sobjectDescribe.fields.getMap(); 
        List<Schema.PicklistEntry> pickListValues = fieldMap.get(fieldName).getDescribe().getPickListValues(); 
        for (Schema.PicklistEntry ple : pickListValues){
            pList.add(ple.getLabel());
        }  
        return pList;
    }
    
    public static String queryBuilder(String objectName, List<String> fields, List<String> filter){
        return queryBuilder(objectName,fields,filter,null);
    }
    
    public static String queryBuilder(String objectName, String fieldSetName, List<String> filter){
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
    
     public static List<String> getFieldSetFields(String objectName,String fsetName){
        List<Schema.FieldSetMember> fieldset  = getFieldSetFieldsObjs(objectName,fsetName);
        List<String> items = new List<String>();
        for(Schema.FieldSetMember f : fieldset) {
            items.add(f.getFieldPath());    
        }
        return items;
    }
    
    public static List<Schema.FieldSetMember> getFieldSetFieldsObjs(String objectName,String fsetName){
       return getObjectTypeDescribe(objectName).FieldSets.getMap().get(fsetName).getFields();
    }
    
    public static Schema.DescribeSObjectResult getObjectTypeDescribe(String objectName){
        Type t = Type.forName(objectName);
        return ((Sobject)t.newInstance()).getSObjectType().getDescribe();
    }
    
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
    
    public class Criteria {
       public String fieldName;
       public String operator;
       public String fieldValue;
       public String fieldType;
       public Criteria(String fName, string fValue,string fOperator) {
           fieldName = fName;
           fieldValue = fValue;
           operator = fOperator;
       }
       public Criteria(String fName, string fValue,string fOperator,string fType) {
           fieldName = fName;
           fieldValue = fValue;
           operator = fOperator;
           fieldType =  fType;
       }
       public String getSOQLCriteria() {
           if (String.isBlank(fieldName) || !Pattern.matches('^[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z][A-Za-z0-9_]*)*$', fieldName)) {
               throw new IllegalArgumentException('Invalid SOQL field path');
           }
           Set<String> allowedOperators = new Set<String>{ '=', '!=', '<', '<=', '>', '>=', 'LIKE' };
           String normalizedOperator = operator == null ? null : operator.trim().toUpperCase();
           if (!allowedOperators.contains(normalizedOperator)) {
               throw new IllegalArgumentException('Invalid SOQL operator');
           }
           if(fieldValue == null){
                return fieldName + ' ' + normalizedOperator + ' null';
            }
           if(fieldType != 'Date' && fieldType != 'Double' && fieldType != 'Integer'){
               return fieldName + ' ' + normalizedOperator + ' \'' + String.escapeSingleQuotes(fieldValue) + '\'';
           }else{
               return fieldName + ' ' + normalizedOperator + ' ' + fieldValue;
           }
           
       }
    
       public boolean isFieldValueGiven() {
           return fieldValue != null && fieldValue != '';
       }
    }
    
    public static String generateWhereQuery(List<Criteria> criterias) {
        List<String> andConditions = new List<String>();
        for(Criteria singleCriteria : criterias) {
            //if (single_criteria.IsFieldValueGiven()) {
                andConditions.add(singleCriteria.getSOQLCriteria());
            //}
        }
        return String.join(andConditions, ' AND ');
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
        return [SELECT Id, IsSandbox FROM Organization  WITH USER_MODE LIMIT 1].IsSandbox;
    }
	public static Map<String, Schema.SObjectField> getObjectFieldsDescribe(string objectName){
        Map <String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
		Schema.SObjectType sobjType = gd.get(objectName);
		Schema.DescribeSObjectResult r = sobjType.getDescribe();
		Map<String, Schema.SObjectField> mapofField = r.fields.getMap();
        return mapofField;
	}
    Public static List<Object> records;
    Public static List<Object> getAllRecByTooling(string objectName,List<string> fields, List<Map<string,Object>> conditions,Integer querylimit, String orderBy){
		records = New List<Object>();
        for(integer i = 0; i< records.size(); i++){
        }
        return records;
    }
    
    public static List<Object> toolingRecords(string objectName,List<string> fields, List<Map<string,Object>> conditions,Integer querylimit, String orderBy,boolean haveNext, string nextURL){ // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
        if(haveNext && nextURL != null){
            object recordObject = DIATooling.fetchNext(nextURL.replace('/services/data/v58.0/query', ''));
            Map<String, Object> mappedResponse = (Map<String, Object>)JSON.deserializeUntyped(string.valueOf(recordObject));
            records.AddAll((List<Object>)mappedResponse.get('records'));         
            string nxtURL = string.valueOf(mappedResponse.get('nextRecordsUrl'));
            if(string.isNotBlank(NxtURL)){
                toolingRecords(objectName,fields,conditions,querylimit,orderBy,true,NxtURL);
            }
        }else{
            object recordObject = DIATooling.fetchRecords(objectName,fields,conditions,querylimit,orderBy);
            Map<String, Object> mappedResponse = (Map<String, Object>)JSON.deserializeUntyped(string.valueOf(recordObject));
            records.AddAll((List<Object>)mappedResponse.get('records'));
            string nxtURL = string.valueOf(mappedResponse.get('nextRecordsUrl'));
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
}
