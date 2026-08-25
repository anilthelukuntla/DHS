public class BIManifestReportsController {
    public date fromDate	{get;set;}
    public date toDate		{get;set;}
    public list<ContentVersion> manifestFiles {get;set;}
    public list<ContentVersion> operationalFiles {get;set;}
    public list<ContentVersion> extensionReqTitleFiles {get;set;}
    public list<ContentVersion> waiverReqFiles {get;set;}
    
    public BIManifestReportsController(){
        getOptionalSummary();
        getExtensionRequest();
        getWaiverRequest();
        getManifestData();
    }
    public void regenerateManifest(){
        date weekStartDate = date.today().toStartOfWeek();
        date weekEndDate = weekStartDate.addDays(5);
        //setPassword(weekStartDate,weekEndDate);
    }
    public void generateCustomDateRangeManifest(){
        List<Sobject> metadataVals = getMetadata('ManifestReport');
        Map<string,List<string>> labelsNApinamesMap = getApinameNLabel(metadataVals);
        generateCSVDate('PM Manifest',labelsNApinamesMap.get('apinames'),labelsNApinamesMap.get('labels'));
    }
    public void generateCustomDateRangeOppSummary(){
        List<Sobject> metadataVals = getMetadata('OprationalSummaryReport');
        Map<string,List<string>> labelsNApinamesMap = getApinameNLabel(metadataVals);
		generateCSVDate('PM Operational Summary',labelsNApinamesMap.get('apinames'),labelsNApinamesMap.get('labels'));
    }
    
    public void generateCustomDateRangeWaiverRequest(){
        List<Sobject> metadataVals = getMetadata('WaiverRequest');
        Map<string,List<string>> labelsNApinamesMap = getApinameNLabel(metadataVals);
		generateCSVDate('PM Waiver Request',labelsNApinamesMap.get('apinames'),labelsNApinamesMap.get('labels'));
    }
    public void generateCustomDateRangeExtensionRequest(){
        List<Sobject> metadataVals = getMetadata('ExtensionRequest');
        Map<string,List<string>> labelsNApinamesMap = getApinameNLabel(metadataVals);
		generateCSVDate('PM Extension Requests',labelsNApinamesMap.get('apinames'),labelsNApinamesMap.get('labels'));
    }
    
    public void generateCSVDate(string tabName,list<string> queryFields,list<string> labels){
        string headers = '';
        for(string label : labels){
            headers += label+',';
        }
        string csv = headers.substringBeforeLast(',')+'\n';
        string query;
            if(tabName == 'PM Manifest'){
                List<DIA_Case__c> cases = new List<DIA_Case__c>();
				query = 'select '+string.join(queryFields,',')+' from DIA_Case__C where ((Case_Completed_Date__c >= : fromDate and Case_Completed_Date__c <=: toDate) or (Case_Cancellation_Date__c >= : fromDate and Case_Cancellation_Date__c <=: toDate) )';
                system.debug(query);
                cases = database.query(query);
                system.debug('cases...'+cases);
                for(sObject c : cases){
                    string currentRow = '';
                    for(integer i = 0; i < queryFields.size(); i++){
                        currentRow += generateCSV(c,queryFields.get(i),labels.get(i));
                    }
                        csv += currentRow.substringBeforeLast(',')+'\n';
                }
                system.debug(csv);
                createContentVersion(tabName,csv);
            }
        	else if(tabName == 'PM Operational Summary'){
                List<DIA_Case__c> cases = new List<DIA_Case__c>();
                query = 'select '+string.join(queryFields,',')+' from DIA_Case__C where ((Order_Received__c >= : fromDate and Order_Received__c <=: toDate ) )';
                cases = database.query(query);
                system.debug('cases...'+cases);
                for(sObject c : cases){
                    string currentRow = '';
                    for(integer i = 0; i < queryFields.size(); i++){
                        currentRow += generateCSV(c,queryFields.get(i),labels.get(i));
                    }
                        csv += currentRow.substringBeforeLast(',')+'\n';
                }
                system.debug(csv);
                createContentVersion(tabName,csv);
                
            }else if(tabName == 'PM Extension Requests'){
                List<DIA_waiver_information__c> waivers = new List<DIA_waiver_information__c>();
                string typex = 'Extension';
                query = 'select '+string.join(queryFields,',')+' from DIA_waiver_information__c where case__r.Order_Received__c >= : fromDate and case__r.Order_Received__c <=: toDate and Type__c = : typex';
				system.debug(query);
                waivers = database.query(query);
                system.debug('waivers...'+waivers);
                for(sObject c : waivers){   
                    string currentRow = '';
                    for(integer i = 0; i < queryFields.size(); i++){
                        currentRow += generateCSV(c,queryFields.get(i),labels.get(i));
                    }
                        csv += currentRow.substringBeforeLast(',')+'\n';
                }
                	createContentVersion(tabName,csv);
			}else if(tabName == 'PM Waiver Request'){
                List<DIA_waiver_information__c> waivers = new List<DIA_waiver_information__c>();
                string type = 'Waiver';
                query = 'select '+string.join(queryFields,',')+' from DIA_waiver_information__c where ((case__r.Order_Received__c >= : fromDate and case__r.Order_Received__c <=: toDate and Type__c = : type))';
				system.debug('query...'+query);
                waivers = database.query(query);
                system.debug('waivers...'+waivers);
                for(sObject c : waivers){   
                    string currentRow = '';
                    for(integer i = 0; i < queryFields.size(); i++){
                        currentRow += generateCSV(c,queryFields.get(i),labels.get(i));
                    }
                        csv += currentRow.substringBeforeLast(',')+'\n';
                }
						createContentVersion(tabName,csv);
            }
    }
    public string generateCSV(sObject record,string apiname,string label){
        string row = '';
        system.debug(apiName);
        if(apiName.contains('__r')){
            string parentApiName = apiname.substringBefore('.');
            system.debug(parentApiName);
            sObject parentObject = (sobject)record.getSObject(parentApiName);
            string suffix = apiname.substringAfter('.');
            system.debug(suffix);
            if(suffix.contains('__r')){
				string gparentApiName = suffix.substringBefore('.');
                sObject gParentObject = (sobject)parentObject.getSObject(gparentApiName);
            	string lastSuffix = suffix.substringAfter('.');
                object val = ((sobject)parentObject.getSObject(gparentApiName)).get(lastSuffix);
                if(val == null){
					row += ''+',';
				}else{
                    if(val instanceof Date) {
                        List<string> dateVal = date.valueOf(val).tostring().substringBefore(' ').split('-');
                    	val = dateVal.get(1)+'-'+dateVal.get(2)+'-'+dateVal.get(0);
                    }else if (val instanceof DateTime) {
                        DateTime dt = (DateTime)val;
                        val = dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                    }
					row += val+',';
				}
            }else{
                object val = ((sobject)record.getSObject(parentApiName)).get(suffix);
                if(val == null){
					row += ''+',';
				}else{
                    if(val instanceof Date) {
                        List<string> dateVal = date.valueOf(val).tostring().substringBefore(' ').split('-');
                    	val = dateVal.get(1)+'-'+dateVal.get(2)+'-'+dateVal.get(0);
                    }else if (val instanceof DateTime) {
                        DateTime dt = (DateTime)val;
                        val = dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                    }
					row += val+',';
				}
			}
        }else{
            if(record.get(apiName) == null){
				row += ''+',';
			}else{
                object val = record.get(apiName);
                if (val instanceof Date) {
                    List<string> dateVal = date.valueOf(val).tostring().substringBefore(' ').split('-');
                    val = dateVal.get(1)+'-'+dateVal.get(2)+'-'+dateVal.get(0);
                } else if (val instanceof DateTime) {
                    DateTime dt = (DateTime)val;
                    val = dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                }
				row += val+',';
			}
        }
        return row;
    }
    public static list<ContentVersion> FetchContentVersion(string tabName){
        string title = tabName+' from'+'%';
        List<Account> acc = [Select ID from Account where Name='ISN'];
        list<ContentDocumentLink> cdls = [SELECT Id, Visibility, linkedentityId,contentdocument.Title, contentdocumentID from ContentDocumentLink WHERE linkedentityId=:acc[0].id and contentdocument.Title like :title];
        list<ContentVersion> cv = new list<ContentVersion>();
        if(cdls.size() > 0) {
            cv = [SELECT Title,Id,CreatedDate,ContentDocumentId,IsLatest,versiondata FROM ContentVersion WHERE Title like : title and IsLatest=true and ContentDocumentId=:cdls[0].contentdocumentID];
        }
        return cv;
    }
    public void createContentVersion(string tabName, string csv){
        list<contentversion> cvd = FetchContentVersion(tabName);
            ContentVersion objCV = new ContentVersion();
            string fileName = tabName+' from '+fromDate.tostring().substringBefore(' ')+' To '+ToDate.tostring().substringBefore(' ');
            if(cvd.size() == 0){
                objCV.Title = fileName;
                objCV.PathOnClient = fileName+'.CSV';
                objCV.VersionData = blob.valueOf(csv);
                insert objCV;
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: objCV.Id].ContentDocumentId;
                cdl.LinkedEntityId = [Select Id from Account Where Name='ISN'].id;
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                insert cdl;
            }else{
                objCV.Title = fileName;
                objCV.PathOnClient = fileName+'.CSV';
                objCV.VersionData = blob.valueOf(csv);
                objCV.contentDocumentId = cvd[0].ContentDocumentId;
                insert objCV;
            }
    }
    public void getOptionalSummary(){
        List<Account> acc = [Select ID from Account where Name='ISN'];
        string summaryTitle = 'PM Operational Summary from'+'%';
        list<ContentDocumentLink> opcdls = [SELECT Id, Visibility, linkedentityId,contentdocument.Title, contentdocumentID from ContentDocumentLink WHERE linkedentityId=:acc[0].id and contentdocument.Title like :summaryTitle];
        operationalFiles = new list<ContentVersion>();
        if(opcdls.size() > 0) {
            operationalFiles = [SELECT Title,Id,CreatedDate,ContentDocumentId,IsLatest,versiondata FROM ContentVersion WHERE Title like : summaryTitle and ContentDocumentId=:opcdls[0].contentdocumentID order by createddate desc];
        }
    }
    public void getExtensionRequest(){
        List<Account> acc = [Select ID from Account where Name='ISN'];
        string extensionReqTitle = 'PM Extension Requests from'+'%';
        list<ContentDocumentLink> ercdls = [SELECT Id, Visibility, linkedentityId,contentdocument.Title, contentdocumentID from ContentDocumentLink WHERE linkedentityId=:acc[0].id and contentdocument.Title like :extensionReqTitle];
        extensionReqTitleFiles = new list<ContentVersion>();
        if(ercdls.size() > 0) {
            extensionReqTitleFiles = [SELECT Title,Id,CreatedDate,ContentDocumentId,IsLatest,versiondata FROM ContentVersion WHERE Title like : extensionReqTitle and ContentDocumentId=:ercdls[0].contentdocumentID order by createddate desc];
        }
    }
    public void getWaiverRequest(){
        List<Account> acc = [Select ID from Account where Name='ISN'];
        string waiverReqTitle = 'PM Waiver Request from'+'%';
        list<ContentDocumentLink> wrcdls = [SELECT Id, Visibility, linkedentityId,contentdocument.Title, contentdocumentID from ContentDocumentLink WHERE linkedentityId=:acc[0].id and contentdocument.Title like :waiverReqTitle];
        waiverReqFiles = new list<ContentVersion>();
        if(wrcdls.size() > 0) {
            waiverReqFiles = [SELECT Title,Id,CreatedDate,ContentDocumentId,IsLatest,versiondata FROM ContentVersion WHERE Title like : waiverReqTitle and ContentDocumentId=:wrcdls[0].contentdocumentID order by createddate desc];
        }
    }
    public void getManifestData(){
        string title = 'PM Manifest from'+'%';
        List<Account> acc = [Select ID from Account where Name='ISN'];
        list<ContentDocumentLink> cdls = [SELECT Id, Visibility, linkedentityId,contentdocument.Title, contentdocumentID from ContentDocumentLink WHERE linkedentityId=:acc[0].id and contentdocument.Title like :title];
        manifestFiles = new list<ContentVersion>();
        if(cdls.size() > 0) {
            manifestFiles = [SELECT Title,Id,CreatedDate,ContentDocumentId,IsLatest,versiondata FROM ContentVersion WHERE Title like : title and ContentDocumentId=:cdls[0].contentdocumentID order by createddate desc];
        }
    }
    public string formatDate(date dateToFormat){
        string formattedDate = '';
            if(dateToFormat.month().tostring().length()  == 1){
                formattedDate = '0'+dateToFormat.month()+'/';
            }else{
                formattedDate = dateToFormat.month()+'/';
            }
        	if(dateToFormat.day().tostring().length()  == 1){
                formattedDate += '0'+dateToFormat.day()+'/';
            }else{
                formattedDate += dateToFormat.day()+'/';
            }
        		formattedDate += dateToFormat.year();
        	return formattedDate;
    }
    public static List<SObject> getMetadata(string reportType){
        // Mapping of report types to their corresponding metadata retrieval methods
        Map<String, List<SObject>> reportTypeToMetadataMap = new Map<String, List<SObject>>{
            'ManifestReport' => Manifest_Report_Export__mdt.getAll().values(),
            'OprationalSummaryReport' => Operational_Summary_Export__mdt.getAll().values(),
            'WaiverRequest' => Waiver_Request_Export__mdt.getAll().values(),
            'ExtensionRequest' => Extension_Request_Export__mdt.getAll().values()
        };
            return reportTypeToMetadataMap.get(reportType);
    }
    public static Map<string,List<string>> getApinameNLabel(List<Sobject> metadataValues){
        Map<integer,Map<string,string>> orderLabelNapiname = New Map<integer,Map<string,string>>();
        for(SObject record : metadataValues){
            string apiname = (string)record.get('API_Name__c');
            string label = (string)record.get('Label');
            integer order = integer.valueOf((decimal)record.get('Order__c'));
            Map<string,string> apinameNLable = New Map<string,string>{'label'=> label,'apiname'=> apiname};
            orderLabelNapiname.put(order,apinameNLable);
        }
		list<string> apinames = New list<string>();
        list<string> labels = New list<string>();
        for(integer i = 1; i<= orderLabelNapiname.keyset().size(); i++){
            if(!apinames.contains(orderLabelNapiname.get(i).get('apiname'))){
                apinames.add(orderLabelNapiname.get(i).get('apiname'));
            }
            labels.add(orderLabelNapiname.get(i).get('label'));
        }
        Map<string,List<string>> returnVal = New Map<string,List<string>>();
        returnVal.put('labels',labels);
        returnVal.put('apinames',apinames);
        return returnVal;
    }
}