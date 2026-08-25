@isTest
public class BICustomerInterfaceControllerTest {
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
            Email = 'test@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserRoleId = null,
            User_Type__c = 'QA',
            Username = 'testuser13456@example.com',
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
            Username = 'testuser12454w@example.com.bitesting2837232',
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
            Username = 'testuser1123er31@example.com.bitesting37232',
            system_access__c = 'Intel'
        );
        insert testUser2;
    }
     @isTest
    static void testConstructorInitialization() {
        // Create test data
        DIA_Customer_order__c order1 = new DIA_Customer_order__c(Status__c = 'Uploaded');
        DIA_Customer_order__c order2 = new DIA_Customer_order__c(Status__c = 'Executed');
        insert new List<DIA_Customer_order__c>{order1, order2};
		Dia_case__c c = new dia_case__c(case_origin__c = 'Case Intake');
        insert c;
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
          DIA_Case__c case2 = new DIA_Case__c(case_origin__C='Case Intake', Current_Task__c = 'QA Review Completed');
        insert case2;

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
        BICustomerInterfaceController.delWrapper('string', 'string', system.now(), 'string', 'string',system.today(), system.today(), 'lastName', 'string','string','Delivered canceled');
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

   
}