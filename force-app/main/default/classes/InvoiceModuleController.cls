public with sharing class InvoiceModuleController {
    public List<Invoice__c> invoices { get; set; }
    public Date periodStartDate { get; set; }
    public Date periodEndDate { get; set; }
    public Integer currentYear { get; set; }
    public List<Date> cycleDates { get; set; }
    public List<SelectOption> cycleDateOptions { get; set; }
    public String selectedCycleFilterDate { get; set; }
    public Date cycleFilterDate { get; set; }
    public String currentMonth { get; set; }
    public List<SelectOption> userTypeOptions { get; set; }
    public String selectedUserOption { get; set; }
    public List<SelectOption> workerOptions { get; set; }
    public String selectedWorkerId { get; set; }
    public String WorkerNameInput { get; set; }
    public Boolean isPMOUser { get; set; }
    public Integer pageNumber { get; set; }
    public Integer totalPages { get; set; }
    public Integer totalRecordCount { get; set; }
    public Boolean disablePrev { get; set; }
    public Boolean disableNext { get; set; }
    public String queryForNextRecords { get; set; }
    public String lastRecordName { get; set; }
    public String firstRecordName { get; set; }
    public Integer currentRecordCount { get; set; }
	public static object criteria {get;set;}
    private static final Integer PAGE_SIZE = 200;

    public InvoiceModuleController() {
        cycleDates = New List<Date>();
        cycleDateOptions = new List<SelectOption>();
        invoices = new List<Invoice__c>();
        selectedUserOption = 'All';
        selectedWorkerId = 'All';
        initializePagination();

        User currentUser = [
            SELECT Id, User_Type__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        isPMOUser = currentUser.User_Type__c == 'PMO';

        userTypeOptions = new List<SelectOption>();
        userTypeOptions.add(new SelectOption('All', 'All'));
        userTypeOptions.add(new SelectOption('Employee', 'Employee'));
        userTypeOptions.add(new SelectOption('SCA', 'SCA'));
        userTypeOptions.add(new SelectOption('Non-SCA', 'Non-SCA'));

        buildWorkerOptions();
        getAllCycleDates();
    }

    public void RefreshWorkerOptions() {
        selectedWorkerId = 'All';
        buildWorkerOptions();
    }

    public void FetchInvoiceRecords() {
        invoices = new List<Invoice__c>();
        initializePagination();
        
        if (!isPMOUser) {
            return;
        }
		List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();

        setCycleFilterDateFromSelection();
		system.debug('cycleFilterDate...'+cycleFilterDate);
        if (cycleFilterDate != null) {
            whereCriteria.add(new ApexUtil.Criteria('Pay_Period_Ending__c',String.valueOf(cycleFilterDate), '=','Date'));
        }
        if (selectedUserOption != null && selectedUserOption != 'All') {
            whereCriteria.add(new ApexUtil.Criteria('Lead__r.Assigned_to__r.contact.onboarding__r.Candidate_Type__c',String.escapeSingleQuotes(selectedUserOption), '='));
        }
        if (selectedWorkerId != null && selectedWorkerId != 'All') {
			whereCriteria.add(new ApexUtil.Criteria('Lead__r.Assigned_to__c',String.escapeSingleQuotes(selectedWorkerId), '='));
        }
		List<string> leadFields = new List<string>();
        leadFields = ApexUtil.FetchFields('Invoice__c');
        whereCriteria.add(new ApexUtil.Criteria('Status__c','Generated', '='));
        string where_cond = ApexUtil.generateWhereQuery(whereCriteria);  
        system.debug('where_cond...'+where_cond);
        
		String query = 'SELECT '+ string.join(leadFields,',') +' FROM Invoice__c ';
        string countQuery;
        system.debug('whereCriteria...'+whereCriteria);
            if(!whereCriteria.isEmpty()){
                queryForNextRecords = query + ' WHERE '+where_cond+' AND';
                query = query + ' WHERE '+where_cond+' WITH SECURITY_ENFORCED Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from Invoice__c WHERE '+ where_cond+' WITH SECURITY_ENFORCED';
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' WITH SECURITY_ENFORCED Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from Invoice__c WITH SECURITY_ENFORCED';
            }
        
        
        
		system.debug(query);
        invoices = Database.query(query);
        totalRecordCount = Database.countQuery(countQuery);
        pageNumber = 1;
        totalPages = calculateTotalPages(totalRecordCount);
        currentRecordCount = invoices.size();
        disablePrev = true;
        disableNext = currentRecordCount >= totalRecordCount;
        
        criteria = JSON.serialize(whereCriteria);
    }

    public void handlePrev() {
        if (String.isBlank(queryForNextRecords) || String.isBlank(firstRecordName) || pageNumber <= 1) {
            return;
        }

        pageNumber--;
        String query = queryForNextRecords + ' Name < :firstRecordName ORDER BY Name DESC LIMIT ' + PAGE_SIZE;
        List<invoice__c> invoiceLeads = Database.query(query);
        currentRecordCount = Math.min(totalRecordCount, pageNumber * PAGE_SIZE);
        disablePrev = pageNumber == 1;
        disableNext = false;
    }

    public void handleNext() {
        if (String.isBlank(queryForNextRecords) || String.isBlank(lastRecordName) || disableNext) {
            return;
        }

        pageNumber++;
        String query = queryForNextRecords + ' Name > :lastRecordName ORDER BY Name ASC LIMIT ' + PAGE_SIZE;
        List<invoice__c> invoiceLeads = Database.query(query);
        currentRecordCount = Math.min(totalRecordCount, pageNumber * PAGE_SIZE);
        disablePrev = false;
        disableNext = currentRecordCount >= totalRecordCount;
    }
    private void buildWorkerOptions() {
        workerOptions = new List<SelectOption>();
        workerOptions.add(new SelectOption('All', 'All'));

        List<User> workers;
        if (String.isBlank(selectedUserOption) || selectedUserOption == 'All') {
            workers = [
                SELECT Id, FirstName, LastName, Name
                FROM User
                WHERE IsActive = TRUE
                AND System_Access__c INCLUDES ('Intel')
                AND Candidate_Type__c IN ('Employee', 'SCA', 'Non-SCA')
                ORDER BY LastName, FirstName
            ];
        } else {
            workers = [
                SELECT Id, FirstName, LastName, Name
                FROM User
                WHERE IsActive = TRUE
                AND System_Access__c INCLUDES ('Intel')
                AND Candidate_Type__c = :selectedUserOption
                ORDER BY LastName, FirstName
            ];
        }

        for (User worker : workers) {
            workerOptions.add(new SelectOption(worker.Id, formatUserName(worker)));
        }
    }

    private void initializePagination() {
        pageNumber = 1;
        totalPages = 1;
        totalRecordCount = 0;
        currentRecordCount = 0;
        disablePrev = true;
        disableNext = true;
        queryForNextRecords = null;
        firstRecordName = null;
        lastRecordName = null;
    }

    private Integer calculateTotalPages(Integer recordCount) {
        if (recordCount == null || recordCount == 0) {
            return 1;
        }
        Double totalNum = Double.valueOf(recordCount) / Double.valueOf(PAGE_SIZE);
        Double floorVal = Math.floor(totalNum);
        Double diff = totalNum - floorVal;
        return diff > 0 ? Integer.valueOf(floorVal) + 1 : Integer.valueOf(floorVal);
    }
    private static String formatUserName(User worker) {
        if (String.isBlank(worker.LastName) && String.isBlank(worker.FirstName)) {
            return worker.Name;
        }
        if (String.isBlank(worker.FirstName)) {
            return worker.LastName;
        }
        if (String.isBlank(worker.LastName)) {
            return worker.FirstName;
        }
        return worker.LastName + ', ' + worker.FirstName;
    }
    public void getAllCycleDates() {
        cycleDates.clear();
        cycleDateOptions.clear();
        cycleDateOptions.add(new SelectOption('', 'All'));
    
        // Custom Label format: MM-dd-yyyy
        String[] parts = System.Label.SecondSundayStartDate.split('-');
    
        Date startDate = Date.newInstance(
            Integer.valueOf(parts[2]),
            Integer.valueOf(parts[0]),
            Integer.valueOf(parts[1])
        );
    
        Date endDate = Date.today();
        Integer cycle = 14;
    
        Date cycleDate = startDate;
    
        while (cycleDate <= endDate) {
            cycleDates.add(cycleDate);
            cycleDate = cycleDate.addDays(cycle);
        }
    
        // Add newest first
        for (Integer i = cycleDates.size() - 1; i >= 0; i--) {
            Date d = cycleDates[i];
            cycleDateOptions.add(
                new SelectOption(
                    String.valueOf(d),
                    formatCycleDateLabel(d)
                )
            );
        }
    }

    private void setCycleFilterDateFromSelection() {
        cycleFilterDate = String.isBlank(selectedCycleFilterDate)
            ? null
            : Date.valueOf(selectedCycleFilterDate);
    }

    private static String formatCycleDateLabel(Date cycleDate) {
        return padTwoDigits(cycleDate.month()) + '/' +
            padTwoDigits(cycleDate.day()) + '/' +
            String.valueOf(cycleDate.year());
    }

    private static String padTwoDigits(Integer value) {
        return value < 10 ? '0' + String.valueOf(value) : String.valueOf(value);
    }
}