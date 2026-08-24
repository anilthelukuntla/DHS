@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexAssertionsShouldIncludeMessage')
private class DHSCustomerInterfaceControllerTest {
    @IsTest
    static void groupsExecutedOrdersAndTheirCases() {
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

        System.assertEquals(1, controller.UploadedcustomerOrders.size());
        System.assertEquals(1, controller.executedCustomerOrders.size());
        System.assertEquals(
            caseRecord.Id,
            controller.executedCustomerOrdersandCasesMap.get(executed.Id)[0].Id
        );
    }
}
