@isTest
public class BITestClass {
    @TestSetUp
    public static void setup(){
        Account acc = New account(name='Test');
        insert acc;
        
        contact con = New contact(lastName = 'Test Contact',accountId = acc.Id,email = 'test@test.com');
        insert con;
        
        // Create test data
        User testUser = new User(
            lastName = 'Test',
            Alias = 'tuser',
            Email = 'test123123@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserRoleId = null,
            User_Type__c = 'QA',
            Username = 'testuser11233@example.com',
            system_access__c = 'Intel'
        );
        insert testUser;
        
        // Create multiple cases for pagination testing
        List<DIA_Case__c> cases = new List<DIA_Case__c>();
        for (Integer i = 0; i < 500; i++) {
            cases.add(new DIA_Case__c(
                Case_Number__c = 'Case' + i,
                Subject__c = 'Subject' + i,
                Case_Type__c = 'Tier 5',
                Submission_Date__c = Date.today(),
                Service_Days__c = '45',
                Assigned_To__c = testUser.Id
            ));
        }
        insert cases;
        
        // Create test data
        User testUser1 = new User(
            lastName = 'Test',
            Alias = 'tuser',
            Email = 'testuser123@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserRoleId = null,
            User_Type__c = 'CMO',
            Username = 'testuser12123@example.com.bitesting2837232',
            system_access__c = 'Intel'
        );
        insert testUser1;
        
        User testUser2 = new User(
            
            lastName = 'Test',
            Alias = 'tuser',
            Email = 'testuser132@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserRoleId = null,
            User_Type__c = 'QA',
            Username = 'testuser11123231@example.com.bitesting37232',
            system_access__c = 'Intel'
        );
        insert testUser2;
    }
    TestMethod static void BIChangePassword(){
        ISNBIChangePasswordController cp = New ISNBIChangePasswordController();
        cp.newPassword = 'Test@12345';
        cp.verifyNewPassword = 'Test@12345';
        cp.oldPassword = 'Test@123';
        cp.changePassword();
	}
    TestMethod static void docRequestTrigger(){
        DIA_Case__c c = new DIA_Case__c();
        c.case_number__c = 'test';
        insert c;
        DIA_lead__c lead = new DIA_lead__c();
        lead.case__c = c.id;
        lead.status__C = 'Assigned';
        insert lead;
        
        
        DIA_Document_Request__c docRequest = new DIA_Document_Request__c(
            to_Address__c = 'test@example.com',
            Additional_To_Address__c = 'additional@example.com',
            Investigator_Comments__c = 'Test comment',
            Lead__c = lead.Id
        );
        insert docRequest;
    }
       
