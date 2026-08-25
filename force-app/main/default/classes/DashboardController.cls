public with sharing class DashboardController {
    public integer totalSubjects {get;set;}
    public integer totalCases {get;set;}
    public integer totalCancelledCases {get;set;}
    public integer totalLeads {get;set;}
    public integer totalPendingCases {get;set;}
    public integer totalCompletedCases {get;set;}
    public integer totalPendingLeads {get;set;}
    public string currentPendingCaseStatus {get;set;}
    public string currentWeekCompletedCaseStatus {get;set;}
    public string pendingLeadsByType {get;set;}
    public string pendingLeadsByStatus {get;set;}
    public string completedLeadsByWeek {get;set;}
    public list<string> currentweekDates{get;set;}
    public string testCMOIds    {get;set;}
    public string testINVIds    {get;set;}
    public user currentUser {get;set;}
    
    public DashboardController(){
        currentUser = [select id,user_type__c from user where id =: userInfo.getUserId()];
        
        testCMOIds = string.valueOf(removeTestUserData('CMO').get('value'));
        testINVIds = string.valueOf(removeTestUserData('INV').get('value'));
        List<string> testCMOs = string.valueOf(system.label.Test_cmos).split(',');
        List<string> testInvs = string.valueOf(system.label.Test_cmos).split(',');
        totalCancelledCases = [SELECT COUNT() FROM Case__c WHERE Status__c = 'Delivered canceled' OR Status__c = 'Canceled'];
        totalCases = [SELECT COUNT() FROM Case__c WHERE Assigned_To__c NOT IN:testCMOs ];
        totalLeads = [SELECT COUNT() FROM Lead__c WHERE Assigned_To__c NOT IN:testInvs ];
        totalPendingCases = [SELECT COUNT() FROM Case__c WHERE Status__c = 'Active' AND Assigned_To__c NOT IN:testCMOs];
        totalCompletedCases = [SELECT COUNT() FROM Case__c WHERE Status__c = 'Delivered' AND Assigned_To__c NOT IN:testCMOs];
        totalPendingLeads = [SELECT COUNT() FROM Lead__c WHERE Status__c != 'Completed' AND Assigned_To__c NOT IN:testInvs];
        
        
        List<Map<string,Object>> conditions = New List<Map<string,Object>>();
        
        
        
        conditions.add(removeTestUserData('CMO'));
        list<string> objectFields = new list<string>{'Id'};
        //object totalCasesObj = DIATooling.fetchRecords('Case__c',objectFields,conditions,null,null);
        //Map<String, Object> mappedResponse = (Map<String, Object>)JSON.deserializeUntyped(string.valueOf(totalCasesObj));
        //totalCases = (integer)mappedResponse.get('totalSize');
        
        List<Map<string,Object>> LeadCondition = New List<Map<string,Object>>();
        LeadCondition.add(removeTestUserData('INV'));
        //object totalLeadsObj = DIATooling.fetchRecords('Lead__c',objectFields,LeadCondition,null,null);
        //Map<String, Object> mappedResponseForLead = (Map<String, Object>)JSON.deserializeUntyped(string.valueOf(totalLeadsObj));
        //totalLeads = (integer)mappedResponseForLead.get('totalSize');
        
        List<Map<string,Object>> caseconditions = New List<Map<string,Object>>();
        Map<string,Object> caseCondition1 = New Map<string,Object>();
        //caseCondition1.put('key','Case_Queue_Status__c');
        //caseCondition1.put('value','Completed');
        caseCondition1.put('key','Status__c');
        caseCondition1.put('value','Delivered');
        caseCondition1.put('operator','!=');
        caseconditions.add(caseCondition1);
        
        caseconditions.add(removeTestUserData('CMO'));
        //object totalPendingCasesObj = DIATooling.fetchRecords('Case__c',objectFields,caseconditions,null,null);
        //Map<String, Object> totalPendingCasesObjmappedResponse = (Map<String, Object>)JSON.deserializeUntyped(string.valueOf(totalPendingCasesObj));
        //totalPendingCases = (integer)totalPendingCasesObjmappedResponse.get('totalSize');
        
        caseconditions = New List<Map<string,Object>>();
        caseCondition1 = New Map<string,Object>();
        //caseCondition1.put('key','Case_Queue_Status__c');
        //caseCondition1.put('value','Completed');
        caseCondition1.put('key','Status__c');
        caseCondition1.put('value','Active');
        caseCondition1.put('operator','=');
        caseconditions.add(caseCondition1);
        caseconditions.add(removeTestUserData('CMO'));
        
        
        //object totalCompeletedCasesObj = DIATooling.fetchRecords('Case__c',objectFields,caseconditions,null,null);
        
        //Map<String, Object> totalCompeletedCasesObjmappedResponse = (Map<String, Object>)JSON.deserializeUntyped(string.valueOf(totalCompeletedCasesObj));
        //totalCompletedCases = (integer)totalCompeletedCasesObjmappedResponse.get('totalSize');
        
        
        List<Map<string,Object>> leadconditions = New List<Map<string,Object>>();
        Map<string,Object> leadCondition1 = New Map<string,Object>();
        leadCondition1.put('key','status__c');
        leadCondition1.put('value','Completed');
        leadCondition1.put('operator','!=');
        leadconditions.add(leadCondition1);
        leadconditions.add(removeTestUserData('INV'));
        
        //object totalPendingLeadsObj = DIATooling.fetchRecords('Lead__c',objectFields,leadconditions,null,null);
        
        //Map<String, Object> totalPendingLeadsObjmappedResponse = (Map<String, Object>)JSON.deserializeUntyped(string.valueOf(totalPendingLeadsObj));
        //totalPendingLeads = (integer)totalPendingLeadsObjmappedResponse.get('totalSize');
        
        
        List<Case__c> pendingCases = new List<Case__c>();
        List<string> CMOs = New List<string>();
        if(!testCMOs.isEmpty()){
            for(string cmo : testCMOs){
                CMOs.add('\''+ cmo + '\'');
            }
        }
        
        pendingCases = [Select id, Current_Task__c,status__c  from Case__C where status__c = 'Active' and assigned_to__c Not IN : testcmos];
        
        List<Case__c> completedCases = new List<Case__c>();
        completedCases = [Select id, Case_Queue_Status__c, Case_Completed_Date__c, Status__c from Case__C where Status__c = 'Delivered' and Case_Completed_Date__c = THIS_WEEK and assigned_to__c Not IN : testcmos];
        
        List<string> INVs = New List<string>();
        if(!testINVs.isEmpty()){
            for(string inv : testINVs){
                INVs.add('\''+ inv + '\'');
            }
        }
        
        List<Lead__c> pendingLeads = new List<Lead__c>();
        pendingLeads = [select id, status__c, LeadType__c  from Lead__c where status__c!='Completed' and assigned_to__c Not IN : INVs];
        map<string,integer> pendingleadsByStatusMap = new map<string,integer>();
        list<list<object>> pendingleadsByStatusList = new list<list<object>>();
        
        map<string,integer> pendingleadsByTypeMap = new map<string,integer>();
        list<list<object>> pendingleadsByLeadTypeList = new list<list<object>>();
        
        map<string,integer> pendingCasesByStatusMap = new map<string,integer>();
        list<list<object>> pendingCasesByStatusList = new list<list<object>>();
        
        
        for(Lead__c lead: pendingLeads){
            if(!pendingleadsByStatusMap.containsKey(lead.status__c)){
                pendingleadsByStatusMap.put(lead.status__c,1);    
            }else{
                integer temp = pendingleadsByStatusMap.get(lead.status__c)+1;
                pendingleadsByStatusMap.put(lead.status__c,temp);       
            }  
            if(!pendingleadsByTypeMap.containsKey(lead.LeadType__c)){
                pendingleadsByTypeMap.put(lead.LeadType__c,1);    
            }else{
                integer temp = pendingleadsByTypeMap.get(lead.LeadType__c)+1;
                pendingleadsByTypeMap.put(lead.LeadType__c,temp);       
            }  
        }
        for(string str: pendingleadsByStatusMap.keyset()){
            list<object> temp = new list<object>();   
            temp.add(str);
            temp.add(pendingleadsByStatusMap.get(str));
            pendingleadsByStatusList.add(temp);
        }
        pendingLeadsByStatus = JSON.serialize(pendingleadsByStatusList);
        
        
        for(string str: pendingleadsByTypeMap.keyset()){
            list<object> temp = new list<object>();   
            temp.add(str);
            temp.add(pendingleadsByTypeMap.get(str));
            pendingleadsByLeadTypeList.add(temp);
        }
        pendingLeadsByType = JSON.serialize(pendingleadsByLeadTypeList);
        
        
        
        for(case__c diacase: pendingCases){
            if(!pendingcasesByStatusMap.containsKey(diacase.Current_Task__c)){
                pendingcasesByStatusMap.put(diacase.Current_Task__c,1);    
            }else{
                integer temp = pendingcasesByStatusMap.get(diacase.Current_Task__c)+1;
                pendingcasesByStatusMap.put(diacase.Current_Task__c,temp);       
            }  
            
        }
        for(string str: pendingcasesByStatusMap.keyset()){
            list<object> temp = new list<object>();   
            temp.add(str);
            temp.add(pendingcasesByStatusMap.get(str));
            pendingcasesByStatusList.add(temp);
        }
        currentPendingCaseStatus = JSON.serialize(pendingcasesByStatusList);
        
        currentweekDates = getCurrentWeekDates();
        //currentWeekCompletedCaseStatus
        //
        map<string,integer> completedCasesByDateThisweekMap = new map<string,integer>();
        list<list<object>> completedCasesByDateThisweek = new list<list<object>>();
        
        
        
        for(case__c diacase: completedCases){
            if(!completedCasesByDateThisweekMap.containsKey(string.valueof(diacase.Case_Completed_Date__c))){
                completedCasesByDateThisweekMap.put(string.valueof(diacase.Case_Completed_Date__c),1);    
            }else{
                integer temp = completedCasesByDateThisweekMap.get(string.valueof(diacase.Case_Completed_Date__c))+1;
                completedCasesByDateThisweekMap.put(string.valueof(diacase.Case_Completed_Date__c),temp);       
            }  
            
        }
        for(string cd:currentweekDates){
            //System.debug('cd...'+cd);
            if(!completedCasesByDateThisweekMap.containsKey(cd)){
                completedCasesByDateThisweekMap.put(cd,0);    
            }    
        }
        
        for(string str: currentweekDates){
            // System.debug('str...'+str);
            list<object> temp = new list<object>();   
            temp.add(str);
            temp.add(completedCasesByDateThisweekMap.get(str));
            completedCasesByDateThisweek.add(temp);
        }
        
        currentWeekCompletedCaseStatus = JSON.serialize(completedCasesByDateThisweek);
        
        
        
        
    }
    
    public list<string> getCurrentWeekDates(){
        list<string> weekDates = new list<string>();
        Date dtFirstWeek = system.today().toStartOfWeek();
        weekDates.add(string.valueof(dtFirstWeek));
        for(integer i=1;i<6;i++){
            date temp = dtFirstWeek.addDays(i);  
            weekDates.add(string.valueof(temp));
        }
        
        return weekDates;
    }
    public static Map<string,Object> removeTestUserData(string userType){
        Map<string,Object> condition = New Map<string,Object>();
        if(userType == 'CMO'){
            List<string> testCMOs = string.valueOf(system.label.Test_cmos).split(',');
            if(!testCMOs.isEmpty()){
                List<string> CMOs = New List<string>();
                for(string cmo : testCMOs){
                    CMOs.add('\''+ cmo + '\'');
                }
                condition.put('key','Assigned_To__c');
                condition.put('value',string.join(CMOs,','));
                condition.put('operator','NOT IN');
            }
        }else if(userType == 'INV'){
            List<string> testINVs = string.valueOf(system.label.Test_INVs).split(',');
            if(!testINVs.isEmpty()){
                List<string> INVs = New List<string>();
                for(string inv : testINVs){
                    INVs.add('\''+ inv + '\'');
                }
                condition.put('key','Assigned_To__c');
                condition.put('value',string.join(INVs,','));
                condition.put('operator','NOT IN');
            }
        }
        return condition;
    }
    @AuraEnabled
    Public static List<Map<string,Object>> getFieldMap(string reportType){
        List<Map<string,Object>> fieldMapReturn = New List<Map<string,Object>>();
        if(reportType == 'pendingCasesByStatus'){
            Map<String, Pending__mdt> mapME = Pending__mdt.getAll();
            for(string key : mapME.keyset()){
                Map<string,Object> con = New Map<string,Object>();
                con.put('label',(string)mapME.get(key).get('Label'));
                con.put('apiname',(string)mapME.get(key).get('API_Name__c'));
                fieldMapReturn.add(con);
            }
        }else if(reportType == 'PendingLeadsByStatus'){
            Map<String, Pending_Leads_By_Status__mdt> mapPL = Pending_Leads_By_Status__mdt.getAll();
            for(string key : mapPL.keyset()){
                Map<string,Object> con = New Map<string,Object>();
                con.put('label',(string)mapPL.get(key).get('Label'));
                con.put('apiname',(string)mapPL.get(key).get('API_Name__c'));
                fieldMapReturn.add(con);
            }
        }else if(reportType == 'PendingLeadsByType'){
            Map<String, Pending_Leads_By_Type__mdt> mapPLT = Pending_Leads_By_Type__mdt.getAll();
            for(string key : mapPLT.keyset()){
                Map<string,Object> con = New Map<string,Object>();
                con.put('label',(string)mapPLT.get(key).get('Label'));
                con.put('apiname',(string)mapPLT.get(key).get('API_Name__c'));
                fieldMapReturn.add(con);
            }
        }else if(reportType == 'CasesCompletedThisWeek'){
            Map<String, Cases_Completed_This_Week__mdt> mapCC = Cases_Completed_This_Week__mdt.getAll();
            for(string key : mapCC.keyset()){
                Map<string,Object> con = New Map<string,Object>();
                con.put('label',(string)mapCC.get(key).get('Label'));
                con.put('apiname',(string)mapCC.get(key).get('API_Name__c'));
                fieldMapReturn.add(con);
            }
        }
        return fieldMapReturn;
    }
}