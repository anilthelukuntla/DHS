@IsTest
@SuppressWarnings('PMD.ApexAssertionsShouldIncludeMessage')
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
            System.assertEquals(1, controller.pageNumber);
            System.assertEquals(1, controller.totalPages);
            System.assertEquals(1, controller.totalRecordCount);
            System.assertEquals(true, controller.disablePrev);
            System.assertEquals(true, controller.disableNext);
            DHS_Invoice__c row = controller.invoices[0];
            System.assertNotEquals(null, row.Id);
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

        System.assertEquals(true, controller.isPMOUser);
        System.assertEquals('DHS_All', controller.selectedUserOption);
        System.assertEquals('DHS_All', controller.selectedWorkerId);

        System.assertEquals(1, controller.pageNumber);
        System.assertEquals(1, controller.totalPages);
        System.assertEquals(0, controller.totalRecordCount);
        System.assertEquals(0, controller.currentRecordCount);
        System.assertEquals(true, controller.disablePrev);
        System.assertEquals(true, controller.disableNext);

        System.assertEquals(4, controller.userTypeOptions.size());
        System.assertEquals(
            'DHS_All',
            controller.userTypeOptions[0].getValue()
        );
        System.assertEquals(
            'Employee',
            controller.userTypeOptions[1].getValue()
        );
        System.assertEquals(
            'SCA',
            controller.userTypeOptions[2].getValue()
        );
        System.assertEquals(
            'Non-SCA',
            controller.userTypeOptions[3].getValue()
        );

        System.assertNotEquals(null, controller.workerOptions);
        System.assertEquals(
            'DHS_All',
            controller.workerOptions[0].getValue()
        );

        System.assertNotEquals(null, controller.cycleDates);
        System.assertNotEquals(null, controller.cycleDateOptions);
        System.assert(
            !controller.cycleDateOptions.isEmpty()
        );
        System.assertEquals(
            '',
            controller.cycleDateOptions[0].getValue()
        );
        System.assertEquals(
            'All',
            controller.cycleDateOptions[0].getLabel()
        );
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
        );
        System.assertNotEquals(null, controller.workerOptions);
        System.assert(
            !controller.workerOptions.isEmpty()
        );
        System.assertEquals(
            'DHS_All',
            controller.workerOptions[0].getValue()
        );
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
        );
        System.assertNotEquals(null, controller.workerOptions);
        System.assert(
            !controller.workerOptions.isEmpty()
        );
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

        System.assertEquals(false, controller.isPMOUser);

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

        System.assertNotEquals(null, controller.invoices);
        System.assertEquals(0, controller.invoices.size());
        System.assertEquals(1, controller.pageNumber);
        System.assertEquals(1, controller.totalPages);
        System.assertEquals(0, controller.totalRecordCount);
        System.assertEquals(0, controller.currentRecordCount);
        System.assertEquals(true, controller.disablePrev);
        System.assertEquals(true, controller.disableNext);
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
        );
        System.assertNotEquals(
            null,
            DHSInvoiceModuleController.criteria
        );
        System.assertNotEquals(
            null,
            controller.queryForNextRecords
        );
        System.assertEquals(1, controller.pageNumber);
        System.assert(
            controller.totalPages >= 1
        );
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

        System.assertEquals(null, controller.cycleFilterDate);
        System.assertNotEquals(
            null,
            DHSInvoiceModuleController.criteria
        );
        System.assertNotEquals(
            null,
            controller.queryForNextRecords
        );

        String serializedCriteria =
            String.valueOf(
                DHSInvoiceModuleController.criteria
            );

        System.assert(
            serializedCriteria.contains('Candidate_type__c')
        );
        System.assert(
            serializedCriteria.contains(pmoUser.Id)
        );
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

        System.assertEquals(null, controller.queryForNextRecords);
        System.assertEquals(null, controller.firstRecordName);
        System.assertEquals(null, controller.lastRecordName);
        System.assertEquals(1, controller.pageNumber);

        Test.startTest();
        controller.handlePrev();
        controller.handleNext();
        Test.stopTest();

        System.assertEquals(1, controller.pageNumber);
        System.assertEquals(true, controller.disablePrev);
        System.assertEquals(true, controller.disableNext);
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
        );
        System.assertEquals(
            controller.cycleDates.size() + 1,
            controller.cycleDateOptions.size()
        );

        Date newestCycleDate = controller.cycleDates[
            controller.cycleDates.size() - 1
        ];

        System.assertEquals(
            String.valueOf(newestCycleDate),
            controller.cycleDateOptions[1].getValue()
        );

        String expectedLabel =
            String.valueOf(newestCycleDate.month()).leftPad(2, '0') +
            '/' +
            String.valueOf(newestCycleDate.day()).leftPad(2, '0') +
            '/' +
            String.valueOf(newestCycleDate.year());

        System.assertEquals(
            expectedLabel,
            controller.cycleDateOptions[1].getLabel()
        );
    }
}

}