    @isTest
    static void testSendHTMLEmail() {
        // Set up test data
        List<String> recipients = new List<String>{'test@example.com'};
        String emailSubject = 'Test Subject';
        String htmlBody = 'This is a <b>test</b> email.';
        List<String> ccRecipients = new List<String>{'cc@example.com'};
        
        Test.startTest();
        
        // Call the method to test
        MailUtilities.sendHTMLEmail(recipients, emailSubject, htmlBody, ccRecipients);
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testSendHTMLEmailWithTemplate() {
        // Create a test EmailTemplate
        //EmailTemplate testTemplate = new EmailTemplate(Name = 'Test Template', DeveloperName = 'Test_Template');
        //insert testTemplate;
        
        EmailTemplate testTemplate = new EmailTemplate();
        testTemplate.isActive = true;
        testTemplate.Name = 'Test Template';
        testTemplate.DeveloperName = 'unique_name_addSomethingSpecialHere';
        testTemplate.TemplateType = 'text';
        testTemplate.FolderId = UserInfo.getUserId();
        
        insert testTemplate;
        
        
        
        // Set up test data
        List<String> recipients = new List<String>{'test@example.com'};
        String emailSubject = 'Test Subject with Template';
        String htmlBody = 'This is a <b>test</b> email using a template.';
        List<String> ccRecipients = new List<String>{'cc@example.com'};
        String emailTemplateName = 'Test Template';
        String whatId; // Replace with a valid Id for the "WhatId" field if necessary
        
        list<contact> con = [select id from contact];
        whatId = con[0].Id;
        Test.startTest();
        system.debug([Select Id, Name from EmailTemplate WHERE Name =:emailTemplateName]);
        
        // Call the method to test
        MailUtilities.sendHTMLEmail(recipients, emailSubject, htmlBody, ccRecipients, emailTemplateName, whatId);
        MailUtilities.sendHTMLEmailWithTargetObjectId(whatId,emailSubject,htmlBody,ccRecipients);
        Test.stopTest();
    }
    
    @isTest
    static void testSendBIEmail() {
        // Set up test data
        List<String> sendingTo = new List<String>{'test@example.com'};
        List<String> sendingToBccAdd = new List<String>{'bcc@example.com'};
        List<String> sendingToccAdd = new List<String>{'cc@example.com'};
        String subject = 'BI Email Subject';
        String body = 'This is a <b>BI test email</b>.';
        
        Test.startTest();
        
        // Call the method to test
        MailUtilities.sendBIEmail(subject, body, sendingTo, sendingToBccAdd, sendingToccAdd);
        Test.stopTest();
    }
       
    @isTest
    static void testIteratorBasicFunctionality() {
        // Setup test data
        String fileData = 'row1\nrow2\nrow3';
        String rowDelimiter = '\n';
        
        // Create the iterator
        DIAUtility_RowIterator iterator = new DIAUtility_RowIterator(fileData, rowDelimiter);
        
        // Collect results
        List<String> results = new List<String>();
        while (iterator.hasNext()) {
            results.add(iterator.next());
        }
    }
    
    @isTest
    static void testIteratorEmptyData() {
        // Setup test data
        String fileData = '';
        String rowDelimiter = '\n';
        
        // Create the iterator
        DIAUtility_RowIterator iterator = new DIAUtility_RowIterator(fileData, rowDelimiter);
        
        // Collect results
        List<String> results = new List<String>();
        while (iterator.hasNext()) {
            results.add(iterator.next());
        }
    }
    
    @isTest
    static void testIteratorNoDelimiters() {
        // Setup test data
        String fileData = 'singleRowData';
        String rowDelimiter = '\n';
        
        // Create the iterator
        DIAUtility_RowIterator iterator = new DIAUtility_RowIterator(fileData, rowDelimiter);
        
        // Collect results
        List<String> results = new List<String>();
        while (iterator.hasNext()) {
            results.add(iterator.next());
        }
    }
    
    @isTest
    static void testIteratorDelimiterAtEnd() {
        // Setup test data
        String fileData = 'row1\nrow2\n';
        String rowDelimiter = '\n';
        
        // Create the iterator
        DIAUtility_RowIterator iterator = new DIAUtility_RowIterator(fileData, rowDelimiter);
        
        // Collect results
        List<String> results = new List<String>();
        while (iterator.hasNext()) {
            results.add(iterator.next());
        }
    }
    
    @isTest
    static void testIteratorCustomDelimiter() {
        // Setup test data
        String fileData = 'row1;row2;row3';
        String rowDelimiter = ';';
        
        // Create the iterator
        DIAUtility_RowIterator iterator = new DIAUtility_RowIterator(fileData, rowDelimiter);
        
        // Collect results
        List<String> results = new List<String>();
        while (iterator.hasNext()) {
            results.add(iterator.next());
        }
    }
    
    @isTest
    static void testConstructorInitialization() {
        // Create test data
        DIA_Customer_order__c order1 = new DIA_Customer_order__c(Status__c = 'Uploaded');
        DIA_Customer_order__c order2 = new DIA_Customer_order__c(Status__c = 'Executed');
        insert new List<DIA_Customer_order__c>{order1, order2};

        // Initialize the controller
        BICustomerInterfaceController controller = new BICustomerInterfaceController();
        UpdateACDDateController ctrl= new UpdateACDDateController();
    }
    
    @isTest
    static void testFetchCasesofCustomerOrder() {
        // Create test data
        DIA_Customer_order__c order = new DIA_Customer_order__c();
        order.status__c = 'Success';
       
        insert order;

        DIA_Case__c case1 = new DIA_Case__c(Order__c = order.Id, Current_Task__c = 'QA Review Completed');
        insert case1;
         order.acd_date__c = system.today();
        update order;

    }

     @isTest
    static void testGetDeliverables() {
        // Create test data
        DIA_Case__c case1 = new DIA_Case__c(
            Current_Task__c = 'QA Review Completed',
            QA_Review_Completed_Date__c = system.today()
        );
        insert case1;

        
        dia_contact__c c = New dia_contact__c(first_name__c='Test Subject');
        insert c;
        List<DIA_Case__c> cases = New List<DIA_Case__c>();
        cases.add(new DIA_Case__c(Case_Queue_Status__c='Completed', Case_Completed_Date__c=System.today(),contact__c = c.Id ,Current_Task__c = 'QA Review Completed'));
        cases.add(new DIA_Case__c(Case_Queue_Status__c='Pending', Case_Completed_Date__c=null,contact__c = c.Id ));
        insert cases;
        
        DIA_Document__c document = new DIA_Document__c(Name__c = 'ROIReport', Case__c = cases[0].Id);
        insert document;

        Attachment attachment = new Attachment(
            ParentId = document.Id,
            Name = 'Attachment',
            Body = Blob.valueOf('Attachment body')
        );
        insert attachment;
		system.debug([Select Id,(select id,Name__c from documents__r) From DIA_Case__c ]);
        BICustomerInterfaceController controller = new BICustomerInterfaceController();
        controller.subjectFirstNameSearchEntry = '';
        controller.subjectLastNameSearchEntry = '';
        controller.subjectSSNSearchEntry = '';
        
         UpdateACDDateController controller1 = new UpdateACDDateController();
        controller.subjectFirstNameSearchEntry = '';
        controller.subjectLastNameSearchEntry = '';
        controller.subjectSSNSearchEntry = '';

    }
    
    
   
    @isTest
    static void testBIDashboardController() {
        // Setup test data
        // Create sample cases
        List<DIA_Case__c> cases = new List<DIA_Case__c>();
        
        dia_contact__c c = New dia_contact__c(first_name__c='Test Subject');
        insert c;
        cases.add(new DIA_Case__c(Case_Queue_Status__c='Completed', Case_Completed_Date__c=System.today(),contact__c = c.Id ));
        cases.add(new DIA_Case__c(Case_Queue_Status__c='Pending', Case_Completed_Date__c=null,contact__c = c.Id ));
        insert cases;
        
        // Create sample leads
        List<DIA_Lead__c> leads = new List<DIA_Lead__c>();
        leads.add(new DIA_Lead__c(status__c='Completed', LeadType__c='Type1',Contact__c = c.Id,case__c = cases[0].Id));
        leads.add(new DIA_Lead__c(status__c='Pending', LeadType__c='Type2',contact__c = c.Id,case__c = cases[1].Id));
        leads.add(new DIA_Lead__c(status__c='Pending', LeadType__c='Type1',contact__c = c.Id,case__c = cases[0].Id));
        insert leads;
        
        // Create mock for DIATooling.fetchRecords
        Test.startTest();
        // Mocking the DIATooling.fetchRecords method
        // Simulate the response for total cases
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('{"totalSize":2}'));
        Test.stopTest();
        
        // Initialize the controller
        BIDashboardController controller = new BIDashboardController();
        
        // Verify current week completed case status
        List<String> currentWeekDates = controller.getCurrentWeekDates();
        // Assuming the completed case is for today, and other days should have 0
        String expectedCurrentWeekCompletedCaseStatus = JSON.serialize(new List<List<Object>>{
            new List<Object>{currentWeekDates[0], 1},
            new List<Object>{currentWeekDates[1], 0},
            new List<Object>{currentWeekDates[2], 0},
            new List<Object>{currentWeekDates[3], 0},
            new List<Object>{currentWeekDates[4], 0},
            new List<Object>{currentWeekDates[5], 0}
        });
    }
    @isTest
    static void testDIALeadDataLoaderBatch() {
        // Create test data
        // Create a DIA_DataLoad_Activity__c record
        DIA_DataLoad_Activity__c activity = new DIA_DataLoad_Activity__c();
        insert activity;
        
        // Create test DIA_Case__c records
        List<DIA_Case__c> cases = new List<DIA_Case__c>();
        
        dia_contact__c con = New dia_contact__c();
        insert con;
        
        cases.add(new DIA_Case__c(Case_Number__c='12345', Contact__c=con.Id));
        cases.add(new DIA_Case__c(Case_Number__c='67890', Contact__c=con.Id));
        insert cases;
        
        // Create a sample CSV file as Blob
        String csvContent = '12345,Value1,10,TypeA,CoverageA,Contact1,Address1,City1,State1,Zip1,OtherInfo1\n' +
                            '67890,Value2,20,TypeB,CoverageB,Contact2,Address2,City2,State2,Zip2,OtherInfo2';
        Blob csvFileBlob = Blob.valueOf(csvContent);

        // Create and execute the batch
        Test.startTest();
        DIALeadDataLoaderBatch batch = new DIALeadDataLoaderBatch(csvFileBlob, activity);
        Database.executeBatch(batch, 1);
        Test.stopTest();
        
        
        // Verify email was sent
        // This is typically done with a mock class for the email sending functionality
        // For simplicity, ensure no exceptions were thrown during the batch execution
    }
    
