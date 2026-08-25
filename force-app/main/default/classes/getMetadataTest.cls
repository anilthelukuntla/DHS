@isTest
public class getMetadataTest {
    TestMethod static void getdata(){
        getMetadata.getFieldMap('CDRLCaseExport');
        getMetadata.getFieldMap('CDRLCheckInCheckOut');
        getMetadata.getFieldMap('CDRLLeadExport');
        getMetadata.getFieldMap('CDRLMessageExport');
        getMetadata.getFieldMap('CDRLWaiverExport');
        getMetadata.getFieldMap('DIACDRLCaseExport');
        getMetadata.getFieldMap('DIACDRLCheckInCheckOut');
        getMetadata.getFieldMap('DIACDRLLeadExport');
        getMetadata.getFieldMap('DIACDRLMessageExport');
        getMetadata.getFieldMap('DIACDRLWaiverExport');
        getMetadata.getFieldMap('pendingCasesByStatus');
        getMetadata.getFieldMap('PendingLeadsByStatus');
        getMetadata.getFieldMap('PendingLeadsByType');
        getMetadata.getFieldMap('CasesCompletedThisWeek');
    }
}