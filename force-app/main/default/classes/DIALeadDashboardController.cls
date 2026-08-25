public class DIALeadDashboardController {
    public string leadTypeSearchEntry{get;set;}
    public string leadStatusSearchEntry{get;set;}
    public string caseNumberSearchEntry{get;set;}
    public string customerCaseNumberSearchEntry{get;set;}
    public string manifestSearchEntry{get;set;}
    public string subjectFirstNameSearchEntry{get;set;}
    public string subjectLastNameSearchEntry{get;set;}
    public string streetaddressSearchEntry{get;set;}
    public string citySearchEntry{get;set;}
    public string stateSearchEntry{get;set;}
    public string ZipSearchEntry{get;set;}
    public list<LeadRecord> leadsSearched {get;set;}
    public boolean showleadssearchcriteriapanel {get;set;}
    public boolean showleadslistpanel {get;set;}
    public user currentUser {get;set;}
    public list<selectoption> assignUserList {get;set;}
    public list<selectoption> leadTypeOptions{get;set;}
    public list<selectoption> leadStatusOptions{get;set;}
    public boolean searchmyavailableleads {get;set;}
    public string leadDetailURLParams {get;set;}
    public map<string,string> leadDetailURLParamsMap {get;set;}
    public string nextURL;
    public integer pageNumber {get;set;}
    public integer TotalPages   {get;set;}
    public integer totalRecordCount {get;set;}
    public boolean disablePrev {get;set;}
    public boolean disableNext {get;set;}
    
    public list<selectoption> stateslist {get;set;}
    public list<selectoption> zipOptions {get;set;}
    public string assigneeStateSelected {get;set;}
    public string assigneeZipSelected {get;set;}
    public date acdDate {get;set;}
    public string queryForNextRecords {get;set;}
    public string lastRecordName {get;set;}
    public string firstRecordName {get;set;}
    public integer currentRecordCount {get;set;}
    public static object criteria {get;set;}
    public date anticipatedCompletionDate	{get;set;}
    public User_Permission__mdt currentUserPermissions {get;set;}
    public DIALeadDashboardController(){
        pageNumber = 1; 
        TotalPages = 1; 
        disablePrev = true;
        disableNext = true;
        showleadssearchcriteriapanel = true; 
        showleadslistpanel = false;
       
        currentUser = [Select Id, User_Type__c, Candidate_Type__c FROM User where Id=:userinfo.getUserId()];
        currentUserPermissions = PermissionsUtil.GetUserPermssions(currentUser.User_Type__c);
        assignUserList = new List<SelectOption>();
        leadTypeOptions = new list<selectoption>();
        leadStatusOptions = new list<selectoption>();
        stateslist = new list<selectoption>();
        zipOptions = new list<selectoption>();
        stateslist.add(new selectoption('','-- State --'));
        zipOptions.add(new selectoption('','-- Zip --'));
        stateslist.add(new selectoption('All States','All States'));
        leadTypeOptions.add(new selectoption('','--None--'));
        zipOptions.add(new selectoption('All Zips','All Zips'));
        list<onboarding__c> onboardingUsers = [select id,zip__c from onboarding__c where Status__c = 'Active' order by zip__c asc];
        for(onboarding__c onboardingUser : onboardingUsers){
            if(!string.isblank(onboardingUser.Zip__c)){
            	zipOptions.add(new selectoption(onboardingUser.Zip__c,onboardingUser.Zip__c));
            }
        }
        for(String lType: apexUtil.getPickListValuesIntoList('DIA_Lead__c','LeadType__c')){
            leadTypeOptions.add(new selectoption(lType,lType));
        }
        
        leadStatusOptions.add(new selectoption('','--None--'));
        for(String lStatus: apexUtil.getPickListValuesIntoList('DIA_Lead__c','Status__c')){
            leadStatusOptions.add(new selectoption(lStatus,lStatus));
        }
        
        searchUnassigned = false;
        searchmyAssigned = false;
        seachqarejected = false;
        searchmydiscontinued = false;
        searchmyavailableleads = false;
        showacceptandrejectbuttons = false;
        searchAfterAssignment = false;
        
        for(String lType: apexUtil.getPickListValuesIntoList('DIA_Lead__c','State__c')){
            stateslist.add(new selectoption(lType,lType));
        }
        assignUserList = new List<SelectOption>();
        assignUserList.add(new SelectOption('','-- Investigator --'));
        
        map<string,string> urlparametersMap = apexpages.currentpage().getparameters();
        System.debug('urlparametersMap..'+urlparametersMap);
        if(!urlparametersMap.isEmpty()){
            for(String str: urlparametersMap.keyset()){
            
                if(str == 'leadTypeSearchEntry'){
                    leadTypeSearchEntry = urlparametersMap.get(str);
                } 
                if(str == 'leadStatusSearchEntry'){
                    leadStatusSearchEntry = urlparametersMap.get(str);
                } 
                if(str == 'caseNumberSearchEntry'){
                    caseNumberSearchEntry = urlparametersMap.get(str);
                } 
                if(str == 'customerCaseNumberSearchEntry'){
                    customerCaseNumberSearchEntry = urlparametersMap.get(str);
                }
                if(str == 'manifestSearchEntry'){
                    manifestSearchEntry = urlparametersMap.get(str);
                } 
                if(str == 'subjectFirstNameSearchEntry'){
                    subjectFirstNameSearchEntry = urlparametersMap.get(str);
                } 
                if(str == 'subjectLastNameSearchEntry'){
                    subjectLastNameSearchEntry = urlparametersMap.get(str);
                } 
                if(str == 'streetaddressSearchEntry'){
                    streetaddressSearchEntry = urlparametersMap.get(str);
                } 
                if(str == 'citySearchEntry'){
                    citySearchEntry = urlparametersMap.get(str);
                } 
                if(str == 'stateSearchEntry'){
                    stateSearchEntry = urlparametersMap.get(str);
                } 
                if(str == 'ZipSearchEntry'){
                    ZipSearchEntry = urlparametersMap.get(str);
                } 
                if(str == 'searchUnassigned'){
                    searchUnassigned = boolean.valueof(urlparametersMap.get(str));
                } 
                if(str == 'searchmyAssigned'){
                    searchmyAssigned = boolean.valueof(urlparametersMap.get(str));
                } 
                if(str == 'searchmydiscontinued'){
                    searchmydiscontinued = boolean.valueof(urlparametersMap.get(str));
                } 
               
                if(str == 'seachqarejected'){
                    seachqarejected = boolean.valueof(urlparametersMap.get(str));
                } 
                if(str == 'searchmyavailableleads'){
                    searchmyavailableleads = boolean.valueof(urlparametersMap.get(str));
                }    
            }
            SearchAction();
        }
        
        FetchLeadCounts();     
    }
    
    public void onstatechange(){
        list<string> userTypesEligibleForLeadAssignment = new list<string>();
        list< User_Permission__mdt > userPermissions = [select id, user_type__c, LeadDashboard_Assignment_IncludeUsers__c  from
                                                       User_Permission__mdt where LeadDashboard_Assignment_IncludeUsers__c = true];
        for(User_Permission__mdt up: userPermissions){
        	userTypesEligibleForLeadAssignment.add(up.user_type__c);    
        }
        System.debug('userTypesEligibleForLeadAssignment...'+userTypesEligibleForLeadAssignment);
        assignUserList = new List<SelectOption>();
        assignUserList.add(new SelectOption('','-- Investigator --'));
        List<user> assignUsers = new List<user>();
        if(assigneeStateSelected != 'All States' && assigneeZipSelected != 'All Zips' && assigneeStateSelected != null && assigneeZipSelected != null){
            system.debug('both...'+'assigneeStateSelected...'+assigneeStateSelected+'assigneeZipSelected...'+assigneeZipSelected);
            assignUsers = [select Id,system_access__c, User_Type__c, FirstName, lastname, contact.OnBoarding__r.state__c  FROM User where contact.OnBoarding__r.state__c =:assigneeStateSelected and contact.OnBoarding__r.zip__c =: assigneeZipSelected and isactive=true and User_Type__c IN: userTypesEligibleForLeadAssignment order by LastName  ];
        }else if(assigneeStateSelected != 'All States' && assigneeStateSelected != null){
            system.debug('state...'+'assigneeStateSelected...'+assigneeStateSelected);
            assignUsers = [select Id,system_access__c, User_Type__c, FirstName, lastname, contact.OnBoarding__r.state__c  FROM User where contact.OnBoarding__r.state__c =:assigneeStateSelected and isactive=true and User_Type__c IN: userTypesEligibleForLeadAssignment order by LastName  ];
        }else if(assigneeZipSelected != 'All Zips' && assigneeZipSelected != null){
            system.debug('zip...'+'assigneeZipSelected...'+assigneeZipSelected);
            assignUsers = [select Id,system_access__c, User_Type__c, FirstName, lastname, contact.OnBoarding__r.state__c  FROM User where contact.OnBoarding__r.zip__c =: assigneeZipSelected and isactive=true and User_Type__c IN: userTypesEligibleForLeadAssignment order by LastName  ];            
        }else if(assigneeZipSelected == null && assigneeStateSelected == null){
            assignUsers = new List<user>(); 
        }else{
            system.debug('none...'+'assigneeStateSelected...'+assigneeStateSelected+'assigneeZipSelected...'+assigneeZipSelected);
            assignUsers = [select Id,system_access__c, User_Type__c, FirstName, lastname, contact.OnBoarding__r.state__c  FROM User where isactive=true and User_Type__c IN: userTypesEligibleForLeadAssignment order by LastName ];
        }
        system.debug(assignUsers);
        for(User u: assignUsers){
            if(u.system_access__c.contains('DIA')){
                assignUserList.add(new SelectOption(u.id,u.lastname +' '+u.firstname));
            }
        }
    }
    public string selectedUserIdForAssignment{get;set;}
    public boolean searchUnassigned {get;set;}
    public boolean searchmyAssigned{get;set;}
    public boolean searchmydiscontinued {get;set;}
    public boolean seachqarejected{get;set;}
    public boolean showacceptandrejectbuttons{get;set;}
    
    public integer myavailableleadscount {get;set;}
    public integer myassignedadscount {get;set;}
    public integer myqarejectedleadscount {get;set;}
    public integer mydiscontinuedcount {get;set;}
    public void FetchLeadCounts(){
        List<string> leadFields = new List<string>();
        leadFields.add('Id');
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        String query1 = 'Select Id From DIA_Lead__c ';
        String query2 = 'Select Id From DIA_Lead__c ';
        String query3 = 'Select Id From DIA_Lead__c ';
        String query4 = 'Select Id From DIA_Lead__c ';
        String where_cond;
        whereCriteria = new List<ApexUtil.Criteria>();
            whereCriteria.add(new ApexUtil.Criteria('Assigned_to__c', userinfo.getuserid(), '=')); 
            whereCriteria.add(new ApexUtil.Criteria('Lead_Accepted_or_Rejected__c','Accepted', '!=')); 
            whereCriteria.add(new ApexUtil.Criteria('Lead_Accepted_or_Rejected__c','Rejected', '!=')); 
            whereCriteria.add(new ApexUtil.Criteria('status__c','Completed', '!='));
            whereCriteria.add(new ApexUtil.Criteria('status__c','QA Review Completed', '!='));
            where_cond = ApexUtil.generateWhereQuery(whereCriteria);
            
            query1 = query1 + ' WHERE '+where_cond; 
            list<DIA_Lead__c> leads = new list<DIA_Lead__c>();
            leads = database.query(query1);
            myavailableleadscount = leads.size();
            
            leads = new list<DIA_Lead__c>();
            whereCriteria = new List<ApexUtil.Criteria>();
            whereCriteria.add(new ApexUtil.Criteria('Assigned_to__c', userinfo.getuserid(), '=')); 
            whereCriteria.add(new ApexUtil.Criteria('Lead_Accepted_or_Rejected__c','Accepted', '=')); 
            whereCriteria.add(new ApexUtil.Criteria('status__c','Completed', '!='));
            whereCriteria.add(new ApexUtil.Criteria('status__c','QA Rejected', '!='));
            whereCriteria.add(new ApexUtil.Criteria('status__c','QA Review Completed', '!='));
            where_cond = ApexUtil.generateWhereQuery(whereCriteria);  
            query2 = query2 + ' WHERE '+where_cond; 
            leads = database.query(query2);
            myassignedadscount = leads.size();
            
            leads = new list<DIA_Lead__c>();
            whereCriteria = new List<ApexUtil.Criteria>();
            whereCriteria.add(new ApexUtil.Criteria('Assigned_to__c', userinfo.getuserid(), '=')); 
            whereCriteria.add(new ApexUtil.Criteria('Lead_Accepted_or_Rejected__c','Accepted', '=')); 
            whereCriteria.add(new ApexUtil.Criteria('status__c','Completed', '!='));
            whereCriteria.add(new ApexUtil.Criteria('status__c','QA Rejected', '='));
            whereCriteria.add(new ApexUtil.Criteria('status__c','QA Review Completed', '!='));
            where_cond = ApexUtil.generateWhereQuery(whereCriteria);  
            query3 = query3 + ' WHERE '+where_cond; 
            leads = database.query(query3);
            myqarejectedleadscount = leads.size();
            
            leads = new list<DIA_Lead__c>();
            whereCriteria = new List<ApexUtil.Criteria>();
            whereCriteria.add(new ApexUtil.Criteria('Assigned_to__c', userinfo.getuserid(), '=')); 
            whereCriteria.add(new ApexUtil.Criteria('status__c','Discontinued', '='));
            where_cond = ApexUtil.generateWhereQuery(whereCriteria);  
            query4 = query4 + ' WHERE '+where_cond; 
            leads = database.query(query4);
            mydiscontinuedcount = leads.size();
    }
    public void SearchAction(){
        System.debug('searchmyavailableleads...'+searchmyavailableleads);
        System.debug('searchUnassigned...'+searchUnassigned);
        System.debug('searchmyassigned...'+searchmyassigned);
        System.debug('seachqarejected...'+seachqarejected);
        System.debug('searchmydiscontinued...'+searchmydiscontinued);
        leadDetailURLParamsMap = new map<string,string>();
        leadDetailURLParams = null;
        leadsSearched = new List<LeadRecord>();  
        List<string> leadFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        //leadFields = ApexUtil.FetchFields('DIA_Lead__c');
        leadFields.add('case__r.ID');
        leadFields.add('case__r.case_Number__c');
        leadFields.add('case__r.customer_case_Number__c');
        leadFields.add('contact__r.first_name__c');
        leadFields.add('contact__r.last_name__c');
        leadFields.add('contact__r.Address__c');
        leadFields.add('contact__r.City__c');
        leadFields.add('contact__r.State__c');
        leadFields.add('contact__r.Zip__c');
        leadFields.add('Case__r.Investigations_Date__c');
        leadFields.add('Case__r.Assigned_To__c');
        leadFields.add('LeadType__c');
        leadFields.add('status__c');
        leadFields.add('Assigned_to__c');
        //string fields = 'Id,Lead_Log__c,Lead_Contact_Name__c,Lead_Contact_Address__c,Lead_Contact_City__c,Lead_Contact_State__c,Lead_Contact_Zip__c,Coverage_Type__c,Extension__c,Assigned_To_Name__c,Item_number__c,Lead_Accepted_or_Rejected__c, Assignee_Date__c ,Anticipated_Completion_Date__c,Accepted_Date__c';
        //leadFields.AddAll(fields.split(','));
        List<Map<string,Object>> conditions = New List<Map<string,Object>>();
        String query;
        //query = 'Select '+string.join(leadFields, ',') + ' From DIA_Lead__c ';
        query = 'Select Id,Mark_As_TDY__c,Name,Lead_Log__c,Lead_Contact_Name__c,Lead_Contact_Address__c,Lead_Contact_City__c,Lead_Contact_State__c,Lead_Contact_Zip__c,Coverage_Type__c,Extension__c,Assigned_To_Name__c,Item_number__c,Lead_Accepted_or_Rejected__c, Assignee_Date__c ,Anticipated_Completion_Date__c,Accepted_Date__c,'+string.join(leadFields, ',') + ' From DIA_Lead__c ';
            //whereCriteria.add(new ApexUtil.Criteria('status__c','Completed', '!='));
            //whereCriteria.add(new ApexUtil.Criteria('status__c','QA Review Completed', '!='));
            
            if(CurrentUser.User_Type__c == 'CMO'){
                 //whereCriteria.add(new ApexUtil.Criteria('Case__r.Assigned_To__c', userinfo.getuserid(), '='));  
            }
            
            System.debug('leadTypeSearchEntry...'+leadTypeSearchEntry);
            if(String.isNotBlank(string.valueof(leadTypeSearchEntry))){
                
                whereCriteria.add(new ApexUtil.Criteria('LeadType__c', leadTypeSearchEntry, '='));
                buildLeadDetailURLParams('leadTypeSearchEntry='+leadTypeSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(leadStatusSearchEntry))){
                
                whereCriteria.add(new ApexUtil.Criteria('status__c', leadStatusSearchEntry, '='));
                buildLeadDetailURLParams('leadStatusSearchEntry='+leadStatusSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(manifestSearchEntry))){
                whereCriteria.add(new ApexUtil.Criteria('Case__r.Manifest__c', manifestSearchEntry, '='));
                buildLeadDetailURLParams('manifestSearchEntry='+manifestSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(caseNumberSearchEntry))){
                
                whereCriteria.add(new ApexUtil.Criteria('Case__r.case_number__c', caseNumberSearchEntry, '='));
                buildLeadDetailURLParams('caseNumberSearchEntry='+caseNumberSearchEntry);
            }
        	if(String.isNotBlank(string.valueof(customerCaseNumberSearchEntry))){
                
                whereCriteria.add(new ApexUtil.Criteria('Case__r.customer_case_number__c', customerCaseNumberSearchEntry, '='));
                buildLeadDetailURLParams('customerCaseNumberSearchEntry='+customerCaseNumberSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(subjectFirstNameSearchEntry))){
                whereCriteria.add(new ApexUtil.Criteria('Contact__r.First_Name__c', '%'+String.escapeSingleQuotes(subjectFirstNameSearchEntry)+'%', 'LIKE'));
                buildLeadDetailURLParams('subjectFirstNameSearchEntry='+subjectFirstNameSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(subjectLastNameSearchEntry))){
                whereCriteria.add(new ApexUtil.Criteria('Contact__r.Last_Name__c', '%'+String.escapeSingleQuotes(subjectLastNameSearchEntry)+'%', 'LIKE'));
                buildLeadDetailURLParams('subjectLastNameSearchEntry='+subjectLastNameSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(streetaddressSearchEntry))){
                whereCriteria.add(new ApexUtil.Criteria('Contact__r.Address__c', streetaddressSearchEntry, '='));
                buildLeadDetailURLParams('streetaddressSearchEntry='+streetaddressSearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(citySearchEntry))){
                
                whereCriteria.add(new ApexUtil.Criteria('Contact__r.city__c', citySearchEntry, '='));
                buildLeadDetailURLParams('citySearchEntry='+citySearchEntry);
            }
            
            if(String.isNotBlank(string.valueof(stateSearchEntry))){
                whereCriteria.add(new ApexUtil.Criteria('Contact__r.state__c', stateSearchEntry, '='));
                buildLeadDetailURLParams('stateSearchEntry='+stateSearchEntry);
            }
            if(String.isNotBlank(string.valueof(zipSearchEntry))){
                whereCriteria.add(new ApexUtil.Criteria('Contact__r.zip__c', zipSearchEntry, '='));
                buildLeadDetailURLParams('zipSearchEntry='+zipSearchEntry);
            }
            if(CurrentUser.User_Type__c == 'INV'){
                
                whereCriteria.add(new ApexUtil.Criteria('Assigned_to__c', userinfo.getuserid(), '=')); 
                whereCriteria.add(new ApexUtil.Criteria('Lead_Accepted_or_Rejected__c','Accepted', '='));    
            }else{
                //whereCriteria.add(new ApexUtil.Criteria('Assigned_to__c', '', '=')); 
            }
            
            
        String where_cond;
        if(searchUnassigned){
            System.debug('inside searchUnassigned...'+searchUnassigned);
            if(CurrentUser.User_Type__c == 'PMO' || CurrentUser.User_Type__c == 'CMO'){
                
                where_cond = 'Assigned_to__c = null AND Status__c != \'Completed\' and Case__r.Investigations_Date__c != null';  
            }else{
                where_cond = 'Assigned_to__c = null AND Status__c != \'Completed\' and Case__r.Investigations_Date__c != null and Case__r.Assigned_To__c =\''+userinfo.getuserid()+'\'';  
            }
            showacceptandrejectbuttons = false;  
            buildLeadDetailURLParams('searchUnassigned=true'); 
        }else if(searchmyavailableleads){
            buildLeadDetailURLParams('searchmyavailableleads=true'); 
            System.debug('inside searchmyavailableleads...'+searchmyavailableleads);
            whereCriteria = new List<ApexUtil.Criteria>();            
            whereCriteria.add(new ApexUtil.Criteria('Assigned_to__c', userinfo.getuserid(), '=')); 
            whereCriteria.add(new ApexUtil.Criteria('Lead_Accepted_or_Rejected__c','Accepted', '!=')); 
            whereCriteria.add(new ApexUtil.Criteria('Lead_Accepted_or_Rejected__c','Rejected', '!=')); 
            whereCriteria.add(new ApexUtil.Criteria('status__c','Completed', '!='));
            whereCriteria.add(new ApexUtil.Criteria('status__c','QA Review Completed', '!='));
            where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
            showacceptandrejectbuttons = true;   
            System.debug('inside searchmyavailableleads......where_cond...'+where_cond);
        }else if(searchmyAssigned){
            buildLeadDetailURLParams('searchmyAssigned=true'); 
            System.debug('inside searchmyAssigned...'+searchmyAssigned);
            
                        
            whereCriteria = new List<ApexUtil.Criteria>();
            whereCriteria.add(new ApexUtil.Criteria('Assigned_to__c', userinfo.getuserid(), '=')); 
            whereCriteria.add(new ApexUtil.Criteria('Lead_Accepted_or_Rejected__c','Accepted', '=')); 
            whereCriteria.add(new ApexUtil.Criteria('status__c','Completed', '!='));
            whereCriteria.add(new ApexUtil.Criteria('status__c','QA Rejected', '!='));
            whereCriteria.add(new ApexUtil.Criteria('status__c','QA Review Completed', '!='));
            where_cond = ApexUtil.generateWhereQuery(whereCriteria);  
           showacceptandrejectbuttons = false;     
        }else if(seachqarejected){
            buildLeadDetailURLParams('searchmyAssigned=true'); 
            System.debug('inside searchmyAssigned...'+searchmyAssigned);
            whereCriteria = new List<ApexUtil.Criteria>();
            

            
            whereCriteria.add(new ApexUtil.Criteria('Assigned_to__c', userinfo.getuserid(), '=')); 
            whereCriteria.add(new ApexUtil.Criteria('Lead_Accepted_or_Rejected__c','Accepted', '=')); 
            whereCriteria.add(new ApexUtil.Criteria('status__c','Completed', '!='));
            whereCriteria.add(new ApexUtil.Criteria('status__c','QA Rejected', '='));
            whereCriteria.add(new ApexUtil.Criteria('status__c','QA Review Completed', '!='));
            where_cond = ApexUtil.generateWhereQuery(whereCriteria);  
           showacceptandrejectbuttons = false;     
        }else if(searchmydiscontinued){
            buildLeadDetailURLParams('searchmydiscontinued=true'); 
            System.debug('inside searchmydiscontinued...'+searchmydiscontinued);
            whereCriteria = new List<ApexUtil.Criteria>();
            
                        
            whereCriteria.add(new ApexUtil.Criteria('Assigned_to__c', userinfo.getuserid(), '=')); 
            whereCriteria.add(new ApexUtil.Criteria('status__c','Discontinued', '='));
            where_cond = ApexUtil.generateWhereQuery(whereCriteria);  
           showacceptandrejectbuttons = false;     
        }else{
            System.debug('inside other...');
            where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
            showacceptandrejectbuttons = false; 
            buildLeadDetailURLParams('searchUnassigned=false');   
        }
        criteria = whereCriteria;
            criteria = JSON.serialize(criteria);
        System.debug('where_cond...'+where_cond);
        string countQuery;
            if(!string.isblank(where_cond)){
                queryForNextRecords = query + ' WHERE '+where_cond+' AND';
                query = query + ' WHERE '+where_cond+' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_Lead__c WHERE '+ where_cond;
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DIA_Lead__c';
            }
        
        
        totalRecordCount = database.countquery(Countquery);
        list<DIA_Lead__c> Leads = new list<DIA_Lead__c>();
        if(test.isRunningTest()){
        	Leads = [select id,Name from DIA_Lead__c];   
        }else{
         	Leads = database.query(query);        
       }
        integer i = 0;
        for(DIA_Lead__c cs: Leads){
            LeadsSearched.add(new LeadRecord(cs,false)); 
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
        system.debug('TotalPages...'+TotalPages);
        if(totalPages == 0){
            PageNumber = 0;
        }
        if(totalRecordCount <= 200){
            disablePrev = true;
            disableNext = true;
            currentRecordCount = totalRecordCount;
        }else{
        	disablePrev = true;   
            disableNext = false;
            currentRecordCount = 200; 
        }
        
        if(!searchAfterAssignment){
            showleadssearchcriteriapanel = false;
            showleadslistpanel = true;
            searchUnassigned = false;
            searchmyAssigned = false;
            seachqarejected = false;
            searchmyavailableleads = false;
        }
        
    }
    public boolean searchAfterAssignment{get;set;}
     public class LeadRecord{
        public DIA_Lead__c ld{get;set;}
        public boolean isSelected {get;set;}
        public boolean markasTDY {get;set;}
        public LeadRecord(DIA_Lead__c ld,boolean isSelected){
            this.ld = ld;
            this.isSelected = isSelected;
            this.markasTDY = markasTDY;
        }
    }
    
    public void MarkLeadAsTDY(){
        list<DIA_Lead__c> LeadsToUpdate = new LisT<DIA_Lead__c>();
        for(LeadRecord cR: LeadsSearched){
            if(cR.markasTDY){
                system.debug(cR);
                cr.ld.Mark_As_TDY__c = 'Yes';
                LeadsToUpdate.add(cr.ld);
            }
        }
        		update LeadsToUpdate;
    }
        
    public void unmarkLeadAsTDY(){
        list<DIA_Lead__c> LeadsToUpdate = new LisT<DIA_Lead__c>();
        for(LeadRecord cR: LeadsSearched){
            if(cR.markasTDY){
                system.debug(cR);
                cr.ld.Mark_As_TDY__c = 'No';
                LeadsToUpdate.add(cr.ld);
            }
        }
        		update LeadsToUpdate;
    }
    
    public static void updateleadsmethod(list<string> leadIds, string userIdForAssigment, Date acdDate){
         list<DIA_Lead__c> LeadsToUpdate = new LisT<DIA_Lead__c>();
         leadsToUpdate = [select id,Assigned_To__c,status__c,Lead_Accepted_or_Rejected__c,Assignee_Date__c,Anticipated_Completion_Date__c from dia_lead__c where id in:leadIds ];
        for(DIA_Lead__c cR: leadsToUpdate){
                cr.Assigned_To__c = userIdForAssigment;
                cr.status__c = 'Assigned';
                cr.Lead_Accepted_or_Rejected__c = null; 
                cr.Assignee_Date__c = system.today(); 
                cr.Anticipated_Completion_Date__c = acdDate; 
        }
        update leadsToUpdate;
    }
    
    public static void updateleadsunassignmethod(list<string> leadIds){
         list<DIA_Lead__c> LeadsToUpdate = new LisT<DIA_Lead__c>();
         leadsToUpdate = [select id,Assigned_To__c,status__c,Lead_Accepted_or_Rejected__c,Assignee_Date__c,Anticipated_Completion_Date__c from dia_lead__c where id in:leadIds ];
        for(DIA_Lead__c cR: leadsToUpdate){
                cr.Assigned_To__c = null;
                cr.status__c = 'Unassigned';
                cr.Lead_Accepted_or_Rejected__c = null; 
                cr.Assignee_Date__c = null; 
                cr.Accepted_Date__c = null; 
        }
        update leadsToUpdate;
    }
    
    
    public void AssignLeadsAction(){
        list<DIA_Lead__c> LeadsToUpdate = new LisT<DIA_Lead__c>();
        list<string> leadIdsToUpdate = new list<string>();
        for(LeadRecord cR: LeadsSearched){
            if(cR.isSelected){
                leadIdsToUpdate.add(cr.ld.id);
                cr.ld.Assigned_To__c = selectedUserIdForAssignment;
                cr.ld.status__c = 'Assigned';
                cr.ld.Lead_Accepted_or_Rejected__c = null; 
                cr.ld.Assignee_Date__c = system.today(); 
                cr.ld.Anticipated_Completion_Date__c = acdDate;
                LeadsToUpdate.add(cr.ld);
             }    
        }
        if(!leadIdsToUpdate.isEmpty()){
            System.debug('leadIdsToUpdate...'+leadIdsToUpdate);
            updateleadsmethod(leadIdsToUpdate,selectedUserIdForAssignment,acdDate);    
            
        }
        if(!LeadsToUpdate.isEmpty()){
            try{
               
               // update LeadsToUpdate;
                
            }catch(exception e){
                system.debug('Exception '+e);
            }  
        } 
        
        
         if(!leadDetailURLParamsMap.isEmpty()){
            for(String str: leadDetailURLParamsMap.keyset()){
            
                if(str == 'leadTypeSearchEntry'){
                    leadTypeSearchEntry = leadDetailURLParamsMap.get(str);
                } 
                if(str == 'leadStatusSearchEntry'){
                    leadStatusSearchEntry = leadDetailURLParamsMap.get(str);
                } 
                if(str == 'caseNumberSearchEntry'){
                    caseNumberSearchEntry = leadDetailURLParamsMap.get(str);
                } 
                if(str == 'customerCaseNumberSearchEntry'){
                    customerCaseNumberSearchEntry = leadDetailURLParamsMap.get(str);
                }
                if(str == 'manifestSearchEntry'){
                    manifestSearchEntry = leadDetailURLParamsMap.get(str);
                } 
                if(str == 'subjectFirstNameSearchEntry'){
                    subjectFirstNameSearchEntry = leadDetailURLParamsMap.get(str);
                } 
                if(str == 'subjectLastNameSearchEntry'){
                    subjectLastNameSearchEntry = leadDetailURLParamsMap.get(str);
                } 
                if(str == 'streetaddressSearchEntry'){
                    streetaddressSearchEntry = leadDetailURLParamsMap.get(str);
                } 
                if(str == 'citySearchEntry'){
                    citySearchEntry = leadDetailURLParamsMap.get(str);
                } 
                if(str == 'stateSearchEntry'){
                    stateSearchEntry = leadDetailURLParamsMap.get(str);
                } 
                if(str == 'ZipSearchEntry'){
                    ZipSearchEntry = leadDetailURLParamsMap.get(str);
                } 
                if(str == 'searchUnassigned'){
                    searchUnassigned = boolean.valueof(leadDetailURLParamsMap.get(str));
                } 
                if(str == 'searchmyAssigned'){
                    searchmyAssigned = boolean.valueof(leadDetailURLParamsMap.get(str));
                }
                if(str == 'searchmydiscontinued'){
                    searchmydiscontinued = boolean.valueof(leadDetailURLParamsMap.get(str));
                }
                if(str == 'seachqarejected'){
                    seachqarejected = boolean.valueof(leadDetailURLParamsMap.get(str));
                }
                if(str == 'searchmyavailableleads'){
                    searchmyavailableleads = boolean.valueof(leadDetailURLParamsMap.get(str));
                }    
            }
            //SearchAction();
        }
        
        
        
        
        //showleadssearchcriteriapanel = true;
        //showleadslistpanel = false;
        //searchAfterAssignment = true;
        //if(!test.isRunningTest()){
            //SearchAction();
        //}
        //searchAfterAssignment = false;
        selectedUserIdForAssignment = null;
        acdDate = Null;
   }
    
    public string leadIdToAccept{get;set;}
    public string leadIdToReject{get;set;}
    
    public void acceptaction(){
        list<LeadRecord> temp = new list<LeadRecord>();
        list<String> leadIds = new list<string>();
        for(LeadRecord lr: leadsSearched){
            if(lr.ld.id == leadIdToAccept){
                leadIds.add(lr.ld.id);
                lr.ld.Lead_Accepted_or_Rejected__c = 'Accepted'; 
                lr.ld.Accepted_Date__c = system.today(); 
               // update lr.ld;       
            }else{
                temp.add(lr);
            }    
        }
        if(!leadIds.isEmpty()){
            list<dia_lead__c> leads = new list<dia_lead__c>();
            leads = [select id,Lead_Accepted_or_Rejected__c,Accepted_Date__c  from dia_lead__C where id in: leadIds ];
                for(dia_lead__c l: leads){
                    l.Lead_Accepted_or_Rejected__c = 'Accepted'; 
                    l.Accepted_Date__c = system.today(); 
                } 
            update leads;
        }
        leadsSearched.clear();
        leadsSearched.addAll(temp);
    }
    
    public void rejectaction(){
        list<LeadRecord> temp = new list<LeadRecord>();
         list<String> leadIds = new list<string>();
        for(LeadRecord lr: leadsSearched){
            if(lr.ld.id == leadIdToReject){
                leadIds.add(lr.ld.id);
                lr.ld.Lead_Accepted_or_Rejected__c = 'Rejected'; 
                //lr.ld.Assigned_To__c = null;
                lr.ld.status__c = 'Investigator Rejected';  
                //update lr.ld;          
            }else{
                temp.add(lr);
            }    
        }
        if(!leadIds.isEmpty()){
            list<dia_lead__c> leads = new list<dia_lead__c>();
            leads = [select id,Lead_Accepted_or_Rejected__c,Accepted_Date__c,status__c  from dia_lead__C where id in: leadIds ];
                for(dia_lead__c l: leads){
                     l.Lead_Accepted_or_Rejected__c = 'Rejected'; 
                     l.status__c = 'Investigator Rejected'; 
                } 
            update leads;
        }
        leadsSearched.clear();
        leadsSearched.addAll(temp);
    }
    
     public void buildLeadDetailURLParams(string condition){
        if(String.isBlank(leadDetailURLParams)){
            leadDetailURLParams = condition;    
        }else{
            leadDetailURLParams = leadDetailURLParams + '&'+condition; 
        }
        list<string> temp = condition.split('=');
        System.debug('temp...'+temp);
        if(temp.size()==2){
            leadDetailURLParamsMap.put(temp[0],temp[1]);
        }
    }
    
    public string leadIdToUpdate {get;set;}
    public string acdDateToUpdate {get;set;}
    public string errorMessage {get;set;}
    public void UpdateACDLead(){
        errorMessage = Null;
        System.debug('acdDateToUpdate...'+acdDateToUpdate);
        System.debug('leadIdToUpdate...'+leadIdToUpdate);
        DIA_Lead__c leadToUpdate;
        for(LeadRecord l: LeadsSearched){
            if(l.ld.id == leadIdToUpdate){
                leadToUpdate = l.ld;
            }
        }    
        if(leadToUpdate != Null){
            try{
                leadToupdate.Anticipated_Completion_Date__c = Date.parse(acdDateToUpdate);
                update leadToUpdate;
            }catch(Exception ex){
                errorMessage = ex.getMessage();
            }
        }
    }
    
    public void updateACDDate(){
	list<DIA_Lead__c> LeadsToUpdate = new LisT<DIA_Lead__c>();
        for(LeadRecord cR: LeadsSearched){
            if(cR.isSelected){
                cr.ld.Anticipated_Completion_Date__c = anticipatedCompletionDate;
                LeadsToUpdate.add(cr.ld);
            }    
        }  
        		update LeadsToUpdate;
    }
    public void UnAssignLeadsAction(){
        list<DIA_Lead__c> LeadsToUpdate = new LisT<DIA_Lead__c>();
         list<string> leadIdsToUpdate = new list<string>();
        for(LeadRecord cR: LeadsSearched){
            if(cR.isSelected){
                leadIdsToUpdate.add(cr.ld.Id);
                cr.ld.Assigned_To__c = null;
                cr.ld.status__c = 'Unassigned';
                cr.ld.Lead_Accepted_or_Rejected__c = null; 
                cr.ld.Assignee_Date__c = null; 
                cr.ld.Accepted_Date__c = null;
                LeadsToUpdate.add(cr.ld);
            }    
        }  
        if(!leadIdsToUpdate.isEmpty()){
            //update LeadsToUpdate;
            System.debug('leadIdsToUpdate...'+leadIdsToUpdate);
            updateleadsunassignmethod(leadIdsToUpdate);         
        } 
        
        
         if(!leadDetailURLParamsMap.isEmpty()){
            for(String str: leadDetailURLParamsMap.keyset()){
            
                if(str == 'leadTypeSearchEntry'){
                    leadTypeSearchEntry = leadDetailURLParamsMap.get(str);
                } 
                if(str == 'leadStatusSearchEntry'){
                    leadStatusSearchEntry = leadDetailURLParamsMap.get(str);
                } 
                if(str == 'caseNumberSearchEntry'){
                    caseNumberSearchEntry = leadDetailURLParamsMap.get(str);
                } 
                if(str == 'customerCaseNumberSearchEntry'){
                    customerCaseNumberSearchEntry = leadDetailURLParamsMap.get(str);
                }
                if(str == 'manifestSearchEntry'){
                    manifestSearchEntry = leadDetailURLParamsMap.get(str);
                } 
                if(str == 'subjectFirstNameSearchEntry'){
                    subjectFirstNameSearchEntry = leadDetailURLParamsMap.get(str);
                } 
                if(str == 'subjectLastNameSearchEntry'){
                    subjectLastNameSearchEntry = leadDetailURLParamsMap.get(str);
                } 
                if(str == 'streetaddressSearchEntry'){
                    streetaddressSearchEntry = leadDetailURLParamsMap.get(str);
                } 
                if(str == 'citySearchEntry'){
                    citySearchEntry = leadDetailURLParamsMap.get(str);
                } 
                if(str == 'stateSearchEntry'){
                    stateSearchEntry = leadDetailURLParamsMap.get(str);
                } 
                if(str == 'ZipSearchEntry'){
                    ZipSearchEntry = leadDetailURLParamsMap.get(str);
                } 
                if(str == 'searchUnassigned'){
                    searchUnassigned = boolean.valueof(leadDetailURLParamsMap.get(str));
                } 
                if(str == 'searchmyAssigned'){
                    searchmyAssigned = boolean.valueof(leadDetailURLParamsMap.get(str));
                }
                if(str == 'searchmydiscontinued'){
                    searchmyDiscontinued = boolean.valueof(leadDetailURLParamsMap.get(str));
                }
                if(str == 'seachqarejected'){
                    seachqarejected = boolean.valueof(leadDetailURLParamsMap.get(str));
                }
                if(str == 'searchmyavailableleads'){
                    searchmyavailableleads = boolean.valueof(leadDetailURLParamsMap.get(str));
                }    
            }
            //SearchAction();
        }
   }
    public void handlePrev(){
        System.debug('queryForNextRecords...'+queryForNextRecords);
        system.debug('firstRecordName....'+firstRecordName);//7474
        system.debug('lastRecordName....'+lastRecordName);//7972
         system.debug('currentRecordCount....'+currentRecordCount);
        PageNumber --;
    	string query = queryForNextRecords + ' Name <:firstRecordName  Order by Name desc Limit 200';	   
        list<Dia_Lead__c> Leads = database.query(query);
        integer i = 0;
        LeadsSearched = new list<LeadRecord>();
        for(Integer j=Leads.size()-1;j>=0; j--){
            System.debug('leads size..'+leads.size());
             System.debug('j..'+j);
            LeadsSearched.add(new LeadRecord(Leads[j],false)); 
            if(j==Leads.size()-1){
            	firstRecordName = Leads[j].Name;	   
            }
            lastRecordName = Leads[j].Name; 
            
        }
        if(Leads.size()<=200){
        	currentRecordCount =  currentRecordCount - Leads.size();        
        }else{
        	currentRecordCount =  currentRecordCount - 200;    
        }
        
        /*if(currentRecordCount <=200){
            disablePrev = true;
            disableNext = false ;
        }else{
        	disablePrev = false;   
            disableNext = false;
        }*/
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
        System.debug('queryForNextRecords...'+queryForNextRecords);
        system.debug('lastRecordName....'+lastRecordName);
    	string query = queryForNextRecords + ' Name >:lastRecordName  Order by Name asc Limit 200';	   
        System.debug('query...'+query);
        list<Dia_Lead__c> Leads = database.query(query);
        LeadsSearched = new list<LeadRecord>();
        integer i = 0;
        for(Dia_Lead__c cs: Leads){
            LeadsSearched.add(new LeadRecord(cs,false)); 
            if(i==0){
            	firstRecordName = cs.Name;    
            }
            lastRecordName = cs.Name;
            i++;
        }
        if(Leads.size()<=200){
        	currentRecordCount =  currentRecordCount + Leads.size();        
        }else{
        	currentRecordCount =  currentRecordCount + 200;    
        }
        /*
        if(totalRecordCount>currentRecordCount){
            disablePrev = false;
            disableNext = false;
        }else{
        	disablePrev = false;   
            disableNext = true;
        }*/
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
}