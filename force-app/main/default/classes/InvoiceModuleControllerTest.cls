@IsTest
/** Exercises the existing InvoiceModuleController behavior. */
@SuppressWarnings('PMD.ExcessiveParameterList, PMD.NcssCount')
private class InvoiceModuleControllerTest {

    @IsTest
    static void fetchInvoiceRecordsReturnsGeneratedInvoiceForSelectedWorker() {
        User pmoUser;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            pmoUser = createUser('pmo', 'PMO', 'Employee');
        }

        Account intelAccount = new Account(
                Name = System.Label.IntelAccountName
            );
            insert intelAccount;

            Contact__c subject = new Contact__c(
                First_Name__c = 'Subject',
                Last_Name__c = 'Smith',
                Email__c = 'subject@example.com',
                Contact_Type__c = 'Subject',
                SSN__c = '123-45-6789'
            );
            insert subject;

            Case__c caseRecord = new Case__c(
                Contact__c = subject.Id,
                Assigned_To__c = pmoUser.Id,
                Case_Number__c = 'TEST1234',
                Case_Type__c = 'Tier 5',
                Service_Days__c = '40',
                Status__c = 'Active',
                Costpoint_Code__c = '3207.C01.0008.T1'
            );
            insert caseRecord;

            OnBoarding__c onboardingRecord = new OnBoarding__c(
                First_Name__c = 'Jason',
                Last_Name__c = 'Stott',
                Email__c = 'jason.stott@example.com',
                User__c = pmoUser.Id,
                User_Profile__c = 'PMO',
                Candidate_Type__c = 'Employee',
                System_Access__c = 'Intel',
                Status__c = 'Active',
                Send_Credentials_To_User__c = false,
                Paychex_ID__c = '12345'
            );
            insert onboardingRecord;

            Lead__c completedLead = createLead(
                caseRecord.Id,
                subject.Id,
                pmoUser.Id,
                'Subject Interview (ESI/TESI)',
                'Subject Interview',
                3
            );
            completedLead.Was_Subject_interview_conducted__c = 'Yes';
            insert completedLead;

            Lead__c rejectedLead = createLead(
                caseRecord.Id,
                subject.Id,
                pmoUser.Id,
                'General (GENL)',
                'Personal',
                6
            );
            rejectedLead.Was_the_record_obtained_Personal__c =
                'Yes, Source was interviewed';
            rejectedLead.Personal_Contact_Method__c = 'Telephone';
            insert rejectedLead;

            Date payPeriodEndingDate = Date.today();

