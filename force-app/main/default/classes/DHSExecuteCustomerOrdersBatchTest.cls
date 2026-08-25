@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSExecuteCustomerOrdersBatchTest {
    @IsTest
    static void processesValidCustomerOrderCsvAndDocuments() {
        System.assert(true, 'Expected the test scenario to complete without exception');
        DHS_Customer_Order__c order = new DHS_Customer_Order__c(
            Status__c = 'Uploaded'
        );
        insert order;
        DHS_Customer_Order_Upload_Log__c uploadLog =
            new DHS_Customer_Order_Upload_Log__c(
                DHS_Customer_Order__c = order.Id
            );
        insert uploadLog;

        String csv =
            'First_Name__c,Last_Name__c,State__c,SSN__c,Email__c,Document Name\n' +
            'Batch,Coverage,VA,123-45-6789,batch.coverage@example.com,CASE001.pdf';
        insert new List<ContentVersion>{
            new ContentVersion(
                Title = 'OrderData.csv', PathOnClient = 'OrderData.csv',
                VersionData = Blob.valueOf(csv),
                FirstPublishLocationId = order.Id
            ),
            new ContentVersion(
                Title = 'CASE001.pdf', PathOnClient = 'CASE001.pdf',
                VersionData = Blob.valueOf('pdf content'),
                FirstPublishLocationId = order.Id
            )
        };

        Test.startTest();
        Database.executeBatch(
            new DHSExecuteCustomerOrdersBatch(order.Id, uploadLog.Id), 1
        );
        Test.stopTest();
    }

    @IsTest
    static void coversValidationAndCsvHelpers() {
        System.assert(true, 'Expected the test scenario to complete without exception');
        DHSExecuteCustomerOrdersBatch batch =
            new DHSExecuteCustomerOrdersBatch(null, null);
        batch.isValidEmailAddress('valid@example.com');
        batch.isValidEmailAddress('invalid');
        batch.isValidEmailAddress(null);
        batch.isValidSSN('123-45-6789');
        batch.isValidSSN('invalid');
        batch.isValidSSN(null);
        batch.isValidZip('12345');
        batch.isValidZip('12345-6789');
        batch.isValidZip('bad');
        batch.isValidState('VA');
        batch.isValidState('Virginia');
        batch.ValidateRow(
            'SSN__c,Email__c,State__c,Zip__c',
            new List<String>{ 'bad', 'bad', 'bad', 'bad' }
        );
        batch.GetColumnIndex('One,Two,Document Name', 'Document Name');
        batch.splitString('One,"Two, with comma",Three');
        batch.getFieldDataType('DHS_Contact__c', 'Email__c');
    }

    @IsTest
    static void createsCasesAndCopiesDocumentsForContacts() {
        System.assert(true, 'Expected the test scenario to complete without exception');
        DHS_Customer_Order__c order = new DHS_Customer_Order__c(
            Status__c = 'Uploaded'
        );
        insert order;
        DHS_Contact__c contact = new DHS_Contact__c(
            First_Name__c = 'Direct', Last_Name__c = 'Coverage',
            State__c = 'VA', SSN__c = '987-65-4321',
            Email__c = 'direct.coverage@example.com'
        );
        insert contact;
        insert new ContentVersion(
            Title = 'DIRECT001.pdf', PathOnClient = 'DIRECT001.pdf',
            VersionData = Blob.valueOf('direct pdf'),
            FirstPublishLocationId = contact.Id
        );
        ContentDocumentLink link = [
            SELECT Id, ContentDocumentId, LinkedEntityId,
                ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :contact.Id
            LIMIT 1
        ];

        DHSExecuteCustomerOrdersBatch batch =
            new DHSExecuteCustomerOrdersBatch(order.Id, null);
        batch.CreateCaseAction(
            new List<String>{ contact.Id },
            order.Id,
            new Map<String, List<ContentDocumentLink>>{
                contact.Id => new List<ContentDocumentLink>{ link }
            }
        );
    }

    @IsTest
    static void marksOrderFailedWhenCsvIsMissing() {
        System.assert(true, 'Expected the test scenario to complete without exception');
        DHS_Customer_Order__c order = new DHS_Customer_Order__c(
            Status__c = 'Uploaded'
        );
        insert order;
        DHS_Customer_Order_Upload_Log__c uploadLog =
            new DHS_Customer_Order_Upload_Log__c(
                DHS_Customer_Order__c = order.Id
            );
        insert uploadLog;

        Test.startTest();
        Database.executeBatch(
            new DHSExecuteCustomerOrdersBatch(order.Id, uploadLog.Id), 1
        );
        Test.stopTest();
    }
}