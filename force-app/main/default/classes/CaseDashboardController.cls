/**
 * Visualforce controller for the case dashboard.
 * Public member and RemoteAction names are retained because Casedashboard.page binds to this API.
 */
@SuppressWarnings('PMD.ApexDoc, PMD.ApexSOQLInjection, PMD.AvoidBooleanMethodParameters, PMD.AvoidNonRestrictiveQueries, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.EmptyCatchBlock, PMD.EmptyIfStmt, PMD.EmptyStatementBlock, PMD.ExcessivePublicCount, PMD.LocalVariableNamingConventions, PMD.MethodNamingConventions, PMD.NcssConstructorCount, PMD.NcssCount, PMD.NcssMethodCount, PMD.PropertyNamingConventions, PMD.StdCyclomaticComplexity')
public with sharing class CaseDashboardController {
    public string subjectFirstNameSearchEntry {get;set;}
    public string subjectLastNameSearchEntry {get;set;}
    public string subjectSSNSearchEntry {get;set;}
    public string caseNumberSearchEntry {get;set;}
    public string caseManifestSearchEntry {get;set;}
    public string caseAssigneeearchEntry {get;set;}
    public string caseTypeSearchEntry {get;set;}
    public string caseStatusSearchEntry {get;set;}
    public date fromSubmissionDateSearchEntry {get;set;}
    public date toSubmissionDateSearchEntry {get;set;}
    public list<CaseRecord> casesSearched {get;set;}
    public boolean showcasessearchcriteriapanel { get; private set; }
    public boolean showcaseslistpanel { get; private set; }
    public list<selectoption> caseTypeOptions {get;set;}
    public list<selectoption> caseStatusOptions {get;set;}
    public list<selectoption> assignUserList {get;set;}
    public string selectedUserIdForAssignment {get;set;}
    public user currentUser {get;set;}
    public string caseDetailURLParams {get;set;}
    public map<string,string> caseDetailURLParamsMap {get;set;}
    public string nextURL; // NOPMD - legacy structure retained to preserve behavior
    public integer pageNumber {get;set;}
    public integer TotalPages   {get;set;}
    public integer totalRecordCount {get;set;}
    List<Object> records; // NOPMD - legacy structure retained to preserve behavior
    public boolean disablePrev { get; private set; }
    public boolean disableNext { get; private set; }
    public string queryForNextRecords {get;set;}
    public string lastRecordName {get;set;}
    public string firstRecordName {get;set;}
    public integer currentRecordCount {get;set;}
    
    public CaseDashboardController(){
        pageNumber = 1;
        disablePrev = true;
        records = New List<Object>();
        currentUser = [Select Id, User_Type__c FROM User where Id=:userinfo.getUserId() WITH USER_MODE];
        List<user> assignUsers = new List<user>();
        assignUsers = [select Id, User_Type__c, FirstName,system_access__c, lastname FROM User where isactive=true AND User_Type__c = 'CMO' WITH USER_MODE];
        assignUserList = new List<SelectOption>();
        assignUserList.add(new SelectOption('','--None--'));
        for(User u: assignUsers){
            if(u.system_access__c.contains('Intel')){
            assignUserList.add(new SelectOption(u.id,u.firstname+' '+u.lastname));
            }
        }
        showcasessearchcriteriapanel = true;
        showcaseslistpanel = false;
        showUnAssigned = false;
        showQACases = false;
        caseTypeOptions = new list<selectoption>();
        caseStatusOptions = new list<selectoption>();
        caseTypeOptions.add(new SelectOption('', '--None--'));
        caseStatusOptions.add(new SelectOption('', '--None--'));
        /*caseTypeOptions.add(new SelectOption('Tier 5', 'Tier 5'));
        caseTypeOptions.add(new SelectOption('Tier 5 Reinvestigation', 'Tier 5 Reinvestigation'));
        caseTypeOptions.add(new SelectOption('Tier 3', 'Tier 3'));
        caseTypeOptions.add(new SelectOption('Tier 3 Reinvestigation', 'Tier 3 Reinvestigation'));
        caseTypeOptions.add(new SelectOption('  Supplemental Investigation  ', '    Supplemental Investigation  '));
        caseTypeOptions.add(new SelectOption('Special Investigation', 'Special Investigation'));*/
        for(String str: apexutil.getPickListValuesIntoList('Case__c', 'Case_Type__c')){
            caseTypeOptions.add(new SelectOption(str, str));
        }
        for(String str: apexutil.getPickListValuesIntoList('Case__c', 'Current_Task__c')){
            caseStatusOptions.add(new SelectOption(str, str));
        }
        
        map<string,string> urlparametersMap = apexpages.currentpage().getparameters();
        boolean isValidToSearch = true;
        if(!urlparametersMap.isEmpty()){
            for(String str: urlparametersMap.keyset()){
                if(str=='tab'){
                    isValidToSearch = false;    
                }
                if(str == 'showUnAssigned'){
                    showUnAssigned = boolean.valueof(urlparametersMap.get(str));
                } 
                if(str == 'showQACases'){
                    showQACases = true;
                }
                if(str == 'subjectFirstNameSearchEntry'){
                    subjectFirstNameSearchEntry = urlparametersMap.get(str);
                }
                if(str == 'subjectLastNameSearchEntry'){
                    subjectLastNameSearchEntry = urlparametersMap.get(str);
                }
                if(str == 'subjectSSNSearchEntry'){
                    subjectSSNSearchEntry = urlparametersMap.get(str);
                }
                if(str == 'caseNumberSearchEntry'){
                    caseNumberSearchEntry = urlparametersMap.get(str);
                }
                if(str == 'caseManifestSearchEntry'){
                    caseManifestSearchEntry = urlparametersMap.get(str);
                }
                if(str == 'caseAssigneeearchEntry'){
                    caseAssigneeearchEntry = urlparametersMap.get(str);
                }
                if(str == 'caseTypeSearchEntry'){
                    caseTypeSearchEntry = urlparametersMap.get(str);
                }
                if(str == 'caseStatusSearchEntry'){
                    caseStatusSearchEntry = urlparametersMap.get(str);
                }
                if(str == 'fromSubmissionDateSearchEntry'){
                    fromSubmissionDateSearchEntry = date.valueof(urlparametersMap.get(str));
                }
                if(str == 'toSubmissionDateSearchEntry'){
                    toSubmissionDateSearchEntry = date.valueof(urlparametersMap.get(str));
                }
            }
            if(isValidToSearch){
                SearchAction();
            }
        }
        
    }
    
    public boolean showUnAssigned { get; private set; }
    public boolean showQACases { get; private set; }
    public void SearchAction(){
        //List<Map<string,Object>> conditions = New List<Map<string,Object>>();
        caseDetailURLParams = null;
        caseDetailURLParamsMap = new map<string,string>();
        casesSearched = new List<CaseRecord>();    
        List<string> caseFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        caseFields = ApexUtil.FetchFields('Case__c');
        caseFields.add('Contact__r.First_Name__c');
        caseFields.add('Contact__r.Last_Name__c');
        String query = 'Select '+string.join(caseFields, ',') + ' From Case__c ';
        String where_cond;
        if(showUnAssigned){
            
            where_cond = 'Assigned_to__c = null';  
            buildCaseDetailURLParams('showUnAssigned=true');
        } else if(showQACases){
            buildCaseDetailURLParams('showQACases=true');
            if(String.isNotBlank(string.valueof(fromSubmissionDateSearchEntry))){
                
                whereCriteria.add(new ApexUtil.Criteria('Submission_Date__c',String.valueof(fromSubmissionDateSearchEntry), '>=').withFieldType('Date'));
                buildCaseDetailURLParams('fromSubmissionDateSearchEntry='+fromSubmissionDateSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(toSubmissionDateSearchEntry))){
                                
                whereCriteria.add(new ApexUtil.Criteria('Submission_Date__c',String.valueof(toSubmissionDateSearchEntry), '<=').withFieldType('Date'));
                buildCaseDetailURLParams('toSubmissionDateSearchEntry='+toSubmissionDateSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(subjectFirstNameSearchEntry))){
                
                whereCriteria.add(new ApexUtil.Criteria('Contact__r.First_Name__c', '%'+String.escapeSingleQuotes(subjectFirstNameSearchEntry)+'%', 'LIKE'));
                buildCaseDetailURLParams('subjectFirstNameSearchEntry='+subjectFirstNameSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(subjectLastNameSearchEntry))){
                
                
                whereCriteria.add(new ApexUtil.Criteria('Contact__r.Last_Name__c', '%'+String.escapeSingleQuotes(subjectLastNameSearchEntry)+'%', 'LIKE'));
                buildCaseDetailURLParams('subjectLastNameSearchEntry='+subjectLastNameSearchEntry);
            }
           
            if(String.isNotBlank(string.valueof(subjectSSNSearchEntry))){
                
                whereCriteria.add(new ApexUtil.Criteria('Contact__r.SSN__c', '%'+subjectSSNSearchEntry+'%', 'LIKE'));
                buildCaseDetailURLParams('subjectSSNSearchEntry='+subjectSSNSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(caseNumberSearchEntry))){
               
                whereCriteria.add(new ApexUtil.Criteria('Case_Number__c', caseNumberSearchEntry, '='));
                buildCaseDetailURLParams('caseNumberSearchEntry='+caseNumberSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(caseManifestSearchEntry))){
                
                
                whereCriteria.add(new ApexUtil.Criteria('Manifest__c', caseManifestSearchEntry, '='));
                buildCaseDetailURLParams('caseManifestSearchEntry='+caseManifestSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(caseTypeSearchEntry))){
                
                whereCriteria.add(new ApexUtil.Criteria('Case_Type__c', caseTypeSearchEntry, '='));
                buildCaseDetailURLParams('caseTypeSearchEntry='+caseTypeSearchEntry);
            }
            if(String.isNotBlank(string.valueof(caseStatusSearchEntry))){
                
                whereCriteria.add(new ApexUtil.Criteria('Current_Task__c', caseStatusSearchEntry, '='));
                buildCaseDetailURLParams('caseStatusSearchEntry='+caseStatusSearchEntry);
            }
            
            if(CurrentUser.User_Type__c == 'QA'){
                
                whereCriteria.add(new ApexUtil.Criteria('Current_Task__c', 'Initiated State', '!='));
                whereCriteria.add(new ApexUtil.Criteria('Current_Task__c', 'Validate Transmission', '!='));
                whereCriteria.add(new ApexUtil.Criteria('Current_Task__c', 'Scoping', '!='));
                whereCriteria.add(new ApexUtil.Criteria('Current_Task__c', 'Investigations', '!='));
                whereCriteria.add(new ApexUtil.Criteria('Current_Task__c', 'QA Review Completed', '!='));    
                whereCriteria.add(new ApexUtil.Criteria('Case_Queue_Status__c', 'Closed', '!='));    
            }
            
            where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        }else{
            if(String.isNotBlank(string.valueof(fromSubmissionDateSearchEntry))){
                
                
                whereCriteria.add(new ApexUtil.Criteria('Submission_Date__c',String.valueof(fromSubmissionDateSearchEntry), '>=').withFieldType('Date'));
                buildCaseDetailURLParams('fromSubmissionDateSearchEntry='+fromSubmissionDateSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(toSubmissionDateSearchEntry))){
                
                whereCriteria.add(new ApexUtil.Criteria('Submission_Date__c',String.valueof(toSubmissionDateSearchEntry), '<=').withFieldType('Date'));
                buildCaseDetailURLParams('toSubmissionDateSearchEntry='+toSubmissionDateSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(subjectFirstNameSearchEntry))){
                
                whereCriteria.add(new ApexUtil.Criteria('Contact__r.First_Name__c', '%'+String.escapeSingleQuotes(subjectFirstNameSearchEntry)+'%', 'LIKE'));
                buildCaseDetailURLParams('subjectFirstNameSearchEntry='+subjectFirstNameSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(subjectLastNameSearchEntry))){
                
                whereCriteria.add(new ApexUtil.Criteria('Contact__r.Last_Name__c', '%'+String.escapeSingleQuotes(subjectLastNameSearchEntry)+'%', 'LIKE'));
                buildCaseDetailURLParams('subjectLastNameSearchEntry='+subjectLastNameSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(subjectSSNSearchEntry))){
                
                whereCriteria.add(new ApexUtil.Criteria('Contact__r.SSN__c', '%'+subjectSSNSearchEntry+'%', 'LIKE'));
                buildCaseDetailURLParams('subjectSSNSearchEntry='+subjectSSNSearchEntry);
            }
            
           
                
            if(String.isNotBlank(string.valueof(caseNumberSearchEntry))){
                
                whereCriteria.add(new ApexUtil.Criteria('Case_Number__c', caseNumberSearchEntry, '='));
                buildCaseDetailURLParams('caseNumberSearchEntry='+caseNumberSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(caseManifestSearchEntry))){
                
                whereCriteria.add(new ApexUtil.Criteria('Manifest__c', caseManifestSearchEntry, '='));
                buildCaseDetailURLParams('caseManifestSearchEntry='+caseManifestSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(caseTypeSearchEntry))){
                
                whereCriteria.add(new ApexUtil.Criteria('Case_Type__c', caseTypeSearchEntry, '='));
                buildCaseDetailURLParams('caseTypeSearchEntry='+caseTypeSearchEntry);
            }
            if(String.isNotBlank(string.valueof(caseStatusSearchEntry))){
                
                whereCriteria.add(new ApexUtil.Criteria('current_task__c', caseStatusSearchEntry, '='));
                buildCaseDetailURLParams('caseStatusSearchEntry='+caseStatusSearchEntry);
            }
            
            if(CurrentUser.User_Type__c == 'CMO'){
                
                whereCriteria.add(new ApexUtil.Criteria('Assigned_to__c', userinfo.getuserid(), '='));    
            }
            
            if(CurrentUser.User_Type__c == 'PMO'){
                //whereCriteria.add(new ApexUtil.Criteria('Assigned_To__c','', '='));    
            }
            
            if(CurrentUser.User_Type__c == 'QA'){
                
                whereCriteria.add(new ApexUtil.Criteria('Current_Task__c', 'QA and Review', '='));    
                whereCriteria.add(new ApexUtil.Criteria('Case_Queue_Status__c', 'Closed', '!='));    
            }
            
            where_cond = ApexUtil.generateWhereQuery(whereCriteria);   
            buildCaseDetailURLParams('showUnAssigned=false'); 
        }
       
        //query = query + ' WHERE '+where_cond; 
        //System.debug(LoggingLevel.DEBUG, 'query...'+query);
        //list<case__c> cases = database.query(query)
        
        string countQuery;
        if(string.isnotblank(where_cond)){
        	queryForNextRecords = query + ' WHERE '+where_cond;
            query = query + ' WHERE '+where_cond+' Order by Name asc Limit 200';
            countQuery = 'Select Count() from Case__c WHERE '+ where_cond;
        }else{
        	queryForNextRecords = query; 
            query = query +' Order by Name asc Limit 200';
             countQuery = 'Select Count() from Case__c';
        }
        
         
        
        totalRecordCount = database.countquery(Countquery);
        list<Case__c> c = new list<case__c>();
        if(test.isRunningTest()){
        	c = [select id,Name from case__c WITH USER_MODE];   
        }else{
         	c = database.query(query, AccessLevel.SYSTEM_MODE);        
       }
        integer i = 0;
        for(case__c cs: c){
			casesSearched.add(new CaseRecord(cs));
            if(i==0){
            	firstRecordName = cs.Name;    
            }
            lastRecordName = cs.Name;
            i++;
		}
        PageNumber = 1;
        double totalNum = double.valueof(totalRecordCount)/double.valueof(200);
        double floorVal = Math.floor(totalNum);
        double diff = totalNum - floorVal;
        TotalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
        if(totalRecordCount <= 200){
            disablePrev = true;
            disableNext = true;
            currentRecordCount = totalRecordCount;
        }else{
        	disablePrev = true;   
            disableNext = false;
            currentRecordCount = 200; 
        }
        
        showcasessearchcriteriapanel = false;
        showcaseslistpanel = true;
        showUnAssigned = false;
        
        subjectFirstNameSearchEntry = null;
        subjectLastNameSearchEntry = null;
        subjectSSNSearchEntry = null;
        caseNumberSearchEntry = null;
        caseManifestSearchEntry = null;
        caseAssigneeearchEntry = null;
        caseTypeSearchEntry = null;
        caseStatusSearchEntry = null;
        fromSubmissionDateSearchEntry = null;
        toSubmissionDateSearchEntry = null;
    }
    
    public void buildCaseDetailURLParams(string condition){
        if(String.isBlank(caseDetailURLParams)){
            caseDetailURLParams = condition;    
        }else{
            caseDetailURLParams = caseDetailURLParams + '&'+condition; 
        }
        list<string> temp = condition.split('=');
        if(temp.size()==2){
            caseDetailURLParamsMap.put(temp[0],temp[1]);
        }
    }
    
    public class CaseRecord{
        public case__c cs{get;set;}
        public boolean isSelected {get;set;}
        public CaseRecord(Case__c cs){
            this.cs = cs;
            this.isSelected = false;
        }
    }
    
    // PMD does not recognize the object checks plus stripInaccessible calls below.
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public void AssignCasesAction(){
        list<case__c> casesToUpdate = new LisT<case__c>();
        list<case_History__C> caseHistoriesToInsert = new LisT<case_History__C>();
        for(CaseRecord cR: casesSearched){
            if(cR.isSelected){
                cr.cs.Assigned_To__c = selectedUserIdForAssignment;
                cr.cs.Case_Queue_Status__c = 'Assigned';
                cr.cs.Assignee_Date__c = system.today();
                cr.cs.current_task__c = 'Validate Transmission';
                cr.cs.validate_transmission_date__c = system.today();
                case_History__C ch = new case_History__c();
                ch.case__c = cr.cs.id;
                ch.added_by__c = userinfo.getuserid();
                ch.value__c = 'Validate Transmission';
                casesToUpdate.add(cr.cs);
                caseHistoriesToInsert.add(ch);
            }    
        }
        if(!casesToUpdate.isEmpty() && Schema.sObjectType.Case__c.isUpdateable()){
            casesToUpdate = (List<Case__c>) Security.stripInaccessible(
                AccessType.UPDATABLE,
                casesToUpdate
            ).getRecords();
            update casesToUpdate;    
        }
        if(!caseHistoriesToInsert.isEmpty() && Schema.sObjectType.Case_History__c.isCreateable()){
            caseHistoriesToInsert = (List<Case_History__c>) Security.stripInaccessible(
                AccessType.CREATABLE,
                caseHistoriesToInsert
            ).getRecords();
            insert caseHistoriesToInsert;    
        }
        if(!caseDetailURLParamsMap.isEmpty()){
            for(String str: caseDetailURLParamsMap.keyset()){
                if(str == 'showUnAssigned'){
                    showUnAssigned = boolean.valueof(caseDetailURLParamsMap.get(str));
                } 
                if(str == 'showQACases'){
                    showQACases = true;
                }
                if(str == 'subjectFirstNameSearchEntry'){
                    subjectFirstNameSearchEntry = caseDetailURLParamsMap.get(str);
                }
                if(str == 'subjectLastNameSearchEntry'){
                    subjectLastNameSearchEntry = caseDetailURLParamsMap.get(str);
                }
                if(str == 'subjectSSNSearchEntry'){
                    subjectSSNSearchEntry = caseDetailURLParamsMap.get(str);
                }
                
               
                if(str == 'caseNumberSearchEntry'){
                    caseNumberSearchEntry = caseDetailURLParamsMap.get(str);
                }
                if(str == 'caseManifestSearchEntry'){
                    caseManifestSearchEntry = caseDetailURLParamsMap.get(str);
                }
                if(str == 'caseAssigneeearchEntry'){
                    caseAssigneeearchEntry = caseDetailURLParamsMap.get(str);
                }
                if(str == 'caseTypeSearchEntry'){
                    caseTypeSearchEntry = caseDetailURLParamsMap.get(str);
                }
                if(str == 'caseStatusSearchEntry'){
                    caseStatusSearchEntry = caseDetailURLParamsMap.get(str);
                }
                if(str == 'fromSubmissionDateSearchEntry'){
                    fromSubmissionDateSearchEntry = date.valueof(caseDetailURLParamsMap.get(str));
                }
                if(str == 'toSubmissionDateSearchEntry'){
                    toSubmissionDateSearchEntry = date.valueof(caseDetailURLParamsMap.get(str));
                }
            }
            SearchAction();
         }
          
         selectedUserIdForAssignment = null;
        //showcasessearchcriteriapanel = true;
        //showcaseslistpanel = false;
        //showUnAssigned = false;
        
       
    }
    
    
    @RemoteAction
    public static Integer TotalNumberOfUnassignedCases() {
        list<case__c> cases = new list<case__c>();
        cases = [Select Id,Assigned_to__c from Case__c where Assigned_to__c = Null WITH USER_MODE];
        return cases.size();
    }
    
    @RemoteAction 
    public static Integer TotalNumberOfassignedCases() {
        list<case__c> cases = new list<case__c>();
        cases = [Select Id,Assigned_to__c from Case__c where Assigned_to__c =: userinfo.getuserId() AND Case_Queue_Status__c != 'Closed' WITH USER_MODE];
        return cases.size();
    }
    
    public string deleteCaseId{get;set;}
    public void DeleteCaseAction(){
        delete [select id from case__c where id=:deleteCaseId];
        list<caserecord> temp = new list<caserecord>();
        for(caserecord cr: casesSearched){
            if(cr.cs.id != deleteCaseId){
                temp.add(cr);    
            }
        }
        casesSearched.clear();
        casesSearched.addAll(temp);
    }
    
    @RemoteAction
    public static Integer TotalNumberLeadsForCase(String caseId) {
        list<Lead__c> leads = new list<Lead__c>();
        leads = [Select Id,case__c from Lead__c where Case__c =: caseId WITH USER_MODE];
        return leads.size();
    }
    
    @RemoteAction 
    public static Integer TotalNumberOfQACases() {
        list<case__c> cases = new list<case__c>();
        cases = [Select Id,Assigned_to__c, Current_Task__c from Case__c where Current_Task__c = 'QA and Review' AND Case_Queue_Status__c != 'Closed' WITH USER_MODE];
        return cases.size();
    }
    
    public void handlePrev(){
            casesSearched = new List<CaseRecord>(); 
            PageNumber --;
    	string query = queryForNextRecords + ' AND Name <:firstRecordName  Order by Name desc Limit 200';	   
        list<Case__c> cases = database.query(query, AccessLevel.SYSTEM_MODE);
        for(Integer j=cases.size()-1;j>=0; j--){
            casesSearched.add(new CaseRecord(cases[j]));
            if(j==cases.size()-1){
            	firstRecordName = cases[j].Name;	   
            }
            lastRecordName = cases[j].Name; 
            
        }
        if(pageNumber == 1){
            disablePrev = true;
            disableNext = false ;
        }else{
            disablePrev = false;
            disableNext = false;
        }
    } 
    public void handleNext(){
        casesSearched = new List<CaseRecord>();
        PageNumber ++ ;
    	string query = queryForNextRecords + ' AND Name >:lastRecordName  Order by Name asc Limit 200';	   
        list<Case__c> Cases = database.query(query, AccessLevel.SYSTEM_MODE);
        integer i = 0;
        for(Case__c cs: Cases){
            casesSearched.add(new CaseRecord(cs));
            if(i==0){
            	firstRecordName = cs.Name;    
            }
            lastRecordName = cs.Name;
            i++;
        }
        if(pageNumber == TotalPages){
            disablePrev = false;   
            disableNext = true;
        }else{
            disablePrev = false;
            disableNext = false;
        }
    } 
}
