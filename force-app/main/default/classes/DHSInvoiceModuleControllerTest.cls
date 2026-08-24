@IsTest

private class DHSInvoiceModuleControllerTest {
    @IsTest
    static void fetchInvoiceRecordsUsesCompletedLeadsAndPaychexId() {
        User pmoUser = createUser('pmo', 'PMO', 'Employee');

        System.runAs(pmoUser) {
            insert new Account(Name = System.Label.DHS_AccountName);

            DHS_Contact__c subject = new DHS_Contact__c(
                First_Name__c = 'Subject',
                Last_Name__c = 'Smith',
                Email__c = 'subject@example.com',
                Contact_Type__c = 'Subject',
                SSN__c = '123-45-6789'
            );
            insert subject;

            DHS_Case__c caseRecord = new DHS_Case__c(
                DHS_Contact__c = subject.Id,
                DHS_Assigned_To__c = pmoUser.Id,
                Case_Number__c = 'TEST1234',
                Case_Type__c = 'Tier 5',
                Service_Days__c = '40',
                Status__c = 'Active'
            );
            caseRecord.put('Costpoint_Code__c', '3207.C01.0008.T1');
            insert caseRecord;

            DHS_Lead__c completedLead = new DHS_Lead__c(
                DHS_Case__c = caseRecord.Id,
                DHS_Assigned_To__c = pmoUser.Id,
                DHS_Contact__c = subject.Id,
                LeadType__c = 'Subject Interview (ESI/TESI)',
                Coverage_Type__c = 'Subject Interview',
                Item_number__c = 3,
                Was_Subject_Interview_Conducted__c = 'Yes',
                Completed_Date__c = Date.today()
            );
            insert completedLead;
            completedLead.Status__c = 'Completed';
            update completedLead;

            DHS_Lead__c rejectedLead = new DHS_Lead__c(
                DHS_Case__c = caseRecord.Id,
                DHS_Assigned_To__c = pmoUser.Id,
                DHS_Contact__c = subject.Id,
                LeadType__c = 'General (GENL)',
                Coverage_Type__c = 'Personal',
                Item_number__c = 6,
                Was_the_record_obtained_Personal__c = 'Yes, Source was interviewed',
                Personal_Contact_Method__c = 'Telephone',
                Completed_Date__c = Date.today()
            );
            insert rejectedLead;

            rejectedLead.Status__c = 'QA Rejected';
            rejectedLead.Completed_Date__c = Date.today();
            update rejectedLead;

            DHSInvoiceModuleController controller = new DHSInvoiceModuleController();

            controller.periodStartDate = Date.today().addDays(-1);
            controller.periodEndDate = Date.today();
            controller.selectedUserOption = 'Employee';
            controller.selectedWorkerId = pmoUser.Id;

            Test.startTest();
            controller.FetchInvoiceRecords();
            Test.stopTest();

            System.assertEquals(1, controller.invoices.size(), 'Only completed, non-QA-rejected leads should be returned.');
            System.assertEquals(1, controller.pageNumber, 'Expected the asserted condition to hold');
            System.assertEquals(1, controller.totalPages, 'Expected the asserted condition to hold');
            System.assertEquals(1, controller.totalRecordCount, 'Expected the asserted condition to hold');
            System.assertEquals(true, controller.disablePrev, 'Expected the asserted condition to hold');
            System.assertEquals(true, controller.disableNext, 'Expected the asserted condition to hold');
            DHS_Invoice__c row = controller.invoices[0];
            System.assertNotEquals(null, row.Id, 'Expected the asserted condition to hold');
        }
    }

    private static User createUser(String aliasPrefix, String userType, String candidateType) {
        Profile profileRecord = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];
        String uniqueValue = String.valueOf(DateTime.now().getTime());
        User testUser = new User(
            Alias = aliasPrefix.left(8),
            Email = aliasPrefix + uniqueValue + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = aliasPrefix,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileRecord.Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = aliasPrefix + uniqueValue + '@example.com',
            User_Type__c = userType,
            Candidate_type__c = candidateType,
            System_Access__c = 'Intel'
        );
        insert testUser;
        insert new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = [
                SELECT Id FROM PermissionSet
                WHERE Name = 'DHS_Package_System_Admin_Access'
                LIMIT 1
            ].Id
        );
        return testUser;
    }
    @IsTest
