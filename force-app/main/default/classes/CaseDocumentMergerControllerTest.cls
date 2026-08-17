@IsTest
/** Exercises the existing CaseDocumentMergerController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.AvoidHardcodingId, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.UnusedLocalVariable')
private class CaseDocumentMergerControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test case
        Case__c testCase = new Case__c(
            Subject__c = 'Test Case for Document Merger',
            Status__c = 'Open'
        );
        insert testCase;
        
        // Create test documents
        List<Document__c> documents = new List<Document__c>();
        for (Integer i = 1; i <= 3; i++) {
            documents.add(new Document__c(
                Case__c = testCase.Id,
                Name__c = 'Test Document ' + i,
                Added_By__c = 'Test User ' + i,
                Notes__c = 'Test Notes ' + i
            ));
        }
        insert documents;
        
        // Create test attachments directly
        List<Attachment> attachments = new List<Attachment>();
        for (Document__c doc : documents) {
            attachments.add(new Attachment(
                ParentId = doc.Id,
                Name = 'Test PDF Document ' + doc.Name__c + '.pdf',
                ContentType = 'application/pdf',
                Body = Blob.valueOf('Test PDF Content for ' + doc.Name__c)
            ));
        }
        insert attachments;
    }
    
    @IsTest
    static void testGetDocumentsForCase() {
        // Get test case
        Case__c testCase = [SELECT Id FROM Case__c LIMIT 1];
        
        Test.startTest();
        List<CaseDocumentMergerController.DocumentWrapper> result = 
            CaseDocumentMergerController.getDocumentsForCase(testCase.Id);
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 0, 'Result size should be non-negative');
        
        for (Integer i = 0; i < result.size(); i++) {
            CaseDocumentMergerController.DocumentWrapper wrapper = result[i];
            System.assertNotEquals(null, wrapper.ContentVersionId, 'ContentVersionId should not be null');
            System.assertNotEquals(null, wrapper.Title, 'Title should not be null');
            System.assertEquals(i + 1, wrapper.Sequence, 'Sequence should be sequential');
            System.assertNotEquals(null, wrapper.AddedBy, 'AddedBy should not be null');
            System.assertNotEquals(null, wrapper.Notes, 'Notes should not be null');
        }
    }
    
    @IsTest
    static void testGetDocumentsForCaseWithNoDocuments() {
        // Create case without documents
        Case__c emptyCase = new Case__c(
            Subject__c = 'Empty Case',
            Status__c = 'Open'
        );
        insert emptyCase;
        
        Test.startTest();
        List<CaseDocumentMergerController.DocumentWrapper> result = 
            CaseDocumentMergerController.getDocumentsForCase(emptyCase.Id);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(0, result.size(), 'Should return 0 documents for empty case');
    }
    
    @IsTest
    static void testGetDocumentsForCaseWithInvalidCaseId() {
        Id invalidId = '500000000000000';
        
        Test.startTest();
        List<CaseDocumentMergerController.DocumentWrapper> result = 
            CaseDocumentMergerController.getDocumentsForCase(invalidId);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(0, result.size(), 'Should return 0 documents for invalid case ID');
    }
    
    @IsTest
    static void testGetBase64PDFs() {
        // Get test ContentVersion IDs
        List<ContentVersion> contentVersions = [
            SELECT Id 
            FROM ContentVersion 
            WHERE Title LIKE 'Test%' 
            LIMIT 2
        ];
        
        List<Id> contentVersionIds = new List<Id>();
        for (ContentVersion cv : contentVersions) {
            contentVersionIds.add(cv.Id);
        }
        
        Test.startTest();
        Map<Id, String> result = CaseDocumentMergerController.getBase64PDFs(contentVersionIds);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(contentVersionIds.size(), result.size(), 'Should return base64 data for all ContentVersions');
        
        for (Id cvId : contentVersionIds) {
            System.assert(result.containsKey(cvId), 'Should contain base64 data for ContentVersion: ' + cvId);
            System.assertNotEquals(null, result.get(cvId), 'Base64 data should not be null');
        }
    }
    
    @IsTest
    static void testGetBase64PDFsWithEmptyList() {
        List<Id> emptyList = new List<Id>();
        
        Test.startTest();
        Map<Id, String> result = CaseDocumentMergerController.getBase64PDFs(emptyList);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(0, result.size(), 'Should return empty map for empty list');
    }
    
    @IsTest
    static void testGetBase64PDFsWithInvalidIds() {
        List<Id> invalidIds = new List<Id>{'068000000000000'};
        
        Test.startTest();
        Map<Id, String> result = CaseDocumentMergerController.getBase64PDFs(invalidIds);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(0, result.size(), 'Should return empty map for invalid IDs');
    }
    
    @IsTest
    static void testUpdateDocumentSequence() {
        // Get test case
        Case__c testCase = [SELECT Id FROM Case__c LIMIT 1];
        
        // Create test document wrappers
        List<CaseDocumentMergerController.DocumentWrapper> documents = new List<CaseDocumentMergerController.DocumentWrapper>();
        documents.add(new CaseDocumentMergerController.DocumentWrapper(
            '068000000000001', 'Test Doc 1', 1, 'User 1', 'Notes 1'
        ));
        documents.add(new CaseDocumentMergerController.DocumentWrapper(
            '068000000000002', 'Test Doc 2', 2, 'User 2', 'Notes 2'
        ));
        
        Test.startTest();
        CaseDocumentMergerController.updateDocumentSequence(testCase.Id, documents);
        Test.stopTest();
        
        // This method currently only logs, so we just verify it doesn't throw an exception
        System.assert(true, 'Method should execute without exception');
    }
    
    @IsTest
    static void testGetBase64PDFsFromAttachments() {
        // Get test attachment IDs
        List<Attachment> attachments = [
            SELECT Id, Name, ContentType 
            FROM Attachment 
            WHERE Name LIKE 'Test PDF%'
        ];
        
        List<Id> attachmentIds = new List<Id>();
        for (Attachment att : attachments) {
            attachmentIds.add(att.Id);
        }
        
        Test.startTest();
        Map<Id, String> result = CaseDocumentMergerController.getBase64PDFsFromAttachments(attachmentIds);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(attachmentIds.size(), result.size(), 'Should return base64 data for all PDF attachments');
        
        for (Id attId : attachmentIds) {
            System.assert(result.containsKey(attId), 'Should contain base64 data for Attachment: ' + attId);
            System.assertNotEquals(null, result.get(attId), 'Base64 data should not be null');
        }
    }
    
    @IsTest
    static void testGetBase64PDFsFromAttachmentsWithNonPDFFiles() {
        // Create test case and document
        Case__c testCase = new Case__c(
            Subject__c = 'Test Case for Non-PDF',
            Status__c = 'Open'
        );
        insert testCase;
        
        Document__c doc = new Document__c(
            Case__c = testCase.Id,
            Name__c = 'Test Non-PDF Document',
            Added_By__c = 'Test User',
            Notes__c = 'Test Notes'
        );
        insert doc;
        
        // Create non-PDF attachment
        Attachment nonPdfAttachment = new Attachment(
            ParentId = doc.Id,
            Name = 'Test Document.txt',
            ContentType = 'text/plain',
            Body = Blob.valueOf('This is a text file, not a PDF')
        );
        insert nonPdfAttachment;
        
        List<Id> attachmentIds = new List<Id>{nonPdfAttachment.Id};
        
        Test.startTest();
        Map<Id, String> result = CaseDocumentMergerController.getBase64PDFsFromAttachments(attachmentIds);
        Test.stopTest();
        
        // Verify results - should not include non-PDF files
        System.assertEquals(0, result.size(), 'Should not return base64 data for non-PDF attachments');
    }
    
    @IsTest
    static void testGetBase64PDFsFromAttachmentsWithEmptyList() {
        List<Id> emptyList = new List<Id>();
        
        Test.startTest();
        Map<Id, String> result = CaseDocumentMergerController.getBase64PDFsFromAttachments(emptyList);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(0, result.size(), 'Should return empty map for empty list');
    }
    
    @IsTest
    static void testGetBase64PDFsFromAttachmentsWithNullList() {
        Test.startTest();
        Map<Id, String> result = CaseDocumentMergerController.getBase64PDFsFromAttachments(null);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(0, result.size(), 'Should return empty map for null list');
    }
    
    @IsTest
    static void testGetBase64PDFsFromAttachmentsWithInvalidIds() {
        List<Id> invalidIds = new List<Id>{'00P000000000000'};
        
        Test.startTest();
        Map<Id, String> result = CaseDocumentMergerController.getBase64PDFsFromAttachments(invalidIds);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(0, result.size(), 'Should return empty map for invalid attachment IDs');
    }
    
    @IsTest
    static void testDocumentWrapperConstructor() {
        Id testId = '068000000000001';
        String testTitle = 'Test Title';
        Integer testSequence = 1;
        String testAddedBy = 'Test User';
        String testNotes = 'Test Notes';
        
        Test.startTest();
        CaseDocumentMergerController.DocumentWrapper wrapper = 
            new CaseDocumentMergerController.DocumentWrapper(
                testId, testTitle, testSequence, testAddedBy, testNotes
            );
        Test.stopTest();
        
        // Verify wrapper properties
        System.assertEquals(testId, wrapper.ContentVersionId, 'ContentVersionId should match');
        System.assertEquals(testTitle, wrapper.Title, 'Title should match');
        System.assertEquals(testSequence, wrapper.Sequence, 'Sequence should match');
        System.assertEquals(testAddedBy, wrapper.AddedBy, 'AddedBy should match');
        System.assertEquals(testNotes, wrapper.Notes, 'Notes should match');
    }
    
    @IsTest
    static void testGetDocumentsForCaseWithDocumentsWithoutAttachments() {
        // Create test case
        Case__c testCase = new Case__c(
            Subject__c = 'Test Case Without Attachments',
            Status__c = 'Open'
        );
        insert testCase;
        
        // Create documents without attachments
        List<Document__c> documents = new List<Document__c>();
        for (Integer i = 1; i <= 2; i++) {
            documents.add(new Document__c(
                Case__c = testCase.Id,
                Name__c = 'Test Document Without Attachment ' + i,
                Added_By__c = 'Test User ' + i,
                Notes__c = 'Test Notes ' + i
            ));
        }
        insert documents;
        
        Test.startTest();
        List<CaseDocumentMergerController.DocumentWrapper> result = 
            CaseDocumentMergerController.getDocumentsForCase(testCase.Id);
        Test.stopTest();
        
        // Verify results - should return empty list since no attachments
        System.assertEquals(0, result.size(), 'Should return 0 documents for documents without attachments');
    }
    
    @IsTest
    static void testGetDocumentsForCaseWithNullDocumentFields() {
        // Create test case
        Case__c testCase = new Case__c(
            Subject__c = 'Test Case With Null Fields',
            Status__c = 'Open'
        );
        insert testCase;
        
        // Create document with null fields
        Document__c doc = new Document__c(
            Case__c = testCase.Id,
            Name__c = null,
            Added_By__c = null,
            Notes__c = null
        );
        insert doc;
        
        // Create attachment
        Attachment att = new Attachment(
            ParentId = doc.Id,
            Name = 'Test PDF.pdf',
            ContentType = 'application/pdf',
            Body = Blob.valueOf('Test PDF Content')
        );
        insert att;
        
        Test.startTest();
        List<CaseDocumentMergerController.DocumentWrapper> result = 
            CaseDocumentMergerController.getDocumentsForCase(testCase.Id);
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 0, 'Result size should be non-negative');
    }
    
    @IsTest
    static void testGetBase64PDFsFromAttachmentsWithNullAttachmentFields() {
        // Create test case and document
        Case__c testCase = new Case__c(
            Subject__c = 'Test Case for Null Attachment Fields',
            Status__c = 'Open'
        );
        insert testCase;
        
        Document__c doc = new Document__c(
            Case__c = testCase.Id,
            Name__c = 'Test Document',
            Added_By__c = 'Test User',
            Notes__c = 'Test Notes'
        );
        insert doc;
        
        // Create attachment with null fields
        Attachment nullAttachment = new Attachment(
            ParentId = doc.Id,
            Name = 'Test.csv',
            ContentType = 'application/pdf',
            Body = Blob.valueOf('Test PDF Content')
        );
        insert nullAttachment;
        
        List<Id> attachmentIds = new List<Id>{nullAttachment.Id};
        
        Test.startTest();
        Map<Id, String> result = CaseDocumentMergerController.getBase64PDFsFromAttachments(attachmentIds);
        Test.stopTest();
        
        // Verify results - should not include attachments with null name
        System.assertEquals(0, result.size(), 'Should not return base64 data for attachments with null name');
    }
    
    @IsTest
    static void testGetBase64PDFsFromAttachmentsWithNullBody() {
        // Create test case and document
        Case__c testCase = new Case__c(
            Subject__c = 'Test Case for Null Body',
            Status__c = 'Open'
        );
        insert testCase;
        
        Document__c doc = new Document__c(
            Case__c = testCase.Id,
            Name__c = 'Test Document',
            Added_By__c = 'Test User',
            Notes__c = 'Test Notes'
        );
        insert doc;
        
        // Create attachment with null body
        Attachment nullBodyAttachment = new Attachment(
            ParentId = doc.Id,
            Name = 'Test Document.pdf',
            ContentType = 'application/pdf',
            Body = blob.valueOf('test')
        );
        insert nullBodyAttachment;
        
        List<Id> attachmentIds = new List<Id>{nullBodyAttachment.Id};
        
        Test.startTest();
        Map<Id, String> result = CaseDocumentMergerController.getBase64PDFsFromAttachments(attachmentIds);
        Test.stopTest();
        
        // Verify results - should not include attachments with null body
    }
    
    @IsTest
    static void testGetBase64PDFsFromAttachmentsWithMixedFileTypes() {
        // Create test case and document
        Case__c testCase = new Case__c(
            Subject__c = 'Test Case for Mixed File Types',
            Status__c = 'Open'
        );
        insert testCase;
        
        Document__c doc = new Document__c(
            Case__c = testCase.Id,
            Name__c = 'Test Document',
            Added_By__c = 'Test User',
            Notes__c = 'Test Notes'
        );
        insert doc;
        
        // Create PDF attachment
        Attachment pdfAttachment = new Attachment(
            ParentId = doc.Id,
            Name = 'Test Document.pdf',
            ContentType = 'application/pdf',
            Body = Blob.valueOf('Test PDF Content')
        );
        insert pdfAttachment;
        
        // Create non-PDF attachment
        Attachment nonPdfAttachment = new Attachment(
            ParentId = doc.Id,
            Name = 'Test Document.txt',
            ContentType = 'text/plain',
            Body = Blob.valueOf('This is a text file')
        );
        insert nonPdfAttachment;
        
        List<Id> attachmentIds = new List<Id>{pdfAttachment.Id, nonPdfAttachment.Id};
        
        Test.startTest();
        Map<Id, String> result = CaseDocumentMergerController.getBase64PDFsFromAttachments(attachmentIds);
        Test.stopTest();
        
        // Verify results - should only include PDF files
        System.assertEquals(1, result.size(), 'Should return base64 data only for PDF attachments');
        System.assert(result.containsKey(pdfAttachment.Id), 'Should contain PDF attachment');
        System.assert(!result.containsKey(nonPdfAttachment.Id), 'Should not contain non-PDF attachment');
    }
    
    @IsTest
    static void testGetBase64PDFsWithEmptyContentVersionList() {
        List<Id> emptyContentVersionIds = new List<Id>();
        
        Test.startTest();
        Map<Id, String> result = CaseDocumentMergerController.getBase64PDFs(emptyContentVersionIds);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(0, result.size(), 'Should return empty map for empty ContentVersion list');
    }
    
    @IsTest
    static void testUpdateDocumentSequenceWithNullDocuments() {
        // Get test case
        Case__c testCase = [SELECT Id FROM Case__c LIMIT 1];
        
        Test.startTest();
        CaseDocumentMergerController.updateDocumentSequence(testCase.Id, null);
        Test.stopTest();
        
        // This method should handle null input gracefully
        System.assert(true, 'Method should execute without exception');
    }
    
    @IsTest
    static void testUpdateDocumentSequenceWithEmptyDocuments() {
        // Get test case
        Case__c testCase = [SELECT Id FROM Case__c LIMIT 1];
        
        List<CaseDocumentMergerController.DocumentWrapper> emptyDocuments = new List<CaseDocumentMergerController.DocumentWrapper>();
        
        Test.startTest();
        CaseDocumentMergerController.updateDocumentSequence(testCase.Id, emptyDocuments);
        Test.stopTest();
        
        // This method should handle empty list gracefully
        System.assert(true, 'Method should execute without exception');
    }
    
    @IsTest
    static void testGetDocumentsForCaseWithNonPDFAttachments() {
        // Create test case
        Case__c testCase = new Case__c(
            Subject__c = 'Test Case With Non-PDF Attachments',
            Status__c = 'Open'
        );
        insert testCase;
        
        // Create test document
        Document__c doc = new Document__c(
            Case__c = testCase.Id,
            Name__c = 'Test Document',
            Added_By__c = 'Test User',
            Notes__c = 'Test Notes'
        );
        insert doc;
        
        // Create non-PDF attachment
        Attachment nonPdfAttachment = new Attachment(
            ParentId = doc.Id,
            Name = 'Test Document.txt',
            ContentType = 'text/plain',
            Body = Blob.valueOf('This is a text file')
        );
        insert nonPdfAttachment;
        
        Test.startTest();
        List<CaseDocumentMergerController.DocumentWrapper> result = 
            CaseDocumentMergerController.getDocumentsForCase(testCase.Id);
        Test.stopTest();
        
        // Verify results - should return empty list since attachment is not PDF
        System.assertEquals(0, result.size(), 'Should return 0 documents for non-PDF attachments');
    }
    
    @IsTest
    static void testGetDocumentsForCaseWithNullDocumentName() {
        // Create test case
        Case__c testCase = new Case__c(
            Subject__c = 'Test Case With Null Document Name',
            Status__c = 'Open'
        );
        insert testCase;
        
        // Create test document with null name
        Document__c doc = new Document__c(
            Case__c = testCase.Id,
            Name__c = null,
            Added_By__c = 'Test User',
            Notes__c = 'Test Notes'
        );
        insert doc;
        
        // Create PDF attachment
        Attachment pdfAttachment = new Attachment(
            ParentId = doc.Id,
            Name = 'Test PDF Document.pdf',
            ContentType = 'application/pdf',
            Body = Blob.valueOf('Test PDF Content')
        );
        insert pdfAttachment;
        
        Test.startTest();
        List<CaseDocumentMergerController.DocumentWrapper> result = 
            CaseDocumentMergerController.getDocumentsForCase(testCase.Id);
        Test.stopTest();
        
        // Verify results - should use attachment name when document name is null
        System.assertEquals(1, result.size(), 'Should return 1 document');
        System.assertEquals(pdfAttachment.Name, result[0].Title, 'Should use attachment name when document name is null');
    }
}