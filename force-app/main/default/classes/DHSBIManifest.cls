/** Retains the existing DHSBIManifest integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc, PMD.ApexCRUDViolation')
public with sharing class DHSBIManifest {
    @AuraEnabled(cacheable=true)
    public static ContentDistribution getDistributionPublicUrl() {
        List<ContentDistribution> links = [
            SELECT Id, DistributionPublicUrl
            FROM ContentDistribution
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return links.isEmpty() ? null : links[0];
    }
}