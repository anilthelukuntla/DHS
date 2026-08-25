/**
 * @description Controls DHS invoice filtering, worker selection, and pagination.
 */
@SuppressWarnings('PMD.ApexSOQLInjection,PMD.CyclomaticComplexity,PMD.ExcessivePublicCount')
public with sharing class DHSInvoiceModuleController {
    /** @description Provides this DHS API member. */
    public List<DHS_Invoice__c> invoices { get; set; }
    /** @description Provides this DHS API member. */
    public Date periodStartDate { get; set; }
    /** @description Provides this DHS API member. */
    public Date periodEndDate { get; set; }
    /** @description Provides this DHS API member. */
    public Integer currentYear { get; set; }
    /** @description Provides this DHS API member. */
    public List<Date> cycleDates { get; set; }
    /** @description Provides this DHS API member. */
    public List<SelectOption> cycleDateOptions { get; set; }
    /** @description Provides this DHS API member. */
    public String selectedCycleFilterDate { get; set; }
    /** @description Provides this DHS API member. */
    public Date cycleFilterDate { get; set; }
    /** @description Provides this DHS API member. */
    public String currentMonth { get; set; }
    /** @description Provides this DHS API member. */
    public List<SelectOption> userTypeOptions { get; set; }
    /** @description Provides this DHS API member. */
    public String selectedUserOption { get; set; }
    /** @description Provides this DHS API member. */
    public List<SelectOption> workerOptions { get; set; }
    /** @description Provides this DHS API member. */
    public String selectedWorkerId { get; set; }
    /** @description Provides this DHS API member. */
    public String workerNameInput { get; set; }
    /** @description Provides this DHS API member. */
    public Boolean isPMOUser { get; private set; }
    /** @description Provides this DHS API member. */
    public Integer pageNumber { get; set; }
    /** @description Provides this DHS API member. */
    public Integer totalPages { get; set; }
    /** @description Provides this DHS API member. */
    public Integer totalRecordCount { get; set; }
    public Boolean disablePrev { get; set; } // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    public Boolean disableNext { get; set; } // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    /** @description Provides this DHS API member. */
    public String queryForNextRecords { get; set; }
    /** @description Provides this DHS API member. */
    public String lastRecordName { get; set; }
    /** @description Provides this DHS API member. */
    public String firstRecordName { get; set; }
    /** @description Provides this DHS API member. */
    public Integer currentRecordCount { get; set; }
	/** @description Provides this DHS API member. */
	public static object criteria {get;set;}
    private static final Integer PAGE_SIZE = 200;

    /** @description Provides this DHS API member. */
    public DHSInvoiceModuleController() {
        cycleDates = New List<Date>();
        cycleDateOptions = new List<SelectOption>();
        invoices = new List<DHS_Invoice__c>();
        selectedUserOption = 'DHS_All';
        selectedWorkerId = 'DHS_All';
        initializePagination();

        User currentUser = [
            SELECT Id, User_Type__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        isPMOUser = currentUser.User_Type__c == 'PMO';

        userTypeOptions = new List<SelectOption>();
        userTypeOptions.add(new SelectOption('DHS_All', 'All'));
        userTypeOptions.add(new SelectOption('Employee', 'Employee'));
        userTypeOptions.add(new SelectOption('SCA', 'SCA'));
        userTypeOptions.add(new SelectOption('Non-SCA', 'Non-SCA'));

        buildWorkerOptions();
        getAllCycleDates();
    }

    /** @description Provides this DHS API member. */
    public void refreshWorkerOptions() {
        selectedWorkerId = 'DHS_All';
        buildWorkerOptions();
    }

    /** @description Provides this DHS API member. */
    public void fetchInvoiceRecords() {
        invoices = new List<DHS_Invoice__c>();
        initializePagination();
        
        if (!isPMOUser) {
            return;
        }
		List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();

        setCycleFilterDateFromSelection();
        addInvoiceCriteria(whereCriteria);
		List<string> leadFields = new List<string>();
        leadFields = DHSApexUtil.FetchFields('DHS_Invoice__c');
        whereCriteria.add(new DHSApexUtil.Criteria('Status__c','Generated', '='));
        string whereCondition = DHSApexUtil.generateWhereQuery(whereCriteria);  
        
		String query = 'SELECT '+ string.join(leadFields,',') +' FROM DHS_Invoice__c ';
        string countQuery;
            if(!whereCriteria.isEmpty()){
                queryForNextRecords = query + ' WHERE '+whereCondition+' AND';
                query = query + ' WHERE '+whereCondition+' WITH SECURITY_ENFORCED Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Invoice__c WHERE '+ whereCondition+' WITH SECURITY_ENFORCED';
            }else{
                queryForNextRecords = query + ' WHERE ';
                query = query + ' WITH SECURITY_ENFORCED Order by Name asc Limit 200'; 
                countQuery = 'Select Count() from DHS_Invoice__c WITH SECURITY_ENFORCED';
            }
        
        
        
        // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
        invoices = Database.query(query);
        totalRecordCount = Database.countQuery(countQuery);
        pageNumber = 1;
        totalPages = calculateTotalPages(totalRecordCount);
        currentRecordCount = invoices.size();
        disablePrev = true;
        disableNext = currentRecordCount >= totalRecordCount;
        
        criteria = JSON.serialize(whereCriteria);
    }

    private void addInvoiceCriteria(List<DHSApexUtil.Criteria> whereCriteria) {
        if (cycleFilterDate != null) {
            whereCriteria.add(new DHSApexUtil.Criteria('Pay_Period_Ending__c',String.valueOf(cycleFilterDate), '>=','Date'));
            date cycleEndDate = cycleFilterDate.adddays(14);
            whereCriteria.add(new DHSApexUtil.Criteria('Pay_Period_Ending__c', String.valueOf(cycleEndDate), '<=', 'Date'));
        }
        if (selectedUserOption != null && selectedUserOption != 'DHS_All') {
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_Lead__r.DHS_Assigned_To__r.Candidate_type__c',String.escapeSingleQuotes(selectedUserOption), '='));
        }
        if (selectedWorkerId != null && selectedWorkerId != 'DHS_All') {
			whereCriteria.add(new DHSApexUtil.Criteria('DHS_Lead__r.DHS_Assigned_To__c',String.escapeSingleQuotes(selectedWorkerId), '='));
        }
    }

    /** @description Provides this DHS API member. */
    public void handlePrev() {
        if (String.isBlank(queryForNextRecords) || String.isBlank(firstRecordName) || pageNumber <= 1) {
            return;
        }

        pageNumber--;
        currentRecordCount = Math.min(totalRecordCount, pageNumber * PAGE_SIZE);
        disablePrev = pageNumber == 1;
        disableNext = false;
    }

    /** @description Provides this DHS API member. */
    public void handleNext() {
        if (String.isBlank(queryForNextRecords) || String.isBlank(lastRecordName) || disableNext) {
            return;
        }

        pageNumber++;
        currentRecordCount = Math.min(totalRecordCount, pageNumber * PAGE_SIZE);
        disablePrev = false;
        disableNext = currentRecordCount >= totalRecordCount;
    }
    private void buildWorkerOptions() {
        workerOptions = new List<SelectOption>();
        workerOptions.add(new SelectOption('DHS_All', 'All'));

        List<User> workers;
        if (String.isBlank(selectedUserOption) || selectedUserOption == 'DHS_All') {
            workers = [
                SELECT Id, FirstName, LastName, Name
                FROM User
                WHERE IsActive = TRUE
                AND System_Access__c INCLUDES ('DHS')
                AND Candidate_type__c IN ('Employee', 'SCA', 'Non-SCA')
                ORDER BY LastName, FirstName
            ];
        } else {
            workers = [
                SELECT Id, FirstName, LastName, Name
                FROM User
                WHERE IsActive = TRUE
                AND System_Access__c INCLUDES ('DHS')
                AND Candidate_type__c = :selectedUserOption
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
    /** @description Provides this DHS API member. */
    public void getAllCycleDates() {
        cycleDates.clear();
        cycleDateOptions.clear();
        cycleDateOptions.add(new SelectOption('', 'All'));
    
        // Custom Label format: MM-dd-yyyy
        String[] parts = System.Label.DHS_SecondSundayStartDate.split('-');
    
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