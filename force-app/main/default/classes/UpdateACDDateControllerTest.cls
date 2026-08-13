@IsTest
/** Exercises PPF customer-order ACD and deliverable processing. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class UpdateACDDateControllerTest {
    @IsTest
    static void loadsOrdersDeliverablesAndWrappers() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
            DIA_Contact__c subject = new DIA_Contact__c(
                First_Name__c = 'Order', Last_Name__c = 'Subject',
                SSN__c = '123-45-6789'
            );
            insert subject;
            DIA_Customer_Order__c executedOrder = new DIA_Customer_Order__c(
                Status__c = 'Executed', ACD_Date__c = Date.today()
            );
            DIA_Customer_Order__c uploadedOrder = new DIA_Customer_Order__c(
                Status__c = 'Uploaded'
            );
            insert new List<DIA_Customer_Order__c>{ executedOrder, uploadedOrder };
            DIA_Case__c completedCase = new DIA_Case__c(
                Contact__c = subject.Id,
                Order__c = executedOrder.Id,
                Current_Task__c = 'QA Review Completed',
                Case_Number__c = 'ACD-TEST'
            );
            insert completedCase;
            DIA_Document__c roi = new DIA_Document__c(
                Case__c = completedCase.Id, Name__c = 'ROIReport'
            );
            insert roi;
            insert new Attachment(
                ParentId = roi.Id, Name = 'roi.pdf', Body = Blob.valueOf('pdf')
            );
            completedCase.Case_Completed_Date__c = Date.today();
            completedCase.Case_Due_Date__c = Date.today().addDays(1);
            Database.update(completedCase, AccessLevel.SYSTEM_MODE);
            insert new Customer_Order_Upload_Log__c(
                DIA_Customer_Order__c = uploadedOrder.Id,
                Error_Message__c = 'Test log'
            );

            UpdateACDDateController controller = new UpdateACDDateController();
            controller.GetCustomerOrders();
            controller.subjectFirstNameSearchEntry = 'Order';
            controller.subjectLastNameSearchEntry = 'Subject';
            controller.subjectSSNSearchEntry = '123-45';
            controller.getDeliverables();
            System.assertEquals(1, controller.deliverables.size(), 'Assertion failed in UpdateACDDateControllerTest at source line 49');
            controller.SaveOrderAction();
            System.assertEquals(1, controller.FetchCasesofCustomerOrder(
                new List<String>{ executedOrder.Id }).size(), 'Assertion failed in UpdateACDDateControllerTest at source line 51');
            System.assert(!controller.FetchOrderInformation('Executed').isEmpty(), 'Assertion failed in UpdateACDDateControllerTest at source line 53');
            UpdateACDDateController.OrderRecord wrapper =
                new UpdateACDDateController.OrderRecord(
                    null, new DIA_Customer_Order__c(), 'log', null
                );
            System.assertEquals('log', wrapper.logMessage, 'Assertion failed in UpdateACDDateControllerTest at source line 58');
        }
    }

    @IsTest
    static void createsOrderForUploadedContent() {
        ContentVersion version = new ContentVersion(
            Title = 'OrderData', PathOnClient = 'OrderData.csv',
            VersionData = Blob.valueOf('header\nvalue')
        );
        insert version;
        UpdateACDDateController.skipBatchExecution = true;

        UpdateACDDateController.CreateOrderNDocuments(
            new List<String>{ version.Id }
        );

        System.assertEquals(1, [
            SELECT count() FROM DIA_Customer_Order__c WHERE Status__c = 'Uploaded'
        ], 'Assertion failed in UpdateACDDateControllerTest at source line 75');
        System.assertEquals(1, [SELECT count() FROM Customer_Order_Upload_Log__c], 'Assertion failed in UpdateACDDateControllerTest at source line 78');
    }

}