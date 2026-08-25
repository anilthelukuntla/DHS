/**
 * @description Manages categorized DHS knowledge-base articles and their attachments.
 */
@SuppressWarnings('PMD.AvoidDeeplyNestedIfStmts,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.NcssCount')
public with sharing class DHSKnowledgeBaseController{
    /** @description Provides this DHS API member. */
    public User currentUser {get;set;}
    /** @description Provides this DHS API member. */
    public List< ArticleRecord > documents{get;set;}
    /** @description Provides this DHS API member. */
    public Map<String, List<ArticleRecord>> documentsByCategory{get;set;}
    /** @description Provides this DHS API member. */
    public List<String> categoryOrder{get;set;}
    /** @description Provides this DHS API member. */
    public Map<String, Integer> categoryCounts{get;set;}
    
    /** @description Provides this DHS API member. */
    public DHSKnowledgeBaseController(){
        currentUser = [Select Id, User_Type__c FROM User where Id=:userinfo.getUserId()];
        fetchArticles();
    }
  
    /** @description Provides this DHS API member. */
    public void fetchArticles(){
        documents = new list<ArticleRecord>();
        documentsByCategory = new Map<String, List<ArticleRecord>>();
        categoryCounts = new Map<String, Integer>();
        categoryOrder = new List<String>{'Job Aids', 'Record templates', 'Administrative Documents', 'IT', 'Trainings'};
        
        // Initialize category lists
        for(String category : categoryOrder){
            documentsByCategory.put(category, new List<ArticleRecord>());
            categoryCounts.put(category, 0);
        }
        documentsByCategory.put('Others', new List<ArticleRecord>());
        categoryCounts.put('Others', 0);
        
        List<string> articleFields = new List<string>();
        articleFields = DHSApexUtil.FetchFields('DHS_Knowledge_Base__c');
        
        String query = 'Select '+string.join(articleFields, ',') + ' From DHS_Knowledge_Base__c';
        query = query + ' ORDER BY Category__c, Sequence__c NULLS LAST, Createddate DESC';
        List<DHS_Knowledge_Base__c> temp = database.query(query, AccessLevel.USER_MODE);
       
        List<string> documentIds = new List<string>();
        for(DHS_Knowledge_Base__c doc: temp){
            documentIds.add(doc.id);
        }
        List<attachment> attachments = new List<attachment>();
        attachments = [Select id, parentid from attachment where parentid in: documentIds WITH USER_MODE];
        Map<String,String> documentNattachmentMap = new Map<String,String>();
        for(attachment att: attachments){
            documentNattachmentMap.put(att.parentid, att.id);    
        }
        
        for(DHS_Knowledge_Base__c doc: temp){
            if(documentNattachmentMap.get(doc.id) != Null){
                ArticleRecord articleRecord = new ArticleRecord(documentNattachmentMap.get(doc.id),doc);
                documents.add(articleRecord);
                
                // Group by category with null safety
                String category = getSelectedStringValue(
                    doc,
                    'Category__c'
                );
                
                if(String.isBlank(category) || !categoryOrder.contains(category)){
                    // Add to Others category
                    if(documentsByCategory.containsKey('Others')){
                        documentsByCategory.get('Others').add(articleRecord);
                        categoryCounts.put('Others', categoryCounts.get('Others') + 1);
                    }
                } else {
                    // Add to specific category
                    if(documentsByCategory.containsKey(category)){
                        documentsByCategory.get(category).add(articleRecord);
                        categoryCounts.put(category, categoryCounts.get(category) + 1);
                    }
                }
            }
        } 
    }
    
    /** @description Provides this DHS API member. */
    public class ArticleRecord{
        /** @description Provides this DHS API member. */
        public DHS_Knowledge_Base__c kb{get;set;}
        /** @description Provides this DHS API member. */
        public string attachmentId {get;set;}
        /**
         * @description Provides this DHS API member.
         * @param attachmentId Method parameter.
         * @param kb Method parameter.
         */
        public ArticleRecord(string attachmentId, DHS_Knowledge_Base__c kb){
           this.attachmentId = attachmentId;
           this.kb = kb;
        }
    }
    
   /** @description Provides this DHS API member. */
   public string deleteKBID{get;set;}
   /** @description Provides this DHS API member. */
   public string editKBID{get;set;}
   /** @description Provides this DHS API member. */
   public string newCategory{get;set;}
   /** @description Provides this DHS API member. */
   public string sequenceKBID{get;set;}
   /** @description Provides this DHS API member. */
   public string newSequence{get;set;}
    
    /** @description Provides this DHS API member. */
    public void deleteKBAction(){
        list<DHS_Knowledge_Base__c> delkb = [select id from DHS_Knowledge_Base__c where id=:deleteKBID WITH USER_MODE];
        database.delete(delkb,false,AccessLevel.USER_MODE);
        fetchArticles();
    }
    
    /** @description Provides this DHS API member. */
    public void updateCategoryAction(){
        try {
            if(String.isNotBlank(editKBID) && String.isNotBlank(newCategory)) {
                DHS_Knowledge_Base__c kbToUpdate = new DHS_Knowledge_Base__c(
                    Id = editKBID,
                    Category__c = newCategory
                );
                Database.update(kbToUpdate, AccessLevel.USER_MODE);
                
                // Refresh the articles to show updated categories
                fetchArticles();
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to update the article category.'));
        }
    }
    
    /** @description Provides this DHS API member. */
    public void updateSequenceAction(){
        try {
            if(String.isNotBlank(sequenceKBID) && String.isNotBlank(newSequence)) {
                // First, get the current record to find its category
                DHS_Knowledge_Base__c currentRecord = [SELECT Id, Category__c, Sequence__c FROM DHS_Knowledge_Base__c WHERE Id = :sequenceKBID WITH USER_MODE LIMIT 1];
                
                // Find any other record in the same category that has the new sequence number
                String category = String.isBlank(currentRecord.Category__c) ? 'Others' : currentRecord.Category__c;
                List<DHS_Knowledge_Base__c> conflictingRecords = [
                    SELECT Id, Sequence__c 
                    FROM DHS_Knowledge_Base__c 
                    WHERE Category__c = :category 
                    AND Sequence__c = :Decimal.valueOf(newSequence)
                    AND Id != :sequenceKBID
                    WITH USER_MODE
                ];
                
                // Clear the sequence from conflicting records
                List<DHS_Knowledge_Base__c> recordsToUpdate = new List<DHS_Knowledge_Base__c>();
                for(DHS_Knowledge_Base__c conflictingRecord : conflictingRecords) {
                    conflictingRecord.Sequence__c = null;
                    recordsToUpdate.add(conflictingRecord);
                }
                
                // Update the current record with the new sequence
                currentRecord.Sequence__c = Decimal.valueOf(newSequence);
                recordsToUpdate.add(currentRecord);
                
                // Update all records
                if(!recordsToUpdate.isEmpty()) {
                    Database.update(recordsToUpdate, AccessLevel.USER_MODE);
                }
                
                // Refresh the articles to show updated sequence
                fetchArticles();
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to update the article sequence.'));
        }
    }
    
    // Method to get used sequences for a specific category
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public Map<String, Set<Integer>> getUsedSequencesByCategory(){
        Map<String, Set<Integer>> usedSequences = new Map<String, Set<Integer>>();
        
        for(String category : categoryOrder){
            usedSequences.put(category, new Set<Integer>());
        }
        usedSequences.put('Others', new Set<Integer>());
        
        // Collect all used sequences per category
        for(String category : documentsByCategory.keySet()){
            for(ArticleRecord doc : documentsByCategory.get(category)){
                Decimal sequenceValue = getSelectedDecimalValue(
                    doc.kb,
                    'Sequence__c'
                );
                if(sequenceValue != null){
                    usedSequences.get(category).add(
                        Integer.valueOf(sequenceValue)
                    );
                }
            }
        }
        
        return usedSequences;
    }

    private static String getSelectedStringValue(
        SObject recordValue,
        String fieldApiName
    ) {
        Object fieldValue = recordValue
            .getPopulatedFieldsAsMap()
            .get(fieldApiName);
        return fieldValue == null ? null : String.valueOf(fieldValue);
    }

    private static Decimal getSelectedDecimalValue(
        SObject recordValue,
        String fieldApiName
    ) {
        Object fieldValue = recordValue
            .getPopulatedFieldsAsMap()
            .get(fieldApiName);
        return fieldValue == null ? null : (Decimal) fieldValue;
    }

}