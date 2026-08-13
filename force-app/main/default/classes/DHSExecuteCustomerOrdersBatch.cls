/** Retains the existing DHSExecuteCustomerOrdersBatch integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc, PMD.AvoidDeeplyNestedIfStmts, PMD.AvoidGlobalModifier, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.DebugsShouldUseLoggingLevel, PMD.EmptyCatchBlock, PMD.EmptyStatementBlock, PMD.FormalParameterNamingConventions, PMD.IfElseStmtsMustUseBraces, PMD.IfStmtsMustUseBraces, PMD.LocalVariableNamingConventions, PMD.MethodNamingConventions, PMD.NcssCount, PMD.NcssMethodCount, PMD.NcssTypeCount, PMD.OperationWithHighCostInLoop, PMD.OperationWithLimitsInLoop, PMD.StdCyclomaticComplexity')
global class DHSExecuteCustomerOrdersBatch implements Database.Stateful,Database.Batchable<sObject> {
    global string customerOrderId;
    global string generatedCSVFile;
    global string formattedgeneratedCSVFile;
    global string customerOrderUploadlogId;
    global integer successCasesCount;
    global integer failureCasesCount;
    global string successMessage;
    global string failureMessage;
    global DHSExecuteCustomerOrdersBatch(string coId,string logId){
        customerOrderId = coId;   
        customerOrderUploadlogId = logId;
        successCasesCount = 0;
        failureCasesCount = 0;
        successMessage = '';
        failureMessage = '';
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'Select id,Status__c from DHS_Customer_Order__c where id=:customerOrderId';
        return Database.getQueryLocator(query);       
    }
    global string getFieldDataType(String objectName, String fieldName){
            return [SELECT DataType FROM FieldDefinition WHERE EntityDefinitionId=:objectName AND QualifiedApiName=:fieldName LIMIT 1].DataType;
    }
    global boolean isValidEmailAddress (string emailAddress){
        if(string.isBlank(emailAddress)) return false;
    	Pattern emailPattern = Pattern.compile('[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+');
        Matcher emailMatcher = emailPattern.matcher(emailAddress.removeEnd('.'));
        Boolean isValidEmail = emailMatcher.matches();  
        return isValidEmail;
    }
    global boolean isValidSSN (string ssnString){
        if(string.isBlank(ssnString)) return false;
    	Pattern ssnPattern = Pattern.compile('\\d{3}-\\d{2}-\\d{4}');
        Matcher ssnMatcher = ssnPattern.matcher(ssnString);
        Boolean isValidSSN = ssnMatcher.matches();  
        return isValidSSN;
    }
    global boolean isValidZip (string zipString){
    	Pattern zipPattern = Pattern.compile('[0-9]{5}(?:-[0-9]{4})?');
        Matcher zipMatcher = zipPattern.matcher(zipString);
        Boolean isValidZIP = zipMatcher.matches();  
        return isValidZIP;
    }
     global boolean isValidState(string stateString){
    	Pattern statePattern = Pattern.compile('^[a-zA-Z]{2}$');
        Matcher stateMatcher = statePattern.matcher(stateString);
        Boolean isValidState = stateMatcher.matches();  
        return isValidState;
    }
    
    global string ValidateRow(string fileHeaderRow,List<string> csvRecordData){
        boolean isValid = true;
        string message;
        integer dataColumnIndex = 0;
        for(string column: fileHeaderRow.split(',')){
            string fieldName = column.tolowercase().trim().replaceAll('\r','').replaceAll('\n','');
            
            if(csvRecordData.size() > dataColumnIndex ){
                string fieldData = csvRecordData[dataColumnIndex];
                
                fieldData = fieldData.trim();
                If(fieldName == 'SSN__c'){
                    isValid = isValidSSN(fieldData);
                    if(!isValid){
                        if(String.isBlank(message)){
                        	message = 'Invalid SSN';       
                        }else{
                        	message = message +' and ' +'Invalid SSN';    
                        }
                    	
                    }
                    
                }
                If(fieldName == 'Email__c'){
                	isValid = isValidEmailAddress(fieldData);
                    if(!isValid){
                        if(String.isBlank(message)){
                        	message = 'Invalid Email';       
                        }else{
                        	message = message +' and ' +'Invalid Email';    
                        }
                    	
                    }
                }
                If(fieldName == 'State__c'){
                	isValid = isValidState(fieldData);
                    if(!isValid){
                        if(String.isBlank(message)){
                        	message = 'Invalid State';       
                        }else{
                        	message = message +' and ' +'Invalid State';    
                        }
                    	
                    }
                }
                If(fieldName == 'Zip__c'){
                    if(fieldData.length() == 4){
                    	fieldData = '0'+fieldData;   
                    }
                	isValid = isValidZip(fieldData);
                    if(!isValid){
                        if(String.isBlank(message)){
                        	message = 'Invalid Zip';       
                        }else{
                        	message = message +' and ' +'Invalid Zip';    
                        }
                    	
                    }
                }
            }
            dataColumnIndex++;
        }   
        return message;
    }
    
    
    global void execute(Database.BatchableContext BC, List<DHS_Customer_Order__c> orders) {
        DHS_Customer_Order__c order = orders[0];
        list<string> documentNamesAttached= new list<string>();
        List<ContentDocumentLink> documentsAttached = [Select id, ContentDocumentId, ContentDocument.title, LinkedEntityId from ContentDocumentLink WHERE LinkedEntityId=:order.id and ContentDocument.title='OrderData.csv'];
        List<ContentDocumentLink> otherDocumentsAttached = [Select id, ContentDocumentId, ContentDocument.title, LinkedEntityId from ContentDocumentLink WHERE LinkedEntityId=:order.id and ContentDocument.title !='OrderData.csv'];
        map<string,ContentDocumentLink> documentNameNCDLMap = new map<string,ContentDocumentLink>();
        for(ContentDocumentLink cdl: otherDocumentsAttached){
            documentNameNCDLMap.put(cdl.ContentDocument.title,cdl); 
            documentNamesAttached.add(cdl.ContentDocument.title);
        }
        list<ContentDocumentLink> cdlsToInsert = new list<ContentDocumentLink>();
        boolean isPartialSuccess =false;
        if(!documentsAttached.isEmpty()){
            contentversion csvData = [select id, versiondata, ContentDocumentId from contentversion where ContentDocumentId=:documentsAttached[0].ContentDocumentId];
            string blobData = csvData.versiondata.tostring();
            list<String> csvFileLines = blobData.split('\n');
            string fileHeaderRow = csvFileLines[0].replaceAll('\n','').replaceAll('\r','');
            generatedCSVFile = fileHeaderRow.replaceAll('\n','').replaceAll('\r','') + ','+'Validation Errors'+','+'Document Status'+'\n';
            formattedgeneratedCSVFile = fileHeaderRow.replaceAll('\n','').replaceAll('\r','') + ','+'Validation Errors'+','+'Document Status'+ ','+'Contact Created/Updated'+','+'Contact ID'+','+'Case ID'+','+'Dev Remarks'+'\n';
            list<sObject> sObjectsToUpsert = new list<sObject>();
            map<string,list<string>> ssnNdocumentsMap = new map<string,list<string>> ();
            map<string,string> contactCreatedOrUpdatedMap = new map<String,string>();
            map<string,string> SSNnContactIdMap = new map<String,string>();
            map<string,string> SSNnErrorMessageMap = new map<String,string>();
            map<string,string> SSNnCaseIdMap = new map<String,string>();
            map<object,object> fieldDataTypesMap = apexutil.getSObjectFieldTypes('DHS_Contact__c');
             
            for(Integer i=1;i<csvFileLines.size();i++){
                boolean isValidForUpsert = true;
                generatedCSVFile = generatedCSVFile + csvFileLines[i].replaceAll('\n','').replaceAll('\r','') ;
                try{
                   
                    List<string> csvRecordData = splitString(csvFileLines[i]);
                    sObject sObj = Schema.getGlobalDescribe().get('DHS_Contact__c').newSObject();
                    integer documentNameIndex = GetColumnIndex(fileHeaderRow,'Document Name');
                 
                    string documentName;
                    if(csvRecordData.size()<=documentNameIndex){
                        documentName = null;   
                    }else{
                        documentName = csvRecordData[documentNameIndex];    
                    }
                    if(string.isblank(documentName)){
                        generatedCSVFile = generatedCSVFile+','+''+','+'Document did not upload. Please ensure the PDF file exists its name match to column# J and is not a broken file.'+'\n';
                        isPartialSuccess = true;
                        isValidForUpsert = false;
                        
                     }else{
                        if(!documentNamesAttached.contains(documentName)){
                             generatedCSVFile = generatedCSVFile+','+''+','+'Document did not upload. Please ensure the PDF file exists its name match to column# J and is not a broken file.'+'\n';
                             isPartialSuccess = true;
                             isValidForUpsert = false;
                             failureCasesCount = failureCasesCount+1;
                             failureMessage = failureMessage + documentName + ' - Document did not upload. Please ensure the PDF file exists its name match to column# J and is not a broken file.<br/>';
                        } else{
                        	//generatedCSVFile = generatedCSVFile+','+''+','+''+'\n';    
                        }   
                    }
                    
                    if(!isValidForUpsert) continue;
                    
                    String validationMessage = ValidateRow(fileHeaderRow,csvRecordData);
                    if(string.isNotBlank(validationMessage)){
                    	isValidForUpsert = false;
                        isPartialSuccess = true;
                        generatedCSVFile = generatedCSVFile+','+validationMessage+','+''+'\n';
                        failureMessage = failureMessage + documentName + ' - '+validationMessage+'<br/>';
                        failureCasesCount = failureCasesCount+1;
                    }else{
                        isValidForUpsert = true;
                    	generatedCSVFile = generatedCSVFile+','+''+','+''+'\n'; 
                    }
                    if(!isValidForUpsert) continue;
                    
                    integer dataColumnIndex = 0;
                    for(string column: fileHeaderRow.split(',')){
                        string fieldName = column.tolowercase().trim().replaceAll('\r','').replaceAll('\n','');
                        string fieldType;
                        for(object obj: fieldDataTypesMap.keyset()){
                            if(string.valueof(obj) == fieldName){
                            	fieldType = (string)fieldDataTypesMap.get(obj);    
                            }
                        }
                        if(csvRecordData.size() > dataColumnIndex ){
                        	string fieldData = csvRecordData[dataColumnIndex];
                            
                        	fieldData = fieldData.trim();
                        	fieldData = fieldData.removeEnd('.');
                            //if(fieldName == 'SSN__c' && fieldName == 'Address__c' && fieldName == 'Zip__c' && fieldName != 'document name' && dataColumnIndex != 0){
                            if( fieldName != 'document name' && dataColumnIndex != 0){
                                if(fieldType == 'DOUBLE' || fieldType == 'CURRENCY') {
                                    if(String.isNotblank(fieldData.trim())){
                                        fieldData = fieldData.replaceAll(',', '');
                                        fieldData = fieldData.replaceAll('$', '');
                                        fieldData = fieldData.replaceAll('$ ', '');
                                        fieldData = fieldData.replaceAll(' ', '');
                                        sObj.put(fieldname,Double.valueOf(fieldData.replaceAll(',', ''))); 
                                    } 
                                }else if(fieldType == 'DATE'){
                                    if(String.isNotblank(fieldData.trim())){
                                        sObj.put(fieldname,Date.valueof(fieldData)); 
                                    }
                                }else if(fieldType == 'STRING' || fieldType == 'PICKLIST' ) {
                                    sObj.put(fieldname,fieldData);  
                                }else if(fieldType == 'BOOLEAN' ) {
                                    sObj.put(fieldname,boolean.valueof(fieldData));  
                                }else{
                                    sObj.put(fieldname,fieldData);  
                                }
                            } else if(dataColumnIndex == 0){
                                sobj.put('First_Name__c',fielddata);
                            } else if(fieldName == 'Address__c'){
                               sobj.put('Address__c',fielddata.replaceAll(',',' ')); 
                            }else if(fieldName == 'SSN__c'){
                               sobj.put('SSN__c',fielddata); 
                            } else if(fieldName == 'Zip__c'){
                               if(fieldData.length() == 4){
                                    fieldData = '0'+fieldData;   
                                } 
                               sobj.put('Zip__c',fielddata); 
                            } else if(fieldName == 'document name'){
    
                                fielddata = fielddata.trim().replaceAll(' ','');
                                
                                
                                if(!ssnNdocumentsMap.containsKey((string)sObj.get('SSN__c'))){
                                    list<string> temp = new list<String>();
                                    if(string.isnotblank(fielddata)){
                                        temp.add(fielddata);
                                        ssnNdocumentsMap.put((string)sObj.get('SSN__c'),temp);    
                                    }
                                }else{
                                    list<string> temp = ssnNdocumentsMap.get((string)sObj.get('SSN__c'));    
                                    if(string.isnotblank(fielddata)){
                                        temp.add(fielddata);
                                        ssnNdocumentsMap.put((string)sObj.get('SSN__c'),temp);    
                                    }
                                }
                            }
                            if(fieldName == 'Zip__c'){
                               if(fieldData.length() == 4){
                                    fieldData = '0'+fieldData;   
                                } 
                               sobj.put('Zip__c',fielddata); 
                            }
                            if(fieldName == 'Address__c'){
                               sobj.put('Address__c',fielddata.replaceAll(',',' ')); 
                            }
                       
                        }
                        dataColumnIndex++;
                    }
                   
                    if (DHS_Contact__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap()
                        .containsKey('Customer_Order_Number__c')) {
                        sObj.put('Customer_Order_Number__c',customerOrderId);
                    }
                   
                    boolean duplicateFound = false;
                    for(sobject sobj1:sObjectsToUpsert ){
                        if((string)sObj.get('SSN__c') == (string)sObj1.get('SSN__c')){
                            duplicateFound = true;  
                        }     
                    }
                    
                    if(!duplicateFound && isValidForUpsert){
                         sObjectsToUpsert.add(sObj);
                    }
                       
                }catch(Exception ex){
                    
                }
            }
            if(!sObjectsToUpsert.isEmpty()){
                List<Schema.SObjectType> gd = Schema.getGlobalDescribe().Values();
                Schema.SObjectType sObjectType;
                for(Schema.SObjectType f : gd){
                    if(f.getDescribe().getName() == 'DHS_Contact__c'){
                        sObjectType = f;
                    }
                }
                map<string,list<contentdocumentlink>> mapOfContactNDocumentsTobeCreated = new map<string,list<contentdocumentlink>>();
                Set<String> contactSsns = new Set<String>();
                for (SObject contactRecord : sObjectsToUpsert) {
                    contactSsns.add((String) contactRecord.get('SSN__c'));
                }
                Map<String, Id> contactIdBySsn = new Map<String, Id>();
                for (DHS_Contact__c existingContact : [
                    SELECT Id, SSN__c FROM DHS_Contact__c WHERE SSN__c IN :contactSsns
                ]) {
                    contactIdBySsn.put(existingContact.SSN__c, existingContact.Id);
                }
                for (SObject contactRecord : sObjectsToUpsert) {
                    Id existingContactId = contactIdBySsn.get(
                        (String) contactRecord.get('SSN__c')
                    );
                    if (existingContactId != null) {
                        contactRecord.put('Id', existingContactId);
                    }
                }
                List<Database.UpsertResult> dsrs = Database.upsert(sObjectsToUpsert, false); 
                list<string> contactIds = new list<string>();
                for(Integer i = 0; i < dsrs.size(); i++){
                  if(dsrs[i].isSuccess()){
                    if(dsrs[i].isCreated()){
                      contactIds.add(dsrs[i].getId());
                      list<string> documentsToBeCreated = new list<string>();
                      documentsToBeCreated = ssnNdocumentsMap.get((string)sObjectsToUpsert[i].get('SSN__c')); 
                      if(documentsToBeCreated != Null){  
                        for(string str: documentsToBeCreated){
                            ContentDocumentLink originalDocLink = documentNameNCDLMap.get(str);
                            if(originalDocLink != Null){
                                ContentDocumentLink cdl = new ContentDocumentLink();
                                cdl.ContentDocumentId = originalDocLink.contentDocumentId;
                                cdl.LinkedEntityId = dsrs[i].getId();
                                cdl.ShareType = 'V';  
                                cdl.Visibility  = 'AllUsers';
                                cdlsToInsert.add(cdl); 
                            }
                        }  
                       }
                       contactCreatedOrUpdatedMap.put((string)sObjectsToUpsert[i].get('SSN__c'),'Created'); 
                       SSNnContactIdMap.put((string)sObjectsToUpsert[i].get('SSN__c'),dsrs[i].getId());                     
                    } else {
                      contactIds.add(dsrs[i].getId());
                      list<string> documentsToBeCreated = new list<string>();
                      documentsToBeCreated = ssnNdocumentsMap.get((string)sObjectsToUpsert[i].get('SSN__c')); 
                      if(documentsToBeCreated != Null){ 
                        for(string str: documentsToBeCreated){
                            ContentDocumentLink originalDocLink = documentNameNCDLMap.get(str);
                            if(originalDocLink != Null){
                                ContentDocumentLink cdl = new ContentDocumentLink();
                                cdl.ContentDocumentId = originalDocLink.contentDocumentId;
                                cdl.LinkedEntityId = dsrs[i].getId();
                                cdl.ShareType = 'V';  
                                cdl.Visibility = 'AllUsers';
                                cdlsToInsert.add(cdl);  
                            }
                        }
                      }
                      contactCreatedOrUpdatedMap.put((string)sObjectsToUpsert[i].get('SSN__c'),'Updated');  
                      SSNnContactIdMap.put((string)sObjectsToUpsert[i].get('SSN__c'),dsrs[i].getId());                                         
                    }
                  }else{
                      Database.Error dbError = dsrs[i].getErrors().get(0);
                      string errorMessage = dbError.getMessage();
                      SSNnErrorMessageMap.put((string)sObjectsToUpsert[i].get('SSN__c'),errorMessage);                                        
                  }
                }
                if(!cdlsToInsert.isEmpty()){
                    insert cdlsToInsert;
                    for(contentdocumentlink cdl: cdlsToInsert){
                        if(!mapOfContactNDocumentsTobeCreated.containsKey(cdl.LinkedEntityId)){
                            mapOfContactNDocumentsTobeCreated.put(cdl.LinkedEntityId, new list<contentdocumentlink>{cdl});      
                        } else{
                            list<contentdocumentlink> cdls = mapOfContactNDocumentsTobeCreated.get(cdl.LinkedEntityId);
                            cdls.add(cdl);
                            mapOfContactNDocumentsTobeCreated.put(cdl.LinkedEntityId,cdls);
                        }  
                    }
                    
                }
                if(!contactids.isEmpty()){
                     SSNnCaseIdMap = CreateCaseAction(contactids,order.id,mapOfContactNDocumentsTobeCreated);    
                }
            }
            list<String> formattedCSVFileLines = generatedCSVFile.split('\n');
            Integer totalRows = formattedCSVFileLines.size()-1;
            for(Integer i=1;i<formattedCSVFileLines.size();i++){
                List<string> formattedCSVRecordData = splitString(formattedCSVFileLines[i]);
                integer ssnIndex = GetColumnIndex(fileHeaderRow,'SSN__c');
                string ssnValue = formattedCSVRecordData[ssnIndex];
                ssnValue = ssnValue.replaceAll(' ','').replaceAll('\n','').replaceAll('\r','').trim();
                
                integer docuemntNameIndex = GetColumnIndex(fileHeaderRow,'Document Name');
                string docuemntNameValue = formattedCSVRecordData[docuemntNameIndex];
                
                if(contactCreatedOrUpdatedMap.get(ssnValue) == Null){
                    string temp;
                    if(SSNnErrorMessageMap.get(ssnValue) == Null){
                    	temp = '';    
                    }else{
                        temp = SSNnErrorMessageMap.get(ssnValue);
                    }
                    
                	formattedgeneratedCSVFile = formattedgeneratedCSVFile + formattedCSVFileLines[i]+','+'Not Created'+','+''+','+''+','+temp+'\n';        
                    isPartialSuccess = true;
                    //failureMessage = failureMessage + docuemntNameValue + ' - '+temp+'<br/>';
                }else{
                	formattedgeneratedCSVFile = formattedgeneratedCSVFile + formattedCSVFileLines[i]+','+contactCreatedOrUpdatedMap.get(ssnValue)+','+SSNnContactIdMap.get(ssnValue)+','+SSNnCaseIdMap.get(ssnValue)+','+''+'\n';    
                	successCasesCount = successCasesCount+1;
                    successMessage = successMessage + docuemntNameValue + ' - Case created<br/>';
                }
                
            } 
            /*if(isPartialSuccess){
                order.Status__c = 'Partial Success';
                update order; 
            }else{
                order.Status__c = 'Success';
                update order;
            } */
            if(totalRows == successCasesCount && failureCasesCount == 0){
            	order.Status__c = 'Success';
                update order;    
            }else if(successCasesCount == 0){
            	order.Status__c = 'Failed';
                update order;    
            }else if(successCasesCount != 0 && failureCasesCount != 0){
            	order.Status__c = 'Partial Success';
                update order;    
            }
            
        } else{
            order.Status__c = 'Failed';
            update order;
            DHS_Customer_Order_Upload_Log__c log = [select id, Error_Message__c from DHS_Customer_Order_Upload_Log__c where id=:customerOrderUploadlogId];
            log.Error_Message__c = 'OrderData.csv file not uploaded';
            update log;
            //DHSMailUtilities.sendBIEmail('Customer Order Upload Failed',emailBody,toAddressList,string.valueOf(system.label.DHS_AdminEmail).split(','),null);
            order.Status__c = 'Failed';
            update order;
        }
        
    }
    global map<string,string> CreateCaseAction(list<string> contactIds, string OrderId,map<string,list<contentdocumentlink>> mapOfContactNDocumentsTobeCreated){
        map<string,string> ssnNCaseIdMap = new map<string,string>();
        map<string,string> ssnNContactIdMap = new map<string,string>();
        
        list<contentdocumentlink> cdlsFromContact = new list<contentdocumentlink>();
        
        for(string conId : mapOfContactNDocumentsTobeCreated.keyset()){
            if(mapOfContactNDocumentsTobeCreated.get(conId) != Null){
            	cdlsFromContact.addAll(mapOfContactNDocumentsTobeCreated.get(conId));    
            }	    
        }
        list<string> cdlIds = new list<String>();
        for(contentdocumentlink cdl: cdlsFromContact){
       		cdlIds.add(cdl.id);     
        }
        map<string,contentdocumentlink> cdlMap = new map<string,contentdocumentlink>();
        map<string,string> cdlIdandName = new map<string,string>();
        if(!cdlIds.isEmpty()){
            for(contentdocumentlink cd: [select id, contentdocument.title from contentdocumentlink where id in:cdlIds]){
                cdlIdandName.put(cd.id,cd.contentdocument.title); 
                cdlMap.put(cd.id,cd);
            }
        }
        
        
        string contactfields1='';
        List<String> validContactToCaseFields = new List<String>();
        if(system.label.DHS_ContactToCaseFields != 'None'){
          Map<String, Schema.SObjectField> contactFieldMap =
              DHS_Contact__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();
          Map<String, Schema.SObjectField> caseFieldMap =
              DHS_Case__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();
          for (String configuredField :
              system.label.DHS_ContactToCaseFields.split(',')) {
              String trimmedField = configuredField.trim();
              if (contactFieldMap.containsKey(trimmedField) &&
                  caseFieldMap.containsKey(trimmedField)) {
                  validContactToCaseFields.add(trimmedField);
              }
          }
          contactfields1 = String.join(validContactToCaseFields, ',');
        }
        string query;
        if(contactfields1 == ''){
            query = 'select id,First_Name__c,Last_Name__c,State__c,SSN__c from DHS_Contact__c where id in:contactIds';
        }else{
        	query = 'select First_Name__c,Last_Name__c,State__c,SSN__c,'+contactfields1+' from DHS_Contact__c where id in:contactIds';    
        }
        list<DHS_Contact__c> diacontacts = database.query(query);
        //list<dia_contact__c> diacontacts = [select id,First_Name__c,Last_Name__c,State__c,SSN__c from  dia_contact__c where id in:contactIds];
        for(DHS_Contact__c con: diacontacts){
            ssnNContactIdMap.put(con.id,con.SSN__c);
        }
        list<DHS_Case__c> casesToCreate = new List<DHS_Case__c>();    
        list<contentdocumentlink> cdlsToInsert = new list<contentdocumentlink>();
        
        for(DHS_Contact__c con: diacontacts){
            list<contentdocumentlink> cdls = new list<contentdocumentlink>();
            cdls = mapOfContactNDocumentsTobeCreated.get(con.id);
            string docName;
            if(!cdls.isEmpty()){
            	docName = cdlMap.get(cdls[0].id).contentdocument.title.split('.pdf')[0]; 	  
            }
            DHS_Case__c newCase= new DHS_Case__c();
            newCase.put('DHS_Contact__c',con.id);  
            newCase.put('Case_Number__c',con.First_Name__c.substring(0,1) + con.Last_Name__c.substring(0,1)+' - '+con.Last_Name__c.right(3)+con.State__c);
            newCase.put('DHS_Order__c',orderId);
            newCase.put('Case_Type__c','Tier 5');
            newCase.put('Customer_Case_Number__c',docName);
            if (DHS_Case__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap()
                .containsKey('Case_Origin__c')) {
                newCase.put('Case_Origin__c','Customer Interface');
            }
            if(!validContactToCaseFields.isEmpty()){
	            	list<string> contactfields = validContactToCaseFields;
                for(string fieldName: contactfields){
                    if(fieldName == 'Manifest__c'){
                        if(con.get(fieldName) != Null){
                        	newCase.put(fieldName,date.valueof(con.get(fieldName)).format());       
                        	newCase.put('Case_Due_Date__c',date.valueof(con.get(fieldName)).adddays(45));  
                        	newCase.put('Waiver_Due_Date__c',date.valueof(con.get(fieldName)).adddays(38));      
                        }
                    	     
                    }else{
                       newCase.put(fieldName,con.get(fieldName));
                    }
                	    
                }
            }
            casesToCreate.add(newCase);
        }
        if(!casesToCreate.isEmpty()){
            List<Database.SaveResult> dsrs = Database.insert(casesToCreate,false); 
            for(Integer i = 0; i < dsrs.size(); i++){
                  if(dsrs[i].isSuccess()){
                      string ssn = ssnNContactIdMap.get(casesToCreate[i].DHS_Contact__c);
                      ssnNCaseIdMap.put(ssn,dsrs[i].getId());
                         
                  }
            }
        }
        string uploadedby = [Select Id,Name from user where id=:userinfo.getuserid() WITH SECURITY_ENFORCED].Name;
        /*list<string> cdlIds = new list<string>();
        for(string str: mapOfContactNDocumentsTobeCreated.keyset()){
            list<contentdocumentlink> cdls1 =   mapOfContactNDocumentsTobeCreated.get(str); 
            for(contentdocumentlink c: cdls1){
                cdlIds.add(c.id);
            }
        }*/
        /*map<string,string> cdlIdandName = new map<string,string>();
        if(!cdlIds.isEmpty()){
            for(contentdocumentlink cd: [select id, contentdocument.title from contentdocumentlink where id in:cdlIds]){
                cdlIdandName.put(cd.id,cd.contentdocument.title);   
            }
        }*/
        for(DHS_Case__c c:casesToCreate){
            list<contentdocumentlink> cdls = mapOfContactNDocumentsTobeCreated.get(c.DHS_Contact__c); 
            if(cdls != Null){
            for(contentdocumentlink cdl: cdls){
                    DHS_Document__c document = new DHS_Document__c();
                    document.Added_By__c = uploadedby;
                    document.DHS_Case__c = c.id;
                    document.Name__c = cdlIdandName.get(cdl.id);
                    insert document;
                            ContentDocumentLink cdl1 = new ContentDocumentLink();
                            cdl1.ContentDocumentId = cdl.contentDocumentId;
                            cdl1.LinkedEntityId = document.id;
                            cdl1.ShareType = 'V';  
                			cdl1.Visibility  = 'AllUsers';
                            cdlsToInsert.add(cdl1);      
                }
            }
        }
        if(!cdlsToInsert.isEmpty()){
            insert cdlsToInsert;
        }
        return ssnNCaseIdMap;
    }
    global void finish(Database.BatchableContext BC) {
      
        Attachment att = new Attachment();
        att.parentId = customerOrderUploadlogId;
        att.Name = 'OrderUploadResult.csv';
        att.Body = Blob.valueOf(
            formattedgeneratedCSVFile == null
                ? ''
                : formattedgeneratedCSVFile
        );
        insert att;
        
        DHS_Customer_Order__c customerOrder = [select Id,Status__c from DHS_Customer_Order__c where id=:customerOrderId];
        string emailBody = 'Hello,<br/><br/>Customer has uploaded orders into ForeSite on '+DateTime.now().format()+'.'+'<br/>The status of the order is '+customerOrder.Status__c+'.';
        emailBody = emailBody + '<br/><br/><b>Summary:</b><br/><b>successfully processed ('+successCasesCount+')</b>';
        emailBody = emailBody + '<br/>'+successMessage;
        emailBody = emailBody + '<br/><b>Failed ('+failureCasesCount+')</b>';
        emailBody = emailBody + '<br/>'+failureMessage+'<br/>';
        emailBody = emailBody + '<br/>Thanks,<br/>ISN Corporation';
      
		Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        semail.setToAddresses(system.label.DHS_CustomerOrderUploadNotificationEmail.split(','));
        if(boolean.valueof(system.label.DHS_CustomerOrderUploadNotificationUseCCAddress)){
            semail.setCCAddresses(new list<string>{userinfo.getuseremail()});    
        }
       
        string emailSubject = system.label.DHS_CustomerOrderUploadNotificationSubject+' - ' + system.now().date().format() +' - '+customerOrder.Status__c;
		semail.setSubject(emailSubject);
		semail.sethtmlBody(emailBody);
        semail.setSaveAsActivity(true);
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {semail});
        } catch (EmailException emailException) {
        }
        
        /*List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
        Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
        fileAttachment.setFileName('OrderUploadResult.csv');
        fileAttachment.setBody(Blob.valueOf(formattedgeneratedCSVFile));
        fileAttachments.add(fileAttachment);
        semail.setFileAttachments(fileAttachments);*/
		
                
    }
    global Integer GetColumnIndex(String header, String columnName){
        Integer i=0;
        Integer index;
        header = header.replace('\r\n', '');
        header = header.replace('\n', '');
        header = header.replace('\r', '');
        //for(String str: header.replaceAll('\\r', '').split(',')){
        for(String str: header.split(',')){
            if(str.replaceAll('\\r', '').trim() == columnName.trim()){
                index = i;    
            } 
            i++;
        } 
        return index;
    }
    public list<string> splitString(String csvLine){
        csvLine = csvLine.replace('\r\n', '');
        csvLine = csvLine.replace('\n', '');
        csvLine = csvLine.replace('\r', '');
        Integer startIndex;
        Integer endIndex;
        while(csvLine.indexOf('"') > -1){
            if(startIndex == null){
                startIndex = csvLine.indexOf('"');
                csvLine = csvLine.substring(0, startIndex) + ':quotes:' + csvLine.substring(startIndex+1, csvLine.length());
            }else{
                if(endIndex == null){
                    endIndex = csvLine.indexOf('"');
                    csvLine = csvLine.substring(0, endIndex) + ':quotes:' + csvLine.substring(endIndex+1, csvLine.length());
                }
            }
            if(startIndex != null && endIndex != null){
                String sub = csvLine.substring(startIndex, endIndex);
                sub = sub.replaceAll(',', ':comma:');
                csvLine = csvLine.substring(0, startIndex) + sub + csvLine.substring(endIndex, csvLine.length());
                startIndex = null;
                endIndex = null;
            }
        }
        List<String> columnValues = new List<String>();
        for(String column : csvLine.split(',')){
            column = column.replaceAll(':quotes:', '').replaceAll(':comma:', ',');
            columnValues.add(column.trim());
        }
        return columnValues;
    }
}