        System.runAs(pmoUser) {
            Invoice__c generatedInvoice = new Invoice__c(
                Lead__c = completedLead.Id,
                Status__c = 'Generated',
                Pay_Period_Ending__c = payPeriodEndingDate
            );
            insert generatedInvoice;

            // This record must not be returned.
            Invoice__c nonGeneratedInvoice = new Invoice__c(
                Lead__c = rejectedLead.Id,
                Status__c = 'In-Review',
                Pay_Period_Ending__c = payPeriodEndingDate
            );
            insert nonGeneratedInvoice;

            InvoiceModuleController controller =
                new InvoiceModuleController();
            controller.selectedUserOption = 'Employee';
            controller.RefreshWorkerOptions();
            controller.handlePrev();
            controller.handleNext();

            /*
             * Use All here because the controller's Employee filter uses:
             * Lead__r.Assigned_To__r.Contact.OnBoarding__r.Candidate_Type__c
             *
             * The test user is an internal user and therefore does
             * not have a ContactId.
             */
            controller.selectedUserOption = 'All';
            controller.selectedWorkerId = pmoUser.Id;
            controller.selectedCycleFilterDate =
                String.valueOf(payPeriodEndingDate);

            Test.startTest();
            controller.FetchInvoiceRecords();
            Test.stopTest();

            System.assertEquals(
                true,
                controller.isPMOUser,
                'The test user should be recognized as a PMO user.'
            );
            System.assertEquals(
                1,
                controller.invoices.size(),
                'Only one generated invoice should match the filters.'
            );
            System.assertEquals(
                generatedInvoice.Id,
                controller.invoices[0].Id,
                'The generated invoice for the selected worker should return.'
            );
            System.assertEquals(
                1,
                controller.totalRecordCount
            , 'Assertion failed in InvoiceModuleControllerTest at source line 132');
            System.assertEquals(
                1,
                controller.totalPages
            , 'Assertion failed in InvoiceModuleControllerTest at source line 136');
            System.assertEquals(
                1,
                controller.currentRecordCount
            , 'Assertion failed in InvoiceModuleControllerTest at source line 140');
            System.assertEquals(
                true,
                controller.disablePrev
            , 'Assertion failed in InvoiceModuleControllerTest at source line 144');
            System.assertEquals(
                true,
                controller.disableNext
            , 'Assertion failed in InvoiceModuleControllerTest at source line 148');
            System.assertNotEquals(
                null,
                InvoiceModuleController.criteria
            , 'Assertion failed in InvoiceModuleControllerTest at source line 152');
            controller.queryForNextRecords =
                'SELECT Id, Name FROM Invoice__c WHERE Id != null AND';
            controller.firstRecordName = 'zzzz';
            controller.lastRecordName = '0';
            controller.pageNumber = 2;
            controller.totalRecordCount = 401;
            controller.disableNext = false;
            controller.handlePrev();
            controller.handleNext();
        }
    }

    @IsTest
    static void fetchInvoiceRecordsReturnsNothingForNonPmoUser() {
        User employeeUser = createUser(
            'employee',
            'INV',
            'Employee'
        );

        System.runAs(employeeUser) {
            InvoiceModuleController controller =
                new InvoiceModuleController();

            Test.startTest();
            controller.FetchInvoiceRecords();
            Test.stopTest();

            System.assertEquals(false, controller.isPMOUser, 'Assertion failed in InvoiceModuleControllerTest at source line 184');
            System.assertEquals(0, controller.invoices.size(), 'Assertion failed in InvoiceModuleControllerTest at source line 185');
            System.assertEquals(0, controller.totalRecordCount, 'Assertion failed in InvoiceModuleControllerTest at source line 186');
        }
    }

    @IsTest
    static void generateInvoiceRecordsBatchCreatesInvoiceForCompletedLead() {
        User investigator;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            investigator = createUser('batchinv', 'INV', 'Employee');
        }

        Contact__c subject = new Contact__c(
            First_Name__c = 'Batch',
            Last_Name__c = 'Subject',
            Email__c = 'batch.subject@example.com',
            Contact_Type__c = 'Subject',
            SSN__c = '987-65-4321'
        );
        insert subject;

        Case__c caseRecord = new Case__c(
            Contact__c = subject.Id,
            Assigned_To__c = investigator.Id,
            Case_Number__c = 'BATCH001',
            Case_Type__c = 'Tier 5',
            Service_Days__c = '40',
            Status__c = 'Active',
            Costpoint_Code__c = '3207.C01.0008.T1'
        );
        insert caseRecord;

        Lead__c completedLead = createLead(
            caseRecord.Id,
            subject.Id,
            investigator.Id,
            'Subject Interview (ESI/TESI)',
            'Subject Interview',
            20
        );
        completedLead.Was_Subject_interview_conducted__c = 'Yes';
        insert completedLead;

        completedLead.Status__c = 'Completed';

        Test.startTest();
        GenerateInvoiceRecordsBatch invoiceBatch =
            new GenerateInvoiceRecordsBatch();
        System.assertNotEquals(null, invoiceBatch.start(null), 'Assertion failed in InvoiceModuleControllerTest at source line 233');
        System.runAs(investigator) {
            invoiceBatch.execute(null, new List<Lead__c>{ completedLead });
            invoiceBatch.finish(null);
        }
        Test.stopTest();

        System.runAs(investigator) {
            List<Invoice__c> generatedInvoices = [
                SELECT Lead__c, Case__c, Interview_Method__c, Item_Price__c,
                    Status__c, Pay_Period_Ending__c
                FROM Invoice__c
                WHERE Lead__c = :completedLead.Id
            ];
            System.assertEquals(1, generatedInvoices.size(), 'Assertion failed in InvoiceModuleControllerTest at source line 247');
            System.assertEquals(caseRecord.Id, generatedInvoices[0].Case__c, 'Assertion failed in InvoiceModuleControllerTest at source line 248');
            System.assertEquals('P', generatedInvoices[0].Interview_Method__c, 'Assertion failed in InvoiceModuleControllerTest at source line 249');
            System.assertEquals(450, generatedInvoices[0].Item_Price__c, 'Assertion failed in InvoiceModuleControllerTest at source line 250');
            System.assertEquals('Generated', generatedInvoices[0].Status__c, 'Assertion failed in InvoiceModuleControllerTest at source line 251');
            System.assertNotEquals(
                null,
                generatedInvoices[0].Pay_Period_Ending__c
            , 'Assertion failed in InvoiceModuleControllerTest at source line 252');
        }
    }

    private static Lead__c createLead(
        Id caseId,
        Id contactId,
        Id assignedUserId,
        String leadType,
        String coverageType,
        Integer itemNumber
    ) {
        return new Lead__c(
            Case__c = caseId,
            Assigned_To__c = assignedUserId,
            Contact__c = contactId,
            LeadType__c = leadType,
            Coverage_Type__c = coverageType,
            Item_Number__c = itemNumber,
            Completed_Date__c = Date.today()
        );
    }

    private static User createUser(
        String aliasPrefix,
        String userType,
        String candidateType
    ) {
        Profile standardProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];

        String uniqueValue =
            String.valueOf(DateTime.now().getTime()) +
            String.valueOf(Crypto.getRandomInteger()).replace('-', '');

        User testUser = new User(
            Alias = aliasPrefix.left(8),
            Email = aliasPrefix + uniqueValue + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = aliasPrefix,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            Username = aliasPrefix + uniqueValue + '@example.com',
            User_Type__c = userType,
            Candidate_Type__c = candidateType,
            System_Access__c = 'Intel'
        );
        insert testUser;

        String permissionSetName = userType == 'PMO'
            ? 'PPF_PMO_PS'
            : 'PPF_INV_PS';
        PermissionSet rolePermissionSet = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = :permissionSetName
            LIMIT 1
        ];
        insert new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = rolePermissionSet.Id
        );

        return testUser;
    }
}