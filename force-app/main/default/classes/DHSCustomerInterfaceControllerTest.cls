@IsTest
/** Exercises the existing DHSCustomerInterfaceController behavior. */
private class DHSCustomerInterfaceControllerTest {
    @TestSetup
    static void setupUser() {
        PPFDHSTestUserFactory.createPmoUser();
    }

    @IsTest
    static void groupsExecutedOrdersAndTheirCases() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
            DHS_Customer_Order__c uploaded =
                new DHS_Customer_Order__c(Status__c = 'Uploaded');
            DHS_Customer_Order__c executed =
                new DHS_Customer_Order__c(Status__c = 'Executed');
            insert new List<DHS_Customer_Order__c>{ uploaded, executed };
            DHS_Case__c caseRecord = new DHS_Case__c(DHS_Order__c = executed.Id);
            insert caseRecord;
            insert new Attachment(
                ParentId = uploaded.Id,
                Name = 'customer-order.txt',
                Body = Blob.valueOf('test')
            );

            DHSCustomerInterfaceController controller =
                new DHSCustomerInterfaceController();

            System.assertEquals(1, controller.UploadedcustomerOrders.size(), 'Assertion failed in DHSCustomerInterfaceControllerTest at source line 28');
            System.assertEquals(1, controller.executedCustomerOrders.size(), 'Assertion failed in DHSCustomerInterfaceControllerTest at source line 29');
            System.assertEquals(
                caseRecord.Id,
                controller.executedCustomerOrdersandCasesMap.get(executed.Id)[0].Id
            , 'Assertion failed in DHSCustomerInterfaceControllerTest at source line 30');
        }
    }
}