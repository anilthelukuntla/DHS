global with sharing class DIACreateTimesheetsBatch implements Database.Stateful,Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        List<string> userFields = new List<string>();
        userFields = ApexUtil.FetchFields('User');
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        String query = 'Select '+string.join(userFields, ',') + ' From User ';
        String where_cond;
        List<String> userProfiles = new List<String>();
        if(!test.isRunningTest()){
            userProfiles.addAll(System.label.DIAUserProfilesToCreateTimesheets.split(','));    
        }else{
            userProfiles.add('System Administrator');        
        }
        
        Map<String, Profile> profileMap = new Map<String, Profile>([Select Id, Name from Profile WHERE Name IN:userProfiles WITH SECURITY_ENFORCED]);
        //whereCriteria.add(new ApexUtil.Criteria('UserName', 'usda-rd@isncorp.com.insight', '='));
        //where_cond = ApexUtil.generateWhereQuery(whereCriteria); 
        //if(where_cond != Null){
        List<String> profileIds = new List<String> ();
        profileIds.addAll(profileMap.Keyset());
            query = query + ' WHERE ProfileId IN:profileIds'; 
        //}
        System.debug('query...'+query);
        return Database.getQueryLocator(query);       
    }
    global void execute(Database.BatchableContext BC, List<User> users) {
       
        list<DIA_timesheet__c> timeSheetsToCreate = new list<DIA_timesheet__c>();
        DateTime todaysDateTime = System.now();
        Integer currentDayOfMonth = todaysDateTime.day();
        Integer month = Date.Today().Month();
        Integer year = Date.Today().Year();
        Integer numberDays = Date.daysInMonth(year, month);
        
        for(User u: users){
            if(currentDayOfMonth >= 1 && currentDayOfMonth <= 15){
                Date startDate = Date.newinstance(year, month, 1);
                Date endDate = Date.newinstance(year, month, 15);
                for(Integer i=1; i<=15;i++){
                    DIA_timesheet__c timeSheet = new DIA_timesheet__c();
                    timeSheet.Period_From__c = startDate;
                    timeSheet.Period_to__c = endDate;
                    timeSheet.Date__c = Date.newinstance(year, month, i);
                    timeSheet.Day_Name__c = DateTime.newInstance(year, month, i).format('EEEE');
                    timeSheet.User__c = u.id;
                    timeSheetsToCreate.add(timeSheet);
                }       
            }
            if(currentDayOfMonth >= 16){
                Date startDate = Date.newinstance(year, month, 16);
                Date endDate = Date.newinstance(year, month, numberDays);    
                for(Integer i=16; i<=numberDays;i++){
                    DIA_timesheet__c timeSheet = new DIA_timesheet__c();
                    timeSheet.Period_From__c = startDate;
                    timeSheet.Period_to__c = endDate;
                    timeSheet.Date__c = Date.newinstance(year, month, i);
                    timeSheet.Day_Name__c = DateTime.newInstance(year, month, i).format('EEEE');
                    timeSheet.User__c = u.id;
                    timeSheetsToCreate.add(timeSheet);  
                }    
            }
        }
        
        if(!timeSheetsToCreate.isEmpty()){
            if(Schema.SobjectType.DIA_timesheet__c.iscreateable()){
                List<Database.SaveResult> dsr = database.insert(timeSheetsToCreate,false,AccessLevel.USER_MODE);
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to create Time Sheet'));
            }
        }
    }
    global void finish(Database.BatchableContext BC) {
    }
}