static void initializesControllerOptionsAndCycleDates() {
    User pmoUser = createUser(
        'pmoInit',
        'PMO',
        'Employee'
    );

    System.runAs(pmoUser) {
        Test.startTest();
        DHSInvoiceModuleController controller =
            new DHSInvoiceModuleController();
        Test.stopTest();

        System.assertEquals(true, controller.isPMOUser, 'Expected the asserted condition to hold');
        System.assertEquals('DHS_All', controller.selectedUserOption, 'Expected the asserted condition to hold');
        System.assertEquals('DHS_All', controller.selectedWorkerId, 'Expected the asserted condition to hold');

        System.assertEquals(1, controller.pageNumber, 'Expected the asserted condition to hold');
        System.assertEquals(1, controller.totalPages, 'Expected the asserted condition to hold');
        System.assertEquals(0, controller.totalRecordCount, 'Expected the asserted condition to hold');
        System.assertEquals(0, controller.currentRecordCount, 'Expected the asserted condition to hold');
        System.assertEquals(true, controller.disablePrev, 'Expected the asserted condition to hold');
        System.assertEquals(true, controller.disableNext, 'Expected the asserted condition to hold');

        System.assertEquals(4, controller.userTypeOptions.size(), 'Expected the asserted condition to hold');
        System.assertEquals(
            'DHS_All',
            controller.userTypeOptions[0].getValue()
        , 'Expected the asserted condition to hold');
        System.assertEquals(
            'Employee',
            controller.userTypeOptions[1].getValue()
        , 'Expected the asserted condition to hold');
        System.assertEquals(
            'SCA',
            controller.userTypeOptions[2].getValue()
        , 'Expected the asserted condition to hold');
        System.assertEquals(
            'Non-SCA',
            controller.userTypeOptions[3].getValue()
        , 'Expected the asserted condition to hold');

        System.assertNotEquals(null, controller.workerOptions, 'Expected the asserted condition to hold');
        System.assertEquals(
            'DHS_All',
            controller.workerOptions[0].getValue()
        , 'Expected the asserted condition to hold');

        System.assertNotEquals(null, controller.cycleDates, 'Expected the asserted condition to hold');
        System.assertNotEquals(null, controller.cycleDateOptions, 'Expected the asserted condition to hold');
        System.assert(
            !controller.cycleDateOptions.isEmpty()
        , 'Expected assertion condition to hold');
        System.assertEquals(
            '',
            controller.cycleDateOptions[0].getValue()
        , 'Expected the asserted condition to hold');
        System.assertEquals(
            'All',
            controller.cycleDateOptions[0].getLabel()
        , 'Expected the asserted condition to hold');
    }
}

@IsTest
static void refreshesWorkerOptionsByCandidateType() {
    User pmoUser = createUser(
        'pmoRefresh',
        'PMO',
        'Employee'
    );

    System.runAs(pmoUser) {
        DHSInvoiceModuleController controller =
            new DHSInvoiceModuleController();

        controller.selectedUserOption = 'Employee';
        controller.selectedWorkerId = pmoUser.Id;

        Test.startTest();
        controller.RefreshWorkerOptions();
        Test.stopTest();

        System.assertEquals(
            'DHS_All',
            controller.selectedWorkerId
        , 'Expected the asserted condition to hold');
        System.assertNotEquals(null, controller.workerOptions, 'Expected the asserted condition to hold');
        System.assert(
            !controller.workerOptions.isEmpty()
        , 'Expected assertion condition to hold');
        System.assertEquals(
            'DHS_All',
            controller.workerOptions[0].getValue()
        , 'Expected the asserted condition to hold');
    }
}

@IsTest
static void refreshesAllWorkerOptions() {
    User pmoUser = createUser(
        'pmoAll',
        'PMO',
        'Employee'
    );

    System.runAs(pmoUser) {
        DHSInvoiceModuleController controller =
            new DHSInvoiceModuleController();

        controller.selectedUserOption = 'DHS_All';
        controller.selectedWorkerId = pmoUser.Id;

        Test.startTest();
        controller.RefreshWorkerOptions();
        Test.stopTest();

        System.assertEquals(
            'DHS_All',
            controller.selectedWorkerId
        , 'Expected the asserted condition to hold');
        System.assertNotEquals(null, controller.workerOptions, 'Expected the asserted condition to hold');
        System.assert(
            !controller.workerOptions.isEmpty()
        , 'Expected assertion condition to hold');
    }
}

@IsTest
static void nonPMOUserCannotFetchInvoices() {
    User investigator = createUser(
        'invFetch',
        'INV',
        'Employee'
    );

    System.runAs(investigator) {
        DHSInvoiceModuleController controller =
            new DHSInvoiceModuleController();

        System.assertEquals(false, controller.isPMOUser, 'Expected the asserted condition to hold');

        /*
         * Set values first to verify FetchInvoiceRecords resets
         * the pagination state before returning.
         */
        controller.pageNumber = 10;
        controller.totalPages = 10;
        controller.totalRecordCount = 100;
        controller.currentRecordCount = 50;
        controller.disablePrev = false;
        controller.disableNext = false;

        Test.startTest();
        controller.FetchInvoiceRecords();
        Test.stopTest();

        System.assertNotEquals(null, controller.invoices, 'Expected the asserted condition to hold');
        System.assertEquals(0, controller.invoices.size(), 'Expected the asserted condition to hold');
        System.assertEquals(1, controller.pageNumber, 'Expected the asserted condition to hold');
        System.assertEquals(1, controller.totalPages, 'Expected the asserted condition to hold');
        System.assertEquals(0, controller.totalRecordCount, 'Expected the asserted condition to hold');
        System.assertEquals(0, controller.currentRecordCount, 'Expected the asserted condition to hold');
        System.assertEquals(true, controller.disablePrev, 'Expected the asserted condition to hold');
        System.assertEquals(true, controller.disableNext, 'Expected the asserted condition to hold');
    }
}

