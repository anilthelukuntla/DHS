/**
 * @description Retains the existing DHSLeadDataGeneratorBatch integration and application behavior.
 */
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.EmptyStatementBlock,PMD.NcssCount,PMD.NcssMethodCount,PMD.StdCyclomaticComplexity')
public class DHSLeadDataGeneratorBatch implements Database.Batchable<SObject>, Database.Stateful {

    private Integer recordCount;
    private Id caseId;

    /**
     * @description Provides this DHS API member.
     * @param recordCount Method parameter.
     */
    public DHSLeadDataGeneratorBatch(Integer recordCount) {
        this.recordCount = (recordCount != null && recordCount > 0) ? recordCount : 10;
    }

    /**
     * @description Provides this DHS API member.
     * @param recordCount Method parameter.
     * @param caseId Method parameter.
     */
    public DHSLeadDataGeneratorBatch(Integer recordCount, Id caseId) {
        this(recordCount);
        this.caseId = caseId;
    }

    /**
     * @description Provides this DHS API member.
     * @param bc Method parameter.
     * @return The requested result.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Dummy query just to run execute()
        return Database.getQueryLocator([SELECT Id FROM DHS_Lead__c LIMIT 1]);
    }

    /**
     * @description Provides this DHS API member.
     * @param bc Method parameter.
     * @param scope Method parameter.
     */
    public void execute(Database.BatchableContext bc, List<DHS_Lead__c> scope) {
        List<DHS_Lead__c> leadsToInsert = new List<DHS_Lead__c>();

        Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.DHS_Lead__c.fields.getMap();

        for (Integer i = 70; i < recordCount; i++) {
            DHS_Lead__c l = new DHS_Lead__c();

            for (String fieldName : fieldsMap.keySet()) {
                Schema.DescribeFieldResult dfr = fieldsMap.get(fieldName).getDescribe();

                if (!dfr.isCreateable() || dfr.isAutoNumber() || dfr.isCalculated()) {
                    continue;
                }

                Schema.DisplayType dt = dfr.getType();

                try {
                    if (dt == Schema.DisplayType.String || dt == Schema.DisplayType.TextArea) {
                        l.put(fieldName, fieldName + '_Sample_' + i);
                    } else if (dt == Schema.DisplayType.Email) {
                        l.put(fieldName, 'lead' + i + '@example.com');
                    } else if (dt == Schema.DisplayType.Phone) {
                        l.put(fieldName, '+1-555-000' + i);
                    } else if (dt == Schema.DisplayType.Url) {
                        l.put(fieldName, 'https://example.com/lead/' + i);
                    } else if (dt == Schema.DisplayType.Boolean) {
                        l.put(fieldName, true);
                    } else if (dt == Schema.DisplayType.Integer) {
                        l.put(fieldName, i);
                    } else if (dt == Schema.DisplayType.Double || dt == Schema.DisplayType.Currency) {
                        l.put(fieldName, Decimal.valueOf(i));
                    } else if (dt == Schema.DisplayType.Date) {
                        l.put(fieldName, System.today().addDays(i));
                    } else if (dt == Schema.DisplayType.DateTime) {
                        l.put(fieldName, System.now().addDays(i));
                    } else if (dt == Schema.DisplayType.Picklist) {
                        List<Schema.PicklistEntry> entries = dfr.getPicklistValues();
                        if (!entries.isEmpty()) {
                            l.put(fieldName, entries[0].getValue()); // Use first picklist value
                        }
                    } else if (dt == Schema.DisplayType.Reference) {
                        // Handle OwnerId reference safely
                        if (fieldName == 'OwnerId') {
                            l.put('OwnerId', UserInfo.getUserId());
                        }
                    }
                    // else ignore unsupported field types
                } catch (Exception e) {
                    continue;
                }
            }

            // Required fields fallback
            l.DHS_Case__c = caseId;

            leadsToInsert.add(l);
        }

        if (!leadsToInsert.isEmpty()) {
            Database.insert(leadsToInsert, false, AccessLevel.USER_MODE);
        }
    }

    /**
     * @description Provides this DHS API member.
     * @param bc Method parameter.
     */
    public void finish(Database.BatchableContext bc) {
    }
}
