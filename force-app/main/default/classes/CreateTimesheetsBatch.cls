global with sharing class CreateTimesheetsBatch implements Database.Stateful,Database.Batchable<sObject> {
    public date periodStartDateVal;
    public class DateRange {
        public Date startDate { get; set; }
        public Date endDate   { get; set; }
        
        public DateRange(Date startDate, Date endDate) {
            this.startDate = startDate;
            this.endDate   = endDate;
        }
        
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
        for (DateRange dr : generateRanges()) {
            if(system.today() <= dr.enddate && system.today() >= dr.startDate){
                periodStartDateVal = dr.startDate;
            }
        }
        
        List<string> userFields = new List<string>();
        userFields = ApexUtil.FetchFields('User');
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        String query = 'Select '+string.join(userFields, ',') + ' From User ';
        String where_cond;
        List<String> userProfiles = new List<String>();
        if(!test.isRunningTest()){
            userProfiles.addAll(System.label.IntelUserProfilesToCreateTimesheets.split(','));    
        }else{
            userProfiles.add('System Administrator');        
        }
        Map<String, Profile> profileMap = new Map<String, Profile>([Select Id, Name from Profile WHERE Name IN:userProfiles]);
        List<String> profileIds = new List<String> ();
        profileIds.addAll(profileMap.Keyset());
		query = query + ' WHERE ProfileId IN:profileIds '; 
        System.debug('query...'+query);
        return Database.getQueryLocator(query);       
    }
    public static List<DateRange> generateRanges() {
        List<DateRange> ranges = new List<DateRange>();
        // Start date
        Date startDate = Date.newInstance(system.today().year(), 1, 13);
        // End limit (Jan 2026 start)
        Date limitDate = Date.newInstance(system.today().addyears(1).year(), 1, 1);
        while (startDate < limitDate) {
            Date endDate = startDate.addDays(13); // 13-day span
            // if end date goes beyond limit, adjust
            if (endDate > limitDate) {
                endDate = limitDate;
            }
            ranges.add(new DateRange(startDate, endDate));
            // next start is the day after current end
            startDate = endDate.addDays(1);
        }        
        return ranges;
    }
    
    global void execute(Database.BatchableContext BC, List<User> users) {
        set<Id> userIds = New set<Id>();
        Map<string,List<date>> userNTimeSheets = New Map<string,List<date>>();
        for(User u : users){
            userIds.add(u.Id);
        }
        list<TimeSheet__c> existingTimeSheets = [select id,date__c,User__c from TimeSheet__c where date__c >=:periodStartDateVal and User__c IN: userIds];
        for(TimeSheet__c timeS : existingTimeSheets){
            if(!userNTimeSheets.ContainsKey(timeS.User__c)) userNTimeSheets.put(timeS.User__c,New List<date>());
            userNTimeSheets.get(timeS.User__c).add(timeS.Date__c);
        }        
        list<TimeSheet__c> timeSheetsToCreate = new list<TimeSheet__c>();
        for(User u: users){
			system.debug(u.Name);
			date yearStartDate = periodStartDateVal;
           	date yearEndDate = date.Newinstance(date.today().addYears(1).year(),1,1);
            integer numberOfDaysInYear = yearStartDate.daysBetween(yearEndDate);
            system.debug(numberOfDaysInYear);
            for(integer i = 0; i < numberOfDaysInYear ; i++){
                if(userNTimeSheets.containsKey(u.Id)){
                    List<date> existingDates = userNTimeSheets.get(u.Id);
                    if(existingDates.contains(yearStartDate.adddays(i))){
                        continue;
                    }
                }
                TimeSheet__c timeSheet = new TimeSheet__c();
				timeSheet.Date__c = yearStartDate.adddays(i);
				timeSheet.Day_Name__c = DateTime.newInstance(yearStartDate.year(), yearStartDate.month(), yearStartDate.day()).adddays(i).format('EEEE');
				timeSheet.User__c = u.id;
                timeSheetsToCreate.add(timeSheet);
            }
        }
        if(!timeSheetsToCreate.isEmpty()){
            insert timeSheetsToCreate;    
            system.debug(timeSheetsToCreate);
        }
    }
    global void finish(Database.BatchableContext BC) {
        
    }
}