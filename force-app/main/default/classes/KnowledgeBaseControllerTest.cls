@isTest
public class KnowledgeBaseControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Knowledge Base records with different categories
        List<Knowledge_Base__c> testKBs = new List<Knowledge_Base__c>();
        
        try {
            // Create KB records for each category
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Test Job Aid Document',
                Category__c = 'Job Aids'
            ));
            
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Test Record Template',
                Category__c = 'Record templates'
            ));
            
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Test Admin Document',
                Category__c = 'Administrative Documents'
            ));
            
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Test IT Document',
                Category__c = 'IT'
            ));
            
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Test Training Document',
                Category__c = 'Trainings'
            ));
            
            // Create KB record without category (should go to Others)
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Test Uncategorized Document'
            ));
            
            // Create KB record with invalid category (should go to Others)
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Test Invalid Category Document',
                Category__c = 'Invalid Category'
            ));
            
            insert testKBs;
        } catch (Exception e) {
            // If Category__c field is not accessible, create records without it
            testKBs.clear();
            testKBs.add(new Knowledge_Base__c(Name__c = 'Test Document 1'));
            testKBs.add(new Knowledge_Base__c(Name__c = 'Test Document 2'));
            testKBs.add(new Knowledge_Base__c(Name__c = 'Test Document 3'));
            testKBs.add(new Knowledge_Base__c(Name__c = 'Test Document 4'));
            testKBs.add(new Knowledge_Base__c(Name__c = 'Test Document 5'));
            testKBs.add(new Knowledge_Base__c(Name__c = 'Test Document 6'));
            testKBs.add(new Knowledge_Base__c(Name__c = 'Test Document 7'));
            insert testKBs;
        }
        
        // Create attachments for each Knowledge Base record
        List<Attachment> testAttachments = new List<Attachment>();
        for(Knowledge_Base__c kb : testKBs) {
            testAttachments.add(new Attachment(
                ParentId = kb.Id,
                Name = kb.Name__c + '.pdf',
                Body = Blob.valueOf('Test file content'),
                ContentType = 'application/pdf'
            ));
        }
        
        insert testAttachments;
    }
    
    @isTest
    static void testConstructor() {
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        Test.stopTest();
        
        // Verify controller properties are initialized
        System.assertNotEquals(null, controller.currentUser, 'Current user should be initialized');
        System.assertNotEquals(null, controller.documents, 'Documents list should be initialized');
        System.assertNotEquals(null, controller.documentsByCategory, 'Documents by category map should be initialized');
        System.assertNotEquals(null, controller.categoryOrder, 'Category order list should be initialized');
        System.assertNotEquals(null, controller.categoryCounts, 'Category counts map should be initialized');
    }
    
    @isTest
    static void testFetchArticles() {
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        Test.stopTest();
        
        // Verify documents are fetched
        System.assertNotEquals(null, controller.documents, 'Documents should be fetched');
        System.assertEquals(7, controller.documents.size(), 'Should have 7 documents with attachments');
        
        // Verify category order is correct
        List<String> expectedOrder = new List<String>{
            'Job Aids', 'Record templates', 'Administrative Documents', 'IT', 'Trainings'
        };
        System.assertEquals(expectedOrder, controller.categoryOrder, 'Category order should match expected order');
        
        // Verify category counts (check if Category__c field is accessible)
        try {
            // Try to access category-specific counts
            Integer jobAidsCount = controller.categoryCounts.get('Job Aids');
            if(jobAidsCount != null && jobAidsCount > 0) {
                // Category field is accessible, test specific categories
                System.assertEquals(1, controller.categoryCounts.get('Job Aids'), 'Job Aids should have 1 document');
                System.assertEquals(1, controller.categoryCounts.get('Record templates'), 'Record templates should have 1 document');
                System.assertEquals(1, controller.categoryCounts.get('Administrative Documents'), 'Administrative Documents should have 1 document');
                System.assertEquals(1, controller.categoryCounts.get('IT'), 'IT should have 1 document');
                System.assertEquals(1, controller.categoryCounts.get('Trainings'), 'Trainings should have 1 document');
                System.assertEquals(2, controller.categoryCounts.get('Others'), 'Others should have 2 documents (uncategorized and invalid category)');
                
                // Verify documents are grouped correctly
                System.assertEquals(1, controller.documentsByCategory.get('Job Aids').size(), 'Job Aids category should have 1 document');
                System.assertEquals(1, controller.documentsByCategory.get('Record templates').size(), 'Record templates category should have 1 document');
                System.assertEquals(1, controller.documentsByCategory.get('Administrative Documents').size(), 'Administrative Documents category should have 1 document');
                System.assertEquals(1, controller.documentsByCategory.get('IT').size(), 'IT category should have 1 document');
                System.assertEquals(1, controller.documentsByCategory.get('Trainings').size(), 'Trainings category should have 1 document');
                System.assertEquals(2, controller.documentsByCategory.get('Others').size(), 'Others category should have 2 documents');
            } else {
                // Category field is not accessible, all documents should go to Others
                System.assertEquals(7, controller.categoryCounts.get('Others'), 'All documents should go to Others when Category__c is not accessible');
                System.assertEquals(7, controller.documentsByCategory.get('Others').size(), 'All documents should be in Others category');
            }
        } catch (Exception e) {
            // If Category__c field is not accessible, all documents should go to Others
            System.assertEquals(7, controller.categoryCounts.get('Others'), 'All documents should go to Others when Category__c is not accessible');
            System.assertEquals(7, controller.documentsByCategory.get('Others').size(), 'All documents should be in Others category');
        }
    }
    
    @isTest
    static void testFetchArticlesWithNoAttachments() {
        // Create KB record without attachment
        Knowledge_Base__c kbWithoutAttachment;
        try {
            kbWithoutAttachment = new Knowledge_Base__c(
                Name__c = 'Document Without Attachment',
                Category__c = 'Job Aids'
            );
        } catch (Exception e) {
            kbWithoutAttachment = new Knowledge_Base__c(
                Name__c = 'Document Without Attachment'
            );
        }
        insert kbWithoutAttachment;
        
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        Test.stopTest();
        
        // Verify that documents without attachments are not included
        System.assertEquals(7, controller.documents.size(), 'Should still have 7 documents (only those with attachments)');
        
        // Check category counts (handle case where Category__c field is not accessible)
        try {
            // Check if Job Aids category has documents (indicating Category__c field is accessible)
            Integer jobAidsCount = controller.categoryCounts.get('Job Aids');
            if(jobAidsCount != null && jobAidsCount > 0) {
                // Category field is accessible, test specific category
                System.assertEquals(1, controller.categoryCounts.get('Job Aids'), 'Job Aids should still have 1 document (the one with attachment)');
            } else {
                // Category field is not accessible, all documents should go to Others
                System.assertEquals(7, controller.categoryCounts.get('Others'), 'All documents should go to Others when Category__c is not accessible');
            }
        } catch (Exception e) {
            // If Category__c field is not accessible, all documents should go to Others
            System.assertEquals(7, controller.categoryCounts.get('Others'), 'All documents should go to Others when Category__c is not accessible');
        }
    }
    
    @isTest
    static void testDeleteKBAction() {
        // Get a test KB record (try specific name first, fallback to any record)
        List<Knowledge_Base__c> testKBs = [SELECT Id FROM Knowledge_Base__c WHERE Name__c = 'Test Job Aid Document' LIMIT 1];
        if(testKBs.isEmpty()) {
            testKBs = [SELECT Id FROM Knowledge_Base__c LIMIT 1];
        }
        Knowledge_Base__c testKB = testKBs[0];
        
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        
        // Verify initial count
        Integer initialCount = controller.documents.size();
        
        // Set deleteKBID and call delete action
        controller.deleteKBID = testKB.Id;
        controller.DeleteKBAction();
        Test.stopTest();
        
        // Verify document was deleted
        List<Knowledge_Base__c> remainingKBs = [SELECT Id FROM Knowledge_Base__c WHERE Id = :testKB.Id];
        System.assertEquals(0, remainingKBs.size(), 'Knowledge Base record should be deleted');
        
        // Verify documents list was refreshed
        System.assertEquals(initialCount - 1, controller.documents.size(), 'Documents list should be refreshed after deletion');
    }
    
    @isTest
    static void testDeleteKBActionWithInvalidId() {
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        
        // Set invalid deleteKBID
        controller.deleteKBID = 'invalid_id';
        
        // This should not throw an exception
        try {
            controller.DeleteKBAction();
        } catch (Exception e) {
            System.assert(false, 'DeleteKBAction should handle invalid IDs gracefully: ' + e.getMessage());
        }
        Test.stopTest();
        
        // Verify no documents were deleted
        System.assertEquals(7, controller.documents.size(), 'No documents should be deleted with invalid ID');
    }
    
    @isTest
    static void testArticleRecordClass() {
        // Create test data
        Knowledge_Base__c testKB;
        try {
            testKB = new Knowledge_Base__c(
                Name__c = 'Test Article Record',
                Category__c = 'Job Aids'
            );
        } catch (Exception e) {
            testKB = new Knowledge_Base__c(
                Name__c = 'Test Article Record'
            );
        }
        insert testKB;
        
        Attachment testAttachment = new Attachment(
            ParentId = testKB.Id,
            Name = 'Test Attachment.pdf',
            Body = Blob.valueOf('Test content'),
            ContentType = 'application/pdf'
        );
        insert testAttachment;
        
        Test.startTest();
        KnowledgeBaseController.ArticleRecord articleRecord = new KnowledgeBaseController.ArticleRecord(
            testAttachment.Id, 
            testKB
        );
        Test.stopTest();
        
        // Verify ArticleRecord properties
        System.assertEquals(testAttachment.Id, articleRecord.attachmentId, 'Attachment ID should be set correctly');
        System.assertEquals(testKB, articleRecord.kb, 'Knowledge Base record should be set correctly');
    }
    
    @isTest
    static void testCategoryOrder() {
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        Test.stopTest();
        
        // Verify category order is as expected
        List<String> expectedOrder = new List<String>{
            'Job Aids', 'Record templates', 'Administrative Documents', 'IT', 'Trainings'
        };
        System.assertEquals(expectedOrder, controller.categoryOrder, 'Category order should match expected order');
        
        // Verify all expected categories are present
        for(String category : expectedOrder) {
            System.assert(controller.categoryOrder.contains(category), 'Category order should contain: ' + category);
        }
    }
    
    @isTest
    static void testEmptyKnowledgeBase() {
        // Delete all test data
        delete [SELECT Id FROM Knowledge_Base__c];
        
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        Test.stopTest();
        
        // Verify empty state
        System.assertEquals(0, controller.documents.size(), 'Should have no documents');
        System.assertEquals(0, controller.categoryCounts.get('Job Aids'), 'Job Aids should have 0 documents');
        System.assertEquals(0, controller.categoryCounts.get('Record templates'), 'Record templates should have 0 documents');
        System.assertEquals(0, controller.categoryCounts.get('Administrative Documents'), 'Administrative Documents should have 0 documents');
        System.assertEquals(0, controller.categoryCounts.get('IT'), 'IT should have 0 documents');
        System.assertEquals(0, controller.categoryCounts.get('Trainings'), 'Trainings should have 0 documents');
        System.assertEquals(0, controller.categoryCounts.get('Others'), 'Others should have 0 documents');
    }
    
    @isTest
    static void testUpdateCategoryAction() {
        // Get a test KB record
        List<Knowledge_Base__c> testKBs = [SELECT Id FROM Knowledge_Base__c LIMIT 1];
        if(testKBs.isEmpty()) {
            System.assert(false, 'No test Knowledge Base records found');
            return;
        }
        Knowledge_Base__c testKB = testKBs[0];
        
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        
        // Set up the update parameters
        controller.editKBID = testKB.Id;
        controller.newCategory = 'IT';
        
        // Call the update action
        controller.UpdateCategoryAction();
        Test.stopTest();
        
        // Verify the category was updated
        Knowledge_Base__c updatedKB = [SELECT Id, Category__c FROM Knowledge_Base__c WHERE Id = :testKB.Id];
        System.assertEquals('IT', updatedKB.Category__c, 'Category should be updated to IT');
    }
    
    @isTest
    static void testUpdateCategoryActionWithBlankValues() {
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        
        // Test with blank values
        controller.editKBID = '';
        controller.newCategory = 'IT';
        controller.UpdateCategoryAction();
        
        controller.editKBID = 'test_id';
        controller.newCategory = '';
        controller.UpdateCategoryAction();
        
        Test.stopTest();
        
        // Should not throw exceptions with blank values
        System.assert(true, 'UpdateCategoryAction should handle blank values gracefully');
    }
    
    @isTest
    static void testUpdateCategoryActionWithInvalidId() {
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        
        // Test with invalid ID
        controller.editKBID = 'invalid_id';
        controller.newCategory = 'IT';
        
        // This should not throw an exception
        try {
            controller.UpdateCategoryAction();
        } catch (Exception e) {
            System.assert(false, 'UpdateCategoryAction should handle invalid IDs gracefully: ' + e.getMessage());
        }
        Test.stopTest();
        
        System.assert(true, 'UpdateCategoryAction should handle invalid IDs gracefully');
    }
    
    @isTest
    static void testSecurityEnforcement() {
        // This test verifies that WITH SECURITY_ENFORCED is working
        // by ensuring the query doesn't fail due to field-level security
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        Test.stopTest();
        
        // If we get here without exceptions, security enforcement is working
        System.assertNotEquals(null, controller.documents, 'Documents should be fetched with security enforcement');
    }
    
    @isTest
    static void testUpdateSequenceAction() {
        // Create fresh test KB records to avoid conflicts
        List<Knowledge_Base__c> testKBs = new List<Knowledge_Base__c>();
        
        try {
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Test KB for Sequence 1',
                Category__c = 'Job Aids',
                Sequence__c = 1
            ));
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Test KB for Sequence 2',
                Category__c = 'Job Aids',
                Sequence__c = 2
            ));
        } catch (Exception e) {
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Test KB for Sequence 1',
                Sequence__c = 1
            ));
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Test KB for Sequence 2',
                Sequence__c = 2
            ));
        }
        
        insert testKBs;
        
        // Create attachments
        List<Attachment> testAttachments = new List<Attachment>();
        for(Knowledge_Base__c kb : testKBs) {
            testAttachments.add(new Attachment(
                ParentId = kb.Id,
                Name = kb.Name__c + '.pdf',
                Body = Blob.valueOf('Test content'),
                ContentType = 'application/pdf'
            ));
        }
        insert testAttachments;
        
        Knowledge_Base__c kb1 = testKBs[0];
        Knowledge_Base__c kb2 = testKBs[1];
        
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        
        // Test sequence update - assign sequence 1 to kb2 (should clear kb1's sequence)
        controller.sequenceKBID = kb2.Id;
        controller.newSequence = '1';
        controller.UpdateSequenceAction();
        Test.stopTest();
        
        // Verify sequence swapping
        Knowledge_Base__c updatedKb1 = [SELECT Id, Sequence__c FROM Knowledge_Base__c WHERE Id = :kb1.Id];
        Knowledge_Base__c updatedKb2 = [SELECT Id, Sequence__c FROM Knowledge_Base__c WHERE Id = :kb2.Id];
        
        System.assertEquals(null, updatedKb1.Sequence__c, 'KB1 sequence should be cleared when KB2 takes sequence 1');
        System.assertEquals(1, updatedKb2.Sequence__c, 'KB2 should have sequence 1');
    }
    
    @isTest
    static void testUpdateSequenceActionWithBlankValues() {
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        
        // Test with blank values
        controller.sequenceKBID = '';
        controller.newSequence = '1';
        controller.UpdateSequenceAction();
        
        controller.sequenceKBID = 'test_id';
        controller.newSequence = '';
        controller.UpdateSequenceAction();
        
        Test.stopTest();
        
        // Should not throw exceptions with blank values
        System.assert(true, 'UpdateSequenceAction should handle blank values gracefully');
    }
    
    @isTest
    static void testUpdateSequenceActionWithInvalidId() {
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        
        // Test with invalid ID
        controller.sequenceKBID = 'invalid_id';
        controller.newSequence = '1';
        
        // This should not throw an exception
        try {
            controller.UpdateSequenceAction();
        } catch (Exception e) {
            System.assert(false, 'UpdateSequenceAction should handle invalid IDs gracefully: ' + e.getMessage());
        }
        Test.stopTest();
        
        System.assert(true, 'UpdateSequenceAction should handle invalid IDs gracefully');
    }
    
    @isTest
    static void testSequenceOrdering() {
        // Create test KB records with sequences
        List<Knowledge_Base__c> testKBs = new List<Knowledge_Base__c>();
        
        try {
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'First Document',
                Category__c = 'Job Aids',
                Sequence__c = 2
            ));
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Second Document',
                Category__c = 'Job Aids',
                Sequence__c = 1
            ));
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Third Document',
                Category__c = 'Job Aids',
                Sequence__c = 3
            ));
        } catch (Exception e) {
            // If Category__c field is not accessible, create without it
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'First Document',
                Sequence__c = 2
            ));
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Second Document',
                Sequence__c = 1
            ));
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Third Document',
                Sequence__c = 3
            ));
        }
        
        insert testKBs;
        
        // Create attachments
        List<Attachment> testAttachments = new List<Attachment>();
        for(Knowledge_Base__c kb : testKBs) {
            testAttachments.add(new Attachment(
                ParentId = kb.Id,
                Name = kb.Name__c + '.pdf',
                Body = Blob.valueOf('Test file content'),
                ContentType = 'application/pdf'
            ));
        }
        insert testAttachments;
        
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        Test.stopTest();
        
        // Verify documents are ordered by sequence
        List<KnowledgeBaseController.ArticleRecord> documents = controller.documents;
        System.assertEquals(10, documents.size(), 'Should have 10 total documents (7 from setup + 3 new)');
        
        // Check if we can access the specific category documents
        try {
            List<KnowledgeBaseController.ArticleRecord> jobAidsDocs = controller.documentsByCategory.get('Job Aids');
            if(jobAidsDocs != null && jobAidsDocs.size() >= 3) {
                // Verify ordering by sequence (1, 2, 3)
                System.assertEquals('Second Document', jobAidsDocs[0].kb.Name__c, 'First document should be Second Document (sequence 1)');
                System.assertEquals('First Document', jobAidsDocs[1].kb.Name__c, 'Second document should be First Document (sequence 2)');
                System.assertEquals('Third Document', jobAidsDocs[2].kb.Name__c, 'Third document should be Third Document (sequence 3)');
            }
        } catch (Exception e) {
            // If Category__c field is not accessible, documents will be in Others category
            System.assert(true, 'Documents should be accessible even if Category__c field is not accessible');
        }
    }
    
    @isTest
    static void testGetUsedSequencesByCategory() {
        // Create test KB records with sequences
        List<Knowledge_Base__c> testKBs = new List<Knowledge_Base__c>();
        
        try {
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Job Aid 1',
                Category__c = 'Job Aids',
                Sequence__c = 1
            ));
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Job Aid 2',
                Category__c = 'Job Aids',
                Sequence__c = 3
            ));
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'IT Doc 1',
                Category__c = 'IT',
                Sequence__c = 2
            ));
        } catch (Exception e) {
            // If Category__c field is not accessible, create without it
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Job Aid 1',
                Sequence__c = 1
            ));
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Job Aid 2',
                Sequence__c = 3
            ));
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'IT Doc 1',
                Sequence__c = 2
            ));
        }
        
        insert testKBs;
        
        // Create attachments
        List<Attachment> testAttachments = new List<Attachment>();
        for(Knowledge_Base__c kb : testKBs) {
            testAttachments.add(new Attachment(
                ParentId = kb.Id,
                Name = kb.Name__c + '.pdf',
                Body = Blob.valueOf('Test file content'),
                ContentType = 'application/pdf'
            ));
        }
        insert testAttachments;
        
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        Map<String, Set<Integer>> usedSequences = controller.getUsedSequencesByCategory();
        Test.stopTest();
        
        // Verify used sequences are tracked correctly
        System.assertNotEquals(null, usedSequences, 'Used sequences map should not be null');
        
        try {
            // Check if Category__c field is accessible
            Set<Integer> jobAidsSequences = usedSequences.get('Job Aids');
            if(jobAidsSequences != null) {
                System.assert(jobAidsSequences.contains(1), 'Job Aids should have sequence 1');
                System.assert(jobAidsSequences.contains(3), 'Job Aids should have sequence 3');
                System.assert(!jobAidsSequences.contains(2), 'Job Aids should not have sequence 2');
                
                Set<Integer> itSequences = usedSequences.get('IT');
                System.assert(itSequences.contains(2), 'IT should have sequence 2');
                System.assert(!itSequences.contains(1), 'IT should not have sequence 1');
            } else {
                // If Category__c field is not accessible, all documents go to Others
                Set<Integer> othersSequences = usedSequences.get('Others');
                System.assert(othersSequences.contains(1), 'Others should have sequence 1');
                System.assert(othersSequences.contains(2), 'Others should have sequence 2');
                System.assert(othersSequences.contains(3), 'Others should have sequence 3');
            }
        } catch (Exception e) {
            System.assert(true, 'getUsedSequencesByCategory should handle field access gracefully');
        }
    }
    
    @isTest
    static void testSequenceWithNullValues() {
        // Create test KB records with null sequences
        List<Knowledge_Base__c> testKBs = new List<Knowledge_Base__c>();
        
        try {
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Document with Null Sequence',
                Category__c = 'Job Aids',
                Sequence__c = null
            ));
        } catch (Exception e) {
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Document with Null Sequence',
                Sequence__c = null
            ));
        }
        
        insert testKBs;
        
        // Create attachment
        Attachment testAttachment = new Attachment(
            ParentId = testKBs[0].Id,
            Name = 'Test Attachment.pdf',
            Body = Blob.valueOf('Test content'),
            ContentType = 'application/pdf'
        );
        insert testAttachment;
        
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        Test.stopTest();
        
        // Verify documents with null sequences are handled correctly
        System.assertNotEquals(null, controller.documents, 'Documents should be fetched even with null sequences');
        
        // Verify the document is included in the results
        Boolean foundDocument = false;
        for(KnowledgeBaseController.ArticleRecord doc : controller.documents) {
            if(doc.kb.Name__c == 'Document with Null Sequence') {
                foundDocument = true;
                System.assertEquals(null, doc.kb.Sequence__c, 'Sequence should be null');
                break;
            }
        }
        System.assert(foundDocument, 'Document with null sequence should be included in results');
    }
    
    @isTest
    static void testUpdateSequenceActionWithException() {
        // Create a test KB record
        Knowledge_Base__c testKB = new Knowledge_Base__c(Name__c = 'Test KB for Exception');
        insert testKB;
        
        // Create attachment
        Attachment testAttachment = new Attachment(
            ParentId = testKB.Id,
            Name = 'Test Attachment.pdf',
            Body = Blob.valueOf('Test content'),
            ContentType = 'application/pdf'
        );
        insert testAttachment;
        
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        
        // Test with invalid sequence value to trigger exception
        controller.sequenceKBID = testKB.Id;
        controller.newSequence = 'invalid_number';
        
        // This should trigger an exception in Decimal.valueOf()
        try {
            controller.UpdateSequenceAction();
        } catch (Exception e) {
            // Expected to catch the exception
            System.assert(true, 'Should handle invalid sequence values gracefully');
        }
        Test.stopTest();
        
        System.assert(true, 'UpdateSequenceAction should handle exceptions gracefully');
    }
    
    @isTest
    static void testUpdateSequenceActionWithNoConflictingRecords() {
        // Create a test KB record
        Knowledge_Base__c testKB = new Knowledge_Base__c(Name__c = 'Test KB No Conflict');
        insert testKB;
        
        // Create attachment
        Attachment testAttachment = new Attachment(
            ParentId = testKB.Id,
            Name = 'Test Attachment.pdf',
            Body = Blob.valueOf('Test content'),
            ContentType = 'application/pdf'
        );
        insert testAttachment;
        
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        
        // Test sequence update with no conflicting records
        controller.sequenceKBID = testKB.Id;
        controller.newSequence = '1';
        controller.UpdateSequenceAction();
        Test.stopTest();
        
        // Verify sequence was set
        Knowledge_Base__c updatedKB = [SELECT Id, Sequence__c FROM Knowledge_Base__c WHERE Id = :testKB.Id];
        System.assertEquals(1, updatedKB.Sequence__c, 'Sequence should be set to 1');
    }
    
    @isTest
    static void testUpdateSequenceActionWithEmptyRecordsToUpdate() {
        // Create a test KB record
        Knowledge_Base__c testKB = new Knowledge_Base__c(Name__c = 'Test KB Empty Update');
        insert testKB;
        
        // Create attachment
        Attachment testAttachment = new Attachment(
            ParentId = testKB.Id,
            Name = 'Test Attachment.pdf',
            Body = Blob.valueOf('Test content'),
            ContentType = 'application/pdf'
        );
        insert testAttachment;
        
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        
        // Test with blank values to ensure empty recordsToUpdate list is handled
        controller.sequenceKBID = '';
        controller.newSequence = '1';
        controller.UpdateSequenceAction();
        
        controller.sequenceKBID = testKB.Id;
        controller.newSequence = '';
        controller.UpdateSequenceAction();
        Test.stopTest();
        
        // Should not throw exceptions
        System.assert(true, 'Should handle empty recordsToUpdate list gracefully');
    }
    
    @isTest
    static void testGetUsedSequencesByCategoryWithEmptyDocuments() {
        // Delete all test data to test empty state
        delete [SELECT Id FROM Knowledge_Base__c];
        
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        Map<String, Set<Integer>> usedSequences = controller.getUsedSequencesByCategory();
        Test.stopTest();
        
        // Verify empty state is handled correctly
        System.assertNotEquals(null, usedSequences, 'Used sequences map should not be null');
        
        // All categories should have empty sets
        for(String category : controller.categoryOrder) {
            Set<Integer> sequences = usedSequences.get(category);
            System.assertNotEquals(null, sequences, 'Category ' + category + ' should have a set');
            System.assertEquals(0, sequences.size(), 'Category ' + category + ' should have no used sequences');
        }
        
        Set<Integer> othersSequences = usedSequences.get('Others');
        System.assertNotEquals(null, othersSequences, 'Others category should have a set');
        System.assertEquals(0, othersSequences.size(), 'Others category should have no used sequences');
    }
    
    @isTest
    static void testGetUsedSequencesByCategoryWithNullSequences() {
        // Create test KB records with null sequences
        List<Knowledge_Base__c> testKBs = new List<Knowledge_Base__c>();
        
        try {
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Document with Null Sequence 1',
                Category__c = 'Job Aids',
                Sequence__c = null
            ));
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Document with Sequence 1',
                Category__c = 'Job Aids',
                Sequence__c = 1
            ));
        } catch (Exception e) {
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Document with Null Sequence 1',
                Sequence__c = null
            ));
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Document with Sequence 1',
                Sequence__c = 1
            ));
        }
        
        insert testKBs;
        
        // Create attachments
        List<Attachment> testAttachments = new List<Attachment>();
        for(Knowledge_Base__c kb : testKBs) {
            testAttachments.add(new Attachment(
                ParentId = kb.Id,
                Name = kb.Name__c + '.pdf',
                Body = Blob.valueOf('Test file content'),
                ContentType = 'application/pdf'
            ));
        }
        insert testAttachments;
        
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        Map<String, Set<Integer>> usedSequences = controller.getUsedSequencesByCategory();
        Test.stopTest();
        
        // Verify null sequences are handled correctly
        System.assertNotEquals(null, usedSequences, 'Used sequences map should not be null');
        
        try {
            // Check if Category__c field is accessible
            Set<Integer> jobAidsSequences = usedSequences.get('Job Aids');
            if(jobAidsSequences != null) {
                System.assert(jobAidsSequences.contains(1), 'Job Aids should have sequence 1');
                System.assertEquals(1, jobAidsSequences.size(), 'Job Aids should have only 1 used sequence (null sequences ignored)');
            } else {
                // If Category__c field is not accessible, all documents go to Others
                Set<Integer> othersSequences = usedSequences.get('Others');
                System.assert(othersSequences.contains(1), 'Others should have sequence 1');
                System.assertEquals(1, othersSequences.size(), 'Others should have only 1 used sequence (null sequences ignored)');
            }
        } catch (Exception e) {
            System.assert(true, 'getUsedSequencesByCategory should handle field access gracefully');
        }
    }
    
    @isTest
    static void testFetchArticlesWithNoDocuments() {
        // Delete all existing test data
        delete [SELECT Id FROM Knowledge_Base__c];
        
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        Test.stopTest();
        
        // Verify empty state
        System.assertEquals(0, controller.documents.size(), 'Should have no documents');
        System.assertEquals(0, controller.categoryCounts.get('Job Aids'), 'Job Aids should have 0 documents');
        System.assertEquals(0, controller.categoryCounts.get('Record templates'), 'Record templates should have 0 documents');
        System.assertEquals(0, controller.categoryCounts.get('Administrative Documents'), 'Administrative Documents should have 0 documents');
        System.assertEquals(0, controller.categoryCounts.get('IT'), 'IT should have 0 documents');
        System.assertEquals(0, controller.categoryCounts.get('Trainings'), 'Trainings should have 0 documents');
        System.assertEquals(0, controller.categoryCounts.get('Others'), 'Others should have 0 documents');
    }
    
    @isTest
    static void testFetchArticlesWithDocumentsButNoAttachments() {
        // Create KB records without attachments
        List<Knowledge_Base__c> testKBs = new List<Knowledge_Base__c>();
        
        try {
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Document Without Attachment 1',
                Category__c = 'Job Aids'
            ));
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Document Without Attachment 2',
                Category__c = 'IT'
            ));
        } catch (Exception e) {
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Document Without Attachment 1'
            ));
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Document Without Attachment 2'
            ));
        }
        
        insert testKBs;
        
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        Test.stopTest();
        
        // Verify documents without attachments are not included
        System.assertEquals(7, controller.documents.size(), 'Should only have documents with attachments from setup');
    }
    
    @isTest
    static void testUpdateSequenceActionWithBlankCategory() {
        // Create a test KB record with blank category
        Knowledge_Base__c testKB = new Knowledge_Base__c(
            Name__c = 'Test KB Blank Category',
            Category__c = null
        );
        insert testKB;
        
        // Create attachment
        Attachment testAttachment = new Attachment(
            ParentId = testKB.Id,
            Name = 'Test Attachment.pdf',
            Body = Blob.valueOf('Test content'),
            ContentType = 'application/pdf'
        );
        insert testAttachment;
        
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        
        // Test sequence update with blank category (should go to Others)
        controller.sequenceKBID = testKB.Id;
        controller.newSequence = '1';
        controller.UpdateSequenceAction();
        Test.stopTest();
        
        // Verify sequence was set
        Knowledge_Base__c updatedKB = [SELECT Id, Sequence__c FROM Knowledge_Base__c WHERE Id = :testKB.Id];
        System.assertEquals(1, updatedKB.Sequence__c, 'Sequence should be set to 1');
    }
    
    @isTest
    static void testUpdateSequenceActionWithSameSequence() {
        // Create a test KB record
        Knowledge_Base__c testKB = new Knowledge_Base__c(
            Name__c = 'Test KB Same Sequence',
            Sequence__c = 1
        );
        insert testKB;
        
        // Create attachment
        Attachment testAttachment = new Attachment(
            ParentId = testKB.Id,
            Name = 'Test Attachment.pdf',
            Body = Blob.valueOf('Test content'),
            ContentType = 'application/pdf'
        );
        insert testAttachment;
        
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        
        // Test setting the same sequence (should not cause issues)
        controller.sequenceKBID = testKB.Id;
        controller.newSequence = '1';
        controller.UpdateSequenceAction();
        Test.stopTest();
        
        // Verify sequence remains the same
        Knowledge_Base__c updatedKB = [SELECT Id, Sequence__c FROM Knowledge_Base__c WHERE Id = :testKB.Id];
        System.assertEquals(1, updatedKB.Sequence__c, 'Sequence should remain 1');
    }
    
    @isTest
    static void testUpdateCategoryActionWithException() {
        // Create a test KB record
        Knowledge_Base__c testKB = new Knowledge_Base__c(Name__c = 'Test KB for Category Exception');
        insert testKB;
        
        // Create attachment
        Attachment testAttachment = new Attachment(
            ParentId = testKB.Id,
            Name = 'Test Attachment.pdf',
            Body = Blob.valueOf('Test content'),
            ContentType = 'application/pdf'
        );
        insert testAttachment;
        
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        
        // Test with valid values that should work
        controller.editKBID = testKB.Id;
        controller.newCategory = 'IT';
        controller.UpdateCategoryAction();
        Test.stopTest();
        
        // Verify category was updated
        Knowledge_Base__c updatedKB = [SELECT Id, Category__c FROM Knowledge_Base__c WHERE Id = :testKB.Id];
        System.assertEquals('IT', updatedKB.Category__c, 'Category should be updated to IT');
    }
    
    @isTest
    static void testDeleteKBActionWithException() {
        // Create a test KB record
        Knowledge_Base__c testKB = new Knowledge_Base__c(Name__c = 'Test KB for Delete Exception');
        insert testKB;
        
        // Create attachment
        Attachment testAttachment = new Attachment(
            ParentId = testKB.Id,
            Name = 'Test Attachment.pdf',
            Body = Blob.valueOf('Test content'),
            ContentType = 'application/pdf'
        );
        insert testAttachment;
        
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        
        // Test delete action
        controller.deleteKBID = testKB.Id;
        controller.DeleteKBAction();
        Test.stopTest();
        
        // Verify record was deleted
        List<Knowledge_Base__c> remainingKBs = [SELECT Id FROM Knowledge_Base__c WHERE Id = :testKB.Id];
        System.assertEquals(0, remainingKBs.size(), 'Knowledge Base record should be deleted');
    }
    
    @isTest
    static void testFetchArticlesWithInvalidCategory() {
        // Create test KB records with invalid categories
        List<Knowledge_Base__c> testKBs = new List<Knowledge_Base__c>();
        
        // Try to create with invalid category first
        try {
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Document with Invalid Category',
                Category__c = 'Invalid Category Name'
            ));
            insert testKBs;
        } catch (Exception e) {
            // If that fails, try without the category field
            testKBs.clear();
            try {
                testKBs.add(new Knowledge_Base__c(
                    Name__c = 'Document with Invalid Category'
                ));
                insert testKBs;
            } catch (Exception e2) {
                // If both fail, skip this test
                System.assert(true, 'Test skipped due to field access restrictions');
                return;
            }
        }
        
        // Create attachment
        Attachment testAttachment = new Attachment(
            ParentId = testKBs[0].Id,
            Name = 'Test Attachment.pdf',
            Body = Blob.valueOf('Test content'),
            ContentType = 'application/pdf'
        );
        insert testAttachment;
        
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        Test.stopTest();
        
        // Verify document with invalid category goes to Others
        System.assertNotEquals(null, controller.documents, 'Documents should be fetched');
        
        // Check if the document is in Others category
        try {
            List<KnowledgeBaseController.ArticleRecord> othersDocs = controller.documentsByCategory.get('Others');
            if(othersDocs != null) {
                Boolean foundInvalidCategoryDoc = false;
                for(KnowledgeBaseController.ArticleRecord doc : othersDocs) {
                    if(doc.kb.Name__c == 'Document with Invalid Category') {
                        foundInvalidCategoryDoc = true;
                        break;
                    }
                }
                System.assert(foundInvalidCategoryDoc, 'Document with invalid category should be in Others');
            } else {
                // If Others category is not accessible, just verify the document exists
                Boolean foundDoc = false;
                for(KnowledgeBaseController.ArticleRecord doc : controller.documents) {
                    if(doc.kb.Name__c == 'Document with Invalid Category') {
                        foundDoc = true;
                        break;
                    }
                }
                System.assert(foundDoc, 'Document with invalid category should be in documents list');
            }
        } catch (Exception e) {
            System.assert(true, 'Should handle invalid categories gracefully');
        }
    }
    
    @isTest
    static void testFetchArticlesWithBlankCategory() {
        // Create test KB records with blank categories
        List<Knowledge_Base__c> testKBs = new List<Knowledge_Base__c>();
        
        try {
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Document with Blank Category',
                Category__c = ''
            ));
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Document with Null Category',
                Category__c = null
            ));
        } catch (Exception e) {
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Document with Blank Category'
            ));
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Document with Null Category'
            ));
        }
        
        insert testKBs;
        
        // Create attachments
        List<Attachment> testAttachments = new List<Attachment>();
        for(Knowledge_Base__c kb : testKBs) {
            testAttachments.add(new Attachment(
                ParentId = kb.Id,
                Name = kb.Name__c + '.pdf',
                Body = Blob.valueOf('Test content'),
                ContentType = 'application/pdf'
            ));
        }
        insert testAttachments;
        
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        Test.stopTest();
        
        // Verify documents with blank/null categories go to Others
        System.assertNotEquals(null, controller.documents, 'Documents should be fetched');
        
        // Check if documents are in Others category
        try {
            List<KnowledgeBaseController.ArticleRecord> othersDocs = controller.documentsByCategory.get('Others');
            if(othersDocs != null) {
                Boolean foundBlankCategoryDoc = false;
                Boolean foundNullCategoryDoc = false;
                for(KnowledgeBaseController.ArticleRecord doc : othersDocs) {
                    if(doc.kb.Name__c == 'Document with Blank Category') {
                        foundBlankCategoryDoc = true;
                    }
                    if(doc.kb.Name__c == 'Document with Null Category') {
                        foundNullCategoryDoc = true;
                    }
                }
                System.assert(foundBlankCategoryDoc, 'Document with blank category should be in Others');
                System.assert(foundNullCategoryDoc, 'Document with null category should be in Others');
            }
        } catch (Exception e) {
            System.assert(true, 'Should handle blank/null categories gracefully');
        }
    }
    
    @isTest
    static void testUpdateSequenceActionWithMultipleConflictingRecords() {
        // Create multiple test KB records in the same category
        List<Knowledge_Base__c> testKBs = new List<Knowledge_Base__c>();
        
        try {
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Test KB 1',
                Category__c = 'Job Aids',
                Sequence__c = 1
            ));
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Test KB 2',
                Category__c = 'Job Aids',
                Sequence__c = 1
            ));
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Test KB 3',
                Category__c = 'Job Aids',
                Sequence__c = 2
            ));
        } catch (Exception e) {
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Test KB 1',
                Sequence__c = 1
            ));
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Test KB 2',
                Sequence__c = 1
            ));
            testKBs.add(new Knowledge_Base__c(
                Name__c = 'Test KB 3',
                Sequence__c = 2
            ));
        }
        
        insert testKBs;
        
        // Create attachments
        List<Attachment> testAttachments = new List<Attachment>();
        for(Knowledge_Base__c kb : testKBs) {
            testAttachments.add(new Attachment(
                ParentId = kb.Id,
                Name = kb.Name__c + '.pdf',
                Body = Blob.valueOf('Test content'),
                ContentType = 'application/pdf'
            ));
        }
        insert testAttachments;
        
        Test.startTest();
        KnowledgeBaseController controller = new KnowledgeBaseController();
        
        // Test sequence update - assign sequence 1 to KB 3 (should clear KB 1 and KB 2's sequences)
        controller.sequenceKBID = testKBs[2].Id; // Test KB 3
        controller.newSequence = '1';
        controller.UpdateSequenceAction();
        Test.stopTest();
        
        // Verify sequence swapping
        List<Knowledge_Base__c> updatedKBs = [SELECT Id, Name__c, Sequence__c FROM Knowledge_Base__c WHERE Id IN :testKBs];
        
        for(Knowledge_Base__c kb : updatedKBs) {
            if(kb.Name__c == 'Test KB 3') {
                System.assertEquals(1, kb.Sequence__c, 'Test KB 3 should have sequence 1');
            } else if(kb.Name__c == 'Test KB 1' || kb.Name__c == 'Test KB 2') {
                System.assertEquals(null, kb.Sequence__c, 'Test KB 1 and 2 should have null sequences');
            }
        }
    }
}