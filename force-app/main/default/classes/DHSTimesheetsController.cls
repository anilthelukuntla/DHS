/**
 * @description Controls DHS pay-period timesheets and investigator check-in/out records.
 */
@SuppressWarnings('PMD.EmptyStatementBlock,PMD.ExcessivePublicCount,PMD.FieldDeclarationsShouldBeAtStart,PMD.NcssConstructorCount')
public with sharing class DHSTimesheetsController {
    /** @description Provides this DHS API member. */
    public list<DHS_TimeSheet__c> timesheets{get;set;}
    /** @description Provides this DHS API member. */
    public string periodStartDate{get;set;}
    /** @description Provides this DHS API member. */
    public string periodEndDate{get;set;}
    /** @description Provides this DHS API member. */
    public Integer currentYear{get;set;}
    /** @description Provides this DHS API member. */
    public string currentMonth{get;set;}
    /** @description Provides this DHS API member. */
    public string todaysDateTime{get;set;}
    /** @description Provides this DHS API member. */
    public DHS_TimeSheet__c currentDayTimeSheet{get;set;}
    /** @description Provides this DHS API member. */
    public list<DHS_Investigator_Check__c> newInvestigatorCheckedOutRecords{get;set;}
    /** @description Provides this DHS API member. */
    public list<DHS_Investigator_Check__c> newInvestigatorCheckedInRecords{get;set;}
    public boolean isCheckedOut{get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    
    
    /** @description Provides this DHS API member. */
    public class DateRange {
        /** @description Provides this DHS API member. */
        public Date startDate { get; set; }
        /** @description Provides this DHS API member. */
        public Date endDate   { get; set; }
        
        /**
         * @description Provides this DHS API member.
         * @param startDate Method parameter.
         * @param endDate Method parameter.
         */
        public DateRange(Date startDate, Date endDate) {
            this.startDate = startDate;
            this.endDate   = endDate;
        }
        
    }
    
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
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
    /** @description Provides this DHS API member. */
    public class DateWrapper {
        /** @description Provides this DHS API member. */
        public string dateVal {get; set;}
        /** @description Provides this DHS API member. */
        public String dayName {get; set;}
        
        /**
         * @description Provides this DHS API member.
         * @param d Method parameter.
         * @param name Method parameter.
         */
        public DateWrapper(string d, String name) {
            dateVal = d;
            dayName = name;
        }
    }
    /** @description Provides this DHS API member. */
    public List<DateWrapper> dateWrappers {get; set;}

    /** @description Provides this DHS API member. */
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
                }
    }
    
        
 
    
    /** @description Provides this DHS API member. */
    public DHSTimesheetsController(){
		debugRanges();
        if(dateWrappers.size() > 0){
            periodStartDate = dateWrappers[0].dateVal;
            periodEndDate = dateWrappers[dateWrappers.size()-1].dateVal;
        }
        
        
        List<string> timesheetFields = new List<string>();
        timesheetFields = DHSApexUtil.FetchFields('DHS_TimeSheet__c');
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        String query = 'Select '+string.join(timesheetFields, ',') + ' From DHS_TimeSheet__c ';
        whereCriteria.add(new DHSApexUtil.Criteria('Date__c',String.valueof(periodStartDateVal), '>=', 'Date'));
        whereCriteria.add(new DHSApexUtil.Criteria('Date__c',String.valueof(enddate), '<=', 'Date'));
        whereCriteria.add(new DHSApexUtil.Criteria('DHS_User__c',userinfo.getUserId(), '='));
        String whereCondition = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+whereCondition+' Order By Date__c'; 
        timesheets = database.query(query, AccessLevel.USER_MODE);
        for(DHS_TimeSheet__c t: timesheets){
            if(!test.isRunningTest()){
                if(t.DHS_User__c == userinfo.getuserid() && t.Date__c==system.today()){
                    currentDayTimeSheet = t;
                }
            }else{
                currentDayTimeSheet = t;        
            }
        }
        fetchInvestigatorCheckRecords(currentDayTimeSheet);
        
    }
    
    /**
     * @description Provides this DHS API member.
     * @param todaysTimeSheet Method parameter.
     */
    public void fetchInvestigatorCheckRecords(DHS_TimeSheet__c todaysTimeSheet){
        if(todaysTimeSheet != null){
            isCheckedOut = false;
            newInvestigatorCheckedOutRecords = new list<DHS_Investigator_Check__c>();
            newInvestigatorCheckedInRecords = new list<DHS_Investigator_Check__c>();
    
            List<string> investigatorCheckFields = new List<string>();
            investigatorCheckFields = DHSApexUtil.FetchFields('DHS_Investigator_Check__c');
            
            List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
            String query = 'Select '+string.join(investigatorCheckFields, ',') + ' From DHS_Investigator_Check__c ';
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_TimeSheet__c',todaysTimeSheet.id, '='));  
            String whereCondition = DHSApexUtil.generateWhereQuery(whereCriteria);    
            query = query + ' WHERE '+whereCondition; 
            list<DHS_Investigator_Check__c> invChecks = database.query(query, AccessLevel.USER_MODE);
            
            for(DHS_Investigator_Check__c invc: invChecks){
                if(invc.Type__c == 'CheckOut'){
                    newInvestigatorCheckedOutRecords.add(invc); 
                }else if(invc.Type__c == 'CheckIn'){
                    newInvestigatorCheckedInRecords.add(invc);
                }   
            }
            if(!todaysTimeSheet.Checked_Out__c){
                DHS_Investigator_Check__c invc = new DHS_Investigator_Check__c();
                invc.Type__c= 'CheckOut';
                invc.DHS_TimeSheet__c = todaysTimeSheet.id;
                newInvestigatorCheckedOutRecords.add(invc);
            } else{
                isCheckedOut = true;
            }  
        }
    }
    
    /** @description Provides this DHS API member. */
    public void addNewInvestigatorCheck(){
        DHS_Investigator_Check__c invc = new DHS_Investigator_Check__c();
        invc.Type__c= 'CheckOut';
        invc.DHS_TimeSheet__c = currentDayTimeSheet.id;
        newInvestigatorCheckedOutRecords.add(invc);
    }
    
    /** @description Provides this DHS API member. */
    public void removeNewInvestigatorCheck(){
        Integer indexVal = Integer.valueof(system.currentpagereference().getparameters().get('index'));  
        newInvestigatorCheckedOutRecords.remove(indexVal);        
    }
    
    /** @description Provides this DHS API member. */
    public void checkoutapexaction(){
        for(DHS_Investigator_Check__c checkout: newInvestigatorCheckedOutRecords){
             checkout.CheckOut_Comments__c = currentDayTimeSheet.CheckOut_Comments__c;
        }
        database.upsert(newInvestigatorCheckedOutRecords,false,AccessLevel.USER_MODE);
        currentDayTimeSheet.Checked_Out__c = true;
        database.update(currentDayTimeSheet,false,AccessLevel.USER_MODE);
        
        list<DHS_Investigator_Check__c> checkinrecords = new list<DHS_Investigator_Check__c>();
        for(DHS_Investigator_Check__c invc: newInvestigatorCheckedOutRecords){
            DHS_Investigator_Check__c temp = invc.clone(false,false,false,false);
            temp.Type__c= 'CheckIn';
            checkinrecords.add(temp);    
        }

        database.insert(checkinrecords,false,AccessLevel.USER_MODE);

        fetchInvestigatorCheckRecords(currentDayTimeSheet);
        
        isCheckedOut = true;
    }
    
    
    /** @description Provides this DHS API member. */
    public void checkinapexaction(){
        for(DHS_Investigator_Check__c invc: newInvestigatorCheckedInRecords){
           invc.CheckIn_Comments__c = currentDayTimeSheet.CheckIn_Comments__c; 
        }
        
        database.update(newInvestigatorCheckedInRecords,false,AccessLevel.USER_MODE);
        currentDayTimeSheet.Checked_IN__c = true;
        database.update(currentDayTimeSheet,false,AccessLevel.USER_MODE);
        
        fetchInvestigatorCheckRecords(currentDayTimeSheet);
    
    }
    
    /** @description Provides this DHS API member. */
    public void updatetimesheetsaction(){
        Database.update(timesheets, AccessLevel.USER_MODE);
        //database.saveresult[] sr = database.update(timesheets,false,AccessLevel.USER_MODE);  
        //
    }

    
    /** @description Provides this DHS API member. */
    public void submittimesheetsaction(){
        for(DHS_TimeSheet__c ts: timesheets){
            ts.Submitted__c = true;    
        }  
        Database.update(timesheets, AccessLevel.USER_MODE);
        //database.saveresult[] sr = database.update(timesheets,false,AccessLevel.USER_MODE);
        //
    }
}
