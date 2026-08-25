public with sharing class TimesheetsController {
    public list<timesheet__c> timesheets{get;set;}
    public string periodStartDate{get;set;}
    public string periodEndDate{get;set;}
    public Integer currentYear{get;set;}
    public string currentMonth{get;set;}
    public string todaysDateTime{get;set;}
    public timesheet__c currentDayTimeSheet{get;set;}
    public list<Investigator_Check__c> newInvestigatorCheckedOutRecords{get;set;}
    public list<Investigator_Check__c> newInvestigatorCheckedInRecords{get;set;}
    public boolean isCheckedOut{get;set;}
    
    
    public class DateRange {
        public Date startDate { get; set; }
        public Date endDate   { get; set; }
        
        public DateRange(Date startDate, Date endDate) {
            this.startDate = startDate;
            this.endDate   = endDate;
        }
        
    }
    
    public static List<DateRange> generateRanges() {
        List<DateRange> ranges = new List<DateRange>();
        
        // Start date
        Date startDate = Date.newInstance(system.today().year(), 1, 13);
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
    public date periodStartDateVal;
    public date periodEndDateVal;
    public date enddate;
    public class DateWrapper {
        public string dateVal {get; set;}
        public String dayName {get; set;}
        
        public DateWrapper(string d, String name) {
            dateVal = d;
            dayName = name;
        }
    }
    public List<DateWrapper> dateWrappers {get; set;}

    public void debugRanges() {
        dateWrappers = New List<DateWrapper>();
        for (DateRange dr : generateRanges()) {
            if(system.today() <= dr.enddate && system.today() >= dr.startDate){
                periodStartDateVal = dr.startDate;
                periodEndDateVal = dr.enddate;
                for(integer i = 0; i<= 13;i++){
                    string dayname = DateTime.newInstance(dr.startDate.year(), dr.startDate.month(), dr.startDate.adddays(i).day()).format('EEEE');
                    string dateValue = dr.startDate.adddays(i).month()+'/'+dr.startDate.adddays(i).day()+'/'+dr.startDate.adddays(i).year();
                    dateWrappers.add(new DateWrapper(dateValue, dayname));
                    enddate = dr.startDate.adddays(i);
                }
            }
            
        }
                for(DateWrapper s : dateWrappers){
                    System.debug(s.dayName+' ===> '+s.dateVal);
                }
    }
    
        
 
    
    public TimesheetsController(){
		debugRanges();
        if(dateWrappers.size() > 0){
            periodStartDate = dateWrappers[0].dateVal;
            periodEndDate = dateWrappers[dateWrappers.size()-1].dateVal;
        }
        
        
        List<string> timesheetFields = new List<string>();
        timesheetFields = ApexUtil.FetchFields('timesheet__c');
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        String query = 'Select '+string.join(timesheetFields, ',') + ' From timesheet__c ';
        String where_cond;
        whereCriteria.add(new Apexutil.Criteria('Date__c',String.valueof(periodStartDateVal), '>=', 'Date'));
        whereCriteria.add(new Apexutil.Criteria('Date__c',String.valueof(enddate), '<=', 'Date'));
        whereCriteria.add(new Apexutil.Criteria('User__c',userinfo.getUserId(), '='));
        where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+' WITH SECURITY_ENFORCED Order By Date__c'; 
        System.debug('query...'+query);
        timesheets = database.query(query);
        System.debug('timesheets...'+timesheets);
        for(timesheet__c t: timesheets){
            if(!test.isRunningTest()){
                if(t.user__c == userinfo.getuserid() && t.Date__c==system.today()){
                    currentDayTimeSheet = t;
                }
            }else{
                currentDayTimeSheet = t;        
            }
        }
        FetchInvestigatorCheckRecords(currentDayTimeSheet);
        
    }
    
    public void FetchInvestigatorCheckRecords(TimeSheet__c todaysTimeSheet){
        if(todaysTimeSheet != null){
            isCheckedOut = false;
            newInvestigatorCheckedOutRecords = new list<Investigator_Check__c>();
            newInvestigatorCheckedInRecords = new list<Investigator_Check__c>();
    
            List<string> investigatorCheckFields = new List<string>();
            investigatorCheckFields = ApexUtil.FetchFields('Investigator_Check__c');
            
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            String query = 'Select '+string.join(investigatorCheckFields, ',') + ' From Investigator_Check__c ';
            String where_cond;
            whereCriteria.add(new Apexutil.Criteria('TimeSheet__c',todaysTimeSheet.id, '='));  
            where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
            query = query + ' WHERE '+where_cond+' WITH SECURITY_ENFORCED'; 
            System.debug('query...'+query);
            list<Investigator_Check__c> invChecks = database.query(query);
            
            for(Investigator_Check__c invc: invChecks){
                if(invc.Type__c == 'CheckOut'){
                    newInvestigatorCheckedOutRecords.add(invc); 
                }else if(invc.Type__c == 'CheckIn'){
                    newInvestigatorCheckedInRecords.add(invc);
                }   
            }
            System.debug('newInvestigatorCheckedOutRecords....'+newInvestigatorCheckedOutRecords);
            if(!todaysTimeSheet.checked_out__c){
                Investigator_Check__c invc = new Investigator_Check__c();
                invc.type__c= 'CheckOut';
                invc.timesheet__c = todaysTimeSheet.id;
                newInvestigatorCheckedOutRecords.add(invc);
            } else{
                isCheckedOut = true;
            }  
            System.debug('newInvestigatorCheckedInRecords....'+newInvestigatorCheckedInRecords);
        }
    }
    
    public void addNewInvestigatorCheck(){
        Investigator_Check__c invc = new Investigator_Check__c();
        invc.type__c= 'CheckOut';
        invc.timesheet__c = currentDayTimeSheet.id;
        newInvestigatorCheckedOutRecords.add(invc);
    }
    
    public void removeNewInvestigatorCheck(){
        Integer indexVal = Integer.valueof(system.currentpagereference().getparameters().get('index'));  
        newInvestigatorCheckedOutRecords.remove(indexVal);        
        System.debug('indexVal...'+indexVal);    
    }
    
    public void checkoutapexaction(){
        System.debug('currentDayTimeSheet...'+currentDayTimeSheet);
        System.debug('newInvestigatorCheckedOutRecords...'+newInvestigatorCheckedOutRecords);
        for(Investigator_Check__c checkout: newInvestigatorCheckedOutRecords){
             checkout.Checkout_Comments__c = currentDayTimeSheet.Checkout_Comments__c;
        }
        database.upsert(newInvestigatorCheckedOutRecords,false,AccessLevel.USER_MODE);
        currentDayTimeSheet.checked_out__c = true;
        database.update(currentDayTimeSheet,false,AccessLevel.USER_MODE);
        
        list<Investigator_Check__c> checkinrecords = new list<Investigator_Check__c>();
        for(Investigator_Check__c invc: newInvestigatorCheckedOutRecords){
            Investigator_Check__c temp = invc.clone(false,false,false,false);
            temp.type__c= 'CheckIn';
            checkinrecords.add(temp);    
        }

        System.debug('Check in records'+checkinrecords);
        database.insert(checkinrecords,false,AccessLevel.USER_MODE);

        FetchInvestigatorCheckRecords(currentDayTimeSheet);
        
        isCheckedOut = true;
    }
    
    
    public void checkinapexaction(){
        for(Investigator_Check__c invc: newInvestigatorCheckedInRecords){
           invc.Checkin_Comments__c = currentDayTimeSheet.Checkin_Comments__c; 
        }
        
        database.update(newInvestigatorCheckedInRecords,false,AccessLevel.USER_MODE);
        currentDayTimeSheet.checked_in__c = true;
        database.update(currentDayTimeSheet,false,AccessLevel.USER_MODE);
        
        FetchInvestigatorCheckRecords(currentDayTimeSheet);
    
    }
    
    public void updatetimesheetsaction(){
        update timesheets;
        //database.saveresult[] sr = database.update(timesheets,false,AccessLevel.USER_MODE);  
        //system.debug(sr);
    }

    
    public void submittimesheetsaction(){
        for(timesheet__c ts: timesheets){
            ts.submitted__c = true;    
        }  
        update timesheets;
        //database.saveresult[] sr = database.update(timesheets,false,AccessLevel.USER_MODE);
        //system.debug(sr);
    }
}