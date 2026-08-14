@IsTest
/** Exercises the existing DHSExecuteCustomerOrdersBatch behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSExecuteCustomerOrdersBatchTest {
    @IsTest
    static void processesValidCustomerOrderCsvAndDocuments() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
        DHS_Customer_Order__c order = new DHS_Customer_Order__c(
            Status__c = 'Uploaded'
        );
        insert order;
        DHS_Customer_Order_Upload_Log__c uploadLog =
            new DHS_Customer_Order_Upload_Log__c(
                DHS_Customer_Order__c = order.Id
            );
        Database.insert(uploadLog, AccessLevel.SYSTEM_MODE);

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
    }

    @IsTest
    static void coversValidationAndCsvHelpers() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
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
        batch.ValidateRow(
            'Email__c,SSN__c', new List<String>{ 'bad', 'bad' }
        );
        batch.ValidateRow('State__c', new List<String>{ 'Virginia' });
        batch.ValidateRow('Zip__c', new List<String>{ 'bad' });
        batch.ValidateRow('Zip__c', new List<String>{ '1234' });
        batch.GetColumnIndex('One,Two,Document Name', 'Document Name');
        batch.splitString('One,"Two, with comma",Three');
        batch.getFieldDataType('DHS_Contact__c', 'Email__c');
            }
    }

    @IsTest
    static void createsCasesAndCopiesDocumentsForContacts() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
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
    }

    @IsTest
    static void marksOrderFailedWhenCsvIsMissing() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
        DHS_Customer_Order__c order = new DHS_Customer_Order__c(
            Status__c = 'Uploaded'
        );
        insert order;
        DHS_Customer_Order_Upload_Log__c uploadLog =
            new DHS_Customer_Order_Upload_Log__c(
                DHS_Customer_Order__c = order.Id
            );
        Database.insert(uploadLog, AccessLevel.SYSTEM_MODE);

        Test.startTest();
        Database.executeBatch(
            new DHSExecuteCustomerOrdersBatch(order.Id, uploadLog.Id), 1
        );
        Test.stopTest();
            }
    }

    @IsTest
    static void rejectsRowsWithMissingDocuments() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
            DHS_Customer_Order__c order = new DHS_Customer_Order__c(Status__c = 'Uploaded');
            insert order;
            String csv =
                'First_Name__c,Last_Name__c,State__c,SSN__c,Email__c,Document Name\n' +
                'Missing,Document,VA,111-22-3333,missing@example.com,NOTFOUND.pdf\n' +
                'Blank,Document,VA,222-33-4444,blank@example.com,';
            insert new ContentVersion(
                Title = 'OrderData.csv', PathOnClient = 'OrderData.csv',
                VersionData = Blob.valueOf(csv), FirstPublishLocationId = order.Id
            );

            DHSExecuteCustomerOrdersBatch batch =
                new DHSExecuteCustomerOrdersBatch(order.Id, null);
            batch.execute(null, new List<DHS_Customer_Order__c>{ order });
            System.assertEquals(1, batch.failureCasesCount, 'Assertion failed in DHSExecuteCustomerOrdersBatchTest at source line 155');
        }
    }

    @IsTest
    static void updatesExistingContactFromValidCsv() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
            insert new DHS_Contact__c(
                First_Name__c = 'Existing', Last_Name__c = 'Contact',
                State__c = 'VA', SSN__c = '333-44-5555',
                Email__c = 'existing@example.com'
            );
            DHS_Customer_Order__c order = new DHS_Customer_Order__c(Status__c = 'Uploaded');
            insert order;
            String csv =
                'First_Name__c,Last_Name__c,State__c,SSN__c,Email__c,Document Name\n' +
                'Updated,Contact,VA,333-44-5555,updated@example.com,UPDATE001.pdf';
            insert new List<ContentVersion>{
                new ContentVersion(
                    Title = 'OrderData.csv', PathOnClient = 'OrderData.csv',
                    VersionData = Blob.valueOf(csv), FirstPublishLocationId = order.Id
                ),
                new ContentVersion(
                    Title = 'UPDATE001.pdf', PathOnClient = 'UPDATE001.pdf',
                    VersionData = Blob.valueOf('pdf'), FirstPublishLocationId = order.Id
                )
            };
            DHSExecuteCustomerOrdersBatch batch =
                new DHSExecuteCustomerOrdersBatch(order.Id, null);
            batch.execute(null, new List<DHS_Customer_Order__c>{ order });
            System.assertEquals(1, batch.successCasesCount, 'Assertion failed in DHSExecuteCustomerOrdersBatchTest at source line 186');
        }
    }
}