public class DIAKnowledgeBaseController{
    public User currentUser {get;set;}
    public List< ArticleRecord > documents{get;set;}
    public DIAKnowledgeBaseController(){
        currentUser = [Select Id, User_Type__c FROM User where Id=:userinfo.getUserId()];
        FetchArticles();
    }
  
    public void FetchArticles(){
        documents = new list<ArticleRecord>();
        List<string> articleFields = new List<string>();
        articleFields = ApexUtil.FetchFields('DIA_Knowledge_Base__c');
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        String query = 'Select '+string.join(articleFields, ',') + ' From DIA_Knowledge_Base__c';
        String where_cond;    
        query = query + ' ORDER BY Createddate DESC '; 
        
        System.debug('query...'+query);
        List<DIA_Knowledge_Base__c> temp = database.query(query);
       
        List<string> documentIds = new List<string>();
        for(DIA_Knowledge_Base__c doc: temp){
            documentIds.add(doc.id);
        }
        List<attachment> attachments = new List<attachment>();
        attachments = [Select id, parentid from attachment where parentid in: documentIds];
        Map<String,String> documentNattachmentMap = new Map<String,String>();
        for(attachment att: attachments){
            documentNattachmentMap.put(att.parentid, att.id);    
        }
        
        for(DIA_Knowledge_Base__c doc: temp){
            if(documentNattachmentMap.get(doc.id) != Null){
                documents.add(new ArticleRecord(documentNattachmentMap.get(doc.id),doc));  
            }
        } 
    }
    
    public class ArticleRecord{
        public DIA_Knowledge_Base__c kb{get;set;}
        public string attachmentId {get;set;}
        public ArticleRecord(string attachmentId, DIA_Knowledge_Base__c kb){
           this.attachmentId = attachmentId;
           this.kb = kb;
        }
    }
    
   public string deleteKBID{get;set;}
    
    public void DeleteKBAction(){
        List<DIA_Knowledge_Base__c> DNB = [select id from DIA_Knowledge_Base__c where id=:deleteKBID ];
        if(Schema.SobjectType.DIA_Knowledge_Base__c.isDeletable()){
            delete DNB;
            FetchArticles();
            /*Database.DeleteResult[] drList = database.delete(DNB,false,AccessLevel.USER_MODE);
                integer i = 0;
                for( Database.DeleteResult dr : drList){
                    if(dr.isSuccess()) i++;
                }
                if(i == DNB.size()){
                    
                }*/
        }
    }
}