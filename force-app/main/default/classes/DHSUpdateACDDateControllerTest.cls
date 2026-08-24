@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexAssertionsShouldIncludeMessage')
private class DHSUpdateACDDateControllerTest {
    @IsTest
    static void loadsOrdersAndWrapperValues() {
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
        controller.getDeliverables();
        controller.SaveOrderAction();
        System.assertEquals(1,
            controller.FetchCasesofCustomerOrder(
                new List<String>{ executedOrder.Id }).size());
        System.assert(!controller.FetchOrderInformation('Executed').isEmpty());
        DHSUpdateACDDateController.OrderRecord wrapper =
            new DHSUpdateACDDateController.OrderRecord(
                null, new DHS_Customer_Order__c(), 'log', null);
        System.assertEquals('log', wrapper.logMessage);
        System.assertNotEquals(null, controller.UploadedcustomerOrders);
        System.assertNotEquals(null, controller.deliverables);
    }

    @IsTest
    static void createsOrderForUploadedContent() {
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
        ]);
        System.assertEquals(1, [
            SELECT count() FROM DHS_Customer_Order_Upload_Log__c
        ]);
    }
}
