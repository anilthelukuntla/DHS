public with sharing class KnowledgeBaseController{
    public User currentUser {get;set;}
    public List< ArticleRecord > documents{get;set;}
    public Map<String, List<ArticleRecord>> documentsByCategory{get;set;}
    public List<String> categoryOrder{get;set;}
    public Map<String, Integer> categoryCounts{get;set;}
    
    public KnowledgeBaseController(){
        currentUser = [Select Id, User_Type__c FROM User where Id=:userinfo.getUserId() WITH SECURITY_ENFORCED];
        FetchArticles();
    }
  
    public void FetchArticles(){
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
        articleFields = ApexUtil.FetchFields('Knowledge_Base__c');
        
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        String query = 'Select '+string.join(articleFields, ',') + ' From Knowledge_Base__c';
        String where_cond;    
        query = query + ' WITH SECURITY_ENFORCED ORDER BY Category__c, Sequence__c NULLS LAST, Createddate DESC';
        List<Knowledge_Base__c> temp = database.query(query);
       
        List<string> documentIds = new List<string>();
        for(Knowledge_Base__c doc: temp){
            documentIds.add(doc.id);
        }
        List<attachment> attachments = new List<attachment>();
        attachments = [Select id, parentid from attachment where parentid in: documentIds WITH SECURITY_ENFORCED];
        Map<String,String> documentNattachmentMap = new Map<String,String>();
        for(attachment att: attachments){
            documentNattachmentMap.put(att.parentid, att.id);    
        }
        
        for(Knowledge_Base__c doc: temp){
            if(documentNattachmentMap.get(doc.id) != Null){
                ArticleRecord articleRecord = new ArticleRecord(documentNattachmentMap.get(doc.id),doc);
                documents.add(articleRecord);
                
                // Group by category with null safety
                String category = doc.Category__c;
                
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
    
    public class ArticleRecord{
        public Knowledge_Base__c kb{get;set;}
        public string attachmentId {get;set;}
        public ArticleRecord(string attachmentId, Knowledge_Base__c kb){
           this.attachmentId = attachmentId;
           this.kb = kb;
        }
    }
    
   public string deleteKBID{get;set;}
   public string editKBID{get;set;}
   public string newCategory{get;set;}
   public string sequenceKBID{get;set;}
   public string newSequence{get;set;}
    
    public void DeleteKBAction(){
        list<Knowledge_Base__c> delkb = [select id from Knowledge_Base__c where id=:deleteKBID WITH SECURITY_ENFORCED];
        database.delete(delkb,false,AccessLevel.USER_MODE);
        FetchArticles();
    }
    
    public void UpdateCategoryAction(){
        try {
            if(String.isNotBlank(editKBID) && String.isNotBlank(newCategory)) {
                Knowledge_Base__c kbToUpdate = new Knowledge_Base__c(
                    Id = editKBID,
                    Category__c = newCategory
                );
                update kbToUpdate;
                
                // Refresh the articles to show updated categories
                FetchArticles();
            }
        } catch (Exception e) {
            System.debug('Error updating category: ' + e.getMessage());
            // You could add a page message here if needed
        }
    }
    
    public void UpdateSequenceAction(){
        try {
            if(String.isNotBlank(sequenceKBID) && String.isNotBlank(newSequence)) {
                // First, get the current record to find its category
                Knowledge_Base__c currentRecord = [SELECT Id, Category__c, Sequence__c FROM Knowledge_Base__c WHERE Id = :sequenceKBID WITH SECURITY_ENFORCED LIMIT 1];
                
                // Find any other record in the same category that has the new sequence number
                String category = String.isBlank(currentRecord.Category__c) ? 'Others' : currentRecord.Category__c;
                List<Knowledge_Base__c> conflictingRecords = [
                    SELECT Id, Sequence__c 
                    FROM Knowledge_Base__c 
                    WHERE Category__c = :category 
                    AND Sequence__c = :Decimal.valueOf(newSequence)
                    AND Id != :sequenceKBID
                    WITH SECURITY_ENFORCED
                ];
                
                // Clear the sequence from conflicting records
                List<Knowledge_Base__c> recordsToUpdate = new List<Knowledge_Base__c>();
                for(Knowledge_Base__c conflictingRecord : conflictingRecords) {
                    conflictingRecord.Sequence__c = null;
                    recordsToUpdate.add(conflictingRecord);
                }
                
                // Update the current record with the new sequence
                currentRecord.Sequence__c = Decimal.valueOf(newSequence);
                recordsToUpdate.add(currentRecord);
                
                // Update all records
                if(!recordsToUpdate.isEmpty()) {
                    update recordsToUpdate;
                }
                
                // Refresh the articles to show updated sequence
                FetchArticles();
            }
        } catch (Exception e) {
            System.debug('Error updating sequence: ' + e.getMessage());
        }
    }
    
    // Method to get used sequences for a specific category
    public Map<String, Set<Integer>> getUsedSequencesByCategory(){
        Map<String, Set<Integer>> usedSequences = new Map<String, Set<Integer>>();
        
        for(String category : categoryOrder){
            usedSequences.put(category, new Set<Integer>());
        }
        usedSequences.put('Others', new Set<Integer>());
        
        // Collect all used sequences per category
        for(String category : documentsByCategory.keySet()){
            for(ArticleRecord doc : documentsByCategory.get(category)){
                if(doc.kb.Sequence__c != null){
                    usedSequences.get(category).add(Integer.valueOf(doc.kb.Sequence__c));
                }
            }
        }
        
        return usedSequences;
    }

}