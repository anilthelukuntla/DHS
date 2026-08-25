public class DIATooling {
	public static String restGet(String endPoint, String method, String sid) {
            try
            {
                Http h = new Http();
                HttpRequest hr = new HttpRequest();
                hr.setHeader('Authorization', 'Bearer ' + sid);
                hr.setTimeout(60000);
                hr.setEndpoint(endPoint);
                hr.setMethod(method);
                HttpResponse r = h.send(hr);
                return r.getBody();
            }
            catch(Exception ex)
            {
                system.debug('Exception in tooling API Call:'+ ex.getMessage());
                return ex.getMessage();
            }
    }
    
    public static String toolingAPISOQL(string query) {
        String baseURL='callout:ToolingRest';  //Named Credential
        System.debug('full query' + baseURL +query);
         return restGet(baseURL +query,'GET', UserInfo.getSessionId());
    } 


    @AuraEnabled
    public static Object fetchRecords(String sObjectName, List<String> fieldNames, List<Map<String, Object>> conditions, Integer querylimit, String orderBy) { 
        String query = generateQuery(sObjectName,fieldNames,  conditions, querylimit,orderBy);
        System.debug(query);
        return toolingAPISOQL('?q='+ EncodingUtil.urlEncode(query, 'UTF-8'));
    }

    @AuraEnabled
    public static Object fetchNext(String url) {
        return toolingAPISOQL(url);
    }

    @AuraEnabled
    public static string generateQuery(String sObjectName, List<String> fieldSetNames, List<Map<String, Object>> conditions, Integer querylimit, String orderBy) {
        String queryString = 'SELECT ';
        
        Set<String> fieldSet = new Set<String>();
        for (String fieldName : fieldSetNames)
        {
            fieldSet.add(fieldName);
        }
        queryString += String.join(new List<String>(fieldSet), ', ');  // Remove the extra comma and space at the end

        
        queryString += ' FROM ' + sObjectName;

        if (conditions != null && !conditions.isEmpty()) {
            List<String> conditionList = new List<String>();
            for (Map<String,Object> condMap : conditions) {
                String dataType = condMap.containsKey('type') ? (String)condMap.get('type') : null;
                String operator = condMap.containsKey('operator') ? (String)condMap.get('operator') : '=';
                if(operator.toLowerCase() == 'not like') { 
                    conditionList.add( '(NOT ' + (String)condMap.get('key') +' like ' + getValueByDataType(condMap.get('value'),dataType) + ')');
                }else if(operator.toLowerCase() == 'not in'){
                    conditionList.add((String)condMap.get('key')+' NOT IN ('+condMap.get('value')+')');
                } else {
                    conditionList.add((String)condMap.get('key') + ' ' + operator + ' '  + getValueByDataType(condMap.get('value'),dataType));
                }
            }
            system.debug(conditionList);
            queryString += ' where ' + String.join(conditionList, ' AND ');
        }
         //Add limit if its set
        if(orderBy != null) {
            queryString += ' ORDER BY ' +  orderBy;
        }
        
        //Add limit if its set
        if(querylimit != null && querylimit > 0) {
            queryString += ' limit ' +  String.valueOf(querylimit);
        }

        return queryString;
    }

    private static Object getValueByDataType(Object value, String datatype) {
        switch on datatype {
            when 'object' {
               return value;
            } when else {
               return '\'' + value + '\'';
            }
        }
    }
}