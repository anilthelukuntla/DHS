/**
 * @description Controls DHS customer-order processing, deliverable search, and ACD updates.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.EmptyStatementBlock,PMD.ExcessiveParameterList,PMD.NcssCount,PMD.NcssMethodCount,PMD.StdCyclomaticComplexity,PMD.UnusedMethod')
global with sharing class DHSUpdateACDDateController {
    /** @description Provides this DHS API member. */
    public List<OrderRecord> customerOrders {get;set;}
    /** @description Provides this DHS API member. */
    public List<OrderRecord> uploadedcustomerOrders {get;set;}
    /** @description Provides this DHS API member. */
    public List<OrderRecord> executedCustomerOrders {get;set;}
    /** @description Provides this DHS API member. */
    public Map<Id,List<DHS_Case__c>> executedCustomerOrdersandCasesMap {get;set;}
    /** @description Provides this DHS API member. */
    public Map<Id,DHS_Customer_Order__c> executedCustomerOrdersMap {get;set;}
    /** @description Provides this DHS API member. */
    global string subjectFirstNameSearchEntry {get;set;}
    /** @description Provides this DHS API member. */
    global string subjectLastNameSearchEntry {get;set;}
    /** @description Provides this DHS API member. */
    global string subjectSSNSearchEntry {get;set;}
    /** @description Provides this DHS API member. */
    global List<DeliverableWrapper> deliverables {get;set;}
    @RemoteAction
    /**
     * @description Provides this DHS API member.
     * @param contentversionIds Method parameter.
     */
    global static void createOrderNDocuments(list<string> contentversionIds){
        list<contentversion> contentVersions = [select id,ContentDocumentId from contentversion WHERE ID IN:contentversionIds WITH USER_MODE];
        list<string> contentDocumentIds = new list<string>();
        for(contentversion cv: contentVersions){
        	contentDocumentIds.add(cv.ContentDocumentId);    
        }
        DHS_Customer_Order_Upload_Log__c log = new DHS_Customer_Order_Upload_Log__c();
        list<ContentDocumentLink> cdlsToCreate = new list<ContentDocumentLink>();
        DHS_Customer_Order__c co = new DHS_Customer_Order__c ();
        co.Status__c = 'Uploaded';
        try{
        	database.insert(co,false,AccessLevel.USER_MODE); 
            log.DHS_Customer_Order__c  = co.id;
        }catch(Exception ex){
        	log.Error_Message__c = ex.getmessage();        
        }
        Database.insert(log, AccessLevel.USER_MODE);
        for(string contentDocumentId : contentDocumentIds){
        	ContentDocumentLink cdl = new ContentDocumentLink();
			cdl.ContentDocumentId = contentDocumentId;
            cdl.LinkedEntityId = co.id;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            cdlsToCreate.add(cdl);
        }
        if(!cdlsToCreate.isEmpty()){
        	database.insert(cdlsToCreate,false,AccessLevel.USER_MODE);    
        }
      
        DHSExecuteCustomerOrdersBatch ctrl = new DHSExecuteCustomerOrdersBatch(co.id,log.id);
        if (!Test.isRunningTest()) {
            database.executebatch(ctrl);
        }
    }
    
    /** @description Provides this DHS API member. */
    public void getCustomerOrders(){
    	 uploadedcustomerOrders = new List<OrderRecord> ();
        executedCustomerOrders = new List<OrderRecord> ();
        uploadedcustomerOrders = fetchOrderInformation('Uploaded'); 
        executedCustomerOrders = fetchOrderInformation('Executed');
        list<string> executedCustomerOrderIds = new list<string>();
        for(OrderRecord ord: executedCustomerOrders){
            executedCustomerOrderIds.add(ord.order.id);    
        }     
        executedCustomerOrdersandCasesMap = new Map<Id,List<DHS_Case__c>>();
        executedCustomerOrdersMap = new Map<Id,DHS_Customer_Order__c> ([Select Id, Status__c,ACD_Date__c from DHS_Customer_Order__c where id in:executedCustomerOrderIds WITH USER_MODE order by createddate desc]);
        List<DHS_Case__c> cases = fetchCasesofCustomerOrder(executedCustomerOrderIds);
        for(DHS_Case__c c: cases){
            if(!executedCustomerOrdersandCasesMap.containsKey(c.DHS_Order__c)){
                executedCustomerOrdersandCasesMap.put(c.DHS_Order__c, new list<DHS_Case__c> {c});
            }else{
                executedCustomerOrdersandCasesMap.get(c.DHS_Order__c).add(c);
            }
        }
        for(OrderRecord ord: executedCustomerOrders){
            if(!executedCustomerOrdersandCasesMap.containsKey(ord.order.id)){
                executedCustomerOrdersandCasesMap.put(ord.order.id,new list<DHS_Case__c>{});  
            }    
        }      
    }
    /** @description Provides this DHS API member. */
    public DHSUpdateACDDateController(){
       getDeliverables();
       getCustomerOrders();
    }
      /** @description Provides this DHS API member. */
      global void getDeliverables(){
        deliverables = New List<DeliverableWrapper>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        List<string> caseFields = new List<string>();
        caseFields = DHSApexUtil.FetchFields('DHS_Case__c');
        caseFields.add('CreatedBy.Name');
		caseFields.add('DHS_Contact__r.Last_Name__c');
        String query = 'Select '+string.join(caseFields, ',') + ',(select id,Name__c from DHS_Case_Documents__r) From DHS_Case__c ';
        String whereCond;
        if(String.isNotBlank(string.valueof(subjectFirstNameSearchEntry))){
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_Contact__r.First_Name__c', '%'+String.escapeSingleQuotes(subjectFirstNameSearchEntry)+'%', 'LIKE'));
        }
        if(String.isNotBlank(string.valueof(subjectLastNameSearchEntry))){
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_Contact__r.Last_Name__c', '%'+String.escapeSingleQuotes(subjectLastNameSearchEntry)+'%', 'LIKE'));
        }
        if(String.isNotBlank(string.valueof(subjectSSNSearchEntry))){
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_Contact__r.SSN__c', '%'+subjectSSNSearchEntry+'%', 'LIKE'));
        }
        whereCriteria.add(new DHSApexUtil.Criteria('Current_Task__c', 'QA Review Completed', '='));
        whereCond = DHSApexUtil.generateWhereQuery(whereCriteria); 
        query = query + ' WHERE '+whereCond+' Order by CreatedDate Desc';
        list<DHS_Case__c> cases = database.query(query, AccessLevel.USER_MODE);
        Map<string,string> docNcaseMap = new Map<string,string>();
        for(DHS_Case__c cse : cases){
            if(cse.DHS_Case_Documents__r.size() > 0){
                for(DHS_Document__c doc : cse.DHS_Case_Documents__r){
                    if(doc.Name__c == 'ROIReport'){
                        docNcaseMap.put(cse.Id,doc.Id);
                    }
				}
			}
		}
        Map<string,string> docNatt = New Map<string,string>();
        List<attachment> att = [select id,parentId from attachment where parentId IN: docNcaseMap.values() WITH USER_MODE ];
        for(attachment a : att){
            docNatt.put(a.parentId,a.Id);
		}
        for(DHS_Case__c cse : cases){
            DeliverableWrapper del = New DeliverableWrapper();
            del.caseNumber = cse.Case_Number__c;
            del.createdBy = cse.CreatedBy.Name;
            del.createdDate = cse.createddate;
            del.documentId = docNatt.get(docNcaseMap.get(cse.Id));
            del.caseId = cse.Id;
            del.completedDate = cse.Case_Completed_Date__c;
            del.dueDate = cse.Case_Due_Date__c;
            del.lastName = cse.DHS_Contact__r.Last_Name__c;
            deliverables.add(del);
        }
        if(deliverables.size() > 0){
            for(DeliverableWrapper dele : deliverables){
            }
        }
	}
        /** @description Provides this DHS API member. */
        global class DeliverableWrapper{
            /** @description Provides this DHS API member. */
            global string caseId {get;set;}
            /** @description Provides this DHS API member. */
            global string caseNumber {get;set;}
            /** @description Provides this DHS API member. */
            global datetime createdDate {get;set;}
            /** @description Provides this DHS API member. */
            global string createdBy {get;set;}
            /** @description Provides this DHS API member. */
            global string documentId {get;set;}
            /** @description Provides this DHS API member. */
            global date completedDate {get;set;}
            /** @description Provides this DHS API member. */
            global date dueDate {get;set;}
            /** @description Provides this DHS API member. */
            global string lastName {get;set;}
        }
    /**
     * @description Provides this DHS API member.
     * @param orderids Method parameter.
     * @return The requested result.
     */
    public list<DHS_Case__c> fetchCasesofCustomerOrder(list<string> orderids){
        List<string> caseFields = new List<string>();
        caseFields = DHSApexUtil.FetchFields('DHS_Case__c');
        String query = 'Select '+string.join(caseFields, ',') + ' From DHS_Case__c ';
        //whereCriteria.add(new DHSApexUtil.Criteria('DHS_Order__c', orderids, 'IN:'));
        //where_cond = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE DHS_Order__c in:orderids'; 
        list<DHS_Case__c> cases = database.query(query, AccessLevel.USER_MODE);
        return cases;
    }
    /** @description Provides this DHS API member. */
    public class OrderRecord{
        /** @description Provides this DHS API member. */
        public string attachmentId{get;set;}   
        /** @description Provides this DHS API member. */
        public DHS_Customer_Order__c order{get;set;}
        /** @description Provides this DHS API member. */
        public string logMessage{get;set;}
        /** @description Provides this DHS API member. */
        public string logAttachmentId{get;set;}
        /**
         * @description Provides this DHS API member.
         * @param attachmentId Method parameter.
         * @param order Method parameter.
         * @param logMessage Method parameter.
         * @param logAttachmentId Method parameter.
         */
        public OrderRecord(string attachmentId, DHS_Customer_Order__c order, string logMessage,string logAttachmentId){
            this.order = order;    
            this.attachmentId = attachmentId;
            this.logMessage = logMessage;
            this.logAttachmentId = logAttachmentId;
        }
    }
    
    /** @description Provides this DHS API member. */
    public void saveOrderAction(){
    	list<DHS_Customer_Order__c> ordersToUpdate = new list<DHS_Customer_Order__c>();
        for(OrderRecord oRecord: executedCustomerOrders){
            if(oRecord.order.ACD_Date__c != Null){
            	ordersToUpdate.add(oRecord.order);    
            }    
        }
        if(!ordersToUpdate.isEmpty()){
            database.update(ordersToUpdate,false,AccessLevel.USER_MODE);
            getCustomerOrders();
        }
    }
    
    /**
     * @description Provides this DHS API member.
     * @param status Method parameter.
     * @return The requested result.
     */
    public List<OrderRecord> fetchOrderInformation(string status){
        List<OrderRecord> customerOrders = new List<OrderRecord> ();
        List<string> orderFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        orderFields = DHSApexUtil.FetchFields('DHS_Customer_Order__c'); 
        orderFields.add('owner.name');
        String query = 'Select '+string.join(orderFields, ',') + ' From DHS_Customer_Order__c ';
        //whereCriteria.add(new DHSApexUtil.Criteria('Status__c',status, '=')); 
        String whereCond = DHSApexUtil.generateWhereQuery(whereCriteria); 
        if(String.isNotblank(whereCond)){
            query = query + ' WHERE '+whereCond ;     
        }else{
            query = query+' Order by createddate desc';         
        }
        list<DHS_Customer_Order__c> orders = database.query(query, AccessLevel.USER_MODE);
        List<string> orderIds = new List<string>();
        for(DHS_Customer_Order__c doc: orders){
            orderIds.add(doc.id);
        }
        list< DHS_Customer_Order_Upload_Log__c  > logs= new list< DHS_Customer_Order_Upload_Log__c >();
        logs = [select id, Error_Message__c ,DHS_Customer_Order__c from DHS_Customer_Order_Upload_Log__c where DHS_Customer_Order__c IN:orderIds WITH USER_MODE ];
        map<string, DHS_Customer_Order_Upload_Log__c> orderNlogMap = new map<string,DHS_Customer_Order_Upload_Log__c>();
        map<string, string> logNattachmentMap = new map<string,string>();
        list<string> logIds =new list<string>();
        for(DHS_Customer_Order_Upload_Log__c log: logs){
        	orderNlogMap.put(log.DHS_Customer_Order__c,log);
            logIds.add(log.id);
        }
        list<attachment> atts = [select id, parentid,name from attachment where parentid in:logIds WITH USER_MODE ];
        for(attachment att: atts){
        	logNattachmentMap.put(att.parentid,att.id);    
        }
        
        List<ContentDocumentLink> documentsAttached = new List<ContentDocumentLink>();
        if(!orderIds.isEmpty()) {
            documentsAttached = [Select id, ContentDocumentId, ContentDocument.title, LinkedEntityId from ContentDocumentLink WHERE LinkedEntityId IN: orderids and ContentDocument.title='OrderData.csv' WITH USER_MODE ];
        }
        Map<String,String> orderNattachmentMap = new Map<String,String>();
        for(ContentDocumentLink cdl: documentsAttached){
            orderNattachmentMap.put(cdl.LinkedEntityId, cdl.ContentDocumentId);    
        }
        
        for(DHS_Customer_Order__c doc: orders){
            if(orderNlogMap.get(doc.id) == Null){
            	customerOrders.add(new OrderRecord(orderNattachmentMap.get(doc.id),doc,null,null));      
            }else if(orderNlogMap.get(doc.id).Error_Message__c != Null){
            	customerOrders.add(new OrderRecord(orderNattachmentMap.get(doc.id),doc,orderNlogMap.get(doc.id).Error_Message__c,null));      	    
            }else if(logNattachmentMap.get(orderNlogMap.get(doc.id).id) != Null){
            	customerOrders.add(new OrderRecord(orderNattachmentMap.get(doc.id),doc,null,logNattachmentMap.get(orderNlogMap.get(doc.id).id)));      	    
            }
            
        }
        
        return customerOrders;
    }
	
}