    @isTest
    static void testDIALeadDataLoaderBatch_ErrorHandling() {
        // Create test data with errors
        DIA_DataLoad_Activity__c activity = new DIA_DataLoad_Activity__c();
        insert activity;
        
        // Create a test DIA_Case__c record with invalid Case Number
        dia_contact__c con = new dia_contact__c();
        insert con;
        DIA_Case__c invalidCase = new DIA_Case__c(Case_Number__c='99999', Contact__c=con.Id);
        insert invalidCase;
        
        // Create a CSV file with an invalid Case Number
        String csvContent = '99999,Value1,10,TypeA,CoverageA,Contact1,Address1,City1,State1,Zip1,OtherInfo1';
        Blob csvFileBlob = Blob.valueOf(csvContent);

        // Create and execute the batch
        Test.startTest();
        DIALeadDataLoaderBatch batch = new DIALeadDataLoaderBatch(csvFileBlob, activity);
        Database.executeBatch(batch, 1);
        Test.stopTest();
        
    }
    
    @isTest
    static void testSplitString() {
        DIALeadDataLoaderBatch batch = new DIALeadDataLoaderBatch(Blob.valueOf(''), new DIA_DataLoad_Activity__c());
        List<String> result = batch.splitString('12345,"Value, with comma",TypeA');
    }
    
