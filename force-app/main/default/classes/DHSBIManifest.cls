/** Retains the existing DHSBIManifest integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc')
public with sharing class DHSBIManifest {
    @AuraEnabled(cacheable=true)
    public static ContentDistribution getDistributionPublicUrl() {
        List<ContentDistribution> links = [
            SELECT Id, DistributionPublicUrl
            FROM ContentDistribution
             WITH USER_MODE ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return links.isEmpty() ? null : links[0];
    }
}
