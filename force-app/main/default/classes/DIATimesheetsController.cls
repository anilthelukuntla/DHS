public with sharing class DIATimesheetsController {
    public list<DIA_Timesheet__c> timesheets{get;set;}
    public Date periodStartDate{get;set;}
    public Date periodEndDate{get;set;}
    public Integer currentYear{get;set;}
    public string currentMonth{get;set;}
    public string todaysDateTime{get;set;}
    public DIA_Timesheet__c currentDayTimeSheet{get;set;}
    public list<DIA_Investigator_Check__c> newInvestigatorCheckedOutRecords{get;set;}
    public list<DIA_Investigator_Check__c> newInvestigatorCheckedInRecords{get;set;}
    public boolean isCheckedOut{get;set;}
    
    public DIATimesheetsController(){
        DateTime todaysDateTime = System.now();
        Integer currentDayOfMonth = todaysDateTime.day();
        Integer month = Date.Today().Month();
        Integer year = Date.Today().Year();
        Integer numberDays = Date.daysInMonth(year, month);
        Date startDate;
        Date endDate;

        
        if(currentDayOfMonth >= 1 && currentDayOfMonth <= 15){
            startDate = Date.newinstance(year, month, 1);
            endDate = Date.newinstance(year, month, 15);
        }
        if(currentDayOfMonth >= 16){
            startDate = Date.newinstance(year, month, 16);
            endDate = Date.newinstance(year, month, numberDays);
        }
        
        periodStartDate = startDate;
        periodEndDate = endDate;
        currentYear = year;
        currentMonth = Datetime.now().format('MMMM');
        
        List<string> timesheetFields = new List<string>();
        timesheetFields = ApexUtil.FetchFields('DIA_Timesheet__c');
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        String query = 'Select '+string.join(timesheetFields, ',') + ' From DIA_Timesheet__c ';
        String where_cond;
        whereCriteria.add(new Apexutil.Criteria('Period_From__c',String.valueof(startDate), '=', 'Date'));
        whereCriteria.add(new Apexutil.Criteria('Period_To__c',String.valueof(endDate), '=', 'Date'));
        whereCriteria.add(new Apexutil.Criteria('User__c',userinfo.getUserId(), '='));
        where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+' Order By Date__c '; 
        System.debug('query...'+query);
        timesheets = database.query(query);
        System.debug('timesheets...'+timesheets);
        for(DIA_Timesheet__c t: timesheets){
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
    
    public void FetchInvestigatorCheckRecords(DIA_Timesheet__c todaysTimeSheet){
        if(todaysTimeSheet != null){
            isCheckedOut = false;
            newInvestigatorCheckedOutRecords = new list<DIA_Investigator_Check__c>();
            newInvestigatorCheckedInRecords = new list<DIA_Investigator_Check__c>();
    
            List<string> investigatorCheckFields = new List<string>();
            investigatorCheckFields = ApexUtil.FetchFields('DIA_Investigator_Check__c');
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            String query = 'Select '+string.join(investigatorCheckFields, ',') + ' From DIA_Investigator_Check__c ';
            String where_cond;
            whereCriteria.add(new Apexutil.Criteria('Timesheet__c',todaysTimeSheet.id, '='));  
            where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
            query = query + ' WHERE '+where_cond+ ' WITH SECURITY_ENFORCED'; 
            System.debug('query...'+query);
            list<DIA_Investigator_Check__c> invChecks = database.query(query);
            
            for(DIA_Investigator_Check__c invc: invChecks){
                if(invc.Type__c == 'CheckOut'){
                    newInvestigatorCheckedOutRecords.add(invc); 
                }else if(invc.Type__c == 'CheckIn'){
                    newInvestigatorCheckedInRecords.add(invc);
                }   
            }
            System.debug('newInvestigatorCheckedOutRecords....'+newInvestigatorCheckedOutRecords);
            if(!todaysTimeSheet.checked_out__c){
                DIA_Investigator_Check__c invc = new DIA_Investigator_Check__c();
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
        DIA_Investigator_Check__c invc = new DIA_Investigator_Check__c();
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
        for(DIA_Investigator_Check__c checkout: newInvestigatorCheckedOutRecords){
             checkout.Checkout_Comments__c = currentDayTimeSheet.Checkout_Comments__c;
        }
        if(Schema.SobjectType.DIA_Investigator_Check__c.isUpdateable() && 
         Schema.SobjectType.DIA_Investigator_Check__c.isCreateable()){
             upsert newInvestigatorCheckedOutRecords;
            //Database.upsertResult[] drList = database.upsert(newInvestigatorCheckedOutRecords, false, AccessLevel.USER_MODE);
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update Investigator Check'));
        }
        
        currentDayTimeSheet.checked_out__c = true;
        Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_Timesheet__c');
        if(Schema.SobjectType.DIA_Timesheet__c.isUpdateable() && 
            fields.get('checked_out__c').getDescribe().isAccessible()
        ){
            update currentDayTimeSheet;
            //database.update(currentDayTimeSheet, false, AccessLevel.USER_MODE);
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update Time Sheet'));
        }
        
        list<DIA_Investigator_Check__c> checkinrecords = new list<DIA_Investigator_Check__c>();
        for(DIA_Investigator_Check__c invc: newInvestigatorCheckedOutRecords){
            DIA_Investigator_Check__c temp = invc.clone(false,false,false,false);
            temp.type__c= 'CheckIn';
            checkinrecords.add(temp);    
        }
        Map<String, Schema.SObjectField> investigatorFields = ApexUtil.getObjectFieldsDescribe('DIA_Investigator_Check__c');
        System.debug('Check in records'+checkinrecords);
        if(Schema.SobjectType.DIA_Investigator_Check__c.isCreateable() &&
        investigatorFields.get('type__c').getDescribe().isAccessible()){
            insert checkinrecords;
            FetchInvestigatorCheckRecords(currentDayTimeSheet);
			isCheckedOut = true;
            /*
            List<Database.SaveResult> dsr = database.insert(checkinrecords, false, AccessLevel.USER_MODE);
            integer i = 0;
            for(Database.SaveResult dr : dsr){
                if(dr.isSuccess()) i++;
            }
            if(i == checkinrecords.size()){
                FetchInvestigatorCheckRecords(currentDayTimeSheet);
                isCheckedOut = true;
            }*/
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to create Investigator Check'));
        }
    }
    
    
    public void checkinapexaction(){
        for(DIA_Investigator_Check__c invc: newInvestigatorCheckedInRecords){
           invc.Checkin_Comments__c = currentDayTimeSheet.Checkin_Comments__c; 
        }
        if(Schema.SobjectType.DIA_Investigator_Check__c.isUpdateable()){
            update newInvestigatorCheckedInRecords;
            //database.update(newInvestigatorCheckedInRecords, false, AccessLevel.USER_MODE);
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update Investigator Check'));
        }
        Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_Timesheet__c');
        currentDayTimeSheet.checked_in__c = true;
        if(Schema.SobjectType.DIA_Timesheet__c.isUpdateable() && 
        fields.get('checked_in__c').getDescribe().isAccessible()){
            update currentDayTimeSheet;
			FetchInvestigatorCheckRecords(currentDayTimeSheet);            
            /*Database.SaveResult dsr = database.update(currentDayTimeSheet, false, AccessLevel.USER_MODE);
            if(dsr.isSuccess()){
                
            }*/
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update Time Sheet'));
        }
    }
    
    public void updatetimesheetsaction(){
        if(Schema.SobjectType.DIA_Timesheet__c.isUpdateable()){
            update timesheets;
            //database.update(timesheets, false, AccessLevel.USER_MODE);
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update Time Sheet'));
        }  
    }

    
    public void submittimesheetsaction(){
        for(DIA_Timesheet__c ts: timesheets){
            ts.submitted__c = true;    
        }  

        Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_Timesheet__c');
        if(Schema.SobjectType.DIA_Timesheet__c.isUpdateable() && 
            fields.get('submitted__c').getDescribe().isAccessible()
        ){
            update timesheets;
            //database.update(timesheets, false, AccessLevel.USER_MODE);
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update Time Sheet'));
        }
    }
}