	@isTest
    static void testDeliverableWrapper() {
        // Create an instance of deliverableWrapper
        BICustomerInterfaceController.deliverableWrapper wrapper = new BICustomerInterfaceController.deliverableWrapper();
        
        // Set properties
        String testCaseId = '001xx000003DGXwAOR';
        String testCaseNumber = 'CASE-12345';
        DateTime testCreatedDate = DateTime.now();
        String testCreatedBy = 'John Doe';
        String testDocumentId = 'doc123';
        Date testCompletedDate = Date.today();
        Date testDueDate = Date.today().addDays(5);
        String testLastName = 'Smith';
        
        wrapper.caseId = testCaseId;
        wrapper.caseNumber = testCaseNumber;
        wrapper.createdDate = testCreatedDate;
        wrapper.createdBy = testCreatedBy;
        wrapper.documentId = testDocumentId;
        wrapper.completedDate = testCompletedDate;
        wrapper.dueDate = testDueDate;
        wrapper.lastName = testLastName;
    }
    
    @isTest
    static void testDeliverableWrapperv2() {
        // Create an instance of deliverableWrapper
        UpdateACDDateController.deliverableWrapper wrapper = new UpdateACDDateController.deliverableWrapper();
        
        // Set properties
        String testCaseId = '001xx000003DGXwAOR';
        String testCaseNumber = 'CASE-12345';
        DateTime testCreatedDate = DateTime.now();
        String testCreatedBy = 'John Doe';
        String testDocumentId = 'doc123';
        Date testCompletedDate = Date.today();
        Date testDueDate = Date.today().addDays(5);
        String testLastName = 'Smith';
        
        wrapper.caseId = testCaseId;
        wrapper.caseNumber = testCaseNumber;
        wrapper.createdDate = testCreatedDate;
        wrapper.createdBy = testCreatedBy;
        wrapper.documentId = testDocumentId;
        wrapper.completedDate = testCompletedDate;
        wrapper.dueDate = testDueDate;
        wrapper.lastName = testLastName;
    }
    @isTest
    static void createOrderNDocs(){
        
        dia_case__c cse = New dia_case__c();
        insert cse;
        
        dia_contact__c sub = New dia_contact__c();
        sub.first_name__c = 'Test';
        sub.ssn__c = '777-12-3123';
        insert sub;
        
        Blob fileBlob = Blob.valueOf('First_Name__c,Last_Name__c,SSN__c,Email__c,Phone__c,Address__c,City__c,State__c,Zip__c,Document Name'+'\n'+'John4,Derrick4,888-12-3123,John.derrick@test.com,(213) 321-1321,Ms Alice Smith Apartment 1c 213 Derrick Street,Boston,MA,99999-3213,SampleDocumentUpload1.csv'+'\n'+'John5,Derrick5,777-12-3123,John.derrick@test.com,(213) 321-1321,Ms Alice Smith Apartment 1c 213 Derrick Street,Boston,MA,99999-3213,SampleDocumentUpload2.csv');

        List<string> cVersions = new list<string>();
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = 'OrderData.csv'; // Title of the document
            contentVersion.PathOnClient = 'OrderData.csv'; // The filename as it appears on the client's machine
            contentVersion.VersionData = fileBlob; // The content of the file in Blob format
            insert contentVersion;
        
        	ContentVersion contentVersion1 = new ContentVersion();
            contentVersion1.Title = 'SampleDocumentUpload1.csv'; // Title of the document
            contentVersion1.PathOnClient = 'SampleDocumentUpload1.csv'; // The filename as it appears on the client's machine
            contentVersion1.VersionData = fileBlob; // The content of the file in Blob format
            insert contentVersion1;
        
        	ContentVersion contentVersion2 = new ContentVersion();
            contentVersion2.Title = 'SampleDocumentUpload2.csv'; // Title of the document
            contentVersion2.PathOnClient = 'SampleDocumentUpload2.csv'; // The filename as it appears on the client's machine
            contentVersion2.VersionData = fileBlob; // The content of the file in Blob format
            insert contentVersion2;

			cVersions.add(contentVersion.Id);
            cVersions.add(contentVersion1.Id);
            cVersions.add(contentVersion2.Id);        
        BICustomerInterfaceController.CreateOrderNDocuments(cVersions);
        DIACaseDetailController.CreateOrderNDocuments(cVersions,cse.Id);
        
    }
     @isTest
    static void createOrderNDocsv2(){
        
        dia_case__c cse = New dia_case__c();
        insert cse;
        
        dia_contact__c sub = New dia_contact__c();
        sub.first_name__c = 'Test';
        sub.ssn__c = '777-12-3123';
        insert sub;
        
        Blob fileBlob = Blob.valueOf('First_Name__c,Last_Name__c,SSN__c,Email__c,Phone__c,Address__c,City__c,State__c,Zip__c,Document Name'+'\n'+'John4,Derrick4,888-12-3123,John.derrick@test.com,(213) 321-1321,Ms Alice Smith Apartment 1c 213 Derrick Street,Boston,MA,99999-3213,SampleDocumentUpload1.csv'+'\n'+'John5,Derrick5,777-12-3123,John.derrick@test.com,(213) 321-1321,Ms Alice Smith Apartment 1c 213 Derrick Street,Boston,MA,99999-3213,SampleDocumentUpload2.csv');

        List<string> cVersions = new list<string>();
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = 'OrderData.csv'; // Title of the document
            contentVersion.PathOnClient = 'OrderData.csv'; // The filename as it appears on the client's machine
            contentVersion.VersionData = fileBlob; // The content of the file in Blob format
            insert contentVersion;
        
        	ContentVersion contentVersion1 = new ContentVersion();
            contentVersion1.Title = 'SampleDocumentUpload1.csv'; // Title of the document
            contentVersion1.PathOnClient = 'SampleDocumentUpload1.csv'; // The filename as it appears on the client's machine
            contentVersion1.VersionData = fileBlob; // The content of the file in Blob format
            insert contentVersion1;
        
        	ContentVersion contentVersion2 = new ContentVersion();
            contentVersion2.Title = 'SampleDocumentUpload2.csv'; // Title of the document
            contentVersion2.PathOnClient = 'SampleDocumentUpload2.csv'; // The filename as it appears on the client's machine
            contentVersion2.VersionData = fileBlob; // The content of the file in Blob format
            insert contentVersion2;

			cVersions.add(contentVersion.Id);
            cVersions.add(contentVersion1.Id);
            cVersions.add(contentVersion2.Id);        

        
        UpdateACDDateController.CreateOrderNDocuments(cVersions);
        
    }
    @isTest
    static void loginController(){
        ISNBILoginPageController test = new ISNBILoginPageController();
        test.getsystemAccess();
        test.newPassword = 'Test@12345';
        test.systemaccessselected = 'Intel';
        test.Username = 'testuser13@example.com';
        test.Password = 'Test@12345';
        test.doLogin();
        test.ForgotPasswordClickAction();
        test.resetpassword();
        test.sendOTP();
    }
    @isTest
    static void loginControllerTest(){
        ISNBILoginPageController test = new ISNBILoginPageController();
        test.systemaccessselected = 'Intel';
        test.Username = 'testuser12@example.com.bitesting2837232';
        test.Password = 'Test@12345';
        test.doLogin();
    }
    @isTest
    static void loginControllerTest1(){
        ISNBILoginPageController test = new ISNBILoginPageController();
        test.systemaccessselected = 'Intel';
        test.Username = 'test@example.com';
        test.Password = 'Test@12345';
        test.doLogin();
    }
    @isTest
    static void loginControllerTest2(){
        ISNBILoginPageController test = new ISNBILoginPageController();
        test.systemaccessselected = 'DIA';
        test.Username = 'testuser11231@example.com.bitesting37232';
        test.Password = 'Test@12345';
        test.doLogin();
    }
}