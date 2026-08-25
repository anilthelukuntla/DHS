public class DIAInvoiceModuleController {
    public list<InvoiceRecord> invoices{get;set;}
    public Date periodStartDate{get;set;}
    public Date periodEndDate{get;set;}
    public Integer currentYear{get;set;}
    public string currentMonth{get;set;}
    public Date fromSearchDate{get;set;}
    public Date toSearchDate{get;set;}
    public list<selectoption> userTypeOptions {get;set;}
    public string selectedUserOption {get;set;}
    public string WorkerNameInput{get;set;}
    public DIAInvoiceModuleController(){
    	userTypeOptions = new list<selectoption>();  
        userTypeOptions.add(new SelectOption('All', 'All'));
        userTypeOptions.add(new SelectOption('Employee', 'Employee'));
        userTypeOptions.add(new SelectOption('SCA', 'SCA'));
        userTypeOptions.add(new SelectOption('Non-SCA', 'Non-SCA'));
    }
    public void FetchInvoiceRecords(){
        invoices = new list<InvoiceRecord>();
        DateTime todaysDateTime = System.today();
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
        timesheetFields.add('User__r.Name');
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        String query = 'Select '+string.join(timesheetFields, ',') + ' From DIA_Timesheet__c ';
        String where_cond;
        if(fromSearchDate != Null)
        whereCriteria.add(new Apexutil.Criteria('Date__c',String.valueof(fromSearchDate), '>=', 'Date'));
        if(toSearchDate != Null)
        whereCriteria.add(new Apexutil.Criteria('Date__c',String.valueof(toSearchDate), '<=', 'Date'));
        if(selectedUserOption != 'All')
        whereCriteria.add(new Apexutil.Criteria('User__r.Candidate_Type__c',selectedUserOption, '='));
        if(WorkerNameInput != Null)
        whereCriteria.add(new Apexutil.Criteria('User__r.Name','%'+WorkerNameInput+'%', 'LIKE'));
        //whereCriteria.add(new Apexutil.Criteria('User__c',userinfo.getUserId(), '='));
        
        where_cond = ApexUtil.generateWhereQuery(whereCriteria); 
        if(String.isNotBlank(where_cond)){
        	where_cond = where_cond + ' AND Submitted__c = true ';    
        }else{
        	where_cond = 'Submitted__c = true ';    
        }
        
        query = query + ' WHERE '+where_cond+' Order By Date__c'; 
        System.debug('query...'+query);
        list<DIA_Timesheet__c> timesheets = database.query(query);
        System.debug('timesheets...'+timesheets);
        for(DIA_Timesheet__c ts: timesheets){
         	invoices.add(new invoicerecord(ts)); 
        }
        
    }
    public class InvoiceRecord{
        public DIA_Timesheet__c timesheet{get;set;}
        public invoicerecord(DIA_Timesheet__c timesheet){
            this.timesheet = timesheet;
        }
    }
}