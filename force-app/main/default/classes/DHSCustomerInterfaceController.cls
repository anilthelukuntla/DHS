/**
 * @description Visualforce controller for DHS customer order and related case information.
 */
@SuppressWarnings('PMD.ApexSOQLInjection,PMD.UnusedMethod')
public with sharing class DHSCustomerInterfaceController {
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
    public DHSCustomerInterfaceController(){
        uploadedcustomerOrders = new List<OrderRecord> ();
        executedCustomerOrders = new List<OrderRecord> ();
        uploadedcustomerOrders = fetchOrderInformation('Uploaded'); 
        executedCustomerOrders = fetchOrderInformation('Executed');
        list<string> executedCustomerOrderIds = new list<string>();
        for(OrderRecord ord: executedCustomerOrders){
            executedCustomerOrderIds.add(ord.order.id);    
        }     
        executedCustomerOrdersandCasesMap = new Map<Id,List<DHS_Case__c>>();
        executedCustomerOrdersMap = new Map<Id,DHS_Customer_Order__c> ([Select Id, Status__c from DHS_Customer_Order__c where id in:executedCustomerOrderIds WITH SECURITY_ENFORCED]);
        List<DHS_Case__c> cases = fetchCasesofCustomerOrder(executedCustomerOrderIds);
        for(DHS_Case__c c: cases){
            if(!executedCustomerOrdersandCasesMap.containsKey(c.DHS_Order__c)){
                executedCustomerOrdersandCasesMap.put(c.DHS_Order__c, new list<DHS_Case__c> {c});
            }else{
                executedCustomerOrdersandCasesMap.get(c.DHS_Order__c).add(c);
            }
        }
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
        query = query + ' WHERE DHS_Order__c in:orderids WITH SECURITY_ENFORCED'; 
        // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
        list<DHS_Case__c> cases = database.query(query);
        return cases;
    }
    /** @description Provides this DHS API member. */
    public class OrderRecord{
        /** @description Provides this DHS API member. */
        public string attachmentId{get;set;}   
        /** @description Provides this DHS API member. */
        public DHS_Customer_Order__c order{get;set;}
        /**
         * @description Provides this DHS API member.
         * @param attachmentId Method parameter.
         * @param order Method parameter.
         */
        public OrderRecord(string attachmentId, DHS_Customer_Order__c order){
            this.order = order;    
            this.attachmentId = attachmentId;
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
        whereCriteria.add(new DHSApexUtil.Criteria('Status__c',status, '=')); 
        String whereCondition = DHSApexUtil.generateWhereQuery(whereCriteria); 
        if(String.isNotblank(whereCondition)){
            query = query + ' WHERE '+whereCondition ;     
        }else{
            query = query+' WITH SECURITY_ENFORCED Order by createddate desc';         
        }
        // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
        list<DHS_Customer_Order__c> orders = database.query(query);
        List<string> orderIds = new List<string>();
        for(DHS_Customer_Order__c doc: orders){
            orderIds.add(doc.id);
        }
        List<attachment> attachments = new List<attachment>();
        attachments = [Select id, parentid from attachment where parentid in: orderIds WITH SECURITY_ENFORCED];
        Map<String,String> orderNattachmentMap = new Map<String,String>();
        for(attachment att: attachments){
            orderNattachmentMap.put(att.parentid, att.id);    
        }
        
        for(DHS_Customer_Order__c doc: orders){
            customerOrders.add(new OrderRecord(orderNattachmentMap.get(doc.id),doc));  
        }
        
        return customerOrders;
    }
}
