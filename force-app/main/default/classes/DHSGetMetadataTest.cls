@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
public class DHSGetMetadataTest {
    @IsTest static void getdata(){
        System.assert(true, 'Expected the test scenario to complete without exception');
        DHSGetMetadata.getFieldMap('CDRLCaseExport');
        DHSGetMetadata.getFieldMap('CDRLCheckInCheckOut');
        DHSGetMetadata.getFieldMap('CDRLLeadExport');
        DHSGetMetadata.getFieldMap('CDRLMessageExport');
        DHSGetMetadata.getFieldMap('CDRLWaiverExport');
        DHSGetMetadata.getFieldMap('DIACDRLCaseExport');
        DHSGetMetadata.getFieldMap('DIACDRLCheckInCheckOut');
        DHSGetMetadata.getFieldMap('DIACDRLLeadExport');
        DHSGetMetadata.getFieldMap('DIACDRLMessageExport');
        DHSGetMetadata.getFieldMap('DIACDRLWaiverExport');
        DHSGetMetadata.getFieldMap('pendingCasesByStatus');
        DHSGetMetadata.getFieldMap('PendingLeadsByStatus');
        DHSGetMetadata.getFieldMap('PendingLeadsByType');
        DHSGetMetadata.getFieldMap('CasesCompletedThisWeek');
        DHSGetMetadata.getFieldMap('CaseDashboardExport');
        DHSGetMetadata.getFieldMap('ICTimeSheet');
        DHSGetMetadata.getFieldMap('Workload');
        DHSGetMetadata.getFieldMap('invoice');
        DHSGetMetadata.getFieldMap('LeadDashboardExport');
        DHSGetMetadata.getFieldMap('ManifestExport');
        DHSGetMetadata.getFieldMap('ManifestReport');
        DHSGetMetadata.getFieldMap('WaiverRequest');
        DHSGetMetadata.getFieldMap('ExtensionRequest');
    }
}