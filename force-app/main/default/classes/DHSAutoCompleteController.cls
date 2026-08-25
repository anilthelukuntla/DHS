/**
 * @description Supplies schema-validated autocomplete results as JSON.
 */
@SuppressWarnings('PMD.ApexSOQLInjection,PMD.ExcessiveParameterList,PMD.UnusedMethod')
public with sharing class DHSAutoCompleteController {

   /**
    * @description Provides this DHS API member.
    * @return The requested result.
    */
   public String getJSON(){
     return JSON.serialize(fetchSuggestions());
   }

   private List<DataWrapper> fetchSuggestions(){
     List<DataWrapper> wrappers = new List<DataWrapper>();

     //get params from url
     Map<String, String> parameters = ApexPages.currentPage().getParameters();
     String searchTerm = parameters.get('q');
     searchTerm = searchTerm == null ? '' : searchTerm;
     String objName = parameters.get('obj');
     Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
     if (String.isBlank(objName) || !globalDescribe.containsKey(objName)) {
       return wrappers;
     }
     Map<String, Schema.SObjectField> availableFields = globalDescribe.get(objName).getDescribe().fields.getMap();
     List<String> lstFields = new List<String>();
     String label = parameters.get('label');
     if (String.isBlank(label) || !availableFields.containsKey(label)) {
       return wrappers;
     }
     lstFields.add(label);
     String urlDetail = parameters.get('detail');
     // Arbitrary WHERE fragments from URL parameters cannot be safely bound or allowlisted.
     String urlWhere = null;
     Integer queryLimit = parseLimit(parameters.get('lm'));

     //add comma-separated detail fieds to query and store in separate list for retrieve
     List<String> lstDetail = collectDetailFields(urlDetail, availableFields);
     lstFields.addAll(lstDetail);
     String value = parameters.get('value');
     if (String.isBlank(value) || !availableFields.containsKey(value)) {
       return wrappers;
     }
     lstFields.add(value);

     String qry = buildQuery(lstFields, objName, label, searchTerm, urlWhere, queryLimit);

     //loop through records to get data
     // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
     for(SObject o :database.query(qry, AccessLevel.USER_MODE)){
       wrappers.add(new DataWrapper(((String)o.get(label)), detailValue(o, lstDetail), ((String)o.get(value))));
     }

     return wrappers;
   }

   private String normalizeWhereClause(String urlWhere){
     if(String.isBlank(urlWhere)){
       return urlWhere;
     }
     String normalizedWhere = EncodingUtil.urlDecode(urlWhere,'utf-8').trim();
     return normalizedWhere.startsWith('and') ? normalizedWhere.substring(3) : normalizedWhere;
   }

   private Integer parseLimit(String urlLimit){
     if (String.isNotBlank(urlLimit) && urlLimit.isNumeric()) {
       return Math.max(1, Math.min(200, Integer.valueOf(urlLimit)));
     }
     return 50;
   }

   private List<String> collectDetailFields(String urlDetail, Map<String, Schema.SObjectField> availableFields){
     List<String> detailFields = new List<String>();
     if(String.isBlank(urlDetail)){
       return detailFields;
     }
     for (String detailField : urlDetail.split(',')) {
       if (availableFields.containsKey(detailField)) {
         detailFields.add(detailField);
       }
     }
     return detailFields;
   }

   private String buildQuery(List<String> fields, String objName, String label, String searchTerm, String urlWhere, Integer queryLimit){
     String qry = 'Select ' + String.join(fields,',');
     qry += ' from ' + objName + ' where ' + label + ' like \'%' + String.escapeSingleQuotes(searchTerm) + '%\'';
     if(String.isNotBlank(urlWhere)){
       qry += ' and ' + urlWhere;
     }
     return qry + ' Limit ' + queryLimit;
   }

   private String detailValue(SObject record, List<String> detailFields){
     if(detailFields.isEmpty()){
       return '';
     }
     if(detailFields.size() == 1){
       return (String) record.get(detailFields[0]);
     }
     List<String> detailValues = new List<String>();
     for(String detailField :detailFields){
       detailValues.add((String)record.get(detailField));
     }
     return String.join(detailValues,', ');
   }

   /** @description Provides this DHS API member. */
   public class DataWrapper{
     String label;
     String detail;
     String value;

     /**
      * @description Provides this DHS API member.
      * @param l Method parameter.
      * @param d Method parameter.
      * @param v Method parameter.
      */
     public DataWrapper(String l, String d, String v){
       label = l; //label of suggestion
       detail = d; //detail of suggestion
       value = v; //the value of what is stored in the input tag. Commonly the Id of the record
     }
   }

}