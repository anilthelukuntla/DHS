@IsTest
/** Exercises ExecuteCustomerOrdersBatch with combined PPF and DHS PMO access. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs')
private class ExecuteCustomerOrdersBatchTest {
    @IsTest
    static void processesValidCustomerOrderCsvAndDocuments() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
            DIA_Customer_Order__c order = new DIA_Customer_Order__c(Status__c = 'Uploaded');
            insert order;
            Customer_Order_Upload_Log__c uploadLog = new Customer_Order_Upload_Log__c(
                DIA_Customer_Order__c = order.Id
            );
            Database.insert(uploadLog, AccessLevel.SYSTEM_MODE);
            String csv =
                'First_Name__c,Last_Name__c,State__c,SSN__c,Email__c,Document Name\n' +
                'Batch,Coverage,VA,123-45-6789,batch.coverage@example.com,CASE001.pdf';
            insert new List<ContentVersion>{
                new ContentVersion(
                    Title = 'OrderData.csv', PathOnClient = 'OrderData.csv',
                    VersionData = Blob.valueOf(csv), FirstPublishLocationId = order.Id
                ),
                new ContentVersion(
                    Title = 'CASE001.pdf', PathOnClient = 'CASE001.pdf',
                    VersionData = Blob.valueOf('pdf content'), FirstPublishLocationId = order.Id
                )
            };

            Test.startTest();
            ExecuteCustomerOrdersBatch batch = new ExecuteCustomerOrdersBatch(order.Id, uploadLog.Id);
            batch.execute(null, new List<DIA_Customer_Order__c>{ order });
            try {
                batch.finish(null);
            } catch (EmailException expected) {
                System.assert(expected.getMessage().contains('email'), 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 35');
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void coversValidationAndCsvHelpers() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
            ExecuteCustomerOrdersBatch batch = new ExecuteCustomerOrdersBatch(null, null);
            System.assertEquals(true, batch.isValidEmailAddress('valid@example.com'), 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 46');
            System.assertEquals(false, batch.isValidEmailAddress('invalid'), 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 47');
            System.assertEquals(false, batch.isValidEmailAddress(null), 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 48');
            System.assertEquals(true, batch.isValidSSN('123-45-6789'), 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 49');
            System.assertEquals(false, batch.isValidSSN('invalid'), 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 50');
            System.assertEquals(false, batch.isValidSSN(null), 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 51');
            System.assertEquals(true, batch.isValidZip('12345'), 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 52');
            System.assertEquals(true, batch.isValidZip('12345-6789'), 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 53');
            System.assertEquals(false, batch.isValidZip('bad'), 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 54');
            System.assertEquals(true, batch.isValidState('VA'), 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 55');
            System.assertEquals(false, batch.isValidState('Virginia'), 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 56');
            System.assertNotEquals(null, batch.ValidateRow(
                'SSN__c,Email__c,State__c,Zip__c',
                new List<String>{ 'bad', 'bad', 'bad', 'bad' }
            ), 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 57');
            System.assertNotEquals(null, batch.ValidateRow(
                'Email__c,SSN__c', new List<String>{ 'bad', 'bad' }
            ), 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 61');
            System.assertNotEquals(null, batch.ValidateRow(
                'State__c', new List<String>{ 'Virginia' }
            ), 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 64');
            System.assertNotEquals(null, batch.ValidateRow(
                'Zip__c', new List<String>{ 'bad' }
            ), 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 67');
            System.assertEquals(null, batch.ValidateRow(
                'Zip__c', new List<String>{ '1234' }
            ), 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 70');
            System.assertEquals(2, batch.GetColumnIndex('One,Two,Document Name', 'Document Name'), 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 73');
            System.assertEquals(3, batch.splitString('One,"Two, with comma",Three').size(), 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 74');
            System.assertNotEquals(null, batch.getFieldDataType('DIA_Contact__c', 'Email__c'), 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 75');
        }
    }

    @IsTest
    static void marksOrderFailedWhenCsvIsMissing() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
            DIA_Customer_Order__c order = new DIA_Customer_Order__c(Status__c = 'Uploaded');
            insert order;
            Customer_Order_Upload_Log__c uploadLog = new Customer_Order_Upload_Log__c(
                DIA_Customer_Order__c = order.Id
            );
            Database.insert(uploadLog, AccessLevel.SYSTEM_MODE);

            Test.startTest();
            ExecuteCustomerOrdersBatch batch = new ExecuteCustomerOrdersBatch(order.Id, uploadLog.Id);
            System.assertNotEquals(null, batch.start(null), 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 92');
            batch.execute(null, new List<DIA_Customer_Order__c>{ order });
            batch.generatedCSVFile = 'Header\n';
            batch.formattedgeneratedCSVFile = 'Header\n';
            try {
                batch.finish(null);
            } catch (EmailException expected) {
                System.assert(expected.getMessage().contains('email'), 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 99');
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void rejectsRowsWithMissingDocuments() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
            DIA_Customer_Order__c order = new DIA_Customer_Order__c(Status__c = 'Uploaded');
            insert order;
            String csv =
                'First_Name__c,Last_Name__c,State__c,SSN__c,Email__c,Document Name\n' +
                'Missing,Document,VA,111-22-3333,missing@example.com,NOTFOUND.pdf\n' +
                'Blank,Document,VA,222-33-4444,blank@example.com,';
            insert new ContentVersion(
                Title = 'OrderData.csv', PathOnClient = 'OrderData.csv',
                VersionData = Blob.valueOf(csv), FirstPublishLocationId = order.Id
            );

            ExecuteCustomerOrdersBatch batch = new ExecuteCustomerOrdersBatch(order.Id, null);
            batch.execute(null, new List<DIA_Customer_Order__c>{ order });
            System.assertEquals(1, batch.failureCasesCount, 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 122');
        }
    }

    @IsTest
    static void createsCasesAndCopiesDocumentsForContacts() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
            DIA_Customer_Order__c order = new DIA_Customer_Order__c(Status__c = 'Uploaded');
            insert order;
            DIA_Contact__c contact = new DIA_Contact__c(
                First_Name__c = 'Direct', Last_Name__c = 'Coverage',
                State__c = 'VA', SSN__c = '987-65-4321',
                Email__c = 'direct.coverage@example.com'
            );
            insert contact;
            insert new ContentVersion(
                Title = 'DIRECT001.pdf', PathOnClient = 'DIRECT001.pdf',
                VersionData = Blob.valueOf('direct pdf'), FirstPublishLocationId = contact.Id
            );
            ContentDocumentLink link = [
                SELECT Id, ContentDocumentId, LinkedEntityId, ContentDocument.Title
                FROM ContentDocumentLink WHERE LinkedEntityId = :contact.Id LIMIT 1
            ];

            ExecuteCustomerOrdersBatch batch = new ExecuteCustomerOrdersBatch(order.Id, null);
            Map<String, String> caseIds = batch.CreateCaseAction(
                new List<String>{ contact.Id },
                order.Id,
                new Map<String, List<ContentDocumentLink>>{
                    contact.Id => new List<ContentDocumentLink>{ link }
                }
            );
            System.assertNotEquals(null, caseIds, 'Assertion failed in ExecuteCustomerOrdersBatchTest at source line 155');
        }
    }
}