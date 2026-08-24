@SuppressWarnings('PMD.ApexDoc,PMD.ApexSOQLInjection,PMD.AvoidDebugStatements,PMD.AvoidDeeplyNestedIfStmts,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.DebugsShouldUseLoggingLevel,PMD.ExcessiveParameterList,PMD.ExcessivePublicCount,PMD.FieldDeclarationsShouldBeAtStart,PMD.IfElseStmtsMustUseBraces,PMD.IfStmtsMustUseBraces,PMD.NcssCount,PMD.NcssMethodCount,PMD.NcssTypeCount,PMD.StdCyclomaticComplexity')
public with sharing class DHSCDRLReportsControllerV2 {
    public user currentUser{get;set;}
    public boolean hasRecords{get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public list<Map<string,object>> records	{get;set;}
    public list<string> apinames	{get;set;}
    public list<string> fetchApinames	{get;set;}
	public list<string> labels	{get;set;}
    public list<selectoption> typesOfReports {get;set;}
    public list<selectoption> cmoUsers {get;set;}
    public list<selectoption> investigatorUsers {get;set;}
    public list<selectoption> caseTaskStatus {get;set;}
    public list<selectoption> caseStatus {get;set;}
    public list<selectoption> leadStatus {get;set;}
    public string selectedCaseStatus {get;set;}
    public string selectedCaseTaskStatus {get;set;}
    public string selectedLeadStatus {get;set;}
    public string selectedReportType {get;set;}
    public string selectedCMOUser {get;set;}
    public string selectedInvestigatorUser {get;set;}
    public date fromDate {get;set;}
    public date toDate {get;set;}
    public transient list<ReportRecord> reports {get;set;}
    public boolean showViewButton {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public boolean showreportstable {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public string selectedRelatedCaseIdForMessages{get;set;}
    public list<selectoption> relatedCasesForMessages {get;set;}
    public string selectedCaseIdForLeadSearch{get;set;}
    public list<selectoption> messageTypeOptions {get;set;}
    public string selectedMessageType{get;set;}
    public string selectedCaseNumberForLeadSearch{get;set;}
    public string selectedleadforstatustracking {get;set;}
    //public list<Lead__History> leadStatusTrackings {get;set;}
    public list<LeadHistoryRecord> leadStatusTrackings{get;set;}
    public integer pageNumber {get;set;}
    public integer totalPages   {get;set;}
    public integer totalRecordCount {get;set;}
    public boolean disablePrev {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public boolean disableNext {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public string queryForNextRecords {get;set;}
    public string lastRecordName {get;set;}
    public string firstRecordName {get;set;}
    public integer currentRecordCount {get;set;}
    public string userType  {get;set;}
    public string contextINVId  {get;set;}
    list<DHS_Case__c> cases {get;set;}
    public class LeadHistoryRecord{
        public Lead__History leadHistory {get;set;}
        public integer numOfDays {get;set;}
        public LeadHistoryRecord(Lead__History lh, integer nd){
            this.leadHistory = lh;
            this.numOfDays = nd;
        }
    }
    
    public DHSCDRLReportsControllerV2(){
        selectedReportType = '';
        cmoUsers = new List<SelectOption>();
        investigatorUsers = new List<SelectOption>();
        relatedCasesForMessages = new List<SelectOption>();
        leadStatusTrackings = new List<LeadHistoryRecord>();
        hasRecords = false;
        records = new list<Map<string,object>>();
        labels = New list<string>();
        apinames = New list<string>();
        fetchApinames = New list<string>();
        showReportsTable = false;
        pageNumber = 1; 
        disablePrev = true;
        disableNext = true;
        currentUser = [select id, firstname, lastname, email, user_type__c from User where id=:userinfo.getuserid() WITH SECURITY_ENFORCED];  
        userType = currentUser.user_type__c;
        if(userType == 'INV'){
            contextINVId = currentUser.Id;
        }
        fetchPicklistValues();
        showViewButton = false;
        showreportstable = false;
        showleadstatustrackingpanel = false;
    }
    public void fetchPicklistValues(){
        typesOfReports = new list<selectoption>();
        typesOfReports.add(new selectoption('','--None--'));
        list<string> reportTypes = new list<string>();
        reportTypes.addAll(system.label.DHS_Types_Of_Reports.split(','));
        for(string rt: reportTypes){
            if(currentUser.user_type__c == 'INV'){
                if(rt == 'Check-in/Check-out'){
                    typesOfReports.add(new selectoption(rt,rt == 'Investigator DHSReports' ? 'Investigator Reports' : rt)); 
                 }  
            } else{
                  typesOfReports.add(new selectoption(rt,rt == 'Investigator DHSReports' ? 'Investigator Reports' : rt)); 
            }    
        }    
        caseStatus = new list<selectoption>();
        caseStatus.add(new selectoption('DHS_All','All'));
        for(String str: DHSApexUtil.getPickListValuesIntoList('DHS_Case__c', 'Status__c')){
            caseStatus.add(new selectoption(str,str));
        }
        caseTaskStatus = new list<selectoption>();
        caseTaskStatus.add(new selectoption('DHS_All','All'));
        for(String str: DHSApexUtil.getPickListValuesIntoList('DHS_Case__c', 'Current_Task__c')){
            if(str == 'Initiated State'){
                caseTaskStatus.add(new selectoption(str,str+' (UnAssigned)'));
            }
            if(str == 'Validate Transmission'){
                caseTaskStatus.add(new selectoption(str,str+' (Assigned)'));
            }
          
            if(str == 'Scoping' || str == 'Investigations' || str == 'Investigations Review' || str == 'QA and Review'){
                caseTaskStatus.add(new selectoption(str,str+' (In Progress)'));
            }
            if(str == 'QA Review Completed'){
                caseTaskStatus.add(new selectoption(str,str+' (Completed)'));
            }
            if(str == 'Discontinued'){
                caseTaskStatus.add(new selectoption(str,str));
            }
        }
        
        leadStatus = new list<selectoption>();
        leadStatus.add(new selectoption('DHS_All','All'));
        for(String str: DHSApexUtil.getPickListValuesIntoList('DHS_Lead__c', 'Status__c')){
            leadStatus.add(new selectoption(str,str));
        }
        
        messageTypeOptions = new list<selectoption>();
        messageTypeOptions.add(new selectoption('','--None--'));
        messageTypeOptions.add(new selectoption('Case Broadcast Message','Case Broadcast Message'));
        messageTypeOptions.add(new selectoption('General Broadcast Message','General Broadcast Message'));
        
    }
    public boolean fiveorlessitemsofcase = false;
    public void runReportAction(){
    
        if(selectedReportType == 'ROIReport'){
            list<DHS_Document__c> documents = new list<DHS_Document__c>();
            list<attachment> attachments = new list<attachment>();
            
            records = new list<Map<string,object>>();
            labels = New list<string>();
        	apinames = New list<string>();
            hasRecords = false;
            list<string> roiApiNames = New list<string>();
            List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
            apinames.addAll(getFieldMap('DHS_Document__c').get('apinames'));
            roiApiNames.addAll(getFieldMap('DHS_Document__c').get('apinames'));
            labels.addAll(getFieldMap('DHS_Document__c').get('labels'));
            if(!apinames.contains('name')) {
                roiApiNames.add('name');
            }
            system.debug(roiApiNames);
            fetchApinames = roiApiNames;
            String query =  'Select '+string.join(roiApiNames, ',') + ' From DHS_Document__c ';
            whereCriteria.add(new DHSApexUtil.Criteria('Name__c','ROIReport','='));
            
            if(fromDate != Null){
                Datetime myDatetime = Datetime.newInstance(fromDate, Time.newInstance(0, 0, 0, 0));
				String isoDatetime = myDatetime.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
                system.debug(isoDatetime);
                whereCriteria.add(new DHSApexUtil.Criteria('createddate',isoDatetime, '>=','Date'));
            }
            if(toDate != Null){
                Datetime myDatetime = Datetime.newInstance(toDate, Time.newInstance(0, 0, 0, 0));
				String isoDatetime = myDatetime.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
                system.debug(isoDatetime);
                whereCriteria.add(new DHSApexUtil.Criteria('createddate',isoDatetime, '<=','Date'));
            }
            
            String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);
            string countQuery;
            if(!string.isblank(whereCond)){
                queryForNextRecords = query + ' WHERE '+whereCond+' AND';
                query = query + ' WHERE '+whereCond+' Order by name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Document__c WHERE '+ whereCond;
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' WITH SECURITY_ENFORCED Order by name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Document__c';
            }
            
        totalRecordCount = database.countquery(Countquery);
			system.debug('query...'+query);            
            list<sobject> documentsObj = new list<sobject>();
            Map<Id,DHS_Document__c> docMap = New Map<Id,DHS_Document__c>();
            // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
            documents = database.query(query);
            documentsObj = documents;
            docMap.putAll(documents);
            attachments = [Select Id, ParentId, Name from Attachment where parentid in: docMap.keyset() WITH USER_MODE ];
            Map<string,string> documentNattachmentMap = new Map<string,string>();
            for(attachment att: attachments){
                 documentNattachmentMap.put(att.parentId,att.id);
            }
            if(!documentsObj.isEmpty()){
                hasRecords = true;
                List<Map<String, Object>> roisMap = DHSUtils.convertToMapList(documentsObj,roiApiNames);
                integer i = 0;
                for(Map<String, Object> roiMap : roisMap){
                    
                    Map<String, Object> flattenedObject = DHSUtils.flatten(roiMap, '.');
                    string docId = string.valueOf(flattenedObject.get('id'));
					string attId = documentNattachmentMap.get(docId);
                    object downloadAtt = '<a onclick="window.open(\'/servlet/servlet.FileDownload?file=' + attId + '\', \'_blank\'); return false;" ' +
                                          'data-toggle="tooltip" title="View Attachment">' +
                                          '<i class="fa fa-eye"></i>' +
                                          '</a>';
                    flattenedObject.put('id',downloadAtt);
                    if(i==0) firstRecordName = string.valueOf(flattenedObject.get('name'));    
                    lastRecordName = string.valueOf(flattenedObject.get('name'));
                    records.add(flattenedObject);
                }
            }
            PageNumber = 1;
            double totalNum = double.valueof(totalRecordCount)/double.valueof(200);
            double floorVal = Math.floor(totalNum);
            double diff = totalNum - floorVal;
            totalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
            system.debug('TotalPages...'+totalPages);
            if(totalRecordCount <= 200){
                disablePrev = true;
                disableNext = true;
                currentRecordCount = totalRecordCount;
            }else{
                disablePrev = true;   
                disableNext = false;
                currentRecordCount = 200; 
            }
        } else if(selectedReportType == 'Case'){
            records = new list<Map<string,object>>();
            labels = New list<string>();
        	apinames = New list<string>();
            hasRecords = false;
            list<string> caseApiNames = New list<string>();
			List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
            apinames.addAll(getFieldMap('DHS_Case__c').get('apinames'));
            caseApiNames.addAll(getFieldMap('DHS_Case__c').get('apinames'));
            labels.addAll(getFieldMap('DHS_Case__c').get('labels'));
            if(!apinames.contains('name')) caseApiNames.add('name');
            system.debug(caseApiNames);
            fetchApinames = caseApiNames;
            String query =  'Select '+string.join(caseApiNames, ',') + ' From DHS_Case__c ';
            if(selectedCaseTaskStatus != 'DHS_All'){
                whereCriteria.add(new DHSApexUtil.Criteria('Current_Task__c',selectedCaseTaskStatus,'='));
            }
            if(selectedCaseStatus != 'DHS_All'){
                whereCriteria.add(new DHSApexUtil.Criteria('Status__c',selectedCaseStatus,'='));
            }
            if(fromDate != Null){
                whereCriteria.add(new DHSApexUtil.Criteria('Submission_Date__c',String.valueof(fromDate), '>=', 'Date'));
            }
            if(toDate != Null){
                whereCriteria.add(new DHSApexUtil.Criteria('Submission_Date__c',String.valueof(toDate), '<=', 'Date'));
            }
            if(selectedCMoUser != 'DHS_All'){
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_Assigned_To__c',selectedCMoUser, '='));    
            }
            String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);
            string countQuery;
            if(!string.isblank(whereCond)){
                queryForNextRecords = query + ' WHERE '+whereCond+' AND';
                query = query + ' WHERE '+whereCond+' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Case__c WHERE '+ whereCond;
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' WITH SECURITY_ENFORCED Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Case__c';
            }
            
        totalRecordCount = database.countquery(Countquery);
        cases = new list<DHS_Case__c>();
            system.debug(query);
		List<SObject> caseRecords = New List<SObject>();
        if(test.isRunningTest()){
            caseRecords = database.query('Select '+string.join(caseApiNames, ',') + ' From DHS_Case__c '); 
        }else{
            // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
            caseRecords = database.query(query);        
       }
            if(!caseRecords.isEmpty()){
                hasRecords = true;
                List<Map<String, Object>> casesMap = DHSUtils.convertToMapList(caseRecords,caseApiNames);
                integer i = 0;
                for(Map<String, Object> caseMap : casesMap){
                    
                    Map<String, Object> flattenedObject = DHSUtils.flatten(caseMap, '.');
                    if(i==0) firstRecordName = string.valueOf(flattenedObject.get('name'));    
                    lastRecordName = string.valueOf(flattenedObject.get('name'));
                    records.add(flattenedObject);
                }
            }
        
            /*
		for(DHS_Case__c cs : Cases){
			Map<String, Object> obj = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(cs));
			Map<String, Object> flattenedObject = DHSUtils.flatten(obj, '.');
			records.add(flattenedObject);
		}*/

         PageNumber = 1;
        double totalNum = double.valueof(totalRecordCount)/double.valueof(200);
        double floorVal = Math.floor(totalNum);
        double diff = totalNum - floorVal;
        totalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
        system.debug('TotalPages...'+totalPages);
        if(totalRecordCount <= 200){
            disablePrev = true;
            disableNext = true;
            currentRecordCount = totalRecordCount;
        }else{
            disablePrev = true;   
            disableNext = false;
            currentRecordCount = 200; 
        }
            
              
        }else if(selectedReportType == 'Lead'){
            records = new list<Map<string,object>>();
            labels = New list<string>();
        	apinames = New list<string>();
            list<string> leadApiNames = New list<string>();
            List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
            apinames.addAll(getFieldMap('DHS_Lead__c').get('apinames'));
            leadApiNames.addAll(getFieldMap('DHS_Lead__c').get('apinames'));
            labels.addAll(getFieldMap('DHS_Lead__c').get('labels'));
            system.debug(apinames);
			if(!apinames.contains('name')) leadApiNames.add('name');
            fetchApinames = leadApiNames;
            String query = 'Select '+string.join(leadApiNames, ',') + ' From DHS_Lead__c ';
            if(SelectedLeadStatus != 'DHS_All'){
                whereCriteria.add(new DHSApexUtil.Criteria('Status__c',SelectedLeadStatus,'='));
            }
            if(fromDate != Null){
                whereCriteria.add(new DHSApexUtil.Criteria('Completed_Date__c',String.valueof(fromDate), '>=', 'Date'));
            }
            if(toDate != Null){
                whereCriteria.add(new DHSApexUtil.Criteria('Completed_Date__c',String.valueof(toDate), '<=', 'Date'));
            }
            if(selectedInvestigatorUser != 'DHS_All'){
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_Assigned_To__c',selectedInvestigatorUser, '='));    
            }
            System.debug('SelectedCaseNumberForLeadSearch...'+selectedCaseNumberForLeadSearch);
            if(String.isnotblank(selectedCaseNumberForLeadSearch)){
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__r.Case_Number__c',selectedCaseNumberForLeadSearch, '='));    
            }
            /*
            if(selectedcasestatus != 'DHS_All'){
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__r.Status__c',selectedcasestatus, '=')); 
            }*/
            
            
            String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);
            system.debug(whereCond);
            string countQuery;
            if(!string.isblank(whereCond)){
                queryForNextRecords = query + ' WHERE '+whereCond+' AND';
                query = query + ' WHERE '+whereCond+' WITH SECURITY_ENFORCED Order by name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Lead__c WHERE '+ whereCond+' WITH SECURITY_ENFORCED';
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' Order by name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Lead__c WITH SECURITY_ENFORCED';
            }
            
        totalRecordCount = database.countquery(Countquery);
        //list<DHS_Lead__c> Leads = new list<DHS_Lead__c>();
        List<SObject> leadRecords = New List<SObject>();
        if(test.isRunningTest()){
            leadRecords = database.query('Select '+string.join(leadApiNames, ',') + ' From DHS_Lead__c WITH SECURITY_ENFORCED');   
        }else{
            // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
            leadRecords = database.query(query);        
       }
            System.debug('query...'+query);
            
		List<Map<String, Object>> leadsMap = DHSUtils.convertToMapList(leadRecords,leadApiNames);
            integer i = 0;
		for(Map<String, Object> leadMap : leadsMap){
            system.debug('leadMap...'+leadMap);
			Map<String, Object> flattenedObject = DHSUtils.flatten(leadMap, '.');
			object val = flattenedObject.get('id'); 
            object returnV = '<a onclick="showleadtracking(\'' + val + '\'); return false;" data-toggle="tooltip" title="Edit User">' +
               '<i class="fas fa-eye mr-3 text-danger"></i>' +
               '</a>';
            flattenedObject.put('id',returnV);
            if(i==0) firstRecordName = string.valueOf(flattenedObject.get('name'));    
                lastRecordName = string.valueOf(flattenedObject.get('name'));
                system.debug(flattenedObject);
                records.add(flattenedObject);
            }
            
            
            PageNumber = 1;
            double totalNum = double.valueof(totalRecordCount)/double.valueof(200);
            double floorVal = Math.floor(totalNum);
            double diff = totalNum - floorVal;
            totalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
            system.debug('TotalPages...'+totalPages);
            if(totalRecordCount <= 200){
                disablePrev = true;
                disableNext = true;
                currentRecordCount = totalRecordCount;
            }else{
                disablePrev = true;   
                disableNext = false;
                currentRecordCount = 200; 
            }
        }else if(selectedReportType == 'Messages'){
            list<string> messageApiNames = New list<string>();
            records = new list<Map<string,object>>();
            labels = New list<string>();
        	apinames = New list<string>();
            List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
            apinames.addAll(getFieldMap('DHS_Message__c').get('apinames'));
            messageApiNames.addAll(getFieldMap('DHS_Message__c').get('apinames'));
            labels.addAll(getFieldMap('DHS_Message__c').get('labels'));
            system.debug(apinames);
			if(!apinames.contains('name')) messageApiNames.add('name');
            fetchApinames = messageApiNames;
            String query = 'Select '+string.join(messageApiNames, ',') + ' From DHS_Message__c ';
            if(selectedMessageType == 'Case Broadcast Message' ){
                if(selectedRelatedCaseIdForMessages != Null){
                    whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__c',selectedRelatedCaseIdForMessages,'='));
                }
            }else{
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__c','','='));
            }
           
            if(fromDate != Null){
                whereCriteria.add(new DHSApexUtil.Criteria('MessageCreatedDate__c',string.valueOf(fromDate), '>=','Date'));
            }
            if(toDate != Null){
               	whereCriteria.add(new DHSApexUtil.Criteria('MessageCreatedDate__c',string.valueOf(toDate), '<=','Date'));
            }  
            
            String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);
            system.debug(whereCond);
            string countQuery;
            if(!string.isblank(whereCond)){
                queryForNextRecords = query + ' WHERE '+whereCond+' AND';
                query = query + ' WHERE '+whereCond+' WITH SECURITY_ENFORCED Order by name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Message__c WHERE '+ whereCond+' WITH SECURITY_ENFORCED';
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' Order by name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Message__c WITH SECURITY_ENFORCED';
            }
                totalRecordCount = database.countquery(Countquery);
                //list<DHS_Message__c> messages = new list<DHS_Message__c>();
            List<SObject> messageRecords = New List<SObject>();
                if(test.isRunningTest()){
                    messageRecords = database.query('Select '+string.join(messageApiNames, ',') + ' From DHS_Message__c '  );   
                }else{
                    // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
                    messageRecords = database.query(query);        
               }
            
            List<Map<String, Object>> messagesMap = DHSUtils.convertToMapList(messageRecords,messageApiNames);
            integer i = 0;
            for(Map<String, Object> messageMap : messagesMap){
                Map<String, Object> flattenedObject = DHSUtils.flatten(messageMap, '.');
                if(i==0) firstRecordName = string.valueOf(flattenedObject.get('name'));    
                lastRecordName = string.valueOf(flattenedObject.get('name'));
                records.add(flattenedObject);
            }
                PageNumber = 1;
                double totalNum = double.valueof(totalRecordCount)/double.valueof(200);
                double floorVal = Math.floor(totalNum);
                double diff = totalNum - floorVal;
                totalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
                system.debug('TotalPages...'+totalPages);
                if(totalRecordCount <= 200){
                    disablePrev = true;
                    disableNext = true;
                    currentRecordCount = totalRecordCount;
                }else{
                    disablePrev = true;   
                    disableNext = false;
                    currentRecordCount = 200; 
                }
        }
        else if(selectedReportType == 'Check-in/Check-out'){
            list<string> checkInApiNames = New list<string>();
            records = new list<Map<string,object>>();
            labels = New list<string>();
        	apinames = New list<string>();
            List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
            apinames.addAll(getFieldMap('DHS_Investigator_Check__c').get('apinames'));
            checkInApiNames.addAll(getFieldMap('DHS_Investigator_Check__c').get('apinames'));
            labels.addAll(getFieldMap('DHS_Investigator_Check__c').get('labels'));
            system.debug(apinames);
			if(!apinames.contains('name')) checkInApiNames.add('name');
            fetchApinames = checkInApiNames;
            String query = 'Select '+string.join(checkInApiNames, ',') + ' From DHS_Investigator_Check__c ';
            whereCriteria.add(new DHSApexUtil.Criteria('Type__c', 'CheckOut', '='));
            if(currentUser.user_type__c == 'INV'){
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_TimeSheet__r.DHS_User__c', userinfo.getuserid(), '='));
            }
            if(fromDate != Null){
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_TimeSheet__r.Date__c',String.valueof(fromDate), '>=', 'Date'));
            }
            if(toDate != Null){
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_TimeSheet__r.Date__c',String.valueof(toDate), '<=', 'Date'));
            }
            
            String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);
            system.debug(whereCond);
            string countQuery;
            if(!string.isblank(whereCond)){
                queryForNextRecords = query + ' WHERE '+whereCond+' AND';
                query = query + ' WHERE '+whereCond+' WITH SECURITY_ENFORCED Order by name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Investigator_Check__c WHERE '+ whereCond+' WITH SECURITY_ENFORCED';
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' WITH SECURITY_ENFORCED Order by name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Investigator_Check__c WITH SECURITY_ENFORCED';
            }
            
                totalRecordCount = database.countquery(Countquery);
				List<SObject> invCheckRecords = New List<SObject>();
            	if(test.isRunningTest()){
                    invCheckRecords = database.query('Select '+string.join(checkInApiNames, ',') + ' From DHS_Investigator_Check__c ');   
                }else{
                    // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
                    invCheckRecords = database.query(query);        
               }
                List<Map<String, Object>> invChecksMap = DHSUtils.convertToMapList(invCheckRecords,checkInApiNames);
            integer i = 0;
                for(Map<String, Object> invCheckMap : invChecksMap){
                    Map<String, Object> flattenedObject = DHSUtils.flatten(invCheckMap, '.');
                    if(i==0) firstRecordName = string.valueOf(flattenedObject.get('name'));    
                	lastRecordName = string.valueOf(flattenedObject.get('name'));
                    records.add(flattenedObject);
                }
            
                PageNumber = 1;
                double totalNum = double.valueof(totalRecordCount)/double.valueof(200);
                double floorVal = Math.floor(totalNum);
                double diff = totalNum - floorVal;
                totalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
                system.debug('TotalPages...'+totalPages);
                if(totalRecordCount <= 200){
                    disablePrev = true;
                    disableNext = true;
                    currentRecordCount = totalRecordCount;
                }else{
                    disablePrev = true;   
                    disableNext = false;
                    currentRecordCount = 200; 
                }
            
        } else if(selectedReportType == 'Waivers'){
            list<string> waiversApiNames = New list<string>();
            records = new list<Map<string,object>>();
            labels = New list<string>();
        	apinames = New list<string>();
            List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
            apinames.addAll(getFieldMap('DHS_Waiver_Information__c').get('apinames'));
            waiversApiNames.addAll(getFieldMap('DHS_Waiver_Information__c').get('apinames'));
            labels.addAll(getFieldMap('DHS_Waiver_Information__c').get('labels'));
            system.debug(apinames);
			if(!apinames.contains('name')) waiversApiNames.add('name');
            fetchApinames = waiversApiNames;
            String query = 'Select '+string.join(waiversApiNames, ',') + ' From DHS_Waiver_Information__c ';
            
            String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);
            system.debug(whereCond);
            string countQuery;
            if(!string.isblank(whereCond)){
                queryForNextRecords = query + ' WHERE '+whereCond+' AND';
                query = query + ' WHERE '+whereCond+' Order by name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Waiver_Information__c WHERE '+ whereCond+' WITH SECURITY_ENFORCED';
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Waiver_Information__c WITH SECURITY_ENFORCED';
            }
            
                totalRecordCount = database.countquery(Countquery);
                List<SObject> waiverRecords = New List<SObject>();
                if(test.isRunningTest()){
                    waiverRecords = database.query('Select '+string.join(waiversApiNames, ',') + ' From DHS_Waiver_Information__c WITH SECURITY_ENFORCED');   
                }else{
                    // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
                    waiverRecords = database.query(query);        
               }
                integer i = 0;
                List<Map<String, Object>> waiversMap = DHSUtils.convertToMapList(waiverRecords,waiversApiNames);
                for(Map<String, Object> waiverMap : waiversMap){
                    Map<String, Object> flattenedObject = DHSUtils.flatten(waiverMap, '.');
                    if(i==0) firstRecordName = string.valueOf(flattenedObject.get('name'));    
                	lastRecordName = string.valueOf(flattenedObject.get('name'));
                    records.add(flattenedObject);
                }
                PageNumber = 1;
                double totalNum = double.valueof(totalRecordCount)/double.valueof(200);
                double floorVal = Math.floor(totalNum);
                double diff = totalNum - floorVal;
                totalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
                system.debug('TotalPages...'+totalPages);
                if(totalRecordCount <= 200){
                    disablePrev = true;
                    disableNext = true;
                    currentRecordCount = totalRecordCount;
                }else{
                    disablePrev = true;   
                    disableNext = false;
                    currentRecordCount = 200; 
                }
            
        }
        else if(selectedReportType == 'Investigator DHSReports'){
            reports = new list<ReportRecord>();
            List<string> productionSummaryFields = new List<string>();
            List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
            productionSummaryFields = DHSApexUtil.FetchFields('DHS_Daily_Production_Summary__c');
            String query = 'Select '+string.join(productionSummaryFields, ',') + ' From DHS_Daily_Production_Summary__c ';
            if(fromDate != Null){
                whereCriteria.add(new DHSApexUtil.Criteria('Summary_Date__c',String.valueof(fromDate), '>=', 'Date'));
            }
            if(toDate != Null){
                whereCriteria.add(new DHSApexUtil.Criteria('Summary_Date__c',String.valueof(toDate), '<=', 'Date'));
            }
            if(!whereCriteria.isEmpty()){
                String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);
                query = query + ' WHERE '+whereCond;
            }
            System.debug('query...'+query);
            // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
            list< DHS_Daily_Production_Summary__c > productionSummaries = database.query(query);
            Map<string,Decimal> leadsAccepted = new Map<string,Decimal>();
            Map<string,Decimal> leadsRejected = new Map<string,Decimal>();
            Map<string,Decimal> leadsCompleted = new Map<string,Decimal>();
            set<string> reviewerIds = new set<String>();
            for(DHS_Daily_Production_Summary__c dps:productionSummaries ){
                if(String.isBlank(dps.DHS_Reviewer__c)){
                    continue;
                }
                Decimal acceptedCount = dps.Leads_Accepted__c == null ? 0 : dps.Leads_Accepted__c;
                Decimal rejectedCount = dps.Leads_Rejected__c == null ? 0 : dps.Leads_Rejected__c;
                Decimal completedCount = dps.Leads_Completed__c == null ? 0 : dps.Leads_Completed__c;
                if(!leadsAccepted.containsKey(dps.DHS_Reviewer__c)){
                    leadsAccepted.put(dps.DHS_Reviewer__c,acceptedCount);
                }else{
                    leadsAccepted.put(dps.DHS_Reviewer__c,leadsAccepted.get(dps.DHS_Reviewer__c)+acceptedCount);
                }
                if(!leadsRejected.containsKey(dps.DHS_Reviewer__c)){
                    leadsRejected.put(dps.DHS_Reviewer__c,rejectedCount);
                }else{
                    leadsRejected.put(dps.DHS_Reviewer__c,leadsRejected.get(dps.DHS_Reviewer__c)+rejectedCount);
                }
                if(!leadsCompleted.containsKey(dps.DHS_Reviewer__c)){
                    leadsCompleted.put(dps.DHS_Reviewer__c,completedCount);
                }else{
                    leadsCompleted.put(dps.DHS_Reviewer__c,leadsCompleted.get(dps.DHS_Reviewer__c)+completedCount);
                }
                reviewerIds.add(dps.DHS_Reviewer__c);
            }
            Map<string,user> userMap = new Map<String,user>([select id, firstname,lastname from user where id in:reviewerIds WITH USER_MODE ]);
            
            for(string reviewerId : reviewerIds){
                User reviewer = userMap.get(reviewerId);
                String reviewerName = reviewer == null ? '' : String.join(new List<String>{reviewer.FirstName, reviewer.LastName}, ' ').trim();
                reports.add(new ReportRecord(reviewerName,
                            Integer.valueof(leadsAccepted.get(reviewerId) == null ? 0 : leadsAccepted.get(reviewerId)),Integer.valueof(leadsRejected.get(reviewerId) == null ? 0 : leadsRejected.get(reviewerId)),Integer.valueof(leadsCompleted.get(reviewerId) == null ? 0 : leadsCompleted.get(reviewerId))
                            ));    
            }
            
        }
        showreportstable = true;
        fromDate = null;
        toDate = null;
        
    }
    public boolean showleadstatustrackingpanel{get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public void fetchLeadStatusTrackings(){
        System.debug('selectedleadforstatustracking...'+selectedleadforstatustracking);
        leadStatusTrackings = new list< LeadHistoryRecord >();
            List<string> leadStatusTrackingFields = new List<string>();
            List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
            leadStatusTrackingFields = DHSApexUtil.FetchFields('Lead__History');
            leadStatusTrackingFields.add('createdby.name');
            leadStatusTrackingFields.add('createdby.firstname');
            leadStatusTrackingFields.add('createdby.lastname');
            String query = 'Select '+string.join(leadStatusTrackingFields, ',') + ' From Lead__History ';
            whereCriteria.add(new DHSApexUtil.Criteria('parentid', selectedleadforstatustracking, '='));
            whereCriteria.add(new DHSApexUtil.Criteria('field','Status__c', '='));
            
            DHS_Lead__c lead = [select id,createddate from DHS_Lead__c where id=:selectedleadforstatustracking WITH USER_MODE ];
          
            String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);
            if(string.isNotBlank(whereCond)){
                 query = query + ' WHERE '+whereCond + ' Order By CreatedDate ASC';  
            }  
           
            System.debug('query...'+query);
            // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
            lisT<Lead__History> leadhHistories =  database.query(query);
            integer i =0;
            for(Lead__History lh: leadhHistories){
                integer daysBetween;
                if(i == 0){
                    daysBetween = lead.createddate.date().daysBetween(lh.createddate.date());
                    
                }else{
                    daysBetween = leadhHistories[i-1].createddate.date().daysBetween(lh.createddate.date());
                }
                leadStatusTrackings.add(new LeadHistoryRecord(lh,daysBetween));
                i++;
            }
            showleadstatustrackingpanel = true;
    }
    
    public void onReportTypeSelect(){
        if(selectedReportType == 'Case'){
            cmoUsers = new list<selectoption>();
            cmoUsers.add(new selectoption('DHS_All','All'));
            list<User> users = [Select Id, name,System_Access__c, FirstName, LastName, user_type__c from User Where user_type__c = 'CMO' WITH USER_MODE ];
            for(user u: users){
                if(u.System_Access__c.contains('DHS')){
                cmoUsers.add(new selectoption(u.id,u.LastName+' '+u.FirstName)); 
                }
            }
        }
        if(selectedReportType == 'Lead'){
            investigatorUsers = new list<selectoption>();
            investigatorUsers.add(new selectoption('DHS_All','All'));
            list<User> users = [Select Id, name,System_Access__c, FirstName, LastName, user_type__c from User Where user_type__c = 'INV' WITH USER_MODE ];
            for(user u: users){
                if(u.System_Access__c.contains('DHS')){
                investigatorUsers.add(new selectoption(u.id,u.LastName+' '+u.FirstName)); 
                }
            }
        }
        if(selectedReportType == 'Messages'){
            relatedCasesForMessages = new list<selectoption>();
            relatedCasesForMessages.add(new selectoption('','--None--'));
            list<DHS_Case__c> cases = [Select Id,Case_Number__c From DHS_Case__c where Case_Number__c != NULL WITH USER_MODE ];
            for(DHS_Case__c c: cases){
                relatedCasesForMessages.add(new selectoption(c.id,c.Case_Number__c));   
            }
        }
        showReportsTable = false;
       
    }
    
    Public Class ReportRecord {
        public string subjectFirstName{get;set;}
        public string subjectLastName{get;set;}
        public string caseNumber{get;set;}
        public string caseDueDate{get;set;}
        public string customerDeliveryDate{get;set;}
        public string caseType{get;set;}
        public string caseStatus{get;set;}
        public string caseTaskStatus {Get;set;}
        public string manifest{get;set;}
        public string cmoUser{get;set;}
        public string investigatorUser{get;set;}
        public string rDate{get;set;}
        public string attachmentId {get;set;}
        public string leadType {get;set;}
        public string leadStatus {get;set;}
        public DHS_Message__c message {get;set;}
        public DHS_Investigator_Check__c investigatorCheck {get;set;}
        public DHS_Waiver_Information__c waiver {get;set;}
        public string investigatorName {get;set;}
        public integer leadsAccepted {get;set;}
        public integer leadsRejected {get;set;}
        public integer leadsCompleted {get;set;}
        public integer leadItemNumber {get;set;}
        public string leadContactInformation {get;set;}
        public string leadSourceName {get;set;}
        public string leadcontactName {get;set;}
        public string leadcontactAddress {get;set;}
        public string leadcontactCity {get;set;}
        public string leadcontactState {get;set;}
        public string leadcontactZip {get;set;}
        public string leadcontactOtherInformation {get;set;}
        public string anticipatedCompletedDate{get;set;}
        public string coverageType{get;set;}
        public string assignmentDate {get;set;}
        public string leadId {get;set;}
        public string leadContactMethod {get;set;}
        public string waiverduedate {get;set;}
        public string customercasenumber {get;set;}
        public string subjecttype	{get;set;}
        public ReportRecord(DHS_Message__c message){
            this.message = message;
        }
        public ReportRecord(DHS_Investigator_Check__c investigatorCheck){
            this.investigatorCheck = investigatorCheck;
        }
        public ReportRecord(DHS_Waiver_Information__c waiver){
            this.waiver = waiver;
        }
        public ReportRecord(string investigatorName, integer leadsAccepted, integer leadsRejected, integer leadsCompleted){
            this.investigatorName = investigatorName;
            this.leadsAccepted = leadsAccepted;
            this.leadsRejected = leadsRejected;
            this.leadsCompleted = leadsCompleted;
        }
        
        
public ReportRecord(string subjectFirstName,string subjectLastName, string caseNumber, string customercasenumber, string caseDueDate, string customerDeliveryDate, string caseType, string caseStatus, string caseTaskStatus, string manifest, string cmoUser, string investigatorUser,
                            string waiverduedate, string rDate, string attachmentId, string leadType, string leadStatus,string leadId,string subjecttype){
            this.subjectFirstName = subjectFirstName;
            this.subjectLastName = subjectLastName;
            this.caseNumber = caseNumber;
            this.customercasenumber = customercasenumber;
            this.caseDueDate = caseDueDate;
            this.customerDeliveryDate = customerDeliveryDate;
            this.caseType = caseType;
            this.caseStatus = caseStatus;
            this.caseTaskStatus = caseTaskStatus;
            this.manifest = manifest;
            this.cmoUser = cmoUser;
            this.investigatorUser = investigatorUser;
            this.rDate = rDate;
            this.waiverduedate = waiverduedate;
            this.attachmentId = attachmentId;
            this.leadType = leadType;
            this.leadStatus = leadStatus;
			this.subjecttype = subjecttype;           
        }
        
        public ReportRecord(string subjectFirstName,string subjectLastName, string caseNumber, string caseDueDate, string customerDeliveryDate,string caseType, string caseStatus, string caseTaskStatus,string manifest, string cmoUser, string investigatorUser,
                            string rDate, string attachmentId, string leadType, string leadStatus, integer leadItemNumber, string leadSourceName,
                            string leadcontactName, string leadContactAddress, string leadContactCity, string leadContactState, string leadContactZip,
                            string leadContactOtherInformation, string anticipatedCompletedDate, string coverageType, string assignmentDate, string leadId, string leadContactMethod){

            this.subjectFirstName = subjectFirstName;
            this.subjectLastName = subjectLastName;
            this.caseNumber = caseNumber;
            this.caseDueDate = caseDueDate;
            this.customerDeliveryDate = customerDeliveryDate;
            this.caseType = caseType;
            this.caseStatus = caseStatus;
            this.caseTaskStatus = caseTaskStatus;
            this.manifest = manifest;
            this.cmoUser = cmoUser;
            this.investigatorUser = investigatorUser;
            this.rDate = rDate;
            this.attachmentId = attachmentId;
            this.leadType = leadType;
            this.leadStatus = leadStatus;
            this.leadItemNumber = leadItemNumber;
            this.leadContactInformation = leadContactInformation;
            this.leadSourceName = leadSourceName;
            this.leadcontactName = leadcontactName;
            this.leadContactAddress = leadContactAddress;
            this.leadContactCity= leadContactCity;
            this.leadContactState = leadContactState;
            this.leadContactZip = leadContactZip;
            this.leadContactOtherInformation= leadContactOtherInformation;
            this.anticipatedCompletedDate = anticipatedCompletedDate;
            this.coverageType = coverageType;
            this.assignmentdate = assignmentDate;
            this.leadId = leadId;
            this.leadContactMethod = leadContactMethod;
                                
        }
    
    }
    public void handlePrev(){
        System.debug('queryForNextRecords...'+queryForNextRecords);
        system.debug('firstRecordName....'+firstRecordName);//7474
        system.debug('lastRecordName....'+lastRecordName);//7972
         system.debug('currentRecordCount....'+currentRecordCount);
        PageNumber --;
        records = new list<Map<string,object>>();
        string query = queryForNextRecords + ' name <:firstRecordName  Order by Name desc Limit 200';
        // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
        list<Sobject> recordsData = database.query(query);
        
		List<Map<String, Object>> maps = DHSUtils.convertToMapList(recordsData,fetchApinames);
        for(Integer j=maps.size()-1;j>=0; j--){
            Map<String, Object> flattenedObject = DHSUtils.flatten(maps.get(j), '.');
            records.add(flattenedObject);
            if(j == maps.size()-1) firstRecordName = string.valueOf(maps[j].get('name'));       
			lastRecordName = string.valueOf(maps[j].get('name')); 
        }
        if(pageNumber == 1){
            disablePrev = true;
            disableNext = false ;
        }else{
            disablePrev = false;
            disableNext = false;
        }
        system.debug('firstRecordName....'+firstRecordName);
        system.debug('lastRecordName....'+lastRecordName);
        system.debug('currentRecordCount....'+currentRecordCount);
    }
    public void handleNext(){
        PageNumber ++ ;
        records = new list<Map<string,object>>();
        System.debug('queryForNextRecords...'+queryForNextRecords);
        system.debug('lastRecordName....'+lastRecordName);
        string query = queryForNextRecords + ' name >:lastRecordName  Order by Name asc Limit 200';    
        System.debug('query...'+query);
        // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
        list<Sobject> recordData = database.query(query);
        integer i = 0;
		List<Map<String, Object>> maps = DHSUtils.convertToMapList(recordData,fetchApinames);
		for(Map<String, Object> m : maps){
			Map<String, Object> flattenedObject = DHSUtils.flatten(m, '.');
            records.add(flattenedObject);
			if(i==0) firstRecordName = string.valueOf(flattenedObject.get('name'));    
			lastRecordName = string.valueOf(flattenedObject.get('name'));
            i++;
		}

        if(pageNumber == totalPages){
            disablePrev = false;   
            disableNext = true;
        }else{
            disablePrev = false;
            disableNext = false;
        }
         system.debug('firstRecordName....'+firstRecordName);
        system.debug('lastRecordName....'+lastRecordName);
         system.debug('currentRecordCount....'+currentRecordCount);
    }
    public static Map<String, List<string>> getFieldMap(String reportType) {
        Map<String, List<string>> returnVal = new Map<String, List<string>>();
        List<String> labels = new List<String>();
        List<String> apinames = new List<String>();
    	
        string currentSystem = 'Intel';
        List<DHS_Report_Export__c> temps = [select id,Label__c	,Api_Name__c,Order__c,Report_Type__c,System__c from DHS_Report_Export__c 
                                       where System__c =: currentSystem and Report_Type__c =: reportType
                                        WITH USER_MODE order by Order__c asc];
        for(DHS_Report_Export__c temp : temps){
            if(!apinames.contains(temp.Api_Name__c.tolowercase())){
                labels.add(temp.Label__c);
				apinames.add(temp.Api_Name__c.tolowercase());
            }
        }   
            returnVal.put('labels', labels);
            returnVal.put('apinames', apinames);
        
        return returnVal;
    }
}