@IsTest
static void fetchesUsingCycleDateFilter() {
    User pmoUser = createUser(
        'pmoCycle',
        'PMO',
        'Employee'
    );

    System.runAs(pmoUser) {
        DHSInvoiceModuleController controller =
            new DHSInvoiceModuleController();

        controller.selectedCycleFilterDate =
            String.valueOf(Date.today().addDays(-14));
        controller.selectedUserOption = 'DHS_All';
        controller.selectedWorkerId = 'DHS_All';

        Test.startTest();
        controller.FetchInvoiceRecords();
        Test.stopTest();

        System.assertEquals(
            Date.today().addDays(-14),
            controller.cycleFilterDate
        , 'Expected the asserted condition to hold');
        System.assertNotEquals(
            null,
            DHSInvoiceModuleController.criteria
        , 'Expected the asserted condition to hold');
        System.assertNotEquals(
            null,
            controller.queryForNextRecords
        , 'Expected the asserted condition to hold');
        System.assertEquals(1, controller.pageNumber, 'Expected the asserted condition to hold');
        System.assert(
            controller.totalPages >= 1
        , 'Expected assertion condition to hold');
    }
}

@IsTest
static void fetchesUsingUserAndWorkerFilters() {
    User pmoUser = createUser(
        'pmoFilter',
        'PMO',
        'Employee'
    );

    System.runAs(pmoUser) {
        DHSInvoiceModuleController controller =
            new DHSInvoiceModuleController();

        controller.selectedCycleFilterDate = null;
        controller.selectedUserOption = 'Employee';
        controller.selectedWorkerId = pmoUser.Id;

        Test.startTest();
        controller.FetchInvoiceRecords();
        Test.stopTest();

        System.assertEquals(null, controller.cycleFilterDate, 'Expected the asserted condition to hold');
        System.assertNotEquals(
            null,
            DHSInvoiceModuleController.criteria
        , 'Expected the asserted condition to hold');
        System.assertNotEquals(
            null,
            controller.queryForNextRecords
        , 'Expected the asserted condition to hold');

        String serializedCriteria =
            String.valueOf(
                DHSInvoiceModuleController.criteria
            );

        System.assert(
            serializedCriteria.contains('Candidate_type__c')
        , 'Expected assertion condition to hold');
        System.assert(
            serializedCriteria.contains(pmoUser.Id)
        , 'Expected assertion condition to hold');
    }
}

@IsTest
static void paginationMethodsHandleInvalidState() {
    User pmoUser = createUser(
        'pmoPage',
        'PMO',
        'Employee'
    );

    System.runAs(pmoUser) {
        DHSInvoiceModuleController controller =
            new DHSInvoiceModuleController();

        System.assertEquals(null, controller.queryForNextRecords, 'Expected the asserted condition to hold');
        System.assertEquals(null, controller.firstRecordName, 'Expected the asserted condition to hold');
        System.assertEquals(null, controller.lastRecordName, 'Expected the asserted condition to hold');
        System.assertEquals(1, controller.pageNumber, 'Expected the asserted condition to hold');

        Test.startTest();
        controller.handlePrev();
        controller.handleNext();
        Test.stopTest();

        System.assertEquals(1, controller.pageNumber, 'Expected the asserted condition to hold');
        System.assertEquals(true, controller.disablePrev, 'Expected the asserted condition to hold');
        System.assertEquals(true, controller.disableNext, 'Expected the asserted condition to hold');
    }
}

@IsTest
static void rebuildsCycleDateOptions() {
    User pmoUser = createUser(
        'pmoDates',
        'PMO',
        'Employee'
    );

    System.runAs(pmoUser) {
        DHSInvoiceModuleController controller =
            new DHSInvoiceModuleController();

        controller.cycleDates.clear();
        controller.cycleDateOptions.clear();

        Test.startTest();
        controller.getAllCycleDates();
        Test.stopTest();

        System.assert(
            !controller.cycleDates.isEmpty()
        , 'Expected assertion condition to hold');
        System.assertEquals(
            controller.cycleDates.size() + 1,
            controller.cycleDateOptions.size()
        , 'Expected the asserted condition to hold');

        Date newestCycleDate = controller.cycleDates[
            controller.cycleDates.size() - 1
        ];

        System.assertEquals(
            String.valueOf(newestCycleDate),
            controller.cycleDateOptions[1].getValue()
        , 'Expected the asserted condition to hold');

        String expectedLabel =
            String.valueOf(newestCycleDate.month()).leftPad(2, '0') +
            '/' +
            String.valueOf(newestCycleDate.day()).leftPad(2, '0') +
            '/' +
            String.valueOf(newestCycleDate.year());

        System.assertEquals(
            expectedLabel,
            controller.cycleDateOptions[1].getLabel()
        , 'Expected the asserted condition to hold');
    }
}

}
