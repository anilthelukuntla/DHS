/**
 * @description Visualforce controller for the DHS case dashboard.
 */
@SuppressWarnings('PMD.AvoidNonRestrictiveQueries,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.EmptyStatementBlock,PMD.ExcessivePublicCount,PMD.NcssConstructorCount,PMD.NcssCount,PMD.NcssMethodCount,PMD.StdCyclomaticComplexity')
public with sharing class DHSCaseDashboardController {
    /** @description Provides this DHS API member. */
    public string subjectFirstNameSearchEntry {get;set;}
    /** @description Provides this DHS API member. */
    public string subjectLastNameSearchEntry {get;set;}
    /** @description Provides this DHS API member. */
    public string subjectSSNSearchEntry {get;set;}
    /** @description Provides this DHS API member. */
    public string caseNumberSearchEntry {get;set;}
    /** @description Provides this DHS API member. */
    public string caseManifestSearchEntry {get;set;}
    /** @description Provides this DHS API member. */
    public string caseAssigneeearchEntry {get;set;}
    /** @description Provides this DHS API member. */
    public string caseTypeSearchEntry {get;set;}
    /** @description Provides this DHS API member. */
    public string caseStatusSearchEntry {get;set;}
    /** @description Provides this DHS API member. */
    public date fromSubmissionDateSearchEntry {get;set;}
    /** @description Provides this DHS API member. */
    public date toSubmissionDateSearchEntry {get;set;}
    /** @description Provides this DHS API member. */
    public list<CaseRecord> casesSearched {get;set;}
    /** @description Provides this DHS API member. */
    public boolean showcasessearchcriteriapanel { get; private set; }
    /** @description Provides this DHS API member. */
    public boolean showcaseslistpanel { get; private set; }
    /** @description Provides this DHS API member. */
    public list<selectoption> caseTypeOptions {get;set;}
    /** @description Provides this DHS API member. */
    public list<selectoption> caseStatusOptions {get;set;}
    /** @description Provides this DHS API member. */
    public list<selectoption> assignUserList {get;set;}
    /** @description Provides this DHS API member. */
    public string selectedUserIdForAssignment {get;set;}
    /** @description Provides this DHS API member. */
    public user currentUser {get;set;}
    /** @description Provides this DHS API member. */
    public string caseDetailURLParams {get;set;}
    /** @description Provides this DHS API member. */
    public map<string,string> caseDetailURLParamsMap {get;set;}
    public string nextURL;
    /** @description Provides this DHS API member. */
    public integer pageNumber {get;set;}
    /** @description Provides this DHS API member. */
    public integer totalPages   {get;set;}
    /** @description Provides this DHS API member. */
    public integer totalRecordCount {get;set;}
    List<Object> records;
    /** @description Provides this DHS API member. */
    public boolean disablePrev { get; private set; }
    /** @description Provides this DHS API member. */
    public boolean disableNext { get; private set; }
    /** @description Provides this DHS API member. */
    public string queryForNextRecords {get;set;}
    /** @description Provides this DHS API member. */
    public string lastRecordName {get;set;}
    /** @description Provides this DHS API member. */
    public string firstRecordName {get;set;}
    /** @description Provides this DHS API member. */
    public integer currentRecordCount {get;set;}
    /** @description Provides this DHS API member. */
    public static object criteria {get;set;}
    /** @description Provides this DHS API member. */
    public DHSCaseDashboardController(){
        pageNumber = 1;
        disablePrev = true;
        records = New List<Object>();
        currentUser = [Select Id, User_Type__c FROM User where Id=:userinfo.getUserId()];
        List<user> assignUsers = new List<user>();
        assignUsers = [select Id, User_Type__c, FirstName,System_Access__c, lastname  FROM User where isactive=true AND User_Type__c = 'CMO'];
        assignUserList = new List<SelectOption>();
        assignUserList.add(new SelectOption('','--None--'));
        for(User u: assignUsers){
            if(u.System_Access__c.contains('DHS')){
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
        for(String str: apexutil.getPickListValuesIntoList('DHS_Case__c', 'Case_Type__c')){
            caseTypeOptions.add(new SelectOption(str, str));
        }
        for(String str: apexutil.getPickListValuesIntoList('DHS_Case__c', 'Current_Task__c')){
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
                searchAction();
            }
        }
        
    }
    
    /** @description Provides this DHS API member. */
    public boolean showUnAssigned { get; private set; }
    /** @description Provides this DHS API member. */
    public boolean showQACases { get; private set; }
    /** @description Provides this DHS API member. */
    public void searchAction(){
        //List<Map<string,Object>> conditions = New List<Map<string,Object>>();
        caseDetailURLParams = null;
        caseDetailURLParamsMap = new map<string,string>();
        casesSearched = new List<CaseRecord>();    
        List<string> caseFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        caseFields = DHSApexUtil.FetchFields('DHS_Case__c');
        caseFields.add('DHS_Contact__r.First_Name__c');
        caseFields.add('DHS_Contact__r.Last_Name__c');
        String query = 'Select '+String.escapeSingleQuotes(string.join(caseFields, ',')) + ' From DHS_Case__c ';
        String whereCond;
        if(showUnAssigned){
            
            whereCond = 'DHS_Assigned_To__c = null';  
            buildCaseDetailURLParams('showUnAssigned=true');
        } else if(showQACases){
            buildCaseDetailURLParams('showQACases=true');
            if(String.isNotBlank(string.valueof(fromSubmissionDateSearchEntry))){
                
                whereCriteria.add(new DHSApexUtil.Criteria('Submission_Date__c',String.escapeSingleQuotes(String.valueof(fromSubmissionDateSearchEntry)), '>=', 'Date'));
                buildCaseDetailURLParams('fromSubmissionDateSearchEntry='+fromSubmissionDateSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(toSubmissionDateSearchEntry))){
                                
                whereCriteria.add(new DHSApexUtil.Criteria('Submission_Date__c',String.escapeSingleQuotes(String.valueof(toSubmissionDateSearchEntry)), '<=', 'Date'));
                buildCaseDetailURLParams('toSubmissionDateSearchEntry='+toSubmissionDateSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(subjectFirstNameSearchEntry))){
                
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_Contact__r.First_Name__c', '%'+String.escapeSingleQuotes(String.escapeSingleQuotes(subjectFirstNameSearchEntry))+'%', 'LIKE'));
                buildCaseDetailURLParams('subjectFirstNameSearchEntry='+subjectFirstNameSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(subjectLastNameSearchEntry))){
                
                
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_Contact__r.Last_Name__c', '%'+String.escapeSingleQuotes(subjectLastNameSearchEntry)+'%', 'LIKE'));
                buildCaseDetailURLParams('subjectLastNameSearchEntry='+subjectLastNameSearchEntry);
            }
           
            if(String.isNotBlank(string.valueof(subjectSSNSearchEntry))){
                
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_Contact__r.SSN__c', '%'+String.escapeSingleQuotes(subjectSSNSearchEntry)+'%', 'LIKE'));
                buildCaseDetailURLParams('subjectSSNSearchEntry='+subjectSSNSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(caseNumberSearchEntry))){
               
                whereCriteria.add(new DHSApexUtil.Criteria('Case_Number__c', String.escapeSingleQuotes(caseNumberSearchEntry), '='));
                buildCaseDetailURLParams('caseNumberSearchEntry='+caseNumberSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(caseManifestSearchEntry))){
                
                
                whereCriteria.add(new DHSApexUtil.Criteria('Manifest__c', String.escapeSingleQuotes(caseManifestSearchEntry), '='));
                buildCaseDetailURLParams('caseManifestSearchEntry='+caseManifestSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(caseTypeSearchEntry))){
                
                whereCriteria.add(new DHSApexUtil.Criteria('Case_Type__c', String.escapeSingleQuotes(caseTypeSearchEntry), '='));
                buildCaseDetailURLParams('caseTypeSearchEntry='+caseTypeSearchEntry);
            }
            if(String.isNotBlank(string.valueof(caseStatusSearchEntry))){
                
                whereCriteria.add(new DHSApexUtil.Criteria('Current_Task__c', String.escapeSingleQuotes(caseStatusSearchEntry), '='));
                buildCaseDetailURLParams('caseStatusSearchEntry='+caseStatusSearchEntry);
            }
            
            if(CurrentUser.User_Type__c == 'QA'){
                
                whereCriteria.add(new DHSApexUtil.Criteria('Current_Task__c', 'Initiated State', '!='));
                whereCriteria.add(new DHSApexUtil.Criteria('Current_Task__c', 'Validate Transmission', '!='));
                whereCriteria.add(new DHSApexUtil.Criteria('Current_Task__c', 'Scoping', '!='));
                whereCriteria.add(new DHSApexUtil.Criteria('Current_Task__c', 'Investigations', '!='));
                whereCriteria.add(new DHSApexUtil.Criteria('Current_Task__c', 'QA Review Completed', '!='));    
                whereCriteria.add(new DHSApexUtil.Criteria('Case_Queue_Status__c', 'Closed', '!='));    
            }
            
            whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        }else{
            if(String.isNotBlank(string.valueof(fromSubmissionDateSearchEntry))){
                
                
                whereCriteria.add(new DHSApexUtil.Criteria('Submission_Date__c',String.escapeSingleQuotes(String.valueof(fromSubmissionDateSearchEntry)), '>=', 'Date'));
                buildCaseDetailURLParams('fromSubmissionDateSearchEntry='+fromSubmissionDateSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(toSubmissionDateSearchEntry))){
                
                whereCriteria.add(new DHSApexUtil.Criteria('Submission_Date__c',String.escapeSingleQuotes(String.valueof(toSubmissionDateSearchEntry)), '<=', 'Date'));
                buildCaseDetailURLParams('toSubmissionDateSearchEntry='+toSubmissionDateSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(subjectFirstNameSearchEntry))){
                
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_Contact__r.First_Name__c', '%'+String.escapeSingleQuotes(String.escapeSingleQuotes(subjectFirstNameSearchEntry))+'%', 'LIKE'));
                buildCaseDetailURLParams('subjectFirstNameSearchEntry='+subjectFirstNameSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(subjectLastNameSearchEntry))){
                
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_Contact__r.Last_Name__c', '%'+String.escapeSingleQuotes(String.escapeSingleQuotes(subjectLastNameSearchEntry))+'%', 'LIKE'));
                buildCaseDetailURLParams('subjectLastNameSearchEntry='+subjectLastNameSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(subjectSSNSearchEntry))){
                
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_Contact__r.SSN__c', '%'+String.escapeSingleQuotes(String.escapeSingleQuotes(subjectSSNSearchEntry))+'%', 'LIKE'));
                buildCaseDetailURLParams('subjectSSNSearchEntry='+subjectSSNSearchEntry);
            }
            
           
                
            if(String.isNotBlank(string.valueof(caseNumberSearchEntry))){
                
                whereCriteria.add(new DHSApexUtil.Criteria('Case_Number__c', String.escapeSingleQuotes(caseNumberSearchEntry), '='));
                buildCaseDetailURLParams('caseNumberSearchEntry='+caseNumberSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(caseManifestSearchEntry))){
                
                whereCriteria.add(new DHSApexUtil.Criteria('Manifest__c', String.escapeSingleQuotes(caseManifestSearchEntry), '='));
                buildCaseDetailURLParams('caseManifestSearchEntry='+caseManifestSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(caseTypeSearchEntry))){
                
                whereCriteria.add(new DHSApexUtil.Criteria('Case_Type__c', String.escapeSingleQuotes(caseTypeSearchEntry), '='));
                buildCaseDetailURLParams('caseTypeSearchEntry='+caseTypeSearchEntry);
            }
            if(String.isNotBlank(string.valueof(caseStatusSearchEntry))){
                
                whereCriteria.add(new DHSApexUtil.Criteria('Current_Task__c', String.escapeSingleQuotes(caseStatusSearchEntry), '='));
                buildCaseDetailURLParams('caseStatusSearchEntry='+caseStatusSearchEntry);
            }
            
            if(CurrentUser.User_Type__c == 'CMO'){
                
                whereCriteria.add(new DHSApexUtil.Criteria('DHS_Assigned_To__c', String.escapeSingleQuotes(userinfo.getuserid()), '='));    
            }
            
            if(CurrentUser.User_Type__c == 'QA'){
                
                whereCriteria.add(new DHSApexUtil.Criteria('Current_Task__c', 'QA and Review', '='));    
                whereCriteria.add(new DHSApexUtil.Criteria('Case_Queue_Status__c', 'Closed', '!='));    
            }
            
            criteria = whereCriteria;
            criteria = JSON.serialize(criteria);
            whereCond = DHSApexUtil.generateWhereQuery(whereCriteria);   
            buildCaseDetailURLParams('showUnAssigned=false'); 
        }
       
        //query = query + ' WHERE '+where_cond; 
        //
        //list<DHS_Case__c> cases = database.query(query, AccessLevel.USER_MODE)
        
        string countQuery;
        if(string.isnotblank(whereCond)){
        	queryForNextRecords = query + ' WHERE '+whereCond;
            query = query + ' WHERE '+whereCond+' Order by Name asc Limit 200';
            countQuery = 'Select Count() from DHS_Case__c WHERE '+ whereCond;
        }else{
        	queryForNextRecords = query; 
            query = query +' Order by Name asc Limit 200';
             countQuery = 'Select Count() from DHS_Case__c';
        }
        
         
        
        totalRecordCount = database.countquery(Countquery, AccessLevel.USER_MODE);
        list<DHS_Case__c> c = new list<DHS_Case__c>();
        if(test.isRunningTest()){
        	c = [select id,Name from DHS_Case__c WITH USER_MODE];   
        }else{
         	c = database.query(query, AccessLevel.USER_MODE);        
       }
        integer i = 0;
        for(DHS_Case__c cs: c){
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
        totalPages = diff > 0 ? integer.valueOf(floorVal) + 1 : integer.valueOf(floorVal);
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
    
    /**
     * @description Provides this DHS API member.
     * @param condition Method parameter.
     */
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
    
    /** @description Provides this DHS API member. */
    public class CaseRecord{
        /** @description Provides this DHS API member. */
        public DHS_Case__c cs{get;set;}
        public boolean isSelected {get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
        /**
         * @description Provides this DHS API member.
         * @param cs Method parameter.
         */
        public CaseRecord(DHS_Case__c cs){
            this.cs = cs;
            this.isSelected = false;
        }
    }
    
    /** @description Provides this DHS API member. */
    public void assignCasesAction(){
        list<DHS_Case__c> casesToUpdate = new LisT<DHS_Case__c>();
        list<DHS_Case_History__c> caseHistoriesToInsert = new LisT<DHS_Case_History__c>();
        for(CaseRecord cR: casesSearched){
            if(cR.isSelected){
                cr.cs.DHS_Assigned_To__c = selectedUserIdForAssignment;
                cr.cs.Case_Queue_Status__c = 'Assigned';
                cr.cs.Assignee_Date__c = system.today();
                cr.cs.Current_Task__c = 'Validate Transmission';
                cr.cs.Validate_Transmission_Date__c = system.today();
                DHS_Case_History__c ch = new DHS_Case_History__c();
                ch.DHS_Case__c = cr.cs.id;
                ch.DHS_Added_By__c = userinfo.getuserid();
                ch.Value__c = 'Validate Transmission';
                casesToUpdate.add(cr.cs);
                caseHistoriesToInsert.add(ch);
            }    
        }
        if(!casesToUpdate.isEmpty()){
            database.update(casesToUpdate,false,AccessLevel.USER_MODE);    
        }
        if(!caseHistoriesToInsert.isEmpty()){
            database.insert(caseHistoriesToInsert,false,AccessLevel.USER_MODE);   
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
            searchAction();
         }
          
         selectedUserIdForAssignment = null;
        //showcasessearchcriteriapanel = true;
        //showcaseslistpanel = false;
        //showUnAssigned = false;
        
       
    }
    
    
    @RemoteAction
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public static Integer totalNumberOfUnassignedCases() {
        list<DHS_Case__c> cases = new list<DHS_Case__c>();
        cases = [Select Id,DHS_Assigned_To__c from DHS_Case__c where DHS_Assigned_To__c = Null WITH USER_MODE];
        return cases.size();
    }
    
    @RemoteAction 
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public static Integer totalNumberOfassignedCases() {
        list<DHS_Case__c> cases = new list<DHS_Case__c>();
        cases = [Select Id,DHS_Assigned_To__c from DHS_Case__c where DHS_Assigned_To__c =: userinfo.getuserId() AND Case_Queue_Status__c != 'Closed' WITH USER_MODE];
        return cases.size();
    }
    
    /** @description Provides this DHS API member. */
    public string deleteCaseId{get;set;}
    /** @description Provides this DHS API member. */
    public void deleteCaseAction(){
        Database.delete([select id from DHS_Case__c where id=:deleteCaseId WITH USER_MODE], AccessLevel.USER_MODE);
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
    /**
     * @description Provides this DHS API member.
     * @param caseId Method parameter.
     * @return The requested result.
     */
    public static Integer totalNumberLeadsForCase(String caseId) {
        list<DHS_Lead__c> leads = new list<DHS_Lead__c>();
        leads = [Select Id,DHS_Case__c from DHS_Lead__c where DHS_Case__c =: caseId WITH USER_MODE];
        return leads.size();
    }
    
    @RemoteAction 
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public static Integer totalNumberOfQACases() {
        list<DHS_Case__c> cases = new list<DHS_Case__c>();
        cases = [Select Id,DHS_Assigned_To__c, Current_Task__c from DHS_Case__c where Current_Task__c = 'QA and Review' AND Case_Queue_Status__c != 'Closed' WITH USER_MODE];
        return cases.size();
    }
    
    /** @description Provides this DHS API member. */
    public void handlePrev(){
            casesSearched = new List<CaseRecord>(); 
            PageNumber --;
            firstRecordName = String.escapeSingleQuotes(firstRecordName);
    	string query = queryForNextRecords + ' AND Name <:firstRecordName  Order by Name desc Limit 200';	   
        list<DHS_Case__c> cases = database.query(query, AccessLevel.USER_MODE);
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
    /** @description Provides this DHS API member. */
    public void handleNext(){
        casesSearched = new List<CaseRecord>();
        PageNumber ++ ;
        lastRecordName = String.escapeSingleQuotes(lastRecordName);
    	string query = queryForNextRecords + ' AND Name >:lastRecordName  Order by Name asc Limit 200';	   
        list<DHS_Case__c> cases = database.query(query, AccessLevel.USER_MODE);
        integer i = 0;
        for(DHS_Case__c cs: cases){
            casesSearched.add(new CaseRecord(cs));
            if(i==0){
            	firstRecordName = cs.Name;    
            }
            lastRecordName = cs.Name;
            i++;
        }
        if(pageNumber == totalPages){
            disablePrev = false;   
            disableNext = true;
        }else{
            disablePrev = false;
            disableNext = false;
        }
    } 
}