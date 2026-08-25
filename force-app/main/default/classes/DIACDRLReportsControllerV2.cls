public class DIACDRLReportsControllerV2 {
    public user currentUser{get;set;}
    public boolean hasRecords{get;set;}
    public list<Map<string,object>> records {get;set;}
    public list<string> apinames    {get;set;}
    public list<string> fetchApinames   {get;set;}
    public list<string> labels  {get;set;}
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
    public date waiverAcceptedFromDate {get;set;}
    public date waiverAcceptedToDate {get;set;}
    public date extensionAcceptedFromDate {get;set;}
    public date extensionAcceptedToDate {get;set;}
    public boolean showonly90daysfromCaseClosed {get;set;}
    public string selectedTDY {get;set;}
    public list<selectoption> leadTDY {get;set;}
    public transient list<ReportRecord> reports {get;set;}
    public boolean showViewButton {get;set;}
    public boolean showreportstable {get;set;}
    public boolean showonly90daysfromQAcomplete {get;set;}
    public string SelectedRelatedCaseIdForMessages{get;set;}
    public list<selectoption> relatedCasesForMessages {get;set;}
    public string SelectedCaseIdForLeadSearch{get;set;}
    public list<selectoption> messageTypeOptions {get;set;}
    public string selectedMessageType{get;set;}
    public string SelectedCaseNumberForLeadSearch{get;set;}
    public string selectedleadforstatustracking {get;set;}
    //public list<Lead__History> leadStatusTrackings {get;set;}
    public list<LeadHistoryRecord> leadStatusTrackings{get;set;}
    public integer pageNumber {get;set;}
    public integer TotalPages   {get;set;}
    public integer totalRecordCount {get;set;}
    public boolean disablePrev {get;set;}
    public boolean disableNext {get;set;}
    public string queryForNextRecords {get;set;}
    public string lastRecordName {get;set;}
    public string firstRecordName {get;set;}
    public integer currentRecordCount {get;set;}
    public string userType  {get;set;}
    public string contextINVId  {get;set;}
    
    public class LeadHistoryRecord{
        public DIA_Lead__History leadHistory {get;set;}
        public integer numOfDays {get;set;}
        public LeadHistoryRecord(DIA_Lead__History lh, integer nd){
            this.leadHistory = lh;
            this.numOfDays = nd;
        }
    }
    
    public DIACDRLReportsControllerV2(){
        hasRecords = false;
        records = new list<Map<string,object>>();
        labels = New list<string>();
        apinames = New list<string>();
        fetchApinames = New list<string>();
        showReportsTable = false;
        pageNumber = 1; 
        disablePrev = true;
        disableNext = true;
        currentUser = [select id, firstname, lastname, email, user_type__c from User where id=:userinfo.getuserid()];  
        userType = currentUser.user_type__c;
        if(userType == 'INV'){
            contextINVId = currentUser.Id;
        }
        FetchPicklistValues();
        showViewButton = false;
        showreportstable = false;
        showleadstatustrackingpanel = false;
    }
    public void FetchPicklistValues(){
        typesOfReports = new list<selectoption>();
        typesOfReports.add(new selectoption('','--None--'));
        leadTDY = new list<selectoption>();
        leadTDY.add(new selectoption('','--None--'));
        list<string> reportTypes = new list<string>();
        reportTypes.addAll(system.label.DIA_Types_Of_Reports.split(','));
        for(string rt: reportTypes){
            if(currentUser.user_type__c == 'INV'){
                if(rt == 'Check-in/Check-out'){
                    typesOfReports.add(new selectoption(rt,rt)); 
                 }  
            } else{
                if(rt == 'Waiver/Extension'){
                    typesOfReports.add(new selectoption('Waivers',rt)); 
                }else{
                    typesOfReports.add(new selectoption(rt,rt)); 
                }
            }    
        }    
        caseStatus = new list<selectoption>();
        caseStatus.add(new selectoption('All','All'));
        for(String str: ApexUtil.getPickListValuesIntoList('DIA_Case__c', 'Status__c')){
            caseStatus.add(new selectoption(str,str));
        }
        caseTaskStatus = new list<selectoption>();
        caseTaskStatus.add(new selectoption('All','All'));
        for(String str: ApexUtil.getPickListValuesIntoList('DIA_Case__c', 'Current_Task__c')){
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
        leadStatus.add(new selectoption('All','All'));
        for(String str: ApexUtil.getPickListValuesIntoList('DIA_Lead__c', 'Status__c')){
            leadStatus.add(new selectoption(str,str));
        }
        for(String str: ApexUtil.getPickListValuesIntoList('DIA_Lead__c', 'Mark_As_TDY__c')){
            leadTDY.add(new selectoption(str,str));
        }
        
        messageTypeOptions = new list<selectoption>();
        messageTypeOptions.add(new selectoption('','--None--'));
        messageTypeOptions.add(new selectoption('Case Broadcast Message','Case Broadcast Message'));
        messageTypeOptions.add(new selectoption('General Broadcast Message','General Broadcast Message'));
        
    }
    public boolean fiveorlessitemsofcase = false;
    public void RunReportAction(){
    
        if(selectedReportType == 'ROIReport'){
            
            string documentPrefix =  DIA_Document__c.sObjectType.getDescribe().getKeyPrefix();
            list<DIA_Document__c> documents = new list<DIA_Document__c>();
            list<attachment> attachments = new list<attachment>();
            string likeCondition = '%'+documentPrefix;
            string nameCondition = '%'+selectedReportType+'%';
            
            records = new list<Map<string,object>>();
            labels = New list<string>();
            apinames = New list<string>();
            hasRecords = false;
            list<string> roiApiNames = New list<string>();
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            apinames.addAll(getFieldMap('DIA_Document__c').get('apinames'));
            roiApiNames.addAll(getFieldMap('DIA_Document__c').get('apinames'));
            labels.addAll(getFieldMap('DIA_Document__c').get('labels'));
            if(!apinames.contains('name')) roiApiNames.add('name');
            system.debug(roiApiNames);
            fetchApinames = roiApiNames;
            String query =  'Select '+string.join(roiApiNames, ',') + ' From DIA_Document__c ';
            whereCriteria.add(new ApexUtil.Criteria('Name__c','ROIReport','='));
            
            if(fromDate != Null){
                
                Datetime myDatetime = Datetime.newInstance(fromDate, Time.newInstance(0, 0, 0, 0));
				String isoDatetime = myDatetime.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');

                system.debug(isoDatetime);
                whereCriteria.add(new ApexUtil.Criteria('createddate',isoDatetime, '>=','Date'));
            }
            if(toDate != Null){
                Datetime myDatetime = Datetime.newInstance(toDate, Time.newInstance(0, 0, 0, 0));
				String isoDatetime = myDatetime.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');

                system.debug(isoDatetime);
                
                whereCriteria.add(new ApexUtil.Criteria('createddate',isoDatetime, '<=','Date'));
            }
            
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);
            string countQuery;
            if(!string.isblank(where_cond)){
                queryForNextRecords = query + ' WHERE '+where_cond+' AND';
                query = query + ' WHERE '+where_cond+' Order by name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_Document__c WHERE '+ where_cond;
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' WITH SECURITY_ENFORCED Order by name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_Document__c';
            }
            
        totalRecordCount = database.countquery(Countquery);
            system.debug('query...'+query);            
            list<sobject> documentsObj = new list<sobject>();
            Map<Id,DIA_Document__c> docMap = New Map<Id,DIA_Document__c>();
            documents = database.query(query);
            documentsObj = documents;
            docMap.putAll(documents);
            attachments = [Select Id, ParentId, Name from Attachment where parentid in: docMap.keyset()];
            Map<string,string> documentNattachmentMap = new Map<string,string>();
            for(attachment att: attachments){
                 documentNattachmentMap.put(att.parentId,att.id);
            }
            if(!documentsObj.isEmpty()){
                hasRecords = true;
                List<Map<String, Object>> roisMap = utils.convertToMapList(documentsObj,roiApiNames);
                integer i = 0;
                for(Map<String, Object> roiMap : roisMap){
                    
                    Map<String, Object> flattenedObject = utils.flatten(roiMap, '.');
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
            system.debug(records);
            PageNumber = 1;
            double totalNum = double.valueof(totalRecordCount)/double.valueof(200);
            double floorVal = Math.floor(totalNum);
            double diff = totalNum - floorVal;
            TotalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
            system.debug('TotalPages...'+TotalPages);
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
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            apinames.addAll(getFieldMap('DIA_Case__c').get('apinames'));
            caseApiNames.addAll(getFieldMap('DIA_Case__c').get('apinames'));
            labels.addAll(getFieldMap('DIA_Case__c').get('labels'));
            if(!apinames.contains('name')) caseApiNames.add('name');
            system.debug(caseApiNames);
            fetchApinames = caseApiNames;
            String query =  'Select '+string.join(caseApiNames, ',') + ' From DIA_Case__c ';
            if(selectedCaseTaskStatus != 'All'){
                whereCriteria.add(new ApexUtil.Criteria('Current_Task__c',selectedCaseTaskStatus,'='));
            }
            if(selectedCaseStatus != 'All'){
                whereCriteria.add(new ApexUtil.Criteria('Status__c',selectedCaseStatus,'='));
            }
            if(fromDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('Submission_Date__c',String.valueof(fromDate), '>=', 'Date'));
            }
            if(toDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('Submission_Date__c',String.valueof(toDate), '<=', 'Date'));
            }
            if(waiverAcceptedFromDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('Waiver_Approved_Date__c',String.valueof(waiverAcceptedFromDate), '>=', 'Date'));
            }
            if(waiverAcceptedToDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('Waiver_Approved_Date__c',String.valueof(waiverAcceptedToDate), '<=', 'Date'));
            }
            if(extensionAcceptedFromDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('Extension_Approved_Date__c',String.valueof(extensionAcceptedFromDate), '>=', 'Date'));
            }
            if(extensionAcceptedToDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('Extension_Approved_Date__c',String.valueof(extensionAcceptedToDate), '<=', 'Date'));
            }
            if(showonly90daysfromCaseClosed == true){
                whereCriteria.add(new ApexUtil.Criteria('Days_from_Date_Closed__c','90', '>=','Integer'));
            }
            if(selectedCMoUser != 'All'){
                whereCriteria.add(new ApexUtil.Criteria('Assigned_to__c',selectedCMoUser, '='));    
            }
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);
            string countQuery;
            if(!string.isblank(where_cond)){
                queryForNextRecords = query + ' WHERE '+where_cond+' AND';
                query = query + ' WHERE '+where_cond+' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_Case__c WHERE '+ where_cond;
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' WITH SECURITY_ENFORCED Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_Case__c';
            }
            
        totalRecordCount = database.countquery(Countquery);
            system.debug(query);
        List<SObject> caseRecords = New List<SObject>();
        if(test.isRunningTest()){
            caseRecords = database.query('Select '+string.join(caseApiNames, ',') + ' From DIA_Case__c '); 
        }else{
            caseRecords = database.query(query);        
       }
            if(!caseRecords.isEmpty()){
                hasRecords = true;
                List<Map<String, Object>> casesMap = utils.convertToMapList(caseRecords,caseApiNames);
                integer i = 0;
                for(Map<String, Object> caseMap : casesMap){
                    
                    Map<String, Object> flattenedObject = utils.flatten(caseMap, '.');
                    if(i==0) firstRecordName = string.valueOf(flattenedObject.get('name'));    
                    lastRecordName = string.valueOf(flattenedObject.get('name'));
                    records.add(flattenedObject);
                }
            }
         PageNumber = 1;
        double totalNum = double.valueof(totalRecordCount)/double.valueof(200);
        double floorVal = Math.floor(totalNum);
        double diff = totalNum - floorVal;
        TotalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
        system.debug('TotalPages...'+TotalPages);
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
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            apinames.addAll(getFieldMap('DIA_Lead__c').get('apinames'));
            leadApiNames.addAll(getFieldMap('DIA_Lead__c').get('apinames'));
            labels.addAll(getFieldMap('DIA_Lead__c').get('labels'));
            system.debug(apinames);
            if(!apinames.contains('name')) leadApiNames.add('name');
            fetchApinames = leadApiNames;
            String query = 'Select '+string.join(leadApiNames, ',') + ' From DIA_Lead__c ';
            if(SelectedLeadStatus != 'All'){
                whereCriteria.add(new ApexUtil.Criteria('status__c',SelectedLeadStatus,'='));
            }
            if(fromDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('completed_date__c',String.valueof(fromDate), '>=', 'Date'));
            }
            if(toDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('completed_date__c',String.valueof(toDate), '<=', 'Date'));
            }
            if(selectedInvestigatorUser != 'All'){
                whereCriteria.add(new ApexUtil.Criteria('assigned_to__c',selectedInvestigatorUser, '='));    
            }
            if(showonly90daysfromQAcomplete == true){
                whereCriteria.add(new ApexUtil.Criteria('Days_from_QA_Review_Completed__c','90', '>=','Integer'));
            }
            System.debug('SelectedCaseNumberForLeadSearch...'+SelectedCaseNumberForLeadSearch);
            if(String.isnotblank(SelectedCaseNumberForLeadSearch)){
                whereCriteria.add(new ApexUtil.Criteria('case__r.case_number__c',SelectedCaseNumberForLeadSearch, '='));    
            }
            if(selectedTDY != null){
                whereCriteria.add(new ApexUtil.Criteria('Mark_As_TDY__c', selectedTDY,'='));
            }
            
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);
            system.debug(where_cond);
            string countQuery;
            if(!string.isblank(where_cond)){
                queryForNextRecords = query + ' WHERE '+where_cond+' AND';
                query = query + ' WHERE '+where_cond+' WITH SECURITY_ENFORCED Order by name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_Lead__c WHERE '+ where_cond+' WITH SECURITY_ENFORCED';
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' Order by name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_Lead__c WITH SECURITY_ENFORCED';
            }
            
        totalRecordCount = database.countquery(Countquery);
        //list<lead__c> Leads = new list<lead__c>();
        List<SObject> leadRecords = New List<SObject>();
        if(test.isRunningTest()){
            leadRecords = database.query('Select '+string.join(leadApiNames, ',') + ' From DIA_Lead__c WITH SECURITY_ENFORCED');   
        }else{
            leadRecords = database.query(query);        
       }
            System.debug('query...'+query);
            
        List<Map<String, Object>> leadsMap = utils.convertToMapList(leadRecords,leadApiNames);
            integer i = 0;
        for(Map<String, Object> leadMap : leadsMap){
            system.debug('leadMap...'+leadMap);
            Map<String, Object> flattenedObject = utils.flatten(leadMap, '.');
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
            TotalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
            system.debug('TotalPages...'+TotalPages);
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
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            apinames.addAll(getFieldMap('DIA_Message__c').get('apinames'));
            messageApiNames.addAll(getFieldMap('DIA_Message__c').get('apinames'));
            labels.addAll(getFieldMap('DIA_Message__c').get('labels'));
            system.debug(apinames);
            if(!apinames.contains('name')) messageApiNames.add('name');
            fetchApinames = messageApiNames;
            String query = 'Select '+string.join(messageApiNames, ',') + ' From DIA_Message__c ';
            if(selectedMessageType == 'Case Broadcast Message' ){
                if(SelectedRelatedCaseIdForMessages != Null){
                    whereCriteria.add(new ApexUtil.Criteria('case__c',SelectedRelatedCaseIdForMessages,'='));
                }
            }else{
                whereCriteria.add(new ApexUtil.Criteria('case__c','','='));
            }
            
           
            if(fromDate != Null){
                //Datetime DatetimeVal = Datetime.newInstance(fromDate, Time.newInstance(0, 0, 0, 0));
                //String isoDatetime = DatetimeVal.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
				//System.debug('ISO Datetime: ' + isoDatetime);
                whereCriteria.add(new ApexUtil.Criteria('MessageCreatedDate__c',string.valueOf(fromDate), '>=','Date'));
            }
            if(toDate != Null){
                //Datetime DatetimeVal = Datetime.newInstance(toDate, Time.newInstance(0, 0, 0, 0));
                //String isoDatetime = DatetimeVal.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
				//System.debug('ISO Datetime: ' + isoDatetime);
                
                whereCriteria.add(new ApexUtil.Criteria('MessageCreatedDate__c',string.valueOf(toDate), '<=','Date'));
            }  
            
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);
            system.debug(where_cond);
            string countQuery;
            if(!string.isblank(where_cond)){
                queryForNextRecords = query + ' WHERE '+where_cond+' AND';
                query = query + ' WHERE '+where_cond+' WITH SECURITY_ENFORCED Order by name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_Message__c WHERE '+ where_cond+' WITH SECURITY_ENFORCED';
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' Order by name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_Message__c WITH SECURITY_ENFORCED';
            }
                totalRecordCount = database.countquery(Countquery);
                //list<Message__c> messages = new list<Message__c>();
            List<SObject> messageRecords = New List<SObject>();
                if(test.isRunningTest()){
                    messageRecords = database.query('Select '+string.join(messageApiNames, ',') + ' From DIA_Message__c '  );   
                }else{
                    messageRecords = database.query(query);        
               }
            system.debug('MessageRecords'+messageRecords);
            List<Map<String, Object>> messagesMap = utils.convertToMapList(messageRecords,messageApiNames);
            integer i = 0;
            for(Map<String, Object> messageMap : messagesMap){
                Map<String, Object> flattenedObject = utils.flatten(messageMap, '.');
                if(i==0) firstRecordName = string.valueOf(flattenedObject.get('name'));    
                lastRecordName = string.valueOf(flattenedObject.get('name'));
                records.add(flattenedObject);
            }
                PageNumber = 1;
                double totalNum = double.valueof(totalRecordCount)/double.valueof(200);
                double floorVal = Math.floor(totalNum);
                double diff = totalNum - floorVal;
                TotalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
                system.debug('TotalPages...'+TotalPages);
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
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            apinames.addAll(getFieldMap('DIA_Investigator_Check__c').get('apinames'));
            checkInApiNames.addAll(getFieldMap('DIA_Investigator_Check__c').get('apinames'));
            labels.addAll(getFieldMap('DIA_Investigator_Check__c').get('labels'));
            system.debug(apinames);
            if(!apinames.contains('name')) checkInApiNames.add('name');
            fetchApinames = checkInApiNames;
            String query = 'Select '+string.join(checkInApiNames, ',') + ' From DIA_Investigator_Check__c ';
            whereCriteria.add(new ApexUtil.Criteria('Type__c', 'CheckOut', '='));
            if(currentUser.user_type__c == 'INV'){
                whereCriteria.add(new ApexUtil.Criteria('TimeSheet__r.User__c', userinfo.getuserid(), '='));
            }
            if(fromDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('TimeSheet__r.Date__c',String.valueof(fromDate), '>=', 'Date'));
            }
            if(toDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('TimeSheet__r.Date__c',String.valueof(toDate), '<=', 'Date'));
            }
            
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);
            system.debug(where_cond);
            string countQuery;
            if(!string.isblank(where_cond)){
                queryForNextRecords = query + ' WHERE '+where_cond+' AND';
                query = query + ' WHERE '+where_cond+' WITH SECURITY_ENFORCED Order by name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_Investigator_Check__c WHERE '+ where_cond+' WITH SECURITY_ENFORCED';
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' WITH SECURITY_ENFORCED Order by name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_Investigator_Check__c WITH SECURITY_ENFORCED';
            }
            
                totalRecordCount = database.countquery(Countquery);
                List<SObject> invCheckRecords = New List<SObject>();
                if(test.isRunningTest()){
                    invCheckRecords = database.query('Select '+string.join(checkInApiNames, ',') + ' From DIA_Investigator_Check__c ');   
                }else{
                    invCheckRecords = database.query(query);        
               }
                List<Map<String, Object>> invChecksMap = utils.convertToMapList(invCheckRecords,checkInApiNames);
            integer i = 0;
                for(Map<String, Object> invCheckMap : invChecksMap){
                    Map<String, Object> flattenedObject = utils.flatten(invCheckMap, '.');
                    if(i==0) firstRecordName = string.valueOf(flattenedObject.get('name'));    
                    lastRecordName = string.valueOf(flattenedObject.get('name'));
                    records.add(flattenedObject);
                }
            
                PageNumber = 1;
                double totalNum = double.valueof(totalRecordCount)/double.valueof(200);
                double floorVal = Math.floor(totalNum);
                double diff = totalNum - floorVal;
                TotalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
                system.debug('TotalPages...'+TotalPages);
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
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            apinames.addAll(getFieldMap('DIA_Waiver_Information__c').get('apinames'));
            waiversApiNames.addAll(getFieldMap('DIA_Waiver_Information__c').get('apinames'));
            labels.addAll(getFieldMap('DIA_Waiver_Information__c').get('labels'));
            system.debug(apinames);
            if(!apinames.contains('name')) waiversApiNames.add('name');
            fetchApinames = waiversApiNames;
            String query = 'Select '+string.join(waiversApiNames, ',') + ' From DIA_Waiver_Information__c ';
            
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);
            system.debug(where_cond);
            string countQuery;
            if(!string.isblank(where_cond)){
                queryForNextRecords = query + ' WHERE '+where_cond+' AND';
                query = query + ' WHERE '+where_cond+' Order by name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_Waiver_Information__c WHERE '+ where_cond+' WITH SECURITY_ENFORCED';
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_Waiver_Information__c WITH SECURITY_ENFORCED';
            }
            
                totalRecordCount = database.countquery(Countquery);
                List<SObject> waiverRecords = New List<SObject>();
                if(test.isRunningTest()){
                    waiverRecords = database.query('Select '+string.join(waiversApiNames, ',') + ' From DIA_Waiver_Information__c WITH SECURITY_ENFORCED');   
                }else{
                    waiverRecords = database.query(query);        
               }
                integer i = 0;
                List<Map<String, Object>> waiversMap = utils.convertToMapList(waiverRecords,waiversApiNames);
                for(Map<String, Object> waiverMap : waiversMap){
                    Map<String, Object> flattenedObject = utils.flatten(waiverMap, '.');
                    if(i==0) firstRecordName = string.valueOf(flattenedObject.get('name'));    
                    lastRecordName = string.valueOf(flattenedObject.get('name'));
                    records.add(flattenedObject);
                }
                PageNumber = 1;
                double totalNum = double.valueof(totalRecordCount)/double.valueof(200);
                double floorVal = Math.floor(totalNum);
                double diff = totalNum - floorVal;
                TotalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
                system.debug('TotalPages...'+TotalPages);
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
        else if(selectedReportType == 'Investigator Reports'){
            reports = new list<ReportRecord>();
            List<string> productionSummaryFields = new List<string>();
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            productionSummaryFields = ApexUtil.FetchFields('DIA_Daily_Production_Summary__c');
            String query = 'Select '+string.join(productionSummaryFields, ',') + ' From DIA_Daily_Production_Summary__c ';
            if(fromDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('Summary_Date__c',String.valueof(fromDate), '>=', 'Date'));
            }
            if(toDate != Null){
                whereCriteria.add(new ApexUtil.Criteria('Summary_Date__c',String.valueof(toDate), '<=', 'Date'));
            }
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
            query = query + ' WHERE '+where_cond; 
            System.debug('query...'+query);
            list< DIA_Daily_Production_Summary__c > productionSummaries = database.query(query);
            Map<string,Decimal> leadsAccepted = new Map<string,Decimal>();
            Map<string,Decimal> leadsRejected = new Map<string,Decimal>();
            Map<string,Decimal> leadsCompleted = new Map<string,Decimal>();
            set<string> reviewerIds = new set<String>();
            for(DIA_Daily_Production_Summary__c dps:productionSummaries ){
                if(!leadsAccepted.containsKey(dps.reviewer__c)){
                    leadsAccepted.put(dps.reviewer__c,dps.Leads_Accepted__c);
                }else{
                    leadsAccepted.put(dps.reviewer__c,leadsAccepted.get(dps.reviewer__c)+dps.Leads_Accepted__c);
                }
                if(!leadsRejected.containsKey(dps.reviewer__c)){
                    leadsRejected.put(dps.reviewer__c,dps.Leads_Rejected__c);
                }else{
                    leadsRejected.put(dps.reviewer__c,leadsRejected.get(dps.reviewer__c)+dps.Leads_Rejected__c);
                }
                if(!leadsCompleted.containsKey(dps.reviewer__c)){
                    leadsCompleted.put(dps.reviewer__c,dps.Leads_Completed__c);
                }else{
                    leadsCompleted.put(dps.reviewer__c,leadsCompleted.get(dps.reviewer__c)+dps.Leads_Completed__c);
                }
                reviewerIds.add(dps.reviewer__C);
            }
            Map<string,user> userMap = new Map<String,user>([select id, firstname,lastname from user where id in:reviewerIds]);
            
            for(string reviewerId : reviewerIds){
                reports.add(new ReportRecord(userMap.get(reviewerId).FirstName+' '+userMap.get(reviewerId).LastName,
                            Integer.valueof(leadsAccepted.get(reviewerId)),Integer.valueof(leadsRejected.get(reviewerId)),Integer.valueof(leadsCompleted.get(reviewerId))
                            ));    
            }
            
        }
        showreportstable = true;
        fromDate = null;
        toDate = null;
    }
    public boolean showleadstatustrackingpanel{get;set;}
    public void FetchLeadStatusTrackings(){
        System.debug('selectedleadforstatustracking...'+selectedleadforstatustracking);
        leadStatusTrackings = new list< LeadHistoryRecord >();
            List<string> leadStatusTrackingFields = new List<string>();
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            leadStatusTrackingFields = ApexUtil.FetchFields('DIA_Lead__History');
            leadStatusTrackingFields.add('createdby.name');
            leadStatusTrackingFields.add('createdby.firstname');
            leadStatusTrackingFields.add('createdby.lastname');
            String query = 'Select '+string.join(leadStatusTrackingFields, ',') + ' From DIA_Lead__History ';
            whereCriteria.add(new ApexUtil.Criteria('parentid', selectedleadforstatustracking, '='));
            whereCriteria.add(new ApexUtil.Criteria('field','status__C', '='));
            
            DIA_Lead__c lead = [select id,createddate from DIA_Lead__c where id=:selectedleadforstatustracking];
          
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);
            if(string.isNotBlank(where_cond)){
                 query = query + ' WHERE '+where_cond + ' Order By CreatedDate ASC';  
            }  
           
            System.debug('query...'+query);
            lisT<DIA_Lead__History> leadhHistories =  database.query(query);
            integer i =0;
            for(DIA_Lead__History lh: leadhHistories){
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
    
    public void OnReportTypeSelect(){
        if(selectedReportType == 'Case'){
            cmoUsers = new list<selectoption>();
            cmoUsers.add(new selectoption('All','All'));
            list<User> users = [Select Id, name, system_access__c, FirstName, LastName, user_type__c from User Where user_type__c = 'CMO' order by LastName];
            for(user u: users){
                if(u.system_access__c.contains('DIA')){
                cmoUsers.add(new selectoption(u.id,u.LastName+' '+u.FirstName)); 
                }
            }
        }
        if(selectedReportType == 'Lead'){
            investigatorUsers = new list<selectoption>();
            investigatorUsers.add(new selectoption('All','All'));
            list<string> userTypesEligibleForLeadAssignment = new list<string>();
            list< User_Permission__mdt > userPermissions = [select id, user_type__c, LeadDashboard_Assignment_IncludeUsers__c  from
                                                           User_Permission__mdt where LeadDashboard_Assignment_IncludeUsers__c = true];
            for(User_Permission__mdt up: userPermissions){
                userTypesEligibleForLeadAssignment.add(up.user_type__c);    
            }
            
            list<User> users = [Select Id, name, system_access__c, FirstName, LastName, user_type__c from User Where user_type__c IN : userTypesEligibleForLeadAssignment order by LastName];
            for(user u: users){
                if(u.system_access__c.contains('DIA')){
                investigatorUsers.add(new selectoption(u.id,u.LastName+' '+u.FirstName));  
                }
            }
        }
        if(selectedReportType == 'Messages'){
            relatedCasesForMessages = new list<selectoption>();
            relatedCasesForMessages.add(new selectoption('','--None--'));
            list<DIA_Case__c> cases = [Select Id,case_number__c From DIA_Case__c where case_number__c != NULL];
            for(DIA_Case__c c: cases){
                relatedCasesForMessages.add(new selectoption(c.id,c.case_number__c));   
            }
        }
        showreportstable = false;
       
    }
    
    Public Class ReportRecord {
        public string subjectFirstName{get;set;}
        public string subjectLastName{get;set;}
        public string caseNumber{get;set;}
        public date caseDueDate{get;set;}
        public date customerDeliveryDate{get;set;}
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
        public DIA_message__c message {get;set;}
        public DIA_Investigator_Check__c investigatorCheck {get;set;}
        public DIA_Waiver_Information__c waiver {get;set;}
        public string investigatorName {get;set;}
        public integer leadsAccepted {get;set;}
        public integer leadsRejected {get;set;}
        public integer leadsCompleted {get;set;}
        public integer leadItemNumber {get;set;}
        public string leadContactInformation {get;set;}
        public string leadSourceName {get;set;}
        public decimal leadPrice {get;set;}
        public string leadcontactName {get;set;}
        public string leadcontactAddress {get;set;}
        public string leadcontactCity {get;set;}
        public string leadcontactState {get;set;}
        public string leadcontactZip {get;set;}
        public string leadcontactOtherInformation {get;set;}
        public date AnticipatedCompletedDate{get;set;}
        public string coverageType{get;set;}
        public date assignmentDate {get;set;}
        public string leadId {get;set;}
        public string leadContactMethod {get;set;}
        public date waiverduedate {get;set;}
        public string customercasenumber {get;set;}
        public date extensionDueDate{get;set;}
        public decimal  daysfromqacompleted{get;set;}
        public datetime createdDate{get;set;}
        public ReportRecord(DIA_message__c message){
            this.message = message;
        }
        public ReportRecord(DIA_Investigator_Check__c investigatorCheck){
            this.investigatorCheck = investigatorCheck;
        }
        public ReportRecord(DIA_Waiver_Information__c waiver){
            this.waiver = waiver;
        }
        public ReportRecord(string investigatorName, integer leadsAccepted, integer leadsRejected, integer leadsCompleted){
            this.investigatorName = investigatorName;
            this.leadsAccepted = leadsAccepted;
            this.leadsRejected = leadsRejected;
            this.leadsCompleted = leadsCompleted;
        }
        
        
        public ReportRecord(string subjectFirstName,string subjectLastName, string caseNumber, string customercasenumber, date caseDueDate, date customerDeliveryDate, string caseType, string caseStatus, string caseTaskStatus, string manifest, string cmoUser, string investigatorUser,
                            string rDate,date waiverduedate,date extensionDueDate,  string attachmentId, string leadType, string leadStatus,string leadId){
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
            this.extensionDueDate= extensionDueDate;
            this.attachmentId = attachmentId;
            this.leadType = leadType;
            this.leadStatus = leadStatus;
            
        }
        
        public ReportRecord(string subjectFirstName,string subjectLastName, string caseNumber, date caseDueDate,date extensionDueDate, date customerDeliveryDate,string customercaseNumber, string caseStatus, string caseTaskStatus,string manifest, string cmoUser, string investigatorUser,
                            string rDate, string attachmentId, string leadType, string leadStatus, integer leadItemNumber, string leadSourceName,
                            string leadcontactName, string leadContactAddress, string leadContactCity, string leadContactState, string leadContactZip,
                            string leadContactOtherInformation, date AnticipatedCompletedDate, string coverageType, date assignmentDate, string leadId, string leadContactMethod,decimal leadPrice,decimal daysfromqacompleted,datetime createdDate){

            this.subjectFirstName = subjectFirstName;
            this.subjectLastName = subjectLastName;
            this.caseNumber = caseNumber;
            this.caseDueDate = caseDueDate;
            this.extensionDueDate = extensionDueDate;
            this.customerDeliveryDate = customerDeliveryDate;
            this.customercaseNumber = customercaseNumber;
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
            this.AnticipatedCompletedDate = AnticipatedCompletedDate;
            this.coverageType = coverageType;
            this.assignmentdate = assignmentDate;
            this.leadId = leadId;
            this.leadContactMethod = leadContactMethod;
            this.leadPrice = leadPrice;
            this.daysfromqacompleted = daysfromqacompleted;
            this.createdDate = createdDate;
            this.customercaseNumber = customercaseNumber;
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
        list<Sobject> recordsData = database.query(query);
        
        List<Map<String, Object>> maps = utils.convertToMapList(recordsData,fetchApinames);
        for(Integer j=maps.size()-1;j>=0; j--){
            Map<String, Object> flattenedObject = utils.flatten(maps.get(j), '.');
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
        list<Sobject> recordData = database.query(query);
        integer i = 0;
        List<Map<String, Object>> maps = utils.convertToMapList(recordData,fetchApinames);
        for(Map<String, Object> m : maps){
            Map<String, Object> flattenedObject = utils.flatten(m, '.');
            records.add(flattenedObject);
            if(i==0) firstRecordName = string.valueOf(flattenedObject.get('name'));    
            lastRecordName = string.valueOf(flattenedObject.get('name'));
            i++;
        }

        if(pageNumber == TotalPages){
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
        
        string currentSystem = 'BI';
        List<Report_Export__c> temps = [select id,Label__c  ,Api_Name__c,Order__c,Report_Type__c,System__c from Report_Export__c 
                                       where System__c =: currentSystem and Report_Type__c =: reportType
                                       order by Order__c asc];
        for(Report_Export__c temp : temps){
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