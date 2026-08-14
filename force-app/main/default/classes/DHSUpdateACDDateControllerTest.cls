@IsTest
/** Exercises the existing DHSUpdateACDDateController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSUpdateACDDateControllerTest {
    @IsTest
    static void loadsOrdersAndWrapperValues() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
        DHS_Contact__c subject = new DHS_Contact__c(
            First_Name__c = 'Order', Last_Name__c = 'Subject',
            SSN__c = '123-45-6789'
        );
        insert subject;
        DHS_Customer_Order__c executedOrder = new DHS_Customer_Order__c(
            Status__c = 'Executed', ACD_Date__c = Date.today()
        );
        DHS_Customer_Order__c uploadedOrder = new DHS_Customer_Order__c(
            Status__c = 'Uploaded'
        );
        insert new List<DHS_Customer_Order__c>{ executedOrder, uploadedOrder };
        DHS_Case__c completedCase = new DHS_Case__c(
            DHS_Contact__c = subject.Id,
            DHS_Order__c = executedOrder.Id,
            Current_Task__c = 'QA Review Completed',
            Case_Number__c = 'ACD-TEST'
        );
        insert completedCase;
        DHS_Document__c roi = new DHS_Document__c(
            DHS_Case__c = completedCase.Id, Name__c = 'ROIReport'
        );
        insert roi;
        insert new Attachment(
            ParentId = roi.Id, Name = 'roi.pdf',
            Body = Blob.valueOf('pdf')
        );
        completedCase.Current_Task__c = 'QA Review Completed';
        completedCase.Case_Completed_Date__c = Date.today();
        completedCase.Case_Due_Date__c = Date.today().addDays(1);
        Database.update(completedCase, AccessLevel.SYSTEM_MODE);
        DHS_Customer_Order_Upload_Log__c log =
            new DHS_Customer_Order_Upload_Log__c(
                DHS_Customer_Order__c = uploadedOrder.Id,
                Error_Message__c = 'Test log'
            );
        insert log;

        DHSUpdateACDDateController controller =
            new DHSUpdateACDDateController();
        controller.GetCustomerOrders();
        controller.subjectFirstNameSearchEntry = 'Order';
        controller.subjectLastNameSearchEntry = 'Subject';
        controller.subjectSSNSearchEntry = '123-45';
        controller.getDeliverables();
        System.assertEquals(1, controller.deliverables.size(), 'Assertion failed in DHSUpdateACDDateControllerTest at source line 54');
        controller.SaveOrderAction();
        System.assertEquals(1,
            controller.FetchCasesofCustomerOrder(
                new List<String>{ executedOrder.Id }).size(), 'Assertion failed in DHSUpdateACDDateControllerTest at source line 56');
        System.assert(!controller.FetchOrderInformation('Executed').isEmpty(), 'Assertion failed in DHSUpdateACDDateControllerTest at source line 59');
        DHSUpdateACDDateController.OrderRecord wrapper =
            new DHSUpdateACDDateController.OrderRecord(
                null, new DHS_Customer_Order__c(), 'log', null);
        System.assertEquals('log', wrapper.logMessage, 'Assertion failed in DHSUpdateACDDateControllerTest at source line 63');
        System.assertNotEquals(null, controller.UploadedcustomerOrders, 'Assertion failed in DHSUpdateACDDateControllerTest at source line 64');
        System.assertNotEquals(null, controller.deliverables, 'Assertion failed in DHSUpdateACDDateControllerTest at source line 65');
        }
    }

    @IsTest
    static void createsOrderForUploadedContent() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
        ContentVersion version = new ContentVersion(
            Title = 'OrderData',
            PathOnClient = 'OrderData.csv',
            VersionData = Blob.valueOf('header\nvalue')
        );
        insert version;
        DHSUpdateACDDateController.CreateOrderNDocuments(
            new List<String>{ version.Id });
        System.assertEquals(1, [
            SELECT count() FROM DHS_Customer_Order__c
            WHERE Status__c = 'Uploaded'
        ], 'Assertion failed in DHSUpdateACDDateControllerTest at source line 81');
        System.assertEquals(1, [
            SELECT count() FROM DHS_Customer_Order_Upload_Log__c
        ], 'Assertion failed in DHSUpdateACDDateControllerTest at source line 85');
        }
